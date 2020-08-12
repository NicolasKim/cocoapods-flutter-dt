require 'digest'
require 'open-uri'
require 'json'
require 'cocoapods-flutter/native/archive/archive'

module Pod
  class Podfile
    module DSL
      # require
      #   :path=>'/User/path/path' pubspec.yaml dir
      #   '0.1.0' version from binary server
      #   :mode=>'debug/release'
      #   name flutter project name
      def flutter_pod(name = nil, *requirements)
        unless name
          raise StandardError, 'A dependency requires a name.'
        end
        # {
        #     :git => {
        #         :url => '',
        #         :ref => '',
        #         :wrapper => 'flutterw'
        #     }
        # }
        flutter_project_name = name
        flutter_project_mode = parse_key(:mode, requirements)
        flutter_project_path = parse_key(:path, requirements)
        flutter_project_repo = parse_key(:git, requirements)
        flutter_project_version = parse_version requirements
        if flutter_project_mode.nil?
          flutter_project_mode = "release"
        end

        unless flutter_project_path.nil?
          UI.info "Using local flutter project..."
          load File.join(flutter_project_path, '.ios', 'Flutter', 'podhelper.rb')
          install_all_flutter_pods flutter_project_path
          return
        end

        unless flutter_project_repo.nil?
          flutter_project_repo_url =  flutter_project_repo[:url]
          flutter_project_repo_ref =  flutter_project_repo[:ref]
          flutter_command_wrapper =  flutter_project_repo[:wrapper]
          UI.info "Using git source..."
          if flutter_project_repo_ref.nil?
            flutter_project_repo_ref = 'master'
          end

          if flutter_command_wrapper.nil?
            flutter_command_wrapper = 'flutter'
          end

          flutter_application_path = Dir.pwd + + "/.flutter"

          CommandRunner.run 'git', 'clone', flutter_project_repo_url, flutter_application_path
          Dir.chdir flutter_application_path  do |dir|
            CommandRunner.run 'git', 'fetch', '--all', '-v'
            CommandRunner.run 'git', 'reset', '--hard', 'origin/master'
            CommandRunner.run 'git', 'pull'
            CommandRunner.run 'git', 'checkout', flutter_project_repo_ref
            archiver = Archiver.new(flutter_project_name,flutter_project_version,sources,flutter_command_wrapper,true ,"",true ,dir, "")
            pods = archiver.make_flutter_pods flutter_project_mode
            pods.each do |p|
              pod p.name, :path => p.path
            end
          end
          return
        end

        pod "#{flutter_project_name}_#{flutter_project_mode}", flutter_project_version

      end
      # def flutter_pod(name = nil, *requirements)
      #   if ENV['FLUTTER_BINARY_SERVER_BASEURL'].nil?
      #     raise StandardError, "Need 'FLUTTER_BINARY_SERVER_BASEURL' in env"
      #   end
      #   unless name
      #     raise StandardError, 'A dependency requires a name.'
      #   end
      #
      #   flutter_project_name = name
      #   flutter_binary_server_base_url = ENV['FLUTTER_BINARY_SERVER_BASEURL']
      #   flutter_project_mode = parse_key(:mode, requirements)
      #   flutter_sdk_version = parse_key(:sdk_version, requirements)
      #   flutter_project_path = parse_key(:path, requirements)
      #   flutter_project_version = parse_version requirements
      #   if flutter_project_mode.nil?
      #     flutter_project_mode = "release"
      #   end
      #   if flutter_sdk_version.nil?
      #     flutter_sdk_version = '1.12.13'
      #   end
      #   flutter_sdk_name = 'Flutter'
      #
      #   unless flutter_project_path.nil?
      #     UI.info "Using local flutter project.."
      #     load File.join(flutter_project_path, '.ios', 'Flutter', 'podhelper.rb')
      #     install_all_flutter_pods flutter_project_path
      #     return
      #   end
      #
      #
      #   sdk_dir = flutter_sdk_dir(flutter_sdk_version, flutter_project_mode, false)
      #   app_dir = package_dir(flutter_project_name,flutter_project_version,flutter_project_mode,false )
      #   plugin_dir = plugin_dir(flutter_project_name,flutter_project_version,false )
      #
      #   unless Dir.exist? sdk_dir
      #     sdk_download_url = make_download_url flutter_binary_server_base_url, flutter_sdk_name, flutter_sdk_version, flutter_project_mode
      #     UI.info "Downloading Flutter engine..."
      #     sdk_zip_file = "#{flutter_sdk_dir(flutter_sdk_version, flutter_project_mode, true)}/Flutter.zip"
      #     download sdk_download_url, sdk_zip_file
      #     `unzip -o #{sdk_zip_file} -d #{flutter_sdk_dir(flutter_sdk_version, flutter_project_mode, false)}`
      #     `rm -rf #{sdk_zip_file}`
      #   end
      #
      #
      #   unless Dir.exist? app_dir
      #     app_download_url = make_download_url flutter_binary_server_base_url, flutter_project_name, flutter_project_version, flutter_project_mode
      #     UI.info "Downloading App..."
      #     app_zip_file = "#{package_dir(flutter_project_name,flutter_project_version,flutter_project_mode,true )}/App.zip"
      #     download app_download_url, app_zip_file
      #     `unzip -o #{app_zip_file} -d #{package_dir(flutter_project_name,flutter_project_version,flutter_project_mode,false)}`
      #     `rm -rf #{app_zip_file}`
      #   end
      #   `cp -f -r -- #{sdk_dir}/Flutter.framework #{app_dir}`
      #
      #   unless Dir.exist? plugin_dir
      #     plugins_download_url = make_download_url flutter_binary_server_base_url, "#{flutter_project_name}_plugins", flutter_project_version, "release"
      #     UI.info "Downloading Plugins..."
      #     plugin_zip_file = "#{package_dir(flutter_project_name,flutter_project_version,flutter_project_mode,true )}/FlutterPlugin.zip"
      #     download plugins_download_url, plugin_zip_file
      #     `unzip -o #{plugin_zip_file} -d #{plugin_dir(flutter_project_name,flutter_project_version,false)}`
      #     `rm -rf #{plugin_zip_file}`
      #   end
      #
      #   json = makeFlutterSpec(
      #       'Flutter',
      #       flutter_project_name,
      #       flutter_project_version,
      #       "#{flutter_project_name}-#{flutter_project_version}",
      #       "http://dreamtracer.top",
      #       {:dreamtracer => "http://dreamtracer.top"},
      #       {:ios => '9.0'},
      #       {:path => '.' },
      #       ["Flutter.framework", "App.framework"]
      #   )
      #
      #   File.open(app_dir + '/Flutter.podspec.json', "w+") do |f|
      #     f.write json.to_s
      #     f.close
      #   end
      #   pod 'Flutter', :path =>app_dir + '/Flutter.podspec.json'
      #
      #
      #   Dir.foreach(plugin_dir) do |file|
      #     if file !="." and file !=".."
      #       pod file, :path =>plugin_dir + '/' + file
      #     end
      #   end
      #
      # end




      private

      def makeFlutterSpec(pod_name, package_name, version, desc, homepage, author, platforms, source, vendored_frameworks)
        my_hash = {:name => pod_name}
        my_hash[:version] = version
        my_hash[:summary] = package_name
        my_hash[:description] = desc
        my_hash[:homepage] = homepage
        my_hash[:authors] = author #{:author=>'example@email.com'}
        my_hash[:platforms] = platforms #{:ios => '10.0'}
        my_hash[:source] = source #{ :path => '.' }
        my_hash[:vendored_frameworks] = vendored_frameworks #[Flutter.framework, App.framework]
        json = JSON.pretty_generate my_hash
        json
      end

      def parse_key(key, requirements)
        result = nil
        requirements.each do |obj|
          if obj.is_a?(Hash) && obj.has_key?(key)
            result = obj[key]
          end
        end
        result
      end

      def parse_version(requirements)
        if requirements.first.is_a?(Hash)
          nil
        else
          requirements.first
        end
      end

      def download_sdk(sdkURL, dest)
        sdk_dir = cache_dir + "/#{md5 sdkURL}"
        sdk_file = sdk_dir + "/Flutter.zip"
        unless Dir.exist?(sdk_dir)
          Dir.mkdir sdk_dir
          download sdkURL, sdk_file
        end
        {:dir=> sdk_dir, :file => sdk_file}
      end

      def download_app(appURL)
        app_dir = cache_dir + "/#{md5 appURL}"
        app_file = app_dir + "/App.zip"
        unless Dir.exist?(app_dir)
          Dir.mkdir app_dir
          download appURL, app_file
        end
        {:dir=> app_dir, :file => app_file}
      end

      def download_plugin(pluginURL)
        plugin_dir = cache_dir + "/#{md5 pluginURL}"
        plugin_file = plugin_dir + "/FlutterPlugins.zip"
        unless Dir.exist?(plugin_dir)
          Dir.mkdir plugin_dir
          download pluginURL, plugin_file
        end
        {:dir=> plugin_dir, :file => plugin_file}
      end

      def cache_dir
        home_dir = Dir.home
        cache_dir = home_dir + "/.cocoapods/.flutter_cache"
        unless Dir.exist?(cache_dir)
          Dir.mkdir cache_dir
        end
        cache_dir
      end

      def flutter_sdk_root_dir
        sdk_dir = cache_dir + "/FlutterSDK"
        unless Dir.exist?(sdk_dir)
          Dir.mkdir sdk_dir
        end
        sdk_dir
      end

      def flutter_sdk_dir(version, tag, auto_create)
        sdk_dir = "#{flutter_sdk_root_dir}/#{version}/#{tag}"
        if auto_create
          unless Dir.exist?(sdk_dir)
            FileUtils.mkdir_p sdk_dir
          end
        end
        sdk_dir
      end

      def package_dir(name, version, tag, auto_create)
        pkg_dir = "#{cache_dir}/#{name}/#{version}/#{tag}"
        if auto_create
          unless Dir.exist?(pkg_dir)
            FileUtils.mkdir_p pkg_dir
          end
        end
        pkg_dir
      end

      def plugin_dir(name, version, auto_create)
        plugin_dir = "#{cache_dir}/#{name}/#{version}/plugins"
        if auto_create
          unless Dir.exist?(plugin_dir)
            FileUtils.mkdir_p plugin_dir
          end
        end
        plugin_dir
      end

      def make_download_url(base_url, name, version, tag)
        "#{base_url}/frameworks/#{name}/#{version}/#{tag}/zip"
      end


      def md5(url)
        Digest::MD5.hexdigest url
      end

      def download(url, dest)
        begin
          open(url) do |u|
            File.open(dest, "w+") do |file|
              file.write u.read.force_encoding("UTF-8")
              file.close
            end
          end
        rescue Exception => e
          UI.info e.to_s
        end
      end
    end
  end
end
