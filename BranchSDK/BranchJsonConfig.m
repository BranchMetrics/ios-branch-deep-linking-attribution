//
//  BranchJsonConfig.m
//  Pods
//
//  Created by Jimmy Dee on 6/7/17.
//
//

#import "BNCLog.h"
#import "BranchJsonConfig.h"

NSString * _Nonnull const BranchJsonConfigDebugModeOption = @"debugMode";
NSString * _Nonnull const BranchJsonConfigBranchKeyOption = @"branchKey";
NSString * _Nonnull const BranchJsonConfigLiveKeyOption = @"liveKey";
NSString * _Nonnull const BranchJsonConfigTestKeyOption = @"testKey";
NSString * _Nonnull const BranchJsonConfigUseTestInstanceOption = @"useTestInstance";
NSString * _Nonnull const BranchJsonConfigDelayInitToCheckForSearchAdsOption = @"delayInitToCheckForSearchAds";
NSString * _Nonnull const BranchJsonConfigAppleSearchAdsDebugModeOption = @"appleSearchAdsDebugMode";
NSString * _Nonnull const BranchJsonConfigDeferInitializationForJSLoadOption = @"deferInitializationForJSLoad";
NSString * _Nonnull const BranchJsonConfigEnableFacebookLinkCheck = @"enableFacebookLinkCheck";
NSString * _Nonnull const BranchJsonConfigCheckPasteboardOnInstall = @"checkPasteboardOnInstall";

@interface BranchJsonConfig()
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, readonly, strong) NSData *configFileContents;
@property (nonatomic, strong) NSURL *configFileURL;
@end

@implementation BranchJsonConfig

+ (BranchJsonConfig * _Nonnull)instance
{
    @synchronized(self) {
        static BranchJsonConfig *_instance;
        static dispatch_once_t once = 0;
        dispatch_once(&once, ^{
            _instance = [[BranchJsonConfig alloc] init];
        });
        return _instance;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self findConfigFile];
        [self loadConfigFile];
    }
    return self;
}

- (void)loadConfigFile
{
    NSData *data = self.configFileContents;
    if (!data) return;

    NSError *error;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!object || error) {
        BNCLogError([NSString stringWithFormat:@"Failed to parse branch.json. Error: %@", error.localizedDescription]);
        return;
    }

    if (![object isKindOfClass:NSDictionary.class]) {
        BNCLogError(@"Contents of branch.json should be a JSON object.");
        return;
    }

    self.configuration = object;
}

- (NSData *)configFileContents
{
    if (!self.configFileURL) return nil;
    BNCLog([NSString stringWithFormat:@"Loading %@", self.configFileURL.pathComponents.lastObject]);

    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:self.configFileURL options:0 error:&error];
    if (!data || error) {
        BNCLogError([NSString stringWithFormat:@"Failed to load %@. Error: %@", self.configFileURL, error.localizedDescription]);
        return nil;
    }
    return data;
}

- (void)findConfigFile
{
    if (self.configFileURL) return;

    __block NSURL *configFileURL;
    NSBundle *mainBundle = NSBundle.mainBundle;
    NSArray *filesToCheck =
    @[
#ifdef DEBUG
      @"branch.ios.debug",
      @"branch.debug",
#endif // DEBUG
      @"branch.ios",
      @"branch"
      ];

    [filesToCheck enumerateObjectsUsingBlock:^(NSString *  _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
        configFileURL = [mainBundle URLForResource:file withExtension:@"json"];
        *stop = (configFileURL != nil);
    }];

    if (!configFileURL) {
        BNCLogDebug(@"No branch.json in app bundle.");
        return;
    }

    self.configFileURL = configFileURL;
}

- (BOOL)debugMode
{
    NSNumber *number = self[BranchJsonConfigDebugModeOption];
    return number.boolValue;
}

- (BOOL)useTestInstance
{
    NSNumber *number = self[BranchJsonConfigUseTestInstanceOption];
    return number.boolValue;
}

- (BOOL)delayInitToCheckForSearchAds
{
    NSNumber *number = self[BranchJsonConfigDelayInitToCheckForSearchAdsOption];
    return number.boolValue;
}

- (BOOL)appleSearchAdsDebugMode
{
    NSNumber *number = self[BranchJsonConfigAppleSearchAdsDebugModeOption];
    return number.boolValue;
}

- (BOOL)deferInitializationForJSLoad
{
    NSNumber *number = self[BranchJsonConfigDeferInitializationForJSLoadOption];
    return number.boolValue;
}

- (BOOL)enableFacebookLinkCheck
{
    NSNumber *number = self[BranchJsonConfigEnableFacebookLinkCheck];
    return number.boolValue;
}

- (BOOL)checkPasteboardOnInstall
{
    NSNumber *number = self[BranchJsonConfigCheckPasteboardOnInstall];
    return number.boolValue;
}

- (NSString *)branchKey
{
    return self[BranchJsonConfigBranchKeyOption];
}

- (NSString *)liveKey
{
    return self[BranchJsonConfigLiveKeyOption];
}

- (NSString *)testKey
{
    return self[BranchJsonConfigTestKeyOption];
}

- (id)objectForKey:(NSString *)key
{
    return self.configuration[key];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    return self.configuration[key];
}

@end
