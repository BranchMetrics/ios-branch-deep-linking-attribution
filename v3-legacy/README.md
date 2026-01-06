# Branch iOS SDK v3.x (Legacy - Objective-C)

> **This code is archived.** For active development, see the main branch with Swift 6 implementation.

## Status

| Version | Status | Support Until |
|---------|--------|---------------|
| **4.x (Swift 6)** | Active Development | Ongoing |
| **3.x (Objective-C)** | Maintenance Only | January 2027 |

## About This Archive

This directory contains the legacy Objective-C implementation of the Branch iOS SDK (v3.x). It has been preserved for:

- Historical reference
- Bug investigation context
- Migration assistance for customers still on v3.x

## For v3.x Users

If you need to use the v3.x SDK:

1. **CocoaPods**: Use version constraints
   ```ruby
   pod 'Branch', '~> 3.0'
   ```

2. **SPM**: Reference the v3-legacy tag
   ```swift
   .package(url: "https://github.com/BranchMetrics/ios-branch-deep-linking-attribution.git", .upToNextMajor(from: "3.0.0"))
   ```

## Migration to v4.x

See the [Migration Guide](../docs/MIGRATION-GUIDE.md) for upgrading from v3.x to v4.x.

## Key Changes in v4.x

- Pure Swift 6 implementation
- Full async/await concurrency support
- visionOS support
- iOS 15+ minimum deployment target
- Modern actor-based architecture

## Support

- **v3.x Security Fixes**: Until January 2027
- **New Features**: v4.x only
- **Bug Fixes**: v4.x only (critical security fixes backported to v3.x)

---

## Original v3.x Documentation

Branch helps mobile apps grow with deep links / deeplinks that power paid acquisition and re-engagement campaigns, referral programs, content sharing, deep linked emails, smart banners, custom user onboarding, and more.

View [Branch's SDK documentation for iOS](https://help.branch.io/developers-hub/docs/ios-sdk-overview)

---

*This archive was created during the Swift rewrite migration. See [RFC-001](../docs/RFC-REPOSITORY-MIGRATION-STRATEGY.md) for details.*
