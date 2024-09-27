//
//  BranchQRCode.h
//  Branch
//
//  Created by Nipun Singh on 3/22/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BranchQRCodeImageFormat){
    BranchQRCodeImageFormatPNG,
    BranchQRCodeImageFormatJPEG
};

@interface BranchQRCode : NSObject

/// Primary color of the generated QR code itself.
@property (nonatomic, strong, readwrite) UIColor *codeColor;
/// Secondary color used as the QR Code background.
@property (nonatomic, strong, readwrite) UIColor *backgroundColor;
/// A URL of an image that will be added to the center of the QR code. Must be a PNG or JPEG.
@property (nonatomic, copy, readwrite) NSString *centerLogo;
/// Output size of QR Code image. Min 300px. Max 2000px.
@property (nonatomic, copy, readwrite) NSNumber *width;
/// The number of pixels for the QR code's border.  Min 1px. Max 20px.
@property (nonatomic, copy, readwrite) NSNumber *margin;
/// Format of the returned QR code. Can be a JPEG or PNG.
@property (nonatomic, assign, readwrite) BranchQRCodeImageFormat imageFormat;

/**
Creates a Branch QR Code image. Returns the QR code as NSData.

@param buo  The Branch Universal Object the will be shared.
@param lp   The link properties that the link will have.
@param completion   Completion handler containing the QR code image and error.

*/
- (void)getQRCodeAsData:(nullable BranchUniversalObject *)buo
         linkProperties:(nullable BranchLinkProperties *)lp
             completion:(void(^)(NSData * _Nullable qrCode, NSError * _Nullable error))completion;

/**
Creates a Branch QR Code image. Returns the QR code as a UIImage.

@param buo  The Branch Universal Object the will be shared.
@param lp   The link properties that the link will have.
@param completion   Completion handler containing the QR code image and error.

*/
- (void)getQRCodeAsImage:(nullable BranchUniversalObject *)buo
          linkProperties:(nullable BranchLinkProperties *)lp
              completion:(void(^)(UIImage * _Nullable qrCode, NSError * _Nullable error))completion;


/**
Creates a Branch QR Code image and displays it in a share sheet.

@param buo  The Branch Universal Object the will be shared.
@param lp   The link properties that the link will have.
@param completion   Completion handler containing any potential error.
 
 */
#if !TARGET_OS_TV
- (void)showShareSheetWithQRCodeFromViewController:(nullable UIViewController *)viewController
                                            anchor:(nullable id)anchorViewOrButtonItem
                                   universalObject:(nullable BranchUniversalObject *)buo
                                    linkProperties:(nullable BranchLinkProperties *)lp
                                        completion:(void(^)(NSError * _Nullable error))completion;
#endif

@end

NS_ASSUME_NONNULL_END

