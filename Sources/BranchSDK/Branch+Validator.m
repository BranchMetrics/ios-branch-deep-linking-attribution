//
//  Branch+Validator.m
//  Branch
//
//  Created by agrim on 12/18/17.
//  Copyright © 2017 Branch, Inc. All rights reserved.
//

#import "Branch+Validator.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BNCApplication.h"
#import "BNCEncodingUtils.h"
#import "BNCServerAPI.h"
#import "UIViewController+Branch.h"
#import "BNCConfig.h"
#import "Branch.h"
#if !TARGET_OS_TV
#import "BranchFileLogger.h"
#endif

void BNCForceBranchValidatorCategoryToLoad(void) {
    // Empty body but forces loader to load the category.
}

static inline void BNCPerformBlockOnMainThreadAsync(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

static inline dispatch_time_t BNCDispatchTimeFromSeconds(NSTimeInterval seconds)    {
    return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void BNCAfterSecondsPerformBlockOnMainThread(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_after(BNCDispatchTimeFromSeconds(seconds), dispatch_get_main_queue(), block);
}

typedef NS_ENUM(NSUInteger, BranchValidationError) {
    BranchLinkDomainError, // for link domain or alternate domain mismatch
    BranchURISchemeError, // for uri scheme mismatch
    BranchAppIDError, // for bundle ID or app prefix mismatch
    BranchATTError // for idfa missing error
};

NSString *BranchValidationErrorDescription(BranchValidationError error) {
    switch (error) {
        case BranchLinkDomainError:
            return @"Check the link domain and alternate domain values in your info.plist file under the key 'branch_universal_link_domains'. The values should match with the ones on the Branch dashboard.\n\n";
        case BranchURISchemeError:
            return @"The URI scheme in your info.plist file should match with the URI scheme value for iOS on the Branch dashboard.\n\n";
        case BranchAppIDError:
            return @"Check your bundle ID and Apple App Prefix from the Apple Developer website and ensure it matches with the values you have added on the Branch dashboard.\n\n";
        case BranchATTError:
            return @"The ATT prompt ensures that the Branch SDK can access the IDFA when the user permits it. Add the ATT prompt in your app for IDFA access.\n\n";
    }
    return @"Unknown";
}

NSString *BranchValidationErrorReferenceDescription(BranchValidationError error) {
    switch (error) {
        case BranchLinkDomainError:
            return @"Link Domain Reference";
        case BranchURISchemeError:
            return @"URI Scheme Reference";
        case BranchAppIDError:
            return @"App Prefix/Bundle ID Reference";
        case BranchATTError:
            return @"ATT Prompt Reference";
    }
    return @"Unknown";
}

NSURL *BranchValidationErrorReference(BranchValidationError error) {
    NSString *urlString;

    switch (error) {
        case BranchLinkDomainError:
            urlString = @"https://help.branch.io/developers-hub/docs/ios-basic-integration#4-configure-infoplist";
            break;
        case BranchURISchemeError:
            urlString = @"https://help.branch.io/developers-hub/docs/ios-basic-integration#4-configure-infoplist";
            break;
        case BranchAppIDError:
            urlString = @"https://help.branch.io/developers-hub/docs/ios-basic-integration#1-configure-branch-dashboard";
            break;
        case BranchATTError:
            urlString = @"https://help.branch.io/developers-hub/docs/ios-advanced-features#include-apples-attrackingmanager";
            break;
    }

    return [NSURL URLWithString:urlString];
}

#pragma mark - Branch (Validator)

@implementation Branch (Validator)

- (void)validateSDKIntegrationCore {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self startValidation];
    });
}

- (void) startValidation {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *serverURL = [[BNCServerAPI sharedInstance] validationServiceURL];
    NSString *endpoint = [serverURL stringByAppendingPathComponent:preferenceHelper.lastRunBranchKey];
    
    [[[BNCServerInterface alloc] init] getRequest:nil url:endpoint key:nil callback:^ (BNCServerResponse *response, NSError *error) {
        if (error) {
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
        } else {
            [self validateIntegrationWithServerResponse:response];
        }
    }];
}

