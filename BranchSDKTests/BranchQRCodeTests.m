//
//  BranchQRCodeTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 4/14/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchQRCode.h"
#import "BNCQRCodeCache.h"
#import "BranchConfiguration.h"
#import "NSError+Branch.h"

@interface Branch (BranchQRCodeTest)
+ (void)resetInitializationGuardForTesting;
+ (void)resetBranchKey;
@end

@interface BranchQRCodeTests : XCTestCase

@end

@implementation BranchQRCodeTests

// The QR code request reads the key set by +initialize:, so every test starts from the real key.
- (void)setUp {
    [super setUp];
    [self initializeBranch];
}

- (void)tearDown {
    [self initializeBranch];
    [super tearDown];
}

- (void)initializeBranch {
    [Branch resetBranchKey];
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    [Branch initialize:config];
}

- (void)testQRCodeBeforeInitializeReportsInitError {
    [Branch resetBranchKey];
    [Branch resetInitializationGuardForTesting];

    XCTestExpectation *expectation = [self expectationWithDescription:@"QR code completion"];
    BranchQRCode *qrCode = [BranchQRCode new];
    [qrCode getQRCodeAsData:[BranchUniversalObject new]
             linkProperties:[BranchLinkProperties new]
                 completion:^(NSData * _Nullable qrCode, NSError * _Nullable error) {
        XCTAssertNil(qrCode);
        XCTAssertEqualObjects(error.domain, [NSError bncErrorDomain]);
        XCTAssertEqual(error.code, BNCInitError);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testNormalQRCodeDataWithAllSettings {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.width = @(1000);
    qrCode.margin = @(1);
    qrCode.codeColor = [UIColor blueColor];
    qrCode.backgroundColor = [UIColor whiteColor];
    qrCode.centerLogo = @"https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg";
    qrCode.imageFormat = BranchQRCodeImageFormatPNG;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testNormalQRCodeAsDataWithNoSettings {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testNormalQRCodeWithInvalidLogoURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.centerLogo = @"https://branch.branch/notARealImageURL.jpg";
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testNormalQRCodeAsImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];

    BranchQRCode *qrCode = [BranchQRCode new];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsImage:buo linkProperties:lp completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}

- (void)testQRCodeCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching QR Code"];
    
    BranchQRCode *myQRCode = [BranchQRCode new];
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [myQRCode getQRCodeAsData:buo linkProperties:lp completion:^(NSData * _Nonnull qrCode, NSError * _Nonnull error) {
        
        XCTAssertNil(error);
        XCTAssertNotNil(qrCode);
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        NSMutableDictionary *settings = [NSMutableDictionary new];
        
        settings[@"image_format"] = @"PNG";
        settings[@"width"] = @(300);
        settings[@"margin"] = @(1);

        parameters[@"qr_code_settings"] = settings;
        parameters[@"data"] = [NSMutableDictionary new];
        parameters[@"branch_key"] = [Branch branchKey];
        
        
        NSData *cachedQRCode = [[BNCQRCodeCache sharedInstance] checkQRCodeCache:parameters];
        
        XCTAssertEqual(cachedQRCode, qrCode);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error Testing QR Code Cache: %@", error);
            XCTFail();
        }
    }];
}


@end
