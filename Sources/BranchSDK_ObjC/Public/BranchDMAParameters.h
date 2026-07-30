//
//  BranchDMAParameters.h
//  BranchSDK
//
//  Created by Brandon Boothe on 7/23/26.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 `BranchDMAParameters` carries the parameters required by Google Conversion APIs for DMA compliance in the
 EEA region. It is the iOS counterpart of the Android `DMAParameters` data class.

 It is immutable: construct it with all three named consent signals and hand it to
 `BranchConfiguration.dmaParameters` before calling `+[Branch initialize:]`. Naming each field at the call
 site removes the silent-argument-swap hazard of the old three-positional-boolean API.

 DMA parameters are part of the pre-init configuration and cannot be changed after initialization. If a
 user's consent changes at runtime, the app must reinitialize the SDK with a new configuration.
 */
@interface BranchDMAParameters : NSObject

/// Whether European regulations, including the DMA, apply to this user and conversion.
@property (nonatomic, assign, readonly) BOOL eeaRegion;

/// Whether the end user has granted (YES) or denied (NO) ads-personalization consent.
@property (nonatomic, assign, readonly) BOOL adPersonalizationConsent;

/// Whether the user has granted (YES) or denied (NO) consent for 3P transmission of user-level ad data.
@property (nonatomic, assign, readonly) BOOL adUserDataUsageConsent;

/**
 Creates a DMA parameters object. Named after the leading field to mirror Android's `DMAParameters(...)`
 data-class construction.
 @param eeaRegion Whether European regulations, including the DMA, apply to this user and conversion.
 @param adPersonalizationConsent Whether the end user granted/denied ads-personalization consent.
 @param adUserDataUsageConsent Whether the user granted/denied consent for 3P transmission of ad data.
 */
+ (instancetype)eeaRegion:(BOOL)eeaRegion
 adPersonalizationConsent:(BOOL)adPersonalizationConsent
   adUserDataUsageConsent:(BOOL)adUserDataUsageConsent;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
