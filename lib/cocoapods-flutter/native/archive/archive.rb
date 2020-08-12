require 'cocoapods-flutter/native/archive/command_runner'
require 'cocoapods'
require 'zip'
require 'cocoapods-flutter/native/archive/zip_tool'
require 'cocoapods-flutter/native/archive/remote'
require 'molinillo'

class Archiver

  class Plugins
    attr_reader :spec
    attr_reader :path
    attr_reader :name
    def initialize(name, path, spec)
      @name = name
      @path = path
      @spec = spec
    end
  end

  class Dependency < Hash
    attr_reader :name
    attr_reader :version
    def initialize(name, version)
      @name = name
      @version = version
    end
    def to_hash()
      {:name => name, :version => version}
    end
  end

  public

  def initialize(module_name, version, sources, flutter_wrapper, pub_upgrade, flutter_version, build_run, working_dir, repo)
    @module_name = module_name
    @version = version
    @sources = sources
    @flutter_wrapper = flutter_wrapper
    @pub_upgrade = pub_upgrade
    @flutter_version = flutter_version
    @build_run = build_run
    @working_dir = working_dir
    @product_dir = "#{@working_dir}/.product/"
    @pod_repo = repo
  end

  def archive

    @pub_upgrade ? pub_upgrade : pub_get
    setup_pod_sources
    if @build_run
      excute_build_run
    end
    build_framework
    @plugins = fetch_plugins
    debug
    release
    Pod::UserInterface.message "All is ready to use!, now you can use 'flutter_pod '#{@module_name}', '#{@version}', :mode=>'debug/release' to use the pod"
  end

  def make_flutter_pods(mode)
    @pub_upgrade ? pub_upgrade : pub_get
    setup_pod_sources
    if @build_run
      excute_build_run
    end

    build_app mode

    flutter_spec_dir = @product_dir + 'Flutter'
    flutter_spec_file = flutter_spec_dir + '/Flutter.podspec.json'
    flutter_spec = Pod::Spec.from_file @working_dir + '/.ios/Flutter/engine/Flutter.podspec'
    flutter_spec.vendored_frameworks = ['Flutter.framework', 'App.framework']
    plugin_registrant_spec_file = @working_dir + '/.ios/Flutter/FlutterPluginRegistrant/FlutterPluginRegistrant.podspec'

    unless Dir.exist? flutter_spec_dir
      FileUtils.mkdir_p flutter_spec_dir
    end

    File.open flutter_spec_file, "w+" do |file|
      file.write flutter_spec.to_pretty_json
    end

    FileUtils.cp_r @working_dir + '/.ios/Flutter/engine/Flutter.framework', flutter_spec_dir
    FileUtils.cp_r @working_dir + '/.ios/Flutter/App.framework', flutter_spec_dir

    plugins = fetch_plugins
    plugins.append Plugins.new('Flutter',flutter_spec_file,flutter_spec)
    plugins.append Plugins.new('FlutterPluginRegistrant',plugin_registrant_spec_file, Pod::Spec.from_file(plugin_registrant_spec_file))

    plugins
  end

  private

  def release
    app_file, sdk_file = zip_files @plugins, 'Release'
    upload_files app_file, sdk_file, 'Release'
    make_pod 'Release'
  end

  def debug
    app_file, sdk_file = zip_files @plugins, 'Debug'
    upload_files app_file, sdk_file, 'Debug'
    make_pod 'Debug'
  end

  def pub_upgrade
    if CommandRunner.run(@flutter_wrapper, 'pub', 'upgrade') == false
      raise "Pub upgrade fail"
    end
  end

  def pub_get
    if CommandRunner.run(@flutter_wrapper, 'pub', 'get') == false
      raise "Pub get fail"
    end
  end

  def setup_pod_sources
    Pod::UserInterface.info 'Setup pod sources...'
    origin_pod_file_root_dir = @working_dir + '/.ios'
    origin_pod_file_dir = origin_pod_file_root_dir+ '/Podfile'
    temp_pod_file_dir_1 = @working_dir + '/tmp1.txt'
    temp_pod_file_dir_2 = @working_dir + '/tmp2.txt'
    if File.exist? temp_pod_file_dir_1
      FileUtils.remove_file temp_pod_file_dir_1
    end
    if File.exist? temp_pod_file_dir_2
      FileUtils.remove_file temp_pod_file_dir_2
    end

    # origin_pod_file = File.open origin_pod_file_dir
    temp_pod_file_1 = File.open temp_pod_file_dir_1, "w+"
    temp_pod_file_2 = File.open temp_pod_file_dir_2, "w+"

    @sources.each do |s|
      temp_pod_file_2.puts "source '#{s}'"
    end

    lines = IO.readlines(origin_pod_file_dir)

    lines.each do |line|
      if line =~ /platform\s+:ios\s*,\s*'\s*[0-9]*.[0-9]*\s*'/
        temp_pod_file_1.puts "platform :ios, '9.0'"
      elsif line =~ /source\s+/
        Pod::UserInterface.message 'Ignore ' + line
      else
        temp_pod_file_1.puts line
      end
    end

    temp_pod_file_1.close

    lines = IO.readlines(temp_pod_file_1)
    lines.each do |line|
      temp_pod_file_2.puts line
    end
    temp_pod_file_2.close

    File.open origin_pod_file_dir, "w+" do |file|
      file.write IO.readlines(temp_pod_file_2).join('')
      file.close
    end

  end

  def excute_build_run
    if CommandRunner.run(@flutter_wrapper, 'packages','pub','run','build_runner','build','--delete-conflicting-outputs') == false
      raise "run build_runner fail"
    end
  end

  def build_framework
    if CommandRunner.run(@flutter_wrapper, 'build','ios-framework',"--output=#{@product_dir}") == false
      # FileUtils.remove_dir product_dir, true
      raise "run build_runner fail"
    end
  end

  def build_app(mode)
    if CommandRunner.run(@flutter_wrapper, 'build','ios',"--#{mode}" ,"--no-codesign") == false
      # FileUtils.remove_dir product_dir, true
      raise "run build_runner fail"
    end
  end

  def fetch_plugins
    results = []
    flutter_plugins_list = @working_dir + '/.flutter-plugins'
    lines = IO.readlines(flutter_plugins_list)
    lines.each do |line|
      unless line =~ /^#/
        key_val = line.split '='
        key = key_val[0]
        value = key_val[1]
        value = value.gsub /\n/, ''
        path = "#{value}ios/#{key}.podspec"
        results.append Plugins.new(key, path, Pod::Specification.from_file(path))
      end
    end
    results
  end

  def zip_files(plugins, mode)
    product_dir = @product_dir + "#{mode}"
    zip_file_dir = product_dir + "/zip"
    if Dir.exist? zip_file_dir
      FileUtils.remove_dir zip_file_dir, true
    end
    FileUtils.mkdir_p zip_file_dir
    zip_file = zip_file_dir + "/#{@module_name}.zip"
    Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
      stdin, stdout, stderr, wait_thr = Open3.popen3('git', 'rev-parse', 'HEAD')
      commit = stdout.gets.gsub /\n/, ''
      info_hash = {
          :name => @module_name,
          :commit => commit,
          :version => @version,
          :sdk_version => @flutter_version
      }
      json = JSON.pretty_generate info_hash
      zipfile.get_output_stream("info.json") { |f| f.write json }
      zipfile.add 'pubspec.lock', "#{@working_dir}/pubspec.lock"
      zipfile.get_output_stream("download_sdk.rb") { |f| f.write sdk_download }
      zipfile.add_dir "App.framework", "#{product_dir}/App.framework"
      zipfile.add_dir "FlutterPluginRegistrant.framework","#{product_dir}/FlutterPluginRegistrant.framework"
      plugins.each do |plugin|
        file = File.join(product_dir, "#{plugin.spec.name}.framework")
        if Dir.exist? file
          zipfile.add_dir("#{plugin.spec.name}.framework", file)
        end
      end
    end

    sdk_file = zip_file_dir + "/Flutter.zip"
    Zip::File.open sdk_file, Zip::File::CREATE do |zipfile|
      file = File.join(product_dir, "Flutter.framework")
      zipfile.add_dir "Flutter.framework", file
    end
    [zip_file, sdk_file]
  end

  def sdk_download

    ruby_code = <<-CODE
