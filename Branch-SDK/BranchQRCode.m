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

@interface BranchQRCode()
@property (nonatomic, copy, readwrite) NSString *buoTitle;
@property (nonatomic, strong, readwrite) UIImage *qrCodeImage;
@end

@implementation BranchQRCode

- (instancetype) init {
    self = [super init];
    if (self) {
        self.margin = @(1);
        self.width = @(300);
    }
    return self;
}

- (void) setMargin:(NSNumber *)margin {
    if (margin.intValue > 20) {
        margin = @(20);
        BNCLogWarning(@"Margin was reduced to the maximum of 20.");
    }
    if (margin.intValue < 1) {
        margin = @(1);
        BNCLogWarning(@"Margin was increased to the minimum of 1.");
    }
    _margin = margin;
}

- (void) setWidth:(NSNumber *)width {
    if (width.intValue > 2000) {
        width = @(2000);
        BNCLogWarning(@"Width was reduced to the maximum of 2000.");
    }
    if (width.intValue < 300) {
        width = @(300);
        BNCLogWarning(@"Width was increased to the minimum of 500.");
    }
    _width = width;
}

- (void)getQRCodeAsData:(nullable BranchUniversalObject *)buo
         linkProperties:(nullable BranchLinkProperties *)lp
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
    
    if (lp.channel) { parameters[BRANCH_REQUEST_KEY_URL_CHANNEL] = lp.channel; }
    if (lp.feature) { parameters[BRANCH_REQUEST_KEY_URL_FEATURE] = lp.feature; }
    if (lp.campaign) { parameters[BRANCH_REQUEST_KEY_URL_CAMPAIGN] = lp.campaign; }
    if (lp.stage) { parameters[BRANCH_REQUEST_KEY_URL_STAGE] = lp.stage; }
    if (lp.tags) { parameters[BRANCH_REQUEST_KEY_URL_TAGS] = lp.tags; }
    
    parameters[@"qr_code_settings"] = settings;
    parameters[@"data"] = [buo dictionary];
    parameters[@"branch_key"] = [Branch branchKey];
    
    NSData *cachedQRCode = [[BNCQRCodeCache sharedInstance] checkQRCodeCache:parameters];
    if (cachedQRCode) {
        completion(cachedQRCode, nil);
        return;
    }
    
    [self callQRCodeAPI:parameters completion:^(NSData * _Nullable qrCode, NSError * _Nullable error){
        if (completion != nil) {
            if (qrCode != nil) {
                [[BNCQRCodeCache sharedInstance] addQRCodeToCache:qrCode withParams:parameters];
            }
            completion(qrCode, error);
        }
    }];
}

- (void)getQRCodeAsImage:(nullable BranchUniversalObject *)buo
          linkProperties:(nullable BranchLinkProperties *)lp
              completion:(void(^)(UIImage * _Nullable qrCode, NSError * _Nullable error))completion {
    
    [self getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nullable qrCode, NSError * _Nullable error) {
        if (completion != nil) {
            UIImage *qrCodeImage = nil;
            if (qrCode && !error) {
                qrCodeImage =  [UIImage imageWithData:qrCode];
            }
            completion(qrCodeImage, error);
        }
    }];
}

- (void)callQRCodeAPI:(nullable NSDictionary *)params
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
    
    BNCLogDebug([NSString stringWithFormat:@"Network start operation %@.", request.URL.absoluteString]);

    NSDate *startDate = [NSDate date];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            BNCLogError([NSString stringWithFormat:@"QR Code Post Request Error: %@", [error localizedDescription]]);
            completion(nil, error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode == 200) {
            
            BNCLogDebug([NSString stringWithFormat:@"Network finish operation %@ %1.3fs. Status %ld.",
                request.URL.absoluteString,
                [[NSDate date] timeIntervalSinceDate:startDate],
                (long)httpResponse.statusCode]);
            
            completion(data, nil);
        } else {
            
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            BNCLogError([NSString stringWithFormat:@"Network finish operation %@ %1.3fs. Status %ld error %@.\n%@.",
                         request.URL.absoluteString,
                         [[NSDate date] timeIntervalSinceDate:startDate],
                         (long)httpResponse.statusCode,
                         error,
                         responseDictionary]);
            
            error = [NSError branchErrorWithCode: BNCBadRequestError localizedMessage: responseDictionary[@"message"]];
            
            completion(nil, error);
        }
    }];
    
    [postDataTask resume];
}
#if !TARGET_OS_TV
- (void)showShareSheetWithQRCodeFromViewController:(nullable UIViewController *)viewController
                                            anchor:(nullable id)anchorViewOrButtonItem
                                   universalObject:(nullable BranchUniversalObject *)buo
                                    linkProperties:(nullable BranchLinkProperties *)lp
                                        completion:(void (^)(NSError * _Nullable))completion {
    
    [self getQRCodeAsImage:buo linkProperties:lp completion:^(UIImage * _Nullable qrCode, NSError * _Nullable error) {
        if (completion != nil) {
            if (qrCode) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                    self.buoTitle = buo.title;
                    self.qrCodeImage = qrCode;

                    NSArray *items = @[qrCode, self];
                    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
                    
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
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 13000
- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController API_AVAILABLE(ios(13.0)) {
    LPLinkMetadata * metaData = [[LPLinkMetadata alloc] init];
    metaData.title = self.buoTitle;
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *userURL = preferenceHelper.userUrl;
    metaData.originalURL = [NSURL URLWithString:userURL];
    metaData.URL = [NSURL URLWithString:userURL];
    
    NSItemProvider * imageProvider = [[NSItemProvider alloc] initWithObject:self.qrCodeImage];
    metaData.iconProvider = imageProvider;
    metaData.imageProvider = imageProvider;
    
    return metaData;
}
#endif
#endif

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
    } else {
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
