//
//  BranchSecureSDKProvider.h
//  Branch-SDK
//
//  Created by Nidhi Dixit on 3/23/26.
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#pragma mark BranchSecureSDKProvider

@protocol BranchSecureSDKProvider <NSObject>

@required

/// Generates attestation and ECDH keys and prefetches a server challenge via GET /v3/challenge.
/// Called by Branch when the provider is assigned to fraudDefenseHandler.
- (void)initializeBranchSecureSDKWithBranchKey:(NSString * _Nonnull)branchKey;

/// Layer 1: performs device attestation using the given params as input to the attestation hash.
/// Returns { branch_sdk_secure_context: { context_key, initialization_context: { … } } }, or an
/// empty dict when no attestation was produced.
- (NSDictionary *_Nonnull)addDeviceTrustParams:(NSDictionary *_Nonnull)params;

/// Layer 2 + 3: generates a smart nonce (Layer 3) and HMAC-SHA256 signature (Layer 2) over params.
/// Returns { branch_sdk_secure_context: { context_key, activity_context: { request_signature, nonce } } },
/// or an empty dict if the HMAC secret is not yet available.
- (NSDictionary *_Nonnull)addSignatureAndNonceForParams:(NSDictionary *_Nonnull)params;

/// Releases the claim taken by -addDeviceTrustParams:. Call this once the request that carried
/// the initialization_context has been answered, whether acknowledged or failed terminally.
- (void)releaseAttestationClaim;

@end
