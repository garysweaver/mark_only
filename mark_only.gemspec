# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "mark_only/version" 

Gem::Specification.new do |s|
  s.name        = 'mark_only'
  s.version     = MarkOnly::VERSION
  s.authors     = ['Gary S. Weaver']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/garysweaver/mark_only'
  s.summary     = "A fork of Paranoia (by Ryan Bigg and others) that updates a specified column with an pre-configured value on delete/destroy."
  s.description = "A fork of Paranoia (by Ryan Bigg and others) that updates a specified column with an pre-configured value on destroy, and does no scoping. Supports destroy hooks."
  s.required_rubygems_version = ">= 1.3.6"
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  s.add_runtime_dependency 'activerecord', '>= 3.0.0'
  s.add_development_dependency "activerecord", ">= 3.0.0"
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rake", "0.8.7"
end
