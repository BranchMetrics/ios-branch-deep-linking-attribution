require 'cocoapods'
require 'pathname'

module CocoapodsHelper
  UI = FastlaneCore::UI

  class CocoapodsHelperException < RuntimeError; end

  # Following the lead of npm ci (https://docs.npmjs.com/cli/v7/commands/npm-ci):
  # The Podfile.lock must exist.
  # The Podfile and Podfile.lock must be in sync.
  # A pod install may be required, but it is an error to generate a change to
  # the Podfile.lock, including when it's missing. If pod install is run, it
  # may regenerate Pods/Manifest.lock or the entire Pods folder if the cache
  # is out of sync.
  def pod_install_required?(podfile_folder)
    podfile_folder = File.expand_path podfile_folder
    podfile_path = File.join podfile_folder, 'Podfile'
    raise ArgumentError, "No Podfile at #{podfile_folder}" unless File.readable?(podfile_path)

    # Podfile must be evalled in its current directory in order to resolve
    # the require_relative at the top.
    podfile = Dir.chdir(podfile_folder) { Pod::Podfile.from_file podfile_path }

    # From here on we expect pod install to succeed. We just check whether it's
    # necessary. The Podfile.from_file call above can raise if the Podfile
    # contains errors. In that case, pod install will also fail, so we allow
    # the exception to be raised instead of returning true.

    lockfile_path = File.join podfile_folder, 'Podfile.lock'
    manifest_path = File.join podfile_folder, 'Pods', 'Manifest.lock'

    # Don't regenerate the lockfile
    raise CocoapodsHelperException, "#{lockfile_path} missing or not readable." unless File.readable?(lockfile_path)

    return true unless File.readable?(manifest_path)

    # This validates the Podfile.lock for yaml formatting at least and makes
    # the lockfile hash available to check the Podfile checksum later.
    lockfile = Pod::Lockfile.from_file Pathname.new lockfile_path
    lockfile_contents = File.read lockfile_path

    begin
      # diff the contents of Podfile.lock and Pods/Manifest.lock
      # This is just what is done in the "[CP] Check Pods Manifest.lock" script
      # build phase in a project using CocoaPods. This is a stricter requirement
      # than semantic comparison of the two lockfile hashes.
      return true unless lockfile_contents == File.read(manifest_path)

      # compare checksum of Podfile with checksum in Podfile.lock in case Podfile
      # updated since last pod install/update.
      return false if lockfile.to_hash["PODFILE CHECKSUM"] == podfile.checksum
    rescue StandardError, Pod::PlainInformative => e
      # Any error from Pod::Lockfile.from_file or File.read after verifying a
      # file exists and is readable. pod install will regenerate these files.
      UI.error e.message
      return true
    end

    # Don't regenerate the lockfile.
    raise CocoapodsHelperException, "Podfile checksum #{podfile.checksum} does not match PODFILE CHECKSUM in Podfile.lock."
  end

  def pod_install_if_required(podfile_folder, verbose: false, repo_update: true)
    podfile_folder = File.expand_path podfile_folder
    install_required = pod_install_required? podfile_folder
    UI.message "pod install #{install_required ? '' : 'not '}required in #{podfile_folder}"
    return unless install_required

    command = %w[pod install]
    command << '--silent' unless verbose
    command << '--repo-update' if repo_update

    Dir.chdir(podfile_folder) { Fastlane::Action.sh(*command) }
  end

  def current_pod_version
    # Get current version from podspec
    podspec = File.open('../Branch.podspec', 'r') do |f|
      eval f.read
    end
    podspec.version
  end
end

include CocoapodsHelper
