Pod::Spec.new do |s|
  s.name             = "Branch"
  s.version          = "0.16.1"
  s.summary          = "Create an HTTP URL for any piece of content in your app"
  s.description      = <<-DESC
- Want the highest possible conversions on your sharing feature?
- Want to measure the k-factor of your invite feature?
- Want a whole referral program in 10 lines of code, with automatic user-user attribution and rewarding?
- Want to pass data (deep link) from a URL across install and open?
- Want custom onboarding post install?
- Want it all for free?

Use the Branch SDK (branch.io) to create and power the links that point back to your apps for all of these things and more. Branch makes it incredibly simple to create powerful deep links that can pass data across app install and open while handling all edge cases (using on desktop vs. mobile vs. already having the app installed, etc). Best of all, it's really simple to start using the links for your own app: only 2 lines of code to register the deep link router and one more line of code to create the links with custom data.
                       DESC
  s.homepage         = "https://branch.io"
  s.license          = 'Proprietary'
  s.author           = { "Branch" => "support@branch.io" }
  s.source           = { :git => "https://github.com/BranchMetrics/iOS-Deferred-Deep-Linking-SDK.git", :tag => s.version.to_s }
  s.platform         = :ios, '7.0'
  s.requires_arc     = true

  s.subspec 'Core' do |core|
    core.source_files = "Branch-SDK/Branch-SDK/*.{h,m}", "Branch-SDK/Branch-SDK/Requests/*.{h,m}", "Branch-SDK/Fabric/*.h"
    core.private_header_files = "Branch-SDK/Fabric/*.h"
    core.frameworks = 'AdSupport', 'MobileCoreServices'
  end

  s.subspec 'without-IDFA' do |idfa|
    idfa.source_files = "Branch-SDK/Branch-SDK/*.{h,m}", "Branch-SDK/Branch-SDK/Requests/*.{h,m}", "Branch-SDK/Fabric/*.h"
    idfa.private_header_files = "Branch-SDK/Fabric/*.h"
    idfa.frameworks = 'MobileCoreServices'
  end

  s.subspec 'without-Safari' do |safari|
    safari.source_files = "Branch-SDK/Branch-SDK/*.{h,m}", "Branch-SDK/Branch-SDK/Requests/*.{h,m}", "Branch-SDK/Fabric/*.h"
    safari.private_header_files = "Branch-SDK/Fabric/*.h"
    safari.frameworks = 'AdSupport', 'MobileCoreServices'
  end

end
