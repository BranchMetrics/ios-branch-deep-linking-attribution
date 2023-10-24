Pod::Spec.new do |s|
  s.name             = "BranchSDK"
  s.version          = "3.0.0"
  s.summary          = "Create an HTTP URL for any piece of content in your app"
  s.description      = <<-DESC
- Want the highest possible conversions on your sharing feature?
- Want to measure the k-factor of your invite feature?
- Want a whole referral program in 10 lines of code, with automatic user-user attribution and rewarding?
- Want to pass data (deep link) from a URL across install and open?
- Want custom onboarding post install?

Use the Branch SDK (branch.io) to create and power the links that point back to your apps for all of these things and more. Branch makes it incredibly simple to create powerful deep links that can pass data across app install and open while handling all edge cases (using on desktop vs. mobile vs. already having the app installed, etc). Best of all, it's really simple to start using the links for your own app: only 2 lines of code to register the deep link router and one more line of code to create the links with custom data.
                       DESC
  s.homepage         = "https://help.branch.io/developers-hub/docs/ios-sdk-overview"
  s.license          = 'MIT'
  s.author           = { "Branch" => "sdk-team@branch.io" }
  s.source           = { git: "https://github.com/BranchMetrics/ios-branch-deep-linking-attribution.git", tag: s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'

  s.resources = ["BranchSDK/*.{xcprivacy}"]
  s.ios.source_files = "BranchSDK/*.{h,m}"

  s.tvos.source_files = "BranchSDK/*.{h,m}"
  s.tvos.exclude_files = "BranchSDK/BNCAdClient.{h,m}",
	"BranchSDK/BNCAppleSearchAds.{h,m}",
	"BranchSDK/BNCContentDiscoveryManager.{h,m}",
	"BranchSDK/BNCUserAgentCollector.{h,m}",
	"BranchSDK/BNCSpotlightService.{h,m}",
	"BranchSDK/BranchActivityItemProvider.{h,m}",
	"BranchSDK/BranchCSSearchableItemAttributeSet.{h,m}",
	"BranchSDK/BranchShareLink.{h,m}",
	"BranchSDK/BranchPasteControl.{h,m}"

  s.frameworks = 'CoreServices', 'SystemConfiguration'
  s.weak_framework = 'LinkPresentation'
  s.ios.frameworks = 'WebKit'
end
