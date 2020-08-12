# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-flutter/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-flutter-dt'
  spec.version       = CocoapodsFlutter::VERSION
  spec.authors       = ['Dreamtracer']
  spec.email         = ['jinqiucheng1006@live.cn']
  spec.description   = %q{Flutter archive tool}
  spec.summary       = %q{Simple way to archive and use}
  spec.homepage      = 'https://github.com/NicolasKim/cocoapods-flutter-dt.git'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'parallel'
  spec.add_dependency 'cocoapods', '~> 1.4'
  spec.add_dependency 'rubyzip', '>= 1.0.0'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'molinillo',  '~> 0.6.6'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
