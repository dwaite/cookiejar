require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'fileutils'
require 'spec/rake/spectask'
include FileUtils

# Default Rake task is to run all tests
task :default => :test

# RDoc
Rake::RDocTask.new(:rdoc) do |task|
  task.rdoc_dir = 'doc'
  task.title    = 'CookieJar'
  task.options = %w(--title CookieJar --main README --line-numbers)
  task.rdoc_files.include(['lib/**/*.rb'])
  task.rdoc_files.include(['README', 'LICENSE'])
end

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.spec_files = FileList['test/**/*_test.rb']
end

task :test => :spec
