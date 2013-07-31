require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'

task :default do |t|
  if ENV['BUNDLE_GEMFILE'] =~ /gemfiles/
    load 'test/mark_only_test.rb'
  else
    exec 'bundle install && bundle exec rake appraise'
  end
end

task :appraise => ['appraisal:install'] do |t|
  exec 'bundle install && bundle exec rake appraisal'
end
