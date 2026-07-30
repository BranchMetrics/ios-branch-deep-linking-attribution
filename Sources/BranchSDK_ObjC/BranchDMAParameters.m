//
//  BranchDMAParameters.m
//  BranchSDK
//
//  Created by Brandon Boothe on 7/23/26.
//

#import "BranchDMAParameters.h"

@implementation BranchDMAParameters

+ (instancetype)eeaRegion:(BOOL)eeaRegion
 adPersonalizationConsent:(BOOL)adPersonalizationConsent
   adUserDataUsageConsent:(BOOL)adUserDataUsageConsent {
    BranchDMAParameters *params = [super new];
    if (params) {
        params->_eeaRegion = eeaRegion;
        params->_adPersonalizationConsent = adPersonalizationConsent;
        params->_adUserDataUsageConsent = adUserDataUsageConsent;
    }
    return params;
}

// Immutable value type: `copy` on the config property can return self.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
