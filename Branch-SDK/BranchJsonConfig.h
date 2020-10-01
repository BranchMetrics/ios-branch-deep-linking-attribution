//
//  BranchJsonConfig.h
//  Pods
//
//  Created by Jimmy Dee on 6/7/17.
//
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const BranchJsonConfigDebugModeOption;
extern NSString * _Nonnull const BranchJsonConfigBranchKeyOption;
extern NSString * _Nonnull const BranchJsonConfigLiveKeyOption;
extern NSString * _Nonnull const BranchJsonConfigTestKeyOption;
extern NSString * _Nonnull const BranchJsonConfigUseTestInstanceOption;
extern NSString * _Nonnull const BranchJsonConfigDelayInitToCheckForSearchAdsOption;
extern NSString * _Nonnull const BranchJsonConfigAppleSearchAdsDebugModeOption;
extern NSString * _Nonnull const BranchJsonConfigDeferInitializationForJSLoadOption;
extern NSString * _Nonnull const BranchJsonConfigEnableFacebookLinkCheck;

@interface BranchJsonConfig : NSObject

@property (class, readonly, nonnull) BranchJsonConfig *instance;
@property (nonatomic, readonly, nullable) NSURL *configFileURL;
@property (nonatomic, readonly) BOOL debugMode;
@property (nonatomic, readonly, nullable) NSString *branchKey;
@property (nonatomic, readonly, nullable) NSString *liveKey;
@property (nonatomic, readonly, nullable) NSString *testKey;
@property (nonatomic, readonly) BOOL useTestInstance;
@property (nonatomic, readonly) BOOL delayInitToCheckForSearchAds;
@property (nonatomic, readonly) BOOL appleSearchAdsDebugMode;
@property (nonatomic, readonly) BOOL deferInitializationForJSLoad;
@property (nonatomic, readonly) BOOL enableFacebookLinkCheck;

- (nullable id)objectForKey:(NSString * _Nonnull)key;
- (nullable id)objectForKeyedSubscript:(NSString * _Nonnull)key;

@end