#!/usr/bin/env ruby

require 'digest'
require 'open-uri'

sdk_url = ARGV[0]

def md5(url)
  Digest::MD5.hexdigest url
end
def download(url, dest)
  open(url) do |u|
    File.open(dest, "w+") do |file|
      file.write u.read
    end
  end
end
home_dir = Dir.home
cache_dir = home_dir + "/.cocoapods/.cache"
if Dir.exist?(cache_dir) == false
  Dir.mkdir cache_dir
end
#SDK下载
sdk_dir = cache_dir + "/\#{md5 sdk_url}"
sdk_file = sdk_dir + "/Flutter.zip"
if Dir.exist?(sdk_dir) == false
  Dir.mkdir sdk_dir
  download sdk_url, sdk_file
end
if File.exist? "Flutter.framework"
  `rm -rf Flutter.framework`
end
`unzip \#{sdk_file} -d \#{Dir.pwd}`
    CODE

    ruby_code

  end

  def upload_files(app_file, flutter_sdk, mode)
    Pod::UserInterface.info 'Start upload resources'
    remote = Remote.new()
    Pod::UserInterface.info "Checking #{@module_name}_#{@version}_#{mode.downcase}..."
    result = remote.exist? @module_name, @version, mode.downcase
    if result
      Pod::UserInterface.info "Found #{@module_name}_#{@version}_#{mode.downcase} and deleting..."
      remote.delete @module_name, @version, mode.downcase
    end
    Pod::UserInterface.info "Uploading #{@module_name}_#{@version}_#{mode.downcase}..."
    remote.upload @module_name, @version, mode.downcase, app_file


    Pod::UserInterface.info "Checking Flutter_#{@flutter_version}_#{mode.downcase}..."
    result = remote.exist? 'Flutter', @flutter_version, mode.downcase
    unless result
      Pod::UserInterface.info "No Flutter_#{@flutter_version}_#{mode.downcase} found, start uploading..."
      remote.upload 'Flutter', @flutter_version, mode.downcase, flutter_sdk
    end
    if result
      Pod::UserInterface.info "Flutter_#{@flutter_version}_#{mode.downcase} was found, skip upload"
    end

  end

  def ignore_dependency?(name)
    if name == 'Flutter'
      return true
    end

    for plugin in @plugins
      if plugin.name == name
        return true
      end
    end
    return false
  end

  def make_pod(mode)

    dependency_graph = Molinillo::DependencyGraph.new
    @plugins.each do |plugin|
      plugin.spec.all_dependencies.each do |dep|
        unless ignore_dependency? dep.name
          dependency_graph.add_vertex(dep.name, dep, true)
        end
      end
    end

    remote = Remote.new()
    sdk_download_url = remote.download_url "Flutter", @flutter_version, mode.downcase
    app_download_url = remote.download_url @module_name, @version, mode.downcase
    spec = Pod::Spec.new do |s|
      s.swift_version         = '5.0'
      s.name                  = "#{@module_name}_#{mode.downcase}"
      s.version               = @version
      s.summary               = @module_name
      s.description           = @module_name
      s.homepage              = 'http://dreamtracer.top'
      s.license               = { :type => 'BSD' }
      s.author                = { 'Dreamtracer' => 'http://dreamtracer.top' }
      s.source                = { :http => app_download_url }
      s.ios.deployment_target = '9.0'
      s.prepare_command = "ruby download_sdk.rb #{sdk_download_url}"
      vendored_frameworks = ["App.framework", "Flutter.framework", "FlutterPluginRegistrant.framework"]
      @plugins.each do |plugin|
        vendored_frameworks.append "#{plugin.name}.framework"
      end
      s.vendored_frameworks   = vendored_frameworks

      dependency_graph.each do |vertex|
        s.dependency vertex.payload.name, vertex.payload.requirement.to_s
      end
      s.resources = ['info.json', 'pubspec.lock']
    end
    temp_dir = Dir.tmpdir
    spec_file = temp_dir + "/#{@module_name}_#{mode.downcase}.podspec.json"
    File.open spec_file, "w+" do |file|
      file.write spec.to_pretty_json
    end

    Dir.chdir temp_dir do |dir|
      Pod::Command::Repo::Push.run([@pod_repo, '--allow-warnings', "--sources=#{@sources.join(',')}"])
    end

  end

end