- (void) validateIntegrationWithServerResponse:(BNCServerResponse*)response {
    NSString*passString = @"PASS";
    NSString*errorString = @"ERROR";

    // Decode the server message:
    NSString*serverUriScheme    = BNCStringFromWireFormat(response.data[@"ios_uri_scheme"]) ?: @"";
    NSString*serverBundleID     = BNCStringFromWireFormat(response.data[@"ios_bundle_id"]) ?: @"";
    NSString*serverTeamID       = BNCStringFromWireFormat(response.data[@"ios_team_id"]) ?: @"";
    NSString*defaultDomain = BNCStringFromWireFormat(response.data[@"default_short_url_domain"]) ?: @"";
    NSString*alternateDomain = BNCStringFromWireFormat(response.data[@"alternate_short_url_domain"]) ?: @"";
    NSString*attOptInStatus = [BNCSystemObserver attOptedInStatus];

    // Verify:
    NSLog(@"** Initiating Branch integration verification **");
    NSLog(@"-------------------------------------------------");

    NSLog(@"------ Checking for URI scheme correctness ------");
    bool doUriSchemesMatch = [BNCSystemObserver compareUriSchemes:serverUriScheme];
    NSString *uriScheme = doUriSchemesMatch ? passString : errorString;
    NSLog(@"-------------------------------------------------");

    NSLog(@"-- Checking for bundle identifier correctness ---");
    NSString *clientBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    bool doBundleIDsMatch = [serverBundleID isEqualToString:clientBundleIdentifier];
    NSString *bundleIdentifier = doBundleIDsMatch ? passString : errorString;
    NSString *bundleIdentifierMessage =
        [NSString stringWithFormat:@"%@: Dashboard Link Settings page '%@' compared to client side '%@'",
            bundleIdentifier, serverBundleID, clientBundleIdentifier];
    NSLog(@"%@",bundleIdentifierMessage);
    NSLog(@"-------------------------------------------------");

    NSLog(@"----- Checking for iOS Team ID correctness ------");
    NSString *clientTeamId = [BNCApplication currentApplication].teamID ?: @"";
    NSString *teamID = [serverTeamID isEqualToString:clientTeamId] ? passString : errorString;
    NSString *teamIDMessage =
        [NSString stringWithFormat:@"%@: Dashboard Link Settings page '%@' compared to client side '%@'",
            teamID, serverTeamID, clientTeamId];
    NSLog(@"%@",teamIDMessage);
    NSLog(@"-------------------------------------------------");

    if ([teamID isEqualToString:errorString] ||
        [bundleIdentifier isEqualToString:errorString] ||
        [uriScheme isEqualToString:errorString]) {
        NSLog(@"%@: server side '%@' compared to client side '%@'.", errorString, serverTeamID, clientTeamId);
        NSLog(@"To fix your Dashboard settings head over to https://branch.app.link/link-settings-page");
        NSLog(@"If you see a null value on the client side, please temporarily add the following key-value pair to your plist: \n\t<key>AppIdentifierPrefix</key><string>$(AppIdentifierPrefix)</string>\n-> then re-run this test.");
        NSLog(@"-------------------------------------------------");
    }

    NSLog(@"-------------------------------------------------------------------------------------------------------------------");
    NSLog(@"-----To test your deeplink routing append ?bnc_validate=true to any branch link and click it on your mobile device-----");
    NSLog(@"-------------------------------------------------------------------------------------------------------------------");

    BOOL testsFailed = NO;
    NSString *kPassMark = @"✅\t";
    NSString *kFailMark = @"❌\t";
    NSString *kWarningMark = @"⚠️\t";

    // Build an alert string:
    NSString *alertString = @"";
    NSMutableArray<NSNumber *> *errors = [[NSMutableArray alloc] init];
    alertString = [alertString stringByAppendingFormat:@"\nBranch SDK Version: %@\n", BNC_SDK_VERSION];
    if ([Branch useTestBranchKey]) {
        alertString = [alertString stringByAppendingFormat:@"The SDK is using the test key\n\n"];
    } else {
        alertString = [alertString stringByAppendingFormat:@"The SDK is using the live key\n\n"];
    }
    if ([BNCSystemObserver compareLinkDomain:defaultDomain]) {
        alertString = [alertString stringByAppendingFormat:@"%@Default Link Domain matches:\n\t'%@'\n", kPassMark, defaultDomain];
    } else {
        testsFailed = YES;
        alertString = [alertString stringByAppendingFormat:@"%@Default Link Domain mismatch:\n\t'%@'\n", kFailMark, defaultDomain];
        if (![errors containsObject:@(BranchLinkDomainError)]) {
            [errors addObject:@(BranchLinkDomainError)];
        }
    }

    if ([BNCSystemObserver compareLinkDomain:alternateDomain]) {
        alertString = [alertString stringByAppendingFormat:@"%@Alternate Link Domain matches:\n\t'%@'\n", kPassMark, alternateDomain];
    } else {
        testsFailed = YES;
        alertString = [alertString stringByAppendingFormat:@"%@Alternate Link Domain mismatch:\n\t'%@'\n", kFailMark, alternateDomain];
        if (![errors containsObject:@(BranchLinkDomainError)]) {
            [errors addObject:@(BranchLinkDomainError)];
        }
    }

    if (serverUriScheme.length && doUriSchemesMatch) {
        alertString = [alertString stringByAppendingFormat:@"%@URI Scheme matches:\n\t'%@'\n",
            kPassMark,  serverUriScheme];
    } else {
        testsFailed = YES;
        alertString = [alertString stringByAppendingFormat:@"%@URI Scheme mismatch:\n\t'%@'\n",
            kFailMark,  serverUriScheme];
        if (![errors containsObject:@(BranchURISchemeError)]) {
            [errors addObject:@(BranchURISchemeError)];
        }
    }

    if ([serverBundleID isEqualToString:clientBundleIdentifier]) {
        alertString = [alertString stringByAppendingFormat:@"%@App Bundle ID matches:\n\t'%@'\n",
            kPassMark,  serverBundleID];
    } else {
        testsFailed = YES;
        alertString = [alertString stringByAppendingFormat:@"%@App Bundle ID mismatch:\n\t'%@'\n",
            kFailMark,  serverBundleID];
        if (![errors containsObject:@(BranchAppIDError)]) {
            [errors addObject:@(BranchAppIDError)];
        }
    }

    if ([serverTeamID isEqualToString:clientTeamId]) {
        alertString = [alertString stringByAppendingFormat:@"%@Team ID matches:\n\t'%@'\n",
            kPassMark,  serverTeamID];
    } else {
        testsFailed = YES;
        alertString = [alertString stringByAppendingFormat:@"%@Team ID mismatch:\n\t'%@'\n",
            kFailMark,  serverTeamID];
        if (![errors containsObject:@(BranchAppIDError)]) {
            [errors addObject:@(BranchAppIDError)];
        }
    }
    
    if ([attOptInStatus isEqualToString:@"authorized"]) {
        alertString = [alertString stringByAppendingFormat:@"%@IDFA is accessible\n", kPassMark];
    } else {
        alertString = [alertString stringByAppendingFormat:@"%@IDFA is not accessible\n", kWarningMark];
        if (![errors containsObject:@(BranchATTError)]) {
            [errors addObject:@(BranchATTError)];
        }
    }
    
    if (testsFailed) {
        alertString = [alertString stringByAppendingString:@"\nFailed!"];
    } else {
        alertString = [alertString stringByAppendingString:@"\nPassed!"];
    }

    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.alignment = NSTextAlignmentLeft;
    NSAttributedString *styledAlertString =
        [[NSAttributedString alloc]
            initWithString:alertString
            attributes:@{
                NSParagraphStyleAttributeName:  ps
            }];

    BNCPerformBlockOnMainThreadAsync(^{
        UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"Branch Integration Validator"
                message:alertString
                preferredStyle:UIAlertControllerStyleAlert];
        if (testsFailed) {
            [alertController
                addAction:[UIAlertAction actionWithTitle:@"What should I change?"
                style:UIAlertActionStyleDefault
                handler:^ (UIAlertAction *action) { [self showSolutionsForErrors:(errors)]; }]];
            [alertController
                addAction:[UIAlertAction actionWithTitle:@"Export Logs"
                style:UIAlertActionStyleDefault
                handler:^ (UIAlertAction *action) { [self showExportedLogs]; }]];
            [alertController
                addAction:[UIAlertAction actionWithTitle:@"Done"
                style:UIAlertActionStyleDefault
                handler:nil]];
        } else {
            [alertController
                addAction:[UIAlertAction actionWithTitle:@"Done"
                style:UIAlertActionStyleDefault
                handler:nil]];
            [alertController
                addAction:[UIAlertAction actionWithTitle:@"Export Logs"
                style:UIAlertActionStyleDefault
                handler:^ (UIAlertAction *action) { [self showExportedLogs]; }]];
        }
        [alertController setValue:styledAlertString forKey:@"attributedMessage"];
        [[UIViewController bnc_currentViewController]
            presentViewController:alertController
            animated:YES
            completion:nil];
    });
}

