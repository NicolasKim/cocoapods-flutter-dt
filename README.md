# cocoapods-flutter

Cocoapods plugin for integration Flutter easily.

## Installation

**Precondition**

Before you use `cocoapods-flutter`, make sure binary server is ready. I provide you a simple binary server. Click link below and redirect to another repository.

[BinaryServer](https://github.com/NicolasKim/binary_server.git)


**Gem install**

```
$ gem install cocoapods-flutter-dt
```
Or download source code build gem on your own
```
$ gem install cocoapods-flutter-dt.gem
```

**Config environment**
```
$ export FLUTTER_BINARY_SERVER_BASEURL=https://www.example.com
```
Here is simple [binary server](https://github.com/NicolasKim/binary_server.git)


## Usage


### Archive

```shell script
$ cd flutter project
$ pod flutter archive package_name 0.0.1 --repo=cocoapods --wrapper=flutterw --sources=https://github.com/private_spec_repo.git,https://github.com/Cocoapods/Specs.git
```


There is more options
```shell script
$ pod flutter archive --help
--repo                                 podspec repo
--sources                              podspec sources
--upgrade                              pub upgrade
--wrapper                              Default is flutter
--flutterversion                       FlutterSDK version
--buildrun                             run build-runner
```
 

### Use

In Podfile
```
plugin 'cocoapods-flutter-dt'
```


#### Case 1
Use binary of flutter, In this case, tool will download code from binary server.
```ruby
flutter_pod 'package_name', '0.0.1', :mode=>'debug/release'
```

#### Case 2
Use local flutter project, compile dart code every time when you build native code
```ruby
flutter_pod 'package_name', '0.0.1',:mode=>'debug/release', :path=>'local path of pubspec file'
```


#### Case 3
Pull flutter project from git repository. In this case, the tool will pull the flutter project into native project root directory and create framework when you pod install or update
```ruby
flutter_pod 'package_name', '0.0.1', :mode=>'debug/release', :git=>{

:url=>'http://github.com/flutter/package_name.git',

:ref=>'master',

:wrapper => 'flutterw'

}
```

and `pod install`