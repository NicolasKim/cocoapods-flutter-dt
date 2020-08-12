require 'cocoapods-flutter/native/archive/archive'

module Pod
  class Command
    class Flutter < Command
      class Archive < Flutter
        self.summary = 'archive flutter'
        self.description = <<-DESC
            发布二进制组件 / 源码组件
        DESC

        self.arguments = [
            CLAide::Argument.new([''], false)
        ]

        def self.options
          [
              ['--repo', 'podspec repo'],
              ['--sources', 'podspec sources'],
              ['--upgrade', 'pub upgrade'],
              ['--wrapper', 'Default is flutter'],
              ['--flutterversion', 'FlutterSDK version'],
              ['--buildrun', 'run build-runner']
          ].concat(Pod::Command::Repo::Push.options).concat(super).uniq
        end

        def initialize(argv)
          @module_name = argv.shift_argument
          @version = argv.shift_argument
          @pod_repo = argv.option('repo', 'master')
          @sources = argv.option('sources', 'https://github.com/CocoaPods/Specs.git').split(',')
          @flutter_wrapper = argv.option('wrapper', 'flutter')
          @pub_upgrade = argv.flag?('upgrade', true)
          @flutter_version = argv.option('flutterversion', '1.12.13')
          @build_run = argv.flag?('buildrun', true)
          @working_dir = Dir.pwd
          super
        end

        def run
          archiver = Archiver.new(@module_name, @version, @sources, @flutter_wrapper, @pub_upgrade, @flutter_version, @build_run, @working_dir,@pod_repo)
          archiver.archive
        end

      end
    end
  end
end


