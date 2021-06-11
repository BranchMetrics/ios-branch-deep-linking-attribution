require 'cocoapods'
require 'pathname'

module UpdateHelper
  UI = FastlaneCore::UI

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

    lockfile_readable = File.readable? lockfile_path
    UI.message "#{lockfile_path} not readable" unless lockfile_readable
    manifest_readable = File.readable? manifest_path
    UI.message "#{manifest_path} not readable" unless manifest_readable
    return true unless lockfile_readable && manifest_readable

    begin
      # This validates the Podfile.lock for yaml formatting at least and makes
      # the lockfile hash available to check the Podfile checksum later.
      lockfile = Pod::Lockfile.from_file Pathname.new lockfile_path

      # diff the contents of Podfile.lock and Pods/Manifest.lock
      # This is just what is done in the "[CP] Check Pods Manifest.lock" script
      # build phase in a project using CocoaPods. This is a stricter requirement
      # than semantic comparison of the two lockfile hashes.
      lockfiles_in_sync = File.read(lockfile_path) == File.read(manifest_path)
      UI.message "Lockfiles out of sync" unless lockfiles_in_sync
      return true unless lockfiles_in_sync

      # compare checksum of Podfile with checksum in Podfile.lock in case Podfile
      # updated since last pod install/update.
      invalid_checksum = lockfile.to_hash["PODFILE CHECKSUM"] != podfile.checksum

      UI.message "Invalid Podfile checksum" if invalid_checksum

      invalid_checksum
    rescue StandardError, Pod::PlainInformative => e
      # Any error from Pod::Lockfile.from_file or File.read after verifying a
      # file exists and is readable. pod install will regenerate these files.
      UI.error e.message
      true
    end
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
end

include UpdateHelper
