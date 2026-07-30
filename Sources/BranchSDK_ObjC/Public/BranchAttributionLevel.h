//
//  BranchAttributionLevel.h
//  Branch-SDK
//
//  Copyright © 2025 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

/**
 * Enumeration representing different levels of consumer protection attribution levels
 */
typedef NSString * BranchAttributionLevel NS_STRING_ENUM;

/**
 * Full:
 * - Advertising Ids
 * - Device Ids
 * - Local IP
 * - Persisted Non-Aggregate Ids
 * - Persisted Aggregate Ids
 * - Ads Postbacks / Webhooks
 * - Data Integrations Webhooks
 * - SAN Callouts
 * - Privacy Frameworks
 * - Deep Linking
 */
extern BranchAttributionLevel const BranchAttributionLevelFull;

/**
 * Reduced:
 * - Device Ids
 * - Local IP
 * - Data Integrations Webhooks
 * - Privacy Frameworks
 * - Deep Linking
 */
extern BranchAttributionLevel const BranchAttributionLevelReduced;

/**
 * Minimal:
 * - Device Ids
 * - Local IP
 * - Data Integrations Webhooks
 * - Deep Linking
 */
extern BranchAttributionLevel const BranchAttributionLevelMinimal;

/**
 * None:
 * - Only Deterministic Deep Linking
 * - Disables all other Branch requests
 */
extern BranchAttributionLevel const BranchAttributionLevelNone;
