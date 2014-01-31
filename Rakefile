require "bundler/gem_tasks"

require 'rake'
require 'rake/clean'
require 'yard'
require 'yard/rake/yardoc_task'

CLEAN << Rake::FileList['doc/**', '.yardoc']
#Yard
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']   # optional
  t.options = ['--title', 'CookieJar, a HTTP Client Cookie Parsing Library',
               '--main', 'README.markdown', '--files', 'LICENSE']
end

begin
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new do |t|
    t.libs << 'lib'
    t.spec_files = FileList['test/**/*_test.rb']
  end
rescue LoadError
  puts "Warning: unable to load rspec tasks"
end
task :test => :spec

# Default Rake task is to run all tests
task :default => :test