- (void) showSolutionsForErrors:(NSArray<NSNumber *>*) errors {
    NSString *message = @"";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"What should I change?" message: @"" preferredStyle: UIAlertControllerStyleAlert];
    for (NSNumber *errorNumber in errors) {
        BranchValidationError error = (BranchValidationError)[errorNumber integerValue];
        
        message = [message stringByAppendingString:BranchValidationErrorDescription(error)];
        
        [alertController
            addAction:[UIAlertAction actionWithTitle:BranchValidationErrorReferenceDescription(error)
            style:UIAlertActionStyleDefault
                                             handler:^ (UIAlertAction *action) {
            Class applicationClass = NSClassFromString(@"UIApplication");
            id<NSObject> sharedApplication = [applicationClass performSelector:@selector(sharedApplication)];
            if ([sharedApplication respondsToSelector:@selector(openURL:)])
                [sharedApplication performSelector:@selector(openURL:) withObject:BranchValidationErrorReference(error)];
        }]];
    }
    
    alertController.message = message;
    [alertController
        addAction:[UIAlertAction actionWithTitle:@"Done"
        style:UIAlertActionStyleDefault
        handler:nil]];
    
    [[UIViewController bnc_currentViewController]
        presentViewController:alertController
        animated:YES
        completion:nil];
}

