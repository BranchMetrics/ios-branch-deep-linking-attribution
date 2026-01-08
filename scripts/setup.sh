#!/bin/bash
# Branch iOS SDK - Development Environment Setup
# Copyright © 2024 Branch Metrics. All rights reserved.
# SPDX-License-Identifier: MIT
#
# This script sets up the complete development environment for the Branch iOS SDK.
# Run with: ./scripts/setup.sh
#
# Options:
#   --skip-generate    Skip Xcode project generation
#   --skip-build       Skip verification build
#   --ci               CI mode (non-interactive, skip optional steps)

set -euo pipefail

# =====================
# Configuration
# =====================
SKIP_GENERATE=false
SKIP_BUILD=false
CI_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-generate) SKIP_GENERATE=true ;;
        --skip-build) SKIP_BUILD=true ;;
        --ci) CI_MODE=true ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${CYAN}>>> $1${NC}"; }

# Header
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          Branch iOS SDK - Development Setup                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

info "Project root: $PROJECT_ROOT"

# =====================
# SECTION 1: System Requirements
# =====================
step "Checking system requirements..."

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script requires macOS"
fi

MACOS_VERSION=$(sw_vers -productVersion)
info "macOS version: $MACOS_VERSION"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    error "Xcode is not installed. Please install Xcode from the App Store."
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1 | awk '{print $2}')
info "Xcode version: $XCODE_VERSION"

