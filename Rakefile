require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |g|
    g.name = 'scrubby'
    g.summary = %(Clean up your incoming ActiveRecord model attributes)
    g.description = %(Clean up your incoming ActiveRecord model attributes)
    g.email = 'steve.richert@gmail.com'
    g.homepage = 'http://github.com/laserlemon/scrubby'
    g.authors = ['Steve Richert']
    g.add_dependency 'activerecord'
    g.add_development_dependency 'shoulda'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.pattern = 'test/**/test_*.rb'
    t.verbose = true
  end
rescue LoadError
  task :rcov do
    abort 'RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov'
  end
end

task :test => :check_dependencies

task :default => :test

Rake::RDocTask.new do |r|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''

  r.rdoc_dir = 'rdoc'
  r.title = "scrubby #{version}"
  r.rdoc_files.include('README*')
  r.rdoc_files.include('lib/**/*.rb')
end
