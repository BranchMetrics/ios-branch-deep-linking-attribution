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
extern NSString * _Nonnull const BranchJsonConfigCheckPasteboardOnInstall;

@interface BranchJsonConfig : NSObject

@property (class, readonly, nonnull) BranchJsonConfig *instance;
@property (nonatomic, readonly, nullable) NSURL *configFileURL;
@property (nonatomic, readonly, assign) BOOL debugMode;
@property (nonatomic, readonly, nullable, copy) NSString *branchKey;
@property (nonatomic, readonly, nullable, copy) NSString *liveKey;
@property (nonatomic, readonly, nullable, copy) NSString *testKey;
@property (nonatomic, readonly, assign) BOOL useTestInstance;
@property (nonatomic, readonly, assign) BOOL delayInitToCheckForSearchAds;
@property (nonatomic, readonly, assign) BOOL appleSearchAdsDebugMode;
@property (nonatomic, readonly, assign) BOOL deferInitializationForJSLoad;
@property (nonatomic, readonly, assign) BOOL enableFacebookLinkCheck;
@property (nonatomic, readonly, assign) BOOL checkPasteboardOnInstall;

- (nullable id)objectForKey:(NSString * _Nonnull)key;
- (nullable id)objectForKeyedSubscript:(NSString * _Nonnull)key;

@end
