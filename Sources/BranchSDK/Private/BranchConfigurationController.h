//
//  BranchConfigurationController.h
//  BranchSDK
//
//  Created by Nidhi Dixit on 6/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The BranchConfigurationController class contains SDK configuration information.
 *  .This information is sent to backend as `operational_metrics` with v1/install request.
 */

@interface BranchConfigurationController : NSObject

@property (nonatomic, copy) NSString *branchKeySource;
@property (assign, nonatomic) BOOL deferInitForPluginRuntime;
@property (assign, nonatomic) BOOL checkPasteboardOnInstall;

+ (instancetype)sharedInstance;

/**
 *  Retrieves the current SDK configuration as a dictionary.
 *
 *  @return An `NSDictionary` containing the current configuration values.
 */
- (NSDictionary *) getConfiguration;

@end

NS_ASSUME_NONNULL_END
