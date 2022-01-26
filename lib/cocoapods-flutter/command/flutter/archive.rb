require 'cocoapods-flutter/native/archive/archive'

module Pod
  class Command
    class Flutter < Command
      class Archive < Flutter
        self.summary = 'foryou flutter'
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
              ['--buildrun', 'run build-runner'],
              ['--debug', 'debug mode'],
              ['--release', 'release mode'],
          ].concat(Pod::Command::Repo::Push.options).concat(super).uniq
        end

        def initialize(argv)
          @module_name = argv.shift_argument
          tmp_version = argv.shift_argument
          #如果满足
          if tmp_version =~ /([0-9]+\.)+[0-9]+/
            @version = tmp_version
          else
            tmp_str = tmp_version.dup
            last_v = "0"
            mid_v = "0"
            main_v = "0"
            unless tmp_str.empty?
              last_v = tmp_str.slice!(tmp_str.length - 1, 1)
            end
            unless tmp_str.empty?
              mid_v = tmp_str.slice!(tmp_str.length - 1, 1)
            end
            unless tmp_str.empty?
              main_v = tmp_str
            end

            versions = Array.new
            versions << main_v
            versions << mid_v
            versions << last_v
            @version = versions.join "."
          end


          @build_modes = []
          @pod_repo = argv.option('repo', 'master')
          @sources = argv.option('sources', 'https://github.com/CocoaPods/Specs.git').split(',')
          @flutter_wrapper = argv.option('wrapper', 'flutter')
          @pub_upgrade = argv.flag?('upgrade', true)
          @flutter_version = argv.option('flutterversion', default_fluttter_version)
          @build_run = argv.flag?('buildrun', true)
          @working_dir = Dir.pwd

          if argv.flag?('debug', true)
            @build_modes.append 'debug'
          end
          if argv.flag?('release', true)
            @build_modes.append 'release'
          end

          super
        end

        def run
          archiver = Archiver.new(@module_name, @version, @sources, @flutter_wrapper, @pub_upgrade, @flutter_version, @build_run, @working_dir,@pod_repo, @build_modes)
          archiver.archive
        end

        def default_fluttter_version
          flutter_version = ''
          stdin, stdout_stderr, wait_thr = Open3.popen2e(@flutter_wrapper, '--version');
          stdout_stderr.each_line do |line|
            if line.start_with?('Flutter ')
              flutter_version = line.split(' • ').first.split(' ').last
            end
          end
          exit_status = wait_thr.value
          if exit_status.success?
            puts stdout_stderr.gets
          else
            raise stdout_stderr.gets
          end
          stdout_stderr.close
          stdin.close
          flutter_version
        end
      end
    end
  end
end


