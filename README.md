# Branch iOS SDK (Swift)

Modern Swift implementation of the Branch deep linking and attribution SDK for iOS, macOS, watchOS, tvOS, and visionOS.

## Requirements

- iOS 15.0+ / macOS 12.0+ / watchOS 8.0+ / tvOS 15.0+ / visionOS 1.0+
- Xcode 16.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add Branch SDK to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/BranchMetrics/ios-branch-deep-linking-attribution-swift.git", from: "4.0.0")
]
```

### CocoaPods

```ruby
pod 'BranchSDK', '~> 4.0'
```

## Development Setup

### Prerequisites

1. **macOS 14.0+** (Sonoma or later)
2. **Xcode 16.0+** (for Swift 6 support)
3. **Homebrew** (will be installed automatically if missing)

### Quick Setup

Run the setup script to install all development tools:

```bash
./scripts/setup.sh
```

This script will:
1. Install Homebrew (if needed)
2. Install Mise (tool version manager)
3. Install development tools via Mise:
   - Tuist 4.44.0 (Xcode project generation)
   - SwiftLint 0.58.2 (code linting)
   - Periphery 2.21.0 (dead code detection)
   - xcbeautify 2.17.0 (build output beautifier)
   - Ruby 3.3.0 (for Fastlane/Danger)
4. Install SwiftFormat via Homebrew
5. Install Ruby gems (Danger, Fastlane)
6. Generate Xcode project via Tuist
7. Set up Git hooks

### Manual Setup

If you prefer manual installation:

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Mise
brew install mise

# 3. Activate Mise (add to ~/.zshrc for persistence)
eval "$(mise activate zsh)"

# 4. Install tools from .mise.toml
cd /path/to/project
mise trust
mise install

# 5. Install SwiftFormat (via Homebrew, not Mise)
brew install swiftformat

# 6. Install Ruby gems
bundle install

# 7. Generate Xcode project
tuist generate
```

### Verifying Installation

Check all tools are working:

```bash
# Tool versions
tuist version          # Should show 4.44.0
swiftlint version      # Should show 0.58.2
swiftformat --version  # Should show 0.58.x
periphery version      # Should show 2.21.0
xcbeautify --version   # Should show 2.17.0

# Ruby tools (via bundle)
bundle exec danger --version    # Should show 9.x
bundle exec fastlane --version  # Should show 2.x
```

## Development Commands

### Building

```bash
# Build with Swift
swift build

# Build with Tuist (generates Xcode project first)
tuist generate
xcodebuild -workspace BranchSDK.xcworkspace -scheme BranchSDK -sdk iphonesimulator build

# Build with xcbeautify (pretty output)
swift build 2>&1 | xcbeautify
```

### Testing

```bash
# Run unit tests
swift test

# Run specific test
swift test --filter BranchSDKTests

# Run with coverage (via Tuist)
tuist generate
xcodebuild test -workspace BranchSDK.xcworkspace -scheme BranchSDK -sdk iphonesimulator -enableCodeCoverage YES
```

### Code Quality

```bash
# Run SwiftLint
swiftlint

# Auto-fix SwiftLint issues
swiftlint --fix

# Run SwiftFormat
swiftformat .

# Check formatting without changes
swiftformat . --lint

# Detect dead code
periphery scan
```

### Tuist Commands

```bash
# Generate Xcode project
tuist generate

# Generate and open Xcode
tuist generate && open BranchSDK.xcworkspace

# Edit Tuist manifests
tuist edit

# Clean Tuist cache
tuist clean
```

### Fastlane

```bash
# Run all tests
bundle exec fastlane test

# Run linter
bundle exec fastlane lint

# Full CI pipeline
bundle exec fastlane ci
```

### Danger (PR Checks)

```bash
# Run Danger locally
bundle exec danger local
```

## Project Structure

```
.
├── Sources/
│   ├── BranchSDK/           # Main SDK source
│   └── BranchSDKTestKit/    # Test utilities
├── Tests/
│   ├── BranchSDKTests/              # Unit tests
│   ├── BranchSDKIntegrationTests/   # Integration tests
│   └── BranchSDKPerformanceTests/   # Performance tests
├── Project.swift            # Tuist project definition
├── Package.swift            # SPM manifest
├── .mise.toml              # Tool versions (Mise)
├── .swiftlint.yml          # SwiftLint config
├── .swiftformat            # SwiftFormat config
├── Gemfile                 # Ruby dependencies
├── Dangerfile              # Danger config
└── fastlane/
    └── Fastfile            # Fastlane lanes
```

## Configuration Files

### .mise.toml

Tool versions managed by Mise:
- `tuist = "4.44.0"` - Xcode project generation
- `swiftlint = "0.58.2"` - Code linting
- `periphery = "2.21.0"` - Dead code detection
- `xcbeautify = "2.17.0"` - Build output beautifier
- `ruby = "3.3.0"` - For Fastlane/Danger

**Note:** SwiftFormat must be installed via Homebrew (`brew install swiftformat`) because Mise installs the GUI app instead of CLI.

### .swiftlint.yml

SwiftLint configuration with:
- Swift 6 concurrency support
- Strict code quality rules
- Custom file header requirements

### .swiftformat

SwiftFormat configuration aligned with SwiftLint rules.

## Troubleshooting

### Mise not found after installation

Restart your terminal or run:
```bash
source ~/.zshrc
```

### SwiftFormat not working

Make sure SwiftFormat is installed via Homebrew, not Mise:
```bash
brew install swiftformat
```

### Ruby version mismatch

The project requires Ruby 3.3.0 (managed by Mise). If you see errors about Ruby version:
```bash
mise install ruby@3.3.0
mise use ruby@3.3.0
```

### Tuist generation fails

Clear the cache and try again:
```bash
tuist clean
tuist generate
```

### Bundle install fails

Make sure you're using Ruby 3.3.0:
```bash
ruby --version  # Should show 3.3.0
bundle install
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Run `./scripts/setup.sh` to set up your development environment
3. Create a feature branch
4. Make your changes
5. Run `swiftlint` and `swiftformat .` before committing
6. Submit a pull request
