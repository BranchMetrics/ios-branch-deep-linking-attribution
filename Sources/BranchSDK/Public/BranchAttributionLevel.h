//
//  BranchAttributionLevel.h
//  BranchSDK
//
//  Created by Brandon Boothe on 8/25/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
