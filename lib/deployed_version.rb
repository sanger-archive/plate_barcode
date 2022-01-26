# frozen_string_literal: true

require 'open3'

# Handles release information, displayed when accessing the homepage
module Deployed
  # Holds information about the git commit extracted from files created on build
  class RepoData
    def tag
      @tag ||= git_tag || read_file('TAG').strip.presence
    end

    def revision
      @revision ||= git_rev || read_file('REVISION').strip.presence
    end

    def branch
      @branch ||= git_branch || read_file('BRANCH').strip.presence
    end

    def release
      @release ||= read_file('RELEASE').strip
    end

    def release_url
      @release_url ||= read_file('REPO').strip
    end

    def revision_short
      @revision_short ||= revision&.slice 0..6
    end

    def label
      tag.presence || branch
    end

    def major
      @major ||= version(:major)
    end

    def minor
      @minor ||= version(:minor)
    end

    def patch
      @patch ||= version(:patch)
    end

    def version_hash
      @version_hash ||=
        /\A(?:release-|v){0,1}(?<major>\d+)\.(?<minor>\d+)\.?(?<patch>\S*)\z/
          .match(label)
    end

    # rubocop:disable Style/NumericPredicate
    def version_label
      if major == 0 && minor == 0 && patch == 0
        'WIP'
      else
        "#{major}.#{minor}.#{patch}"
      end
    end

    # rubocop:enable Style/NumericPredicate

    private

    def git_tag
      cmd = 'git tag -l --points-at HEAD --sort -version:refname | head -1'
      @git_tag ||= execute_command(cmd)
    end

    def git_rev
      cmd = 'git rev-parse HEAD'
      @git_rev ||= execute_command(cmd)
    end

    def git_branch
      cmd = 'git rev-parse --abbrev-ref HEAD'
      @git_branch ||= execute_command(cmd)
    end

    def version(rank)
      version_hash ? version_hash[rank] : 0
    end

    def execute_command(cmd)
      _stdin, stdout, _stderr, _wait_thr = Open3.popen3(cmd)
      res = stdout.gets
      res&.strip
    end

    def read_file(filename)
      File.read(filename, 'r')
    rescue Errno::ENOENT, EOFError
      ''
    end
  end

  ENVIRONMENT = RAILS_ENV.to_s

  REPO_DATA = RepoData.new

  VERSION_ID = REPO_DATA.version_label

  APP_NAME = 'Plate Barcode'
  RELEASE_NAME = REPO_DATA.release.presence || 'LOCAL'

  MAJOR = REPO_DATA.major
  MINOR = REPO_DATA.minor
  PATCH = REPO_DATA.patch
  BRANCH = REPO_DATA.label.presence || 'unknown_branch'
  COMMIT = REPO_DATA.revision.presence || 'unknown_revision'
  ABBREV_COMMIT = REPO_DATA.revision_short.presence || 'unknown_revision'

  VERSION_STRING = "#{APP_NAME} #{VERSION_ID} [#{ENVIRONMENT}]".freeze
  VERSION_COMMIT = "#{BRANCH}@#{ABBREV_COMMIT}".freeze
  REPO_URL = REPO_DATA.release_url.presence || '#'
  HOSTNAME = Socket.gethostname

  DETAILS = { version: VERSION_ID, environment: ENVIRONMENT }.freeze
end
