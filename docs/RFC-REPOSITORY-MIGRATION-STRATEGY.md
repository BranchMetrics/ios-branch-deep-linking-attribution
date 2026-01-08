# RFC: Branch iOS SDK Repository Migration Strategy

**RFC Number:** 001
**Title:** Swift Rewrite Repository Strategy
**Author:** Branch SDK Team
**Status:** Implemented
**Created:** 2026-01-06
**Last Updated:** 2026-01-08

---

## Abstract

This document proposes and evaluates strategies for managing the Branch iOS SDK's transition from an Objective-C codebase to a modern Swift 6 implementation. The primary question is whether to maintain the Swift rewrite in a new repository or integrate it into the existing repository while preserving 10+ years of development history.

---

## Table of Contents

1. [Background](#background)
2. [Current State Analysis](#current-state-analysis)
3. [Problem Statement](#problem-statement)
4. [Proposed Options](#proposed-options)
5. [Detailed Analysis](#detailed-analysis)
6. [Recommendation](#recommendation)
7. [Migration Plan](#migration-plan)
8. [Open Questions](#open-questions)
9. [Decision Record](#decision-record)

---

## Background

### Why the Rewrite?

The Branch iOS SDK has served the mobile development community since 2014. However, the iOS ecosystem has evolved significantly:

- **Swift Concurrency**: async/await, actors, and structured concurrency are now standard
- **Swift 6**: Strict concurrency checking requires modern patterns
- **Platform Expansion**: visionOS requires modern Swift support
- **Minimum iOS Version**: iOS 15+ is now a reasonable baseline for new development
- **Developer Experience**: Swift-first APIs are expected by modern iOS developers

### Repository Overview

| Repository | Purpose | Age |
|------------|---------|-----|
| `ios-branch-deep-linking-attribution` | Current production SDK (Obj-C) | ~10 years |
| `ios-branch-deep-linking-attribution-swift` | Swift 6 rewrite | New |

---

## Current State Analysis

### Original Repository (`ios-branch-deep-linking-attribution`)

```
Commits:           4,365
First Commit:      June 5, 2014
Languages:         Objective-C (primary), Swift (compatibility)
Min iOS Version:   iOS 12+
Supported Platforms: iOS, tvOS, macOS (Catalyst)
Package Managers:  CocoaPods, SPM, Carthage
GitHub Stars:      ~2,000+ (estimated)
Open Issues:       [To be filled]
Contributors:      [To be filled]
```

**Key Files:**
- 1,600+ lines of changelog documenting every fix since v0.3.0
- Comprehensive test suite
- Multiple integration examples
- Privacy manifest for iOS 17+

### Swift Rewrite Repository (`ios-branch-deep-linking-attribution-swift`)

```
Commits:           1
First Commit:      January 6, 2026
Languages:         Swift 6 (pure)
Min iOS Version:   iOS 15+
Supported Platforms: iOS, tvOS, macOS, watchOS, visionOS
Package Managers:  SPM, CocoaPods (planned)
Tooling:           Tuist, SwiftLint, SwiftFormat, Periphery
```

**Key Features:**
- Complete Swift 6 concurrency support (@Sendable, actors)
- Modern project structure with Tuist
- Comprehensive development tooling
- Support for visionOS

---

## Problem Statement

We need to decide how to release the Swift rewrite while:

1. **Preserving institutional knowledge** - 10 years of bug fixes, decisions, and patterns
2. **Maintaining ecosystem continuity** - Package managers, integrations, documentation
3. **Minimizing customer disruption** - Clear migration path, no broken dependencies
4. **Enabling future development** - Clean codebase for ongoing work

### Key Questions for Discussion

1. How important is Git history preservation to our team and customers?
2. What is our support timeline for the Objective-C version?
3. How do we communicate this major version change to customers?
4. What are the risks of each approach to our CI/CD and release process?

---

## Proposed Options

### Option A: New Repository (Separate Swift Repo)

Keep the Swift rewrite in `ios-branch-deep-linking-attribution-swift` as the primary repository going forward.

### Option B: Replace in Original Repository

Merge the Swift code into `ios-branch-deep-linking-attribution`, archiving the Obj-C code in a legacy branch.

### Option C: Hybrid Approach

Maintain both repositories indefinitely with different major versions (3.x in old, 4.x in new).

---

## Detailed Analysis

### Option A: New Repository

#### Advantages

| Benefit | Impact | Notes |
|---------|--------|-------|
| Clean slate | High | No legacy build configurations or workflows |
| Clear separation | Medium | Users can choose which version to use |
| Simpler CI/CD | Medium | Fresh pipeline without conditional logic |
| No merge risks | High | No chance of corrupting existing repo |
| Modern tooling | High | Tuist, modern Git workflows from start |

#### Disadvantages

| Drawback | Impact | Severity |
|----------|--------|----------|
| **Lost Git history** | 4,365 commits of context | Critical |
| **Lost GitHub metrics** | Stars, watchers, forks | High |
| **Broken package references** | CocoaPods, SPM specs | High |
| **SEO reset** | Search rankings, documentation links | Medium |
| **Contributor history lost** | Recognition, blame context | Medium |
| **Dual maintenance burden** | Two repos during transition | High |
| **Customer confusion** | "Which repo do I use?" | High |
| **Trust/credibility** | New repo appears unproven | Medium |

#### Hidden Costs

1. **Documentation Updates**
   - All external docs, tutorials, blog posts reference old repo
   - Stack Overflow answers link to old repo
   - Third-party integrations may hardcode old URLs

2. **Onboarding Friction**
   - New developers can't trace why decisions were made
   - "Why is this code here?" questions have no history

3. **Bug Investigation**
   - Without `git blame`, debugging regression requires guesswork
   - Historical context for edge cases is lost

---

### Option B: Replace in Original Repository (Recommended)

#### Advantages

| Benefit | Impact | Notes |
|---------|--------|-------|
| **History preserved** | 10 years of context | Critical |
| **SEO maintained** | Rankings, links work | High |
| **Package continuity** | Same repo URLs | High |
| **Single source of truth** | One repo to watch/star | High |
| **Contributor credit** | Recognition preserved | Medium |
| **Trust maintained** | Established project | High |
| **Version progression** | 3.x → 4.0 is natural | High |

#### Disadvantages

| Drawback | Impact | Mitigation |
|----------|--------|------------|
| Migration complexity | Medium | Clear branch strategy |
| Dual-branch maintenance | Temporary | 12-month EOL for 3.x |
| CI/CD updates needed | Medium | Conditional workflows |
| Large repo size | Low | Git handles this fine |
| Legacy code visible | Low | Clear directory structure |

#### Implementation Strategy

```
main (default)
├── Sources/BranchSDK/        # Swift 6 code
├── Tests/                    # Swift tests
├── Package.swift             # SPM manifest
└── Project.swift             # Tuist config

v3-legacy (archived branch)
├── Sources/                  # Obj-C code (frozen)
├── BranchSDK.podspec         # Legacy podspec
└── README.md                 # "This branch is archived"
```

---

### Option C: Hybrid (Indefinite Parallel Maintenance)

#### Why This Is Not Recommended

| Issue | Problem |
|-------|---------|
| Double maintenance | Bug fixes needed in both repos |
| Customer confusion | "Which one should I use?" |
| Resource drain | Team split across codebases |
| Inconsistent behavior | Diverging implementations |
| No clear end state | Perpetual overhead |

---

## Recommendation

**We recommend Option B: Replace in Original Repository**

### Rationale

1. **History is irreplaceable**
   - Once lost, 4,365 commits cannot be recovered
   - Future debugging depends on historical context
   - Institutional knowledge has tangible value

2. **Ecosystem stability**
   - Package managers continue working
   - Documentation links remain valid
   - Customer integrations don't break

3. **Professional continuity**
   - Project appears mature and well-maintained
   - Contributors retain recognition
   - Trust is preserved

4. **Technical feasibility**
   - Git supports large histories efficiently
   - Branch strategies are well-understood
   - CI/CD can handle multi-branch workflows

### What We Preserve

- ✅ 10 years of commit history
- ✅ Bug fix context and reasoning
- ✅ GitHub stars, watchers, forks
- ✅ Package manager URLs
- ✅ Documentation links
- ✅ Contributor recognition
- ✅ Issue/PR history

### What We Gain

- ✅ Clean Swift 6 codebase
- ✅ Modern tooling (Tuist, etc.)
- ✅ visionOS support
- ✅ Clear version progression
- ✅ Single source of truth

---

## Migration Plan

### Phase 1: Preparation (Week 1-2)

```
□ Create branch `v3-legacy` from current main
□ Tag latest release as v3.12.1 (or current)
□ Document all open issues by version
□ Audit CI/CD workflows for version-specific steps
□ Notify major customers of upcoming changes
```

### Phase 2: Integration (Week 3-4)

```
□ Create branch `swift-rewrite` in original repo
□ Import Swift code using git subtree (preserves commits)
□ Update Package.swift for Swift version
□ Configure Tuist in original repo
□ Set up dual-build CI/CD pipeline
```

### Phase 3: Testing (Week 5-6)

```
□ Run full test suite on Swift code
□ Verify CocoaPods integration
□ Verify SPM integration
□ Test Carthage (if supported)
□ Customer beta testing program
```

### Phase 4: Release (Week 7-8)

```
□ Merge swift-rewrite to main
□ Release v4.0.0
□ Publish migration guide
□ Update all documentation
□ Archive separate Swift repository
```

### Phase 5: Post-Release (Ongoing)

```
□ Monitor for migration issues
□ Backport critical security fixes to v3-legacy
□ Support v3.x for 12 months
□ Deprecation notices in v3.x
□ End-of-life v3.x after support window
```

---

## Version Support Policy

| Version | Status | Support Until | Notes |
|---------|--------|---------------|-------|
| 4.x | Active | Ongoing | Swift 6, iOS 15+ |
| 3.x | Maintenance | Jan 2027 | Security fixes only |
| 2.x | EOL | - | No longer supported |
| 1.x | EOL | - | No longer supported |

---

## Open Questions

Please provide input on the following:

### For Engineering

1. **Git Strategy**: Should we use `git subtree add` or `git merge --allow-unrelated-histories` to import Swift code?
2. **CI/CD**: How do we handle building both Obj-C and Swift versions in the same repo?
3. **Testing**: What's our strategy for testing both versions during transition?

### For Product

4. **Support Timeline**: Is 12 months sufficient for v3.x maintenance?
5. **Communication**: How do we announce this to customers?
6. **Migration Guide**: What level of detail do customers need?

### For Leadership

7. **Resource Allocation**: Can we commit to maintaining two branches temporarily?
8. **Risk Tolerance**: What's our appetite for potential migration issues?
9. **Timeline**: Is the proposed 8-week timeline realistic?

---

## Decision Record

| Item | Decision | Date | Notes |
|------|----------|------|-------|
| Repository strategy | Option B: Replace in Original Repository | 2026-01-08 | V4 in root, V3 in `v3-legacy/` |
| Support timeline | V3.x until January 2027 | 2026-01-08 | Security fixes only |
| Migration approach | Dual-directory structure | 2026-01-08 | Both SDKs coexist in same repo |
| Carthage support | Deprecated for V3 Legacy | 2026-01-08 | Root Package.swift conflicts |

### Implementation Notes

The migration has been implemented with the following structure:

```
ios-branch-deep-linking-attribution/
├── Sources/BranchSDK/           # V4 Swift 6 SDK (Active Development)
├── Sources/BranchSDKTestKit/    # V4 Test utilities
├── Tests/                       # V4 Tests
├── v3-legacy/                   # V3 Objective-C SDK (Maintenance Only)
│   ├── Sources/BranchSDK/       # V3 Objective-C implementation
│   ├── Sources/BranchSwiftSDK/  # V3 Swift bridge
│   └── SDKIntegrationTestApps/  # V3 Integration tests
├── Package.swift                # V4 SPM manifest
└── Project.swift                # V4 Tuist config
```

### CI/CD Configuration

- **V4 SDK**: `verify.yml` workflow for `Sources/`, `Tests/`, `Package.swift` changes
- **V3 Legacy**: `pre-release-qa.yml` workflow for `v3-legacy/**` changes

### Known Limitations

1. **Carthage for V3 Legacy**: Deprecated due to root Package.swift conflict
   - Carthage resolves the root Package.swift (V4) instead of v3-legacy/Package.swift
   - This creates nested path issues during builds
   - Users should migrate to CocoaPods, SPM, or manual xcframework

---

## Appendix A: Git Commands for History Preservation

### Option 1: Subtree Merge (Recommended)

```bash
# In original repo
cd ios-branch-deep-linking-attribution

# Add Swift repo as remote
git remote add swift-rewrite ../ios-branch-deep-linking-attribution-swift

# Fetch the Swift repo
git fetch swift-rewrite

# Create integration branch
git checkout -b swift-integration

# Subtree merge (preserves commit history)
git merge swift-rewrite/main --allow-unrelated-histories -m "Merge Swift rewrite"

# Resolve any conflicts and commit
```

### Option 2: Replace with History Grafting

```bash
# More complex but gives cleaner history
git replace --graft <swift-first-commit> <objc-last-commit>
git filter-branch -- --all
```

---

## Appendix B: Package Manager Updates

### CocoaPods

```ruby
# BranchSDK.podspec
Pod::Spec.new do |s|
  s.name         = 'BranchSDK'
  s.version      = '4.0.0'
  s.swift_version = '6.0'
  s.ios.deployment_target = '15.0'
  # ... rest of spec
end
```

### Swift Package Manager

```swift
// Package.swift
let package = Package(
    name: "BranchSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    // ...
)
```

---

## Appendix C: Customer Communication Template

### Release Announcement

```markdown
# Branch iOS SDK 4.0 - Swift Rewrite

We're excited to announce Branch iOS SDK 4.0, a complete rewrite in Swift 6!

## What's New
- Pure Swift 6 with full concurrency support
- visionOS support
- Modern async/await APIs
- Improved type safety

## Migration
- Minimum iOS version is now iOS 15
- See our [Migration Guide](link) for details
- v3.x will receive security updates until January 2027

## Installation
The repository URL remains unchanged:
`https://github.com/BranchMetrics/ios-branch-deep-linking-attribution`
```

---

## References

- [Git Subtree Documentation](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Swift Evolution: Concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)

---

*This document is open for discussion. Please add comments or reach out to the SDK team with questions.*
