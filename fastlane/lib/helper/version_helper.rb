require 'CFPropertyList'
require 'pattern_patch'
require 'xcodeproj'

module VersionHelper
  # Updates the SDK version from the Fastfile lane opts
  def update_sdk_version(opts)
    # Shell out to agvtool to increment the build number
    Dir.chdir('../carthage-files') { Fastlane::Action.sh(%w[agvtool bump]) }
    # Update the MARKETING_VERSION using patch, minor, major or an actual version number
    next_version = update_project_marketing_version '../carthage-files/BranchSDK.xcodeproj', opts[:version]

    # Update BNCConfig.m
    PatternPatch::Patch.new(
      regexp: /(BNC_SDK_VERSION.*@")(.*)(";)/,
      text: "\\1#{next_version}\\3",
      mode: :replace
    ).apply '../Branch-SDK/BNCConfig.m'

    # Update Branch.podspec
    PatternPatch::Patch.new(
      regexp: /(s.version.*=\s*")(.*)(")/,
      text: "\\1#{next_version}\\3",
      mode: :replace
    ).apply '../Branch.podspec'

    update_testbed_framework_info_plist next_version

    next_version
  end

  # agvtool doesn't do this for the marketing version
  # Pass an actual version or major, minor or patch for an automatic bump
  # If the version includes a suffix like -beta.1, that will be removed in
  # the automatic bump.
  def new_version(version, next_version)
    # Remove any suffix beginning with a hyphen, e.g. 1.2.3-beta.1 -> 1.2.3
    components = version.sub(/-.*$/, '').split '.'

    case next_version
    when 'patch', nil
      components[2] = components[2].to_i + 1
    when 'minor'
      components[1] = components[1].to_i + 1
    when 'major'
      components[0] = components[0].to_i + 1
    else
      return next_version
    end

    components.join '.'
  end

  # Update MARKETING_VERSION to the specified version in the specified project
  # at project_path.
  def update_project_marketing_version(project_path, version)
    # raises
    project = Xcodeproj::Project.open project_path
    framework_targets = project.native_targets.reject &:test_target_type?
    current_marketing_version = framework_targets.first.resolved_build_setting('MARKETING_VERSION')['Release']

    next_version = new_version current_marketing_version, version

    # TODO: Isn't this a project-level setting?
    framework_targets.reject(&:test_target_type?).each do |target|
      target.build_configuration_list.set_setting 'MARKETING_VERSION', next_version
    end

    # raises
    project.save

    next_version
  end

  def update_testbed_framework_info_plist(marketing_version)
    plist = CFPropertyList::List.new file: '../Branch-TestBed/Framework-Info.plist'
    data = CFPropertyList.native_types(plist.value)

    data['CFBundleShortVersionString'] = marketing_version
    # Ordinarily CFBundleVersion is the project version (build number), not the marketing version
    # Following the lead of the existing script here.
    data['CFBundleVersion'] = marketing_version

    plist.value = CFPropertyList.guess data
    plist.save '../Branch-TestBed/Framework-Info.plist', CFPropertyList::List::FORMAT_BINARY
  end
end

include VersionHelper
