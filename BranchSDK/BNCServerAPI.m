//
//  BNCServerAPI.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 8/29/23.
//

#import "BNCServerAPI.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCConfig.h"
#import "BranchConstants.h"

@implementation BNCServerAPI

+ (BNCServerAPI *)sharedInstance {
    static BNCServerAPI *serverAPI;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        serverAPI = [[BNCServerAPI alloc] init];
    });
    
    return serverAPI;
}

- (NSURL *)installServiceURL{
    
    return [NSURL URLWithString: [[self getBaseURLWithVersion] stringByAppendingString: BRANCH_REQUEST_ENDPOINT_INSTALL]];
}

- (NSURL *)openServiceURL {
    return [NSURL URLWithString: [[self getBaseURLWithVersion] stringByAppendingString: BRANCH_REQUEST_ENDPOINT_OPEN]];
}

- (NSURL *)eventServiceURL{
    return [NSURL URLWithString: [[self getBaseURLWithVersion] stringByAppendingString: BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION]];
}

- (NSURL *)linkServiceURL {
    return [NSURL URLWithString: [[self getBaseURLWithVersion] stringByAppendingString: BRANCH_REQUEST_ENDPOINT_GET_SHORT_URL]];
}

- (BOOL)useTrackingDomain {
    NSString* optedInStatus = [BNCSystemObserver attOptedInStatus];
    
    if ([optedInStatus isEqualToString:@"authorized"]){
        return TRUE;
    }
    return FALSE;
}

- (void)setUseEUServers:(BOOL)useEUServers {
    [[BNCPreferenceHelper sharedInstance] setUseEUServers: useEUServers];
}

- (BOOL)useEUServers {
    return [[BNCPreferenceHelper sharedInstance] useEUServers];
}

- (NSString *) getBaseURLWithVersion {
    NSString * urlString;
    
    if ([self useTrackingDomain] && [ self useEUServers]){
        urlString = BNC_SAFETRACK_EU_API_URL;
    } else if ([self useTrackingDomain]) {
        urlString = BNC_SAFETRACK_API_URL;
    } else if ([self useEUServers]){
        urlString = BNC_EU_API_URL;
    } else {
        urlString = BNC_API_URL;
    }
    
    [urlString stringByAppendingFormat:@"/%@/", BNC_API_VERSION_3];
    return urlString;
}

@end
