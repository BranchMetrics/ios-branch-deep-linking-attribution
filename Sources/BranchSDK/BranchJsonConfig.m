//
//  BranchJsonConfig.m
//  Pods
//
//  Created by Jimmy Dee on 6/7/17.
//
//

#import "BranchLogger.h"
#import "BranchJsonConfig.h"

NSString * _Nonnull const BranchJsonConfigDebugModeOption = @"debugMode";
NSString * _Nonnull const BranchJsonConfigBranchKeyOption = @"branchKey";
NSString * _Nonnull const BranchJsonConfigLiveKeyOption = @"liveKey";
NSString * _Nonnull const BranchJsonConfigTestKeyOption = @"testKey";
NSString * _Nonnull const BranchJsonConfigUseTestInstanceOption = @"useTestInstance";
NSString * _Nonnull const BranchJsonConfigDeferInitForPluginRuntimeOption = @"deferInitForPluginRuntime";
NSString * _Nonnull const BranchJsonConfigEnableLogging = @"enableLogging";
NSString * _Nonnull const BranchJsonConfigCheckPasteboardOnInstall = @"checkPasteboardOnInstall";
NSString * _Nonnull const BranchJsonConfigAPIUrl = @"apiUrl";
NSString * _Nonnull const BranchJsonConfigCPPLevel = @"consumerProtectionAttributionLevel";

@interface BranchJsonConfig()
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, readonly, strong) NSData *configFileContents;
@property (nonatomic, strong) NSURL *configFileURL;
@end

@implementation BranchJsonConfig

+ (BranchJsonConfig * _Nonnull)instance {
    static BranchJsonConfig *instance = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        instance = [BranchJsonConfig new];
    });
    return instance;
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
        [[BranchLogger shared] logError:@"Failed to parse branch.json" error:error];
        return;
    }

    if (![object isKindOfClass:NSDictionary.class]) {
        [[BranchLogger shared] logError:@"Contents of branch.json should be a JSON object." error:nil];
        return;
    }

    self.configuration = object;
}

- (NSData *)configFileContents
{
    if (!self.configFileURL) return nil;
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:self.configFileURL options:0 error:&error];
    if (!data || error) {
        [[BranchLogger shared] logError:@"Failed to load branch.json" error:error];
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
    
    // Unity places the config at [[NSBundle mainBundle] bundlePath] + /Data/Raw/branch.json
    if (!configFileURL) {
        configFileURL = [mainBundle URLForResource:@"branch" withExtension:@"json" subdirectory:@"Data/Raw"];
    }
    
    if (!configFileURL) {
        [[BranchLogger shared] logVerbose:@"No branch.json in app bundle" error:nil];
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

- (BOOL)deferInitForPluginRuntime
{
    NSNumber *number = self[BranchJsonConfigDeferInitForPluginRuntimeOption];
    return number.boolValue;
}

- (BOOL)enableLogging
{
    NSNumber *number = self[BranchJsonConfigEnableLogging];
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

- (NSString *)apiUrl
{
    return self[BranchJsonConfigAPIUrl];
}

- (NSString *)cppLevel
{
    return self[BranchJsonConfigCPPLevel];
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
