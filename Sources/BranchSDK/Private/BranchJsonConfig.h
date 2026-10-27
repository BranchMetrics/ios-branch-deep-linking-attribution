//
//  BranchJsonConfig.h
//  Pods
//
//  Created by Jimmy Dee on 6/7/17.
//
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const BranchJsonConfigDebugModeOption;
extern NSString * _Nonnull const BranchJsonConfigEnableLogging;
extern NSString * _Nonnull const BranchJsonConfigCheckPasteboardOnInstall;
extern NSString * _Nonnull const BranchJsonConfigAPIUrl;

@interface BranchJsonConfig : NSObject

@property (class, readonly, nonnull) BranchJsonConfig *instance;
@property (nonatomic, readonly, nullable) NSURL *configFileURL;
@property (nonatomic, readonly, assign) BOOL debugMode;
@property (nonatomic, readonly, assign) BOOL enableLogging;
@property (nonatomic, readonly, assign) BOOL checkPasteboardOnInstall;
@property (nonatomic, readonly, nullable, copy) NSString *apiUrl;
@property (nonatomic, readonly, nullable, copy) NSString *cppLevel;

- (nullable id)objectForKey:(NSString * _Nonnull)key;
- (nullable id)objectForKeyedSubscript:(NSString * _Nonnull)key;

@end
