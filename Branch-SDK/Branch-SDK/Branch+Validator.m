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

void BNCForceBranchValidatorCategoryToLoad(void) {
    // Does nothing but forces loader to load category.
}

@implementation Branch (Validator)

- (void)validateSDKIntegrationCore {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
        NSString *endpoint = [BRANCH_REQUEST_ENDPOINT_APP_LINK_SETTINGS stringByAppendingPathComponent:preferenceHelper.lastRunBranchKey];
        [[[BNCServerInterface alloc] init] getRequest:nil url:[preferenceHelper getAPIURL:endpoint] key:nil callback:^(BNCServerResponse *response, NSError *error) {
            if (error) {
                NSLog(@"Error with debugIntegration(): %@", error);
            }
            else {
                NSString *passString = @"PASS";
                NSString *errorString = @"ERROR";
                
                NSLog(@"** Initiating Branch integration verification **");
                NSLog(@"-------------------------------------------------");
                
                NSLog(@"------ checking for URI scheme correctness ------");
                NSString *serverUriScheme = response.data[@"ios_uri_scheme"];
                NSString *clientUriScheme = [NSString stringWithFormat:@"%@%@", [BNCSystemObserver getDefaultUriScheme], @"://"];
                NSString *uriScheme = [serverUriScheme isEqualToString:clientUriScheme] ? passString : errorString;
                NSLog(@"%@: Dashboard Link Settings page '%@' compared to client side '%@'", uriScheme, serverUriScheme, clientUriScheme);
                NSLog(@"-------------------------------------------------");
                
                NSLog(@"-- checking for bundle identifier correctness ---");
                NSString *serverBundleIdentifier = response.data[@"ios_bundle_id"];
                NSString *clientBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
                NSString *bundleIdentifier = [serverBundleIdentifier isEqualToString:clientBundleIdentifier] ? passString : errorString;
                NSLog(@"%@: Dashboard Link Settings page '%@' compared to client side '%@'", bundleIdentifier, serverBundleIdentifier, clientBundleIdentifier);
                NSLog(@"-------------------------------------------------");
                
                NSLog(@"----- checking for iOS Team ID correctness ------");
                NSString *serverTeamId = response.data[@"ios_team_id"];
                NSString *clientTeamId = [BNCSystemObserver getTeamIdentifier];
                if ([serverTeamId isEqualToString:clientTeamId]) {
                    NSLog(@"%@: Dashboard Link Settings page '%@' compared to client side '%@'.", passString, serverTeamId, clientTeamId);
                }
                else {
                    NSLog(@"%@: server side '%@' compared to client side '%@'.", errorString, serverTeamId, clientTeamId);
                    NSLog(@"To fix your Dashboard settings head over to https://branch.app.link/link-settings-page");
                    NSLog(@"If you see a null value on the client side, please temporarily add the following key-value pair to your plist: \n\t<key>AppIdentifierPrefix</key><string>$(AppIdentifierPrefix)</string>\n-> then re-run this test.");
                }
                NSLog(@"-------------------------------------------------");
            }
        }];
        
    });
}

- (void)returnToBrowserBasedOnReferringLink:(NSString *)referringLink currentTest:(NSString *)currentTest newTestVal:(NSString *)val {
    // TODO: handling for missing ~referring_link
    // TODO: test with short url where, say, t1=b is set in deep link data. If this logic fails then we'll need to generate a new short URL, which is sucky.
    NSURLComponents *comp = [NSURLComponents componentsWithURL:[NSURL URLWithString:referringLink]
                                       resolvingAgainstBaseURL:NO];
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
    [[UIApplication sharedApplication] openURL:comp.URL];
}

- (void)validateDeeplinkRouting:(NSDictionary *)params {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Branch Deeplink Routing Support" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            if ([params[@"+clicked_branch_link"] isEqualToNumber:@YES]) {
                alertController.message = @"Good news - we got link data. Now a question for you, astute developer: did the app deep link to the specific piece of content you expected to see?";
                // yes
                [alertController addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self returnToBrowserBasedOnReferringLink:params[@"~referring_link"] currentTest:params[@"ct"] newTestVal:@"g"];
                }]];
                // no
                [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    [self returnToBrowserBasedOnReferringLink:params[@"~referring_link"] currentTest:params[@"ct"] newTestVal:@"r"];
                }]];
                // cancel
                [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            }
            else {
                alertController.message = @"Bummer. It seems like +clicked_branch_link is false - we didn't deep link.  Double check that the link you're clicking has the same branch_key that is being used in your .plist file. Return to Safari when you're ready to test again.";
                [alertController addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil]];
            }
            
            [[self topViewController] presentViewController:alertController animated:YES completion:nil];
        });
        
    });
}

- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    }
    else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        return rootViewController;
    }
}


@end
