# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Swift 6 implementation
- Support for iOS 12+, macOS 12+, watchOS 8+, tvOS 12+, visionOS 1.0+
- Complete concurrency support with `@Sendable` and actors
- Modern Tuist-based project structure
- Comprehensive test suite
- V3 Legacy CI workflow for `v3-legacy/` path changes

### Changed
- Rewritten from scratch in modern Swift
- Repository restructured to contain both V4 (Swift) and V3 Legacy (Objective-C) SDKs
- V3 Legacy SDK moved to `v3-legacy/` directory

### Deprecated
- V3 Legacy Carthage integration (due to root Package.swift conflict)

### Removed
- N/A

### Fixed
- V3 Legacy CI workflow triggers now properly respond to `v3-legacy/**` path changes
- V3 Legacy CocoaPods Podfiles updated with Swift 5.0 version for compatibility

### Security
- Added privacy manifest for iOS 17+

---

## V3 Legacy Changes

### [3.x] - Maintenance Mode

#### Deprecated
- Carthage integration deprecated due to repository restructuring
  - Root `Package.swift` (V4 SDK) conflicts with Carthage builds
  - Recommended alternatives: CocoaPods, SPM, or manual xcframework

#### Fixed
- CI workflow now runs on `v3-legacy/**` path changes
- CocoaPods integration tests passing with Swift 5.0 compatibility
