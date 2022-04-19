//
//  BranchQRCode.h
//  Branch
//
//  Created by Nipun Singh on 3/22/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BranchQRCodeImageType){
    BranchQRCodeImageTypePNG,
    BranchQRCodeImageTypeJPEG
};

@interface BranchQRCode : NSObject

/// Primary color of the generated QR code itself.
@property (nonatomic, copy, readwrite) UIColor *codeColor;
/// Secondary color used as the QR Code background.
@property (nonatomic, copy, readwrite) UIColor *backgroundColor;
/// A URL of an image that will be added to the center of the QR code. Must be a PNG or JPEG.
@property (nonatomic, copy, readwrite) NSString *centerLogo;
/// Output size of QR Code image. Min 500px. Max 2000px.
@property (nonatomic, readwrite) NSNumber *width;
/// The number of pixels for the QR code's border.  Min 0px. Max 20px.
@property (nonatomic, readwrite) NSNumber *margin;
/// Format of the returned QR code. Can be a JPEG or PNG.
@property (nonatomic, assign, readwrite) BranchQRCodeImageType imageType;

/**
Creates a Branch QR Code image.

@param buo  The Branch Universal Object the will be shared.
@param lp   The link properties that the link will have.
@param completion   Completion handler containing the QR code image and error.

*/
- (void) getQRCode:(BranchUniversalObject*_Nullable)buo
    linkProperties:(BranchLinkProperties*_Nullable)lp
        completion:(void(^)(UIImage *qrCode, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END

