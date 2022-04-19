//
//  BranchQRCode.m
//  Branch
//
//  Created by Nipun Singh on 3/22/22.
//

#import "BranchQRCode.h"
#import "Branch.h"

@implementation BranchQRCode

- (void) setMargin:(NSNumber *)margin {
    if (margin.intValue > 20) {
        margin = @(20);
        BNCLogWarning(@"Margin was reduced to the maximum of 20.");
    }
    if (margin.intValue < 0) {
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
    if (width.intValue < 500) {
        width = @(500);
        BNCLogWarning(@"Width was increased to the minimum of 500.");
    }
    _width = width;
}

- (void) getQRCode:(BranchUniversalObject*_Nullable)buo
    linkProperties:(BranchLinkProperties*_Nullable)lp
        completion:(void(^)(UIImage *qrCode, NSError *error))completion {

    NSMutableDictionary *settings = [NSMutableDictionary new];
    
    if (self.codeColor) { settings[@"code_color"] = [self hexStringForColor:self.codeColor]; }
    if (self.backgroundColor) { settings[@"background_color"] = [self hexStringForColor:self.backgroundColor]; }
    if (self.margin) { settings[@"margin"] = self.margin; }
    if (self.width) { settings[@"width"] = self.width; }

    if (self.imageType == BranchQRCodeImageTypeJPEG) {
        settings[@"image_format"] = @"jpeg";
    } else {
        settings[@"image_format"] = @"png";
    }

    if (self.centerLogo) {
        NSData *data=[NSData dataWithContentsOfURL:[NSURL URLWithString: self.centerLogo]];
        UIImage *image=[UIImage imageWithData:data];
        if (image == nil) {
            //yourImageURL is not valid
            BNCLogWarning(@"QR code center logo was an invalid URL string.");
        } else{
            
            settings[@"center_logo_url"] = self.centerLogo;
            BNCLogWarning(@"Valid QR code center logo.");
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
    
     [self callQRCodeAPI:parameters completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error){
         if (completion != nil) {
             completion(qrCode, error);
         }
    }];
}

- (void) callQRCodeAPI:(NSDictionary*_Nullable)params
            completion:(void(^)(UIImage *qrCode, NSError *error))completion {
    
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
        
        if(httpResponse.statusCode == 200)
        {
            UIImage *qrCode = [UIImage imageWithData:data scale:1];
            completion(qrCode, nil);
        } else {
            
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            BNCLogError([NSString stringWithFormat:@"Error with response and Status Code %ld: %@", (long)httpResponse.statusCode, responseDictionary]);
            error = [NSError branchErrorWithCode: BNCBadRequestError localizedMessage: responseDictionary[@"message"]];
            
            completion(nil, error);
        }
    }];
    
    [postDataTask resume];
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
