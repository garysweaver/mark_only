require 'bundler'
Bundler::GemHelper.install_tasks

task :test do
  load 'test/mark_only_test.rb'
  #Dir['test/*_test.rb'].each do |testfile|
  #  load testfile
  #end
end

task :default => :test
