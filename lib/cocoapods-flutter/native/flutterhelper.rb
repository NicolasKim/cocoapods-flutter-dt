
def update_flutter_app_debug(path, url, ref)
    if !File.exist?(path)
       `git clone #{url} #{path}`
       `cd #{path} && git fetch --all -v && \
       git reset --hard origin/master && \
       git pull && \
       git checkout #{ref} && \
       cd #{path} && \
       sh build_ios.sh -m release`
    end
    puts "Flutter project is already existed, remove '.flutter' folder and `pod install` again the flutter project will be rebuilded with new code."
end

def install_debug_flutter_app(url, ref)

    puts "Compiling☕️️️️️☕️☕️\n"

    flutter_application_path = __dir__ + "/.flutter"
    flutter_application_url = ""
    flutter_application_branch = 'master'

    if url != nil
        flutter_application_url = url
        if ref != nil
            flutter_application_branch = ref
        end
    else
        raise "Error: 请在'Podfile'里增加Flutter App git地址配置，配置格式请查看'flutterhelper.rb'文件"
    end

    update_flutter_app_debug(flutter_application_path, flutter_application_url, flutter_application_branch)

    if $?.to_i == 0

        flutter_package_path = "#{flutter_application_path}/.build_ios/product"
        # 开始安装
        install_release_flutter_app_pod(flutter_package_path)
    else
        raise "Error: 编译 Flutter App失败"
    end
end
