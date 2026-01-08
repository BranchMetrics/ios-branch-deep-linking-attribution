# Branch iOS SDK

Modern Swift SDK for deep linking and attribution on Apple platforms.

## Overview

| | V4 Modern SDK | V3 Legacy SDK |
|---|---|---|
| **Language** | Swift 6 (strict concurrency) | Objective-C |
| **Platforms** | iOS 12+, macOS 12+, watchOS 8+, tvOS 12+, visionOS 1+ | iOS 12+, tvOS 12+ |
| **Distribution** | Swift Package Manager | CocoaPods, SPM, xcframework |
| **Location** | `Sources/`, `Tests/` | `v3-legacy/` |
| **Status** | Active Development | Maintenance Only |

> **Note:** V3 Legacy Carthage support has been deprecated due to repository restructuring. V3 Legacy users should migrate to CocoaPods, SPM, or manual xcframework integration.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/BranchMetrics/ios-branch-deep-linking-attribution.git", from: "4.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and enter the repository URL.

### V3 Legacy SDK

For Objective-C projects or CocoaPods/Carthage support, see [v3-legacy/README.md](./v3-legacy/README.md).

```ruby
# CocoaPods
pod 'BranchSDK', '~> 3.0'
```

## Quick Start

```swift
import BranchSDK

// Initialize Branch
let config = BranchConfiguration(branchKey: "key_live_xxx")
let session = try await Branch.shared.initialize(with: config)

// Handle deep links
if let data = session.linkData {
    print("Deep link data: \(data)")
}

// Create a deep link
let link = try await Branch.shared.createLink(
    with: LinkProperties(channel: "share", feature: "referral")
)
```

## Requirements

- **Xcode** 16.0+
- **Swift** 6.0+
- **macOS** 14.0+ (for development)

### Platform Deployment Targets

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 12.0 |
| macOS | 12.0 |
| watchOS | 8.0 |
| tvOS | 12.0 |
| visionOS | 1.0 |

## Development

### Setup

```bash
# Clone and setup
git clone https://github.com/BranchMetrics/ios-branch-deep-linking-attribution.git
cd ios-branch-deep-linking-attribution
./scripts/setup.sh
```

The setup script installs all required tools:
- Mise (tool version manager)
- Tuist 4.44.0 (Xcode project generation)
- SwiftLint 0.58.2 (linting)
- SwiftFormat (formatting)
- Periphery 2.21.0 (dead code detection)
- Ruby 3.3.0 + Fastlane + Danger

### Build & Test

```bash
# Build
swift build

# Run tests
swift test

# Open in Xcode
tuist generate && open BranchSDK.xcworkspace
```

### Code Quality

```bash
# Lint
swiftlint

# Format
swiftformat .

# Dead code detection
periphery scan
```

### CI Commands

```bash
bundle exec fastlane test    # Run tests
bundle exec fastlane lint    # Run linter
bundle exec fastlane ci      # Full CI pipeline
```

## Project Structure

```
.
├── Sources/
│   ├── BranchSDK/              # Main SDK (Swift 6)
│   └── BranchSDKTestKit/       # Test utilities
├── Tests/
│   ├── BranchSDKTests/         # Unit tests
│   ├── BranchSDKIntegrationTests/
│   └── BranchSDKPerformanceTests/
├── v3-legacy/                  # Legacy Objective-C SDK
├── scripts/
│   └── setup.sh                # Development environment setup
├── Package.swift               # SPM manifest
├── Project.swift               # Tuist configuration
└── fastlane/                   # CI/CD automation
```

## Configuration

### Tool Versions (.mise.toml)

| Tool | Version | Purpose |
|------|---------|---------|
| tuist | 4.44.0 | Xcode project generation |
| swiftlint | 0.58.2 | Code linting |
| periphery | 2.21.0 | Dead code detection |
| xcbeautify | 2.17.0 | Build output formatting |
| ruby | 3.3.0 | Fastlane/Danger |

## Troubleshooting

### Mise not found

```bash
source ~/.zshrc
# or restart terminal
```

### Tuist generation fails

```bash
tuist clean
tuist generate
```

### Ruby/Bundle issues

```bash
mise install ruby@3.3.0
bundle install
```

## Contributing

1. Fork the repository
2. Run `./scripts/setup.sh`
3. Create a feature branch
4. Make changes and ensure `swiftlint` and `swiftformat .` pass
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Branch Documentation](https://help.branch.io/)
- [API Reference](https://help.branch.io/developers-hub/reference)
- [V3 Legacy SDK](./v3-legacy/)