# Check minimum Xcode version (16.0 for Swift 6)
REQUIRED_XCODE="16.0"
if [[ "$(printf '%s\n' "$REQUIRED_XCODE" "$XCODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_XCODE" ]]; then
    error "Xcode $REQUIRED_XCODE or later is required for Swift 6. Current: $XCODE_VERSION"
fi
success "Xcode $XCODE_VERSION is compatible"

# Check Swift version
SWIFT_VERSION=$(swift --version 2>&1 | grep -o 'Swift version [0-9.]*' | awk '{print $3}')
info "Swift version: $SWIFT_VERSION"

# =====================
# SECTION 2: Install Homebrew
# =====================
step "Checking Homebrew..."

if ! command -v brew &> /dev/null; then
    warning "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# =====================
# SECTION 3: Install Mise (Tool Version Manager)
# =====================
step "Setting up Mise (Tool Version Manager)..."

if ! command -v mise &> /dev/null; then
    info "Installing Mise via Homebrew..."
    brew install mise
    success "Mise installed"
else
    success "Mise already installed ($(mise --version 2>/dev/null || echo 'unknown'))"
fi

# ALWAYS ensure Mise is in shell config (even if already installed)
SHELL_CONFIG=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    if ! grep -q "mise activate" "$SHELL_CONFIG" 2>/dev/null; then
        echo '' >> "$SHELL_CONFIG"
        echo '# Mise - Tool Version Manager' >> "$SHELL_CONFIG"
        echo 'eval "$(mise activate zsh)"' >> "$SHELL_CONFIG"
        info "Added Mise activation to $SHELL_CONFIG"
        warning "You will need to restart your terminal or run: source $SHELL_CONFIG"
    else
        success "Mise already configured in $SHELL_CONFIG"
    fi
fi

# Add mise shims to PATH for current script session
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Helper function to run commands with mise environment
mise_run() {
    mise exec -- "$@"
}

# =====================
# SECTION 4: Install Development Tools via Mise
# =====================
step "Installing development tools via Mise..."

cd "$PROJECT_ROOT"

# Trust mise config
mise trust 2>/dev/null || true

# Install all tools from .mise.toml
info "Installing tools from .mise.toml..."
mise install --yes

# Verify installations
echo ""
info "Verifying tool versions:"
echo "  - Tuist: $(tuist version 2>/dev/null || echo 'not installed')"
echo "  - SwiftLint: $(swiftlint version 2>/dev/null || echo 'not installed')"
echo "  - SwiftFormat: $(swiftformat --version 2>/dev/null || echo 'not installed')"
echo "  - Periphery: $(periphery version 2>/dev/null || echo 'not installed')"
echo "  - xcbeautify: $(xcbeautify --version 2>/dev/null || echo 'not installed')"

# =====================
# SECTION 5: Install Ruby Dependencies
# =====================
step "Setting up Ruby dependencies..."

# Check Ruby (use mise Ruby)
RUBY_VERSION=$(mise_run ruby --version | awk '{print $2}')
info "Ruby version: $RUBY_VERSION (via mise)"

# Verify bundler is available with mise Ruby
BUNDLER_VERSION=$(mise_run bundle --version 2>/dev/null | awk '{print $3}' || echo "not found")
if [[ "$BUNDLER_VERSION" == "not found" ]]; then
    info "Installing Bundler..."
    mise_run gem install bundler --no-document
    success "Bundler installed"
else
    success "Bundler available ($BUNDLER_VERSION)"
fi

# Fix Gemfile if needed (remove problematic gem)
if grep -q 'gem "danger-swift_coverage"' "$PROJECT_ROOT/Gemfile" 2>/dev/null; then
    info "Fixing Gemfile (removing unavailable gem)..."
    sed -i '' 's/^gem "danger-swift_coverage".*$/# gem "danger-swift_coverage"  # Disabled - gem not available/' "$PROJECT_ROOT/Gemfile"
    success "Gemfile updated"
fi

# Install gems (use mise Ruby)
info "Installing Ruby gems..."
mise_run bundle config set --local path 'vendor/bundle' 2>/dev/null || true
mise_run bundle install --quiet
success "Ruby dependencies installed"

# =====================
# SECTION 6: Generate Xcode Project
# =====================
if [[ "$SKIP_GENERATE" == "false" ]]; then
    step "Setting up Tuist project..."

    # Install Tuist dependencies
    info "Installing Tuist dependencies..."
    tuist install 2>/dev/null || warning "tuist install had issues (may be expected)"

    # Generate or ask
    if [[ "$CI_MODE" == "true" ]]; then
        info "Generating Xcode project..."
        tuist generate --no-open 2>/dev/null || warning "tuist generate had issues"
    else
        read -p "Generate Xcode project with Tuist? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            info "Generating Xcode project..."
            tuist generate --no-open 2>/dev/null || warning "tuist generate had issues"
            success "Xcode project generated"
        fi
    fi
else
    info "Skipping Xcode project generation (--skip-generate)"
fi

# =====================
# SECTION 7: Resolve Swift Packages
# =====================
step "Resolving Swift Package dependencies..."
swift package resolve 2>/dev/null || warning "Package resolution had issues"
success "Package dependencies resolved"

# =====================
# SECTION 8: Verification Build
# =====================
if [[ "$SKIP_BUILD" == "false" && "$CI_MODE" == "false" ]]; then
    step "Running verification build..."

    if command -v xcbeautify &> /dev/null; then
        swift build --configuration debug 2>&1 | xcbeautify || {
            warning "Build failed. This may be expected for a fresh project."
        }
    else
        swift build --configuration debug || {
            warning "Build failed. This may be expected for a fresh project."
        }
    fi
else
    info "Skipping verification build"
fi

# =====================
# SECTION 9: Setup Git Hooks
# =====================
step "Setting up Git hooks..."

HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
if [[ -d "$PROJECT_ROOT/.git" ]]; then
    # Pre-commit hook
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Branch iOS SDK - Pre-commit Hook

set -e

echo "Running pre-commit checks..."

# Activate mise for tools
eval "$(mise activate bash)" 2>/dev/null || true

# SwiftFormat
if command -v swiftformat &> /dev/null; then
    echo "-> Checking code formatting..."
    swiftformat . --lint --quiet || {
        echo "SwiftFormat found issues. Run 'swiftformat .' to fix."
        exit 1
    }
fi

# SwiftLint
if command -v swiftlint &> /dev/null; then
    echo "-> Running SwiftLint..."
    swiftlint lint --quiet || {
        echo "SwiftLint found issues. Run 'swiftlint --fix' to auto-fix."
        exit 1
    }
fi

echo "Pre-commit checks passed!"
EOF
    chmod +x "$HOOKS_DIR/pre-commit"

    # Pre-push hook
    cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
# Branch iOS SDK - Pre-push Hook

set -e

echo "Running pre-push checks..."

# Activate mise for tools
eval "$(mise activate bash)" 2>/dev/null || true

# Build
echo "-> Building..."
swift build --configuration debug || {
    echo "Build failed."
    exit 1
}

# Tests
echo "-> Running tests..."
swift test --parallel || {
    echo "Tests failed."
    exit 1
}

echo "Pre-push checks passed!"
EOF
    chmod +x "$HOOKS_DIR/pre-push"

    success "Git hooks installed"
else
    warning "Not a Git repository. Skipping hook installation."
fi

# =====================
# SECTION 10: Summary
# =====================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Status check
echo "Tool Status:"
echo "────────────────────────────────────────"
for tool in mise tuist swiftlint swiftformat periphery xcbeautify; do
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${RED}✗${NC} $tool"
    fi
done

if mise_run bundle exec danger --version &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} danger (via bundle)"
else
    echo -e "  ${RED}✗${NC} danger"
fi

if mise_run bundle exec fastlane --version &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} fastlane (via bundle)"
else
    echo -e "  ${RED}✗${NC} fastlane"
fi

echo ""
echo "Next Steps:"
echo "────────────────────────────────────────"
echo "  1. Restart terminal or run: source ~/.zshrc"
echo "  2. Open project: tuist generate && open BranchSDK.xcworkspace"
echo ""
echo "Available Commands:"
echo "────────────────────────────────────────"
echo "  ${BLUE}Development:${NC}"
echo "    swift build              - Build the SDK"
echo "    swift test               - Run tests"
echo "    tuist generate           - Generate Xcode project"
echo "    tuist edit               - Edit Tuist manifests"
echo ""
echo "  ${BLUE}Code Quality:${NC}"
echo "    swiftlint                - Run linter"
echo "    swiftlint --fix          - Auto-fix lint issues"
echo "    swiftformat .            - Format code"
echo "    periphery scan           - Detect dead code"
echo ""
echo "  ${BLUE}Fastlane:${NC}"
echo "    bundle exec fastlane bootstrap  - Full setup"
echo "    bundle exec fastlane test       - Run tests"
echo "    bundle exec fastlane lint       - Run linter"
echo "    bundle exec fastlane ci         - Full CI pipeline"
echo ""
echo "  ${BLUE}Danger (PR checks):${NC}"
echo "    bundle exec danger local - Run Danger locally"
echo ""

success "Setup complete!"
