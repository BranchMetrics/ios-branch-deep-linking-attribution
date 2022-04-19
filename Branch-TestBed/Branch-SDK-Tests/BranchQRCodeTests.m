//
//  BranchQRCodeTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 4/14/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"

@interface BranchQRCodeTests : XCTestCase

@end

@implementation BranchQRCodeTests

- (void)testNormalQRCodeWithAllSettings {
    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.width = @(1000);
    qrCode.margin = @(1);
    qrCode.codeColor = [UIColor blueColor];
    qrCode.backgroundColor = [UIColor whiteColor];
    qrCode.centerLogo = @"https://en.wikipedia.org/wiki/File:Example.jpg";
    qrCode.imageType = BranchQRCodeImageTypeJPEG;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCode:buo linkProperties:lp completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
    }];
}

- (void)testNormalQRCodeWithNoSettings {
    BranchQRCode *qrCode = [BranchQRCode new];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCode:buo linkProperties:lp completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
    }];
}

- (void)testNormalQRCodeWithInvalidLogoURL {
    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.centerLogo = @"https://branch.branch/notARealImageURL.jpg";
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCode:buo linkProperties:lp completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
    }];
}


@end
