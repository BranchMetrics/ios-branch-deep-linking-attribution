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

/// Initializes the fraud defense system: generates attestation + ECDH keys and prefetches
/// a server challenge via GET /v3/challenge, all in parallel.
/// Call this early (e.g. at app launch) before any fraud defense checks are performed.
- (void)initializeBranchSecureSDKWithBranchKey:(NSString * _Nonnull)branchKey;

/// Layer 1: performs device attestation using the given params as input to the attestation hash.
/// Returns { attestationObject_b64, ecdhPublicKey_b64, attestKeyId, challenge_id }.
- (NSDictionary *_Nonnull)addDeviceTrustParams:(NSDictionary *_Nonnull)params;

/// Layer 2 + 3: generates a smart nonce (Layer 3) and HMAC-SHA256 signature (Layer 2) over params.
/// Returns { signature_b64, smart_nonce }, or empty dict if HMAC secret not yet available.
- (NSDictionary *_Nonnull)addSignatureAndNonceForParams:(NSDictionary *_Nonnull)params;

/// Releases the claim taken by -addDeviceTrustParams:. Call this once the request that carried
/// the initialization_context has been answered, whether acknowledged or failed terminally.
- (void)releaseAttestationClaim;

@end
