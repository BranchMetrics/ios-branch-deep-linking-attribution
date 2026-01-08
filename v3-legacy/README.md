# Branch iOS SDK v3.x (Legacy - Objective-C)

> **This code is archived.** For active development, see the main branch with Swift 6 implementation.

## Status

| Version | Status | Support Until |
|---------|--------|---------------|
| **4.x (Swift 6)** | Active Development | Ongoing |
| **3.x (Objective-C)** | Maintenance Only | January 2027 |

## Important: Carthage Deprecation Notice

**Carthage integration for V3 Legacy SDK has been deprecated** due to repository restructuring.

The root `Package.swift` (V4 SDK) conflicts with Carthage builds for V3 Legacy. This is a known limitation that cannot be resolved without breaking other integration methods.

### Recommended Alternatives

| Method | Status | Notes |
|--------|--------|-------|
| **CocoaPods** | ✅ Supported | Recommended for V3 Legacy users |
| **SPM** | ✅ Supported | Use `v3-legacy/Package.swift` |
| **Manual xcframework** | ✅ Supported | Build with `xcodebuild -scheme xcframework` |
| **Tagged releases** | ✅ Supported | Download from GitHub releases |
| ~~Carthage~~ | ❌ Deprecated | Use alternatives above |

## About This Archive

This directory contains the legacy Objective-C implementation of the Branch iOS SDK (v3.x). It has been preserved for:

- Historical reference
- Bug investigation context
- Migration assistance for customers still on v3.x

## For v3.x Users

If you need to use the v3.x SDK:

### 1. CocoaPods (Recommended)

```ruby
pod 'BranchSDK', '~> 3.0'
```

### 2. Swift Package Manager

Reference the v3-legacy Package.swift:

```swift
.package(url: "https://github.com/BranchMetrics/ios-branch-deep-linking-attribution.git", .upToNextMajor(from: "3.0.0"))
```

### 3. Manual xcframework Integration

Build the xcframework from source:

```bash
cd v3-legacy
xcodebuild -project BranchSDK.xcodeproj -scheme xcframework
```

Then add `BranchSDK.xcframework` to your project.

### 4. Static xcframework

For static linking:

```bash
cd v3-legacy
xcodebuild -project BranchSDK.xcodeproj -scheme static-xcframework
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
