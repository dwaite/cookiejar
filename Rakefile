require 'rake'

require 'rake/clean'
require 'rake/packagetask'
require 'yard'
require 'yard/rake/yardoc_task'

require 'fileutils'
include FileUtils

# Default Rake task is to run all tests
task :default => :test
CLEAN << Rake::FileList['doc/**', '.yardoc']
#Yard
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']   # optional
  t.options = ['--title', 'CookieJar, a HTTP Client Cookie Parsing Library',
               '--main', 'README.markdown', '--files', 'LICENSE']
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |t|
#    t.libs << 'lib'
#    t.pattern = 'test/**/*_test.rb'
  end
  task :test => :spec
rescue LoadError
  puts "Warning: unable to load rspec tasks"
end
