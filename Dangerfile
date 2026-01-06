# Branch iOS SDK - Dangerfile
# Copyright © 2024 Branch Metrics. All rights reserved.
# SPDX-License-Identifier: MIT

# =====================
# Configuration
# =====================

# Minimum test coverage threshold
MIN_COVERAGE = 90

# Maximum lines changed in a single PR
MAX_PR_SIZE = 500

# Files that require extra review
SENSITIVE_FILES = [
  "Package.swift",
  "Project.swift",
  "Tuist/Config.swift",
  ".github/workflows/",
  "fastlane/",
  "Sources/BranchSDK/Network/",
  "Sources/BranchSDK/Storage/",
]

# =====================
# PR Metadata Checks
# =====================

# Warn if PR is too large
if git.lines_of_code > MAX_PR_SIZE
  warn("This PR has #{git.lines_of_code} lines of code. Consider breaking it into smaller PRs for easier review.")
end

# Warn if no description
if github.pr_body.length < 50
  warn("Please provide a more detailed PR description explaining the changes and motivation.")
end

# Warn if PR title doesn't follow conventional commits
unless github.pr_title =~ /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+/
  warn("PR title should follow [Conventional Commits](https://www.conventionalcommits.org/) format: `type(scope): description`")
end

# Check for WIP
if github.pr_title.include?("WIP") || github.pr_labels.include?("WIP")
  warn("This PR is marked as Work In Progress. Don't merge until ready!")
end

# =====================
# Code Quality Checks
# =====================

# Check for TODO/FIXME comments in new code
todoist.warn_for_todos
todoist.print_todos_table

# SwiftLint integration
swiftlint.config_file = ".swiftlint.yml"
swiftlint.lint_files(inline_mode: true)

# Check for large files
git.added_files.each do |file|
  next unless file.end_with?(".swift")

  content = File.read(file) rescue next
  lines = content.lines.count

  if lines > 300
    warn("#{file} has #{lines} lines. Consider splitting into smaller files (max 300 lines).")
  end
end

# Check for force unwrapping in new code
git.diff.each do |file|
  next unless file.path.end_with?(".swift")

  file.patch.each_line.with_index do |line, index|
    if line.start_with?("+") && !line.start_with?("+++")
      if line.include?("!") && line =~ /\w+!/
        # Check if it's actually a force unwrap (not negation or other use)
        if line =~ /\.\w+!|\w+\?!|as!/
          warn("Force unwrap detected in #{file.path}. Consider using `guard let` or `if let` instead.", file: file.path, line: index)
        end
      end
    end
  end
end

# =====================
# Sensitive File Checks
# =====================

SENSITIVE_FILES.each do |pattern|
  modified_sensitive = git.modified_files.select { |f| f.include?(pattern) }

  unless modified_sensitive.empty?
    message("⚠️ Sensitive file(s) modified: #{modified_sensitive.join(', ')}. Please ensure thorough review.")
  end
end

# =====================
# Test Coverage
# =====================

# Check if tests were added/modified for code changes
has_code_changes = git.modified_files.any? { |f| f.start_with?("Sources/") && f.end_with?(".swift") }
has_test_changes = git.modified_files.any? { |f| f.start_with?("Tests/") && f.end_with?(".swift") }

if has_code_changes && !has_test_changes
  warn("Code changes detected without corresponding test updates. Please add or update tests.")
end

# Coverage check (if coverage report exists)
if File.exist?("coverage.lcov")
  require "danger/plugins/swift_coverage"

  swift_coverage.minimum_coverage = MIN_COVERAGE
  swift_coverage.warning_coverage = MIN_COVERAGE + 5
  swift_coverage.danger_coverage = MIN_COVERAGE - 10
  swift_coverage.coverage_path = "coverage.lcov"
  swift_coverage.notify_if_coverage_is_low
end

# =====================
# Documentation Checks
# =====================

# Check for public API changes without documentation updates
public_api_changes = git.modified_files.any? do |f|
  next false unless f.end_with?(".swift") && f.start_with?("Sources/")

  content = File.read(f) rescue ""
  content.include?("public ") || content.include?("open ")
end

docs_updated = git.modified_files.any? { |f| f.end_with?(".md") || f.include?("Documentation/") }

if public_api_changes && !docs_updated
  warn("Public API changes detected. Consider updating documentation.")
end

# =====================
# Changelog
# =====================

has_changelog_entry = git.modified_files.include?("CHANGELOG.md")

if !has_changelog_entry && (git.insertions + git.deletions > 50)
  warn("Please add a CHANGELOG.md entry describing this change.")
end

# =====================
# Branch Naming
# =====================

branch = github.branch_for_head

unless branch =~ /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|hotfix|release)\/[a-z0-9-]+$/
  warn("Branch name `#{branch}` doesn't follow naming convention: `type/description` (e.g., `feat/session-state`)")
end

# =====================
# Concurrency Checks (Swift 6)
# =====================

git.diff.each do |file|
  next unless file.path.end_with?(".swift")

  file.patch.each_line.with_index do |line, index|
    if line.start_with?("+") && !line.start_with?("+++")
      # Check for @unchecked Sendable
      if line.include?("@unchecked Sendable")
        warn("@unchecked Sendable found in #{file.path}. Ensure this is intentional and thread-safe.", file: file.path, line: index)
      end

      # Check for nonisolated(unsafe)
      if line.include?("nonisolated(unsafe)")
        warn("nonisolated(unsafe) found in #{file.path}. This bypasses concurrency safety.", file: file.path, line: index)
      end

      # Check for DispatchQueue usage (prefer actors)
      if line.include?("DispatchQueue")
        message("DispatchQueue usage in #{file.path}. Consider using Swift actors for thread safety.", file: file.path, line: index)
      end
    end
  end
end

# =====================
# Final Summary
# =====================

if status_report[:errors].empty? && status_report[:warnings].empty?
  message("✅ Great job! This PR looks good to merge.")
end
