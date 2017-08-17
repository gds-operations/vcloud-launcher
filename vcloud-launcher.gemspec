# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vcloud/launcher/version'

Gem::Specification.new do |s|
  s.name        = 'vcloud-launcher'
  s.version     = Vcloud::Launcher::VERSION
  s.authors     = ['Anna Shipman']
  s.email       = ['anna.shipman@digital.cabinet-office.gov.uk']
  s.summary     = 'Tool to launch and configure vCloud vApps'
  s.homepage    = 'https://github.com/gds-operations/vcloud-launcher'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) {|f| File.basename(f)}
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.2.2'

  s.add_runtime_dependency 'vcloud-core', '~> 2.1.1'
  s.add_runtime_dependency 'nokogiri', '~> 1.6.8.1'
  s.add_development_dependency 'gem_publisher', '1.2.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake', '>= 12'
  s.add_development_dependency 'rspec', '>= 3.6'
  s.add_development_dependency 'rubocop', '~> 0.49.1'
  s.add_development_dependency 'simplecov', '~> 0.14.1'
  s.add_development_dependency 'vcloud-tools-tester'
end
