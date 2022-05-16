//
//  BranchQRCode.m
//  Branch
//
//  Created by Nipun Singh on 3/22/22.
//

#import <LinkPresentation/LPLinkMetadata.h>
#import "BranchQRCode.h"
#import "Branch.h"
#import "BNCQRCodeCache.h"

@implementation BranchQRCode

NSString *buoTitle;
UIImage *qrCodeImage;

- (void) setMargin:(NSNumber *)margin {
    if (margin.intValue > 20) {
        margin = @(20);
        BNCLogWarning(@"Margin was reduced to the maximum of 20.");
    }
    if (margin.intValue < 1) {
        margin = @(0);
        BNCLogWarning(@"Margin was increased to the minimum of 0.");
    }
    _margin = margin;
}

- (void) setWidth:(NSNumber *)width {
    if (width.intValue > 2000) {
        width = @(2000);
        BNCLogWarning(@"Width was reduced to the maximum of 2000.");
    }
    if (width.intValue < 300) {
        width = @(500);
        BNCLogWarning(@"Width was increased to the minimum of 500.");
    }
    _width = width;
}

- (void) getQRCodeAsData:(BranchUniversalObject*_Nullable)buo
          linkProperties:(BranchLinkProperties*_Nullable)lp
              completion:(void(^)(NSData * _Nullable qrCode, NSError * _Nullable error))completion {

    NSMutableDictionary *settings = [NSMutableDictionary new];
    
    if (self.codeColor) { settings[@"code_color"] = [self hexStringForColor:self.codeColor]; }
    if (self.backgroundColor) { settings[@"background_color"] = [self hexStringForColor:self.backgroundColor]; }
    if (self.margin) { settings[@"margin"] = self.margin; }
    if (self.width) { settings[@"width"] = self.width; }
    
    settings[@"image_format"] = (self.imageFormat == BranchQRCodeImageFormatJPEG) ? @"JPEG" : @"PNG";
    
    if (self.centerLogo) {
        NSData *data=[NSData dataWithContentsOfURL:[NSURL URLWithString: self.centerLogo]];
        UIImage *image=[UIImage imageWithData:data];
        if (image == nil) {
            BNCLogWarning(@"QR code center logo was an invalid URL string.");
        } else {
            settings[@"center_logo_url"] = self.centerLogo;
        }
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (lp.channel) { parameters[@"channel"] = lp.channel; }
    if (lp.feature) { parameters[@"feature"] = lp.feature; }
    if (lp.campaign) { parameters[@"campaign"] = lp.campaign; }
    if (lp.stage) { parameters[@"stage"] = lp.stage; }
    if (lp.tags) { parameters[@"tags"] = lp.tags; }
    
    parameters[@"qr_code_settings"] = settings;
    parameters[@"data"] = [buo dictionary];
    parameters[@"branch_key"] = [Branch branchKey];
    
    NSData *cachedQRCode = [[BNCQRCodeCache sharedInstance] checkQRCodeCache:parameters];
    if (cachedQRCode) {
        completion(cachedQRCode, nil);
        return;
    }
    
    [self callQRCodeAPI:parameters completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error){
        if (completion != nil) {
            if (qrCode != nil) {
                [[BNCQRCodeCache sharedInstance] addQRCodeToCache:qrCode withParams:parameters];
            }
            completion(qrCode, error);
        }
    }];
}

- (void)getQRCodeAsImage:(BranchUniversalObject *)buo
          linkProperties:(BranchLinkProperties *)lp
              completion:(void (^)(UIImage * _Nonnull, NSError * _Nonnull))completion {
    
    [self getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        if (completion != nil) {
            if (error) {
                UIImage *img = [UIImage new];
                completion(img, error);
            } else {
                UIImage *qrCodeImage =  [UIImage imageWithData:qrCode];
                completion(qrCodeImage, error);
            }
        }
    }];
}