- (void) showExportedLogs {
    #if !TARGET_OS_TV
    if ([[BranchFileLogger sharedInstance] isLogFilePopulated]) {
        UIViewController *currentVC = [UIViewController bnc_currentViewController];
        [[BranchFileLogger sharedInstance] shareLogFileFromViewController:currentVC];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"No log file available" message: @"Ensure that logging is enabled and you are running the app in debug mode to export logs." preferredStyle: UIAlertControllerStyleAlert];
        [alertController
            addAction:[UIAlertAction actionWithTitle:@"Done"
            style:UIAlertActionStyleDefault
            handler:nil]];
        [[UIViewController bnc_currentViewController]
            presentViewController:alertController
            animated:YES
            completion:nil];
    }
    #endif
}

//MARK: Not in use until development of Integration Validator Phase 2 Changes
- (void) showNextStep {
    NSString *message =
        @"\nGreat! Remove the 'validateSDKIntegration' line in your app.\n\n"
         "Next check your deep link routing.\n\n"
         "Append '?bnc_validate=true' to any of your app's Branch links and "
         "click on it on your mobile device (not the Simulator!) to start the test.\n\n"
         "For instance, to validate a link like:\n"
         "https://<yourapp>.app.link/NdJ6nFzRbK\n\n"
         "click on:\n"
         "https://<yourapp>.app.link/NdJ6nFzRbK?bnc_validate=true";
    
    NSLog(@"----------------------------------------------------------------------------");
    NSLog(@"Branch Integration Next Steps:");
    NSLog(@"%@", message);
    NSLog(@"----------------------------------------------------------------------------");

    [self showAlertWithTitle:@"Next Step" message:message];
}

- (void) showAlertWithTitle:(NSString*)title message:(NSString*)message {
    BNCPerformBlockOnMainThreadAsync(^{
        UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:title
                message:message
                preferredStyle:UIAlertControllerStyleAlert];
        [alertController
            addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault handler:nil]];
        [[UIViewController bnc_currentViewController]
            presentViewController:alertController
            animated:YES
            completion:nil];
    });
}

