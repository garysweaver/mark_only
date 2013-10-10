# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "mark_only/version" 

Gem::Specification.new do |s|
  s.name        = 'mark_only'
  s.version     = MarkOnly::VERSION
  s.authors     = ['Gary S. Weaver']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/FineLinePrototyping/mark_only'
  s.summary     = "Updates a specified column with an pre-configured value on delete/destroy."
  s.description = "Updates a specified column with an pre-configured value on delete/destroy. Supports destroy hooks."
  s.required_rubygems_version = ">= 1.3.6"
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  s.add_runtime_dependency 'activerecord', '>= 3.1', '< 5'
  s.add_runtime_dependency 'activesupport', '>= 3.1', '< 5'
end