- (void) callQRCodeAPI:(NSDictionary*_Nullable)params
            completion:(void(^)(NSData * _Nullable qrCode, NSError * _Nullable error))completion {
    
    NSError *error;
    NSString *branchAPIURL = [BNC_API_BASE_URL copy];
    NSString *urlString = [NSString stringWithFormat: @"%@/v1/qr-code", branchAPIURL];
    NSURL *url = [NSURL URLWithString: urlString];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            BNCLogError([NSString stringWithFormat:@"QR Code Post Request Error: %@", [error localizedDescription]]);
            completion(nil, error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode == 200) {
            completion(data, nil);
        } else {
            
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            BNCLogError([NSString stringWithFormat:@"Error with response and Status Code %ld: %@", (long)httpResponse.statusCode, responseDictionary]);
            error = [NSError branchErrorWithCode: BNCBadRequestError localizedMessage: responseDictionary[@"message"]];
            
            completion(nil, error);
        }
    }];
    
    [postDataTask resume];
}

- (void)showShareSheetWithQRCodeFromViewController:(UIViewController *)viewController
                                            anchor:(id _Nullable)anchorViewOrButtonItem
                                   universalObject:(BranchUniversalObject *)buo
                                    linkProperties:(BranchLinkProperties *)lp
                                        completion:(void (^)(NSError * _Nonnull))completion {
    
    [self getQRCodeAsImage:buo linkProperties:lp completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        if (completion != nil) {
            if (qrCode) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                    buoTitle = buo.title;
                    qrCodeImage = qrCode;
                    
                    NSArray *items = @[qrCode, self];
                    UIActivityViewController *activityViewController = [[UIActivityViewController new] initWithActivityItems:items applicationActivities:nil];
                    
                    UIViewController *presentingViewController = nil;
                    if ([viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                        presentingViewController = viewController;
                    } else {
                        UIViewController *rootController = [UIViewController bnc_currentViewController];
                        if ([rootController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                            presentingViewController = rootController;
                        }
                    }

                    if (!presentingViewController) {
                        BNCLogError(@"No view controller is present to show the share sheet. Not showing sheet.");
                        return;
                    }

                    // Required for iPad/Universal apps on iOS 8+
                    if ([presentingViewController respondsToSelector:@selector(popoverPresentationController)]) {
                        if ([anchorViewOrButtonItem isKindOfClass:UIBarButtonItem.class]) {
                            UIBarButtonItem *anchor = (UIBarButtonItem*) anchorViewOrButtonItem;
                            activityViewController.popoverPresentationController.barButtonItem = anchor;
                        } else
                        if ([anchorViewOrButtonItem isKindOfClass:UIView.class]) {
                            UIView *anchor = (UIView*) anchorViewOrButtonItem;
                            activityViewController.popoverPresentationController.sourceView = anchor;
                            activityViewController.popoverPresentationController.sourceRect = anchor.bounds;
                        } else {
                            activityViewController.popoverPresentationController.sourceView = presentingViewController.view;
                            activityViewController.popoverPresentationController.sourceRect = CGRectMake(0.0, 0.0, 40.0, 40.0);
                        }
                    }
                    [presentingViewController presentViewController:activityViewController animated:YES completion:nil];
                    
                    completion(error);
                });
            } else {
                completion(error);
            }
        }
    }];
}

// Helper Functions
- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController API_AVAILABLE(ios(13.0)) {
    LPLinkMetadata * metaData = [[LPLinkMetadata alloc] init];
    metaData.title = buoTitle;
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *userURL = preferenceHelper.userUrl;
    metaData.originalURL = [NSURL URLWithString:userURL];
    metaData.URL = [NSURL URLWithString:userURL];
    
    NSItemProvider * imageProvider = [[NSItemProvider alloc] initWithObject:qrCodeImage];
    metaData.iconProvider = imageProvider;
    metaData.imageProvider = imageProvider;
    
    return metaData;
}

- (BOOL)isValidUrl:(NSString *)urlString{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    return [NSURLConnection canHandleRequest:request];
}

- (NSString *)hexStringForColor:(UIColor *)color {
    CGColorSpaceModel colorSpace = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat r, g, b;
    
    if (colorSpace == kCGColorSpaceModelMonochrome) {
        r = components[0];
        g = components[0];
        b = components[0];
    }
    else {
        r = components[0];
        g = components[1];
        b = components[2];
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)
    ];
}

@end