- (void)returnToBrowserBasedOnReferringLink:(NSString *)referringLink
                                currentTest:(NSString *)currentTest
                                 newTestVal:(NSString *)val {
    // TODO: handling for missing ~referring_link
    // TODO: test with short url where, say, t1=b is set in deep link data.
    // If this logic fails then we'll need to generate a new short URL, which is sucky.
    referringLink = [self.class returnNonUniversalLink:referringLink];
    NSURLComponents *comp = [NSURLComponents componentsWithURL:[NSURL URLWithString:referringLink] resolvingAgainstBaseURL:NO];
    NSArray *queryParams = [comp queryItems];
    NSMutableArray *newQueryParams = [NSMutableArray array];
    for (NSURLQueryItem *queryParam in queryParams) {
        if (![queryParam.name isEqualToString:currentTest]) {
            [newQueryParams addObject:queryParam];
        }
    }
    [newQueryParams addObject:[NSURLQueryItem queryItemWithName:currentTest value:val]];
    [newQueryParams addObject:[NSURLQueryItem queryItemWithName:@"validate" value:@"true"]];
    comp.queryItems = newQueryParams;
    
    Class applicationClass = NSClassFromString(@"UIApplication");
    id<NSObject> sharedApplication = [applicationClass performSelector:@selector(sharedApplication)];
    if ([sharedApplication respondsToSelector:@selector(openURL:)])
        [sharedApplication performSelector:@selector(openURL:) withObject:comp.URL];
}

- (void)validateDeeplinkRouting:(NSDictionary *)params {
    BNCAfterSecondsPerformBlockOnMainThread(0.30, ^{
        UIAlertController *alertController =
            [UIAlertController
                alertControllerWithTitle:@"Branch Deeplink Routing Support"
                message:nil
                preferredStyle:UIAlertControllerStyleAlert];

        if ([params[@"+clicked_branch_link"] isEqualToNumber:@YES]) {
            alertController.message =
                @"Good news - we got link data. Now a question for you, astute developer: "
                 "did the app deep link to the specific piece of content you expected to see?";
            // yes
            [alertController addAction:[UIAlertAction
                actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction * _Nonnull action) {
                        [self returnToBrowserBasedOnReferringLink:params[@"~referring_link"]
                            currentTest:params[@"ct"] newTestVal:@"g"];
            }]];
            // no
            [alertController addAction:[UIAlertAction
                actionWithTitle:@"No" style:UIAlertActionStyleDestructive
                    handler:^(UIAlertAction * _Nonnull action) {
                        [self returnToBrowserBasedOnReferringLink:params[@"~referring_link"]
                            currentTest:params[@"ct"] newTestVal:@"r"];
            }]];
            // cancel
            [alertController addAction:[UIAlertAction
                actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        }
        else {
            alertController.message =
                @"Bummer. It seems like +clicked_branch_link is false - we didn't deep link.  "
                 "Double check that the link you're clicking has the same branch_key that is being "
                 "used in your .plist file. Return to Safari when you're ready to test again.";
            [alertController addAction:[UIAlertAction
                actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil]];
        }
        [[UIViewController bnc_currentViewController]
            presentViewController:alertController animated:YES completion:nil];
    });
}

+ (NSString *) returnNonUniversalLink:(NSString *) referringLink {
    // Appending /e/ to not treat this link as a Universal link
    NSArray *lines = [referringLink componentsSeparatedByString: @"/"];
    referringLink = @"";
    for (int i = 0 ; i < [lines count]; i++) {
        if(i != 2) {
            referringLink = [referringLink stringByAppendingString:lines[i]];
            referringLink = [referringLink stringByAppendingString:@"/"];
        } else {
            referringLink = [referringLink stringByAppendingString:lines[i]];
            referringLink = [referringLink stringByAppendingString:@"/e/"];
        }
    }
    referringLink = [referringLink stringByReplacingOccurrencesOfString:@"-alternate" withString:@""];
    return referringLink;
}

@end
