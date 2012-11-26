require('rubygems')

require('rake')
include Rake::DSL

require('bundler')
require('bundler/gem_tasks')
Bundler::GemHelper.install_tasks
begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts(e.message)
  $stderr.puts('Run "bundle install" to install missing gems')
  exit(e.status_code)
end

require('rake/testtask')

require('yard')
YARD::Rake::YardocTask.new

require('cucumber/rake/task')

desc('Run all tests')
task(:test => [ 'test:units', 'test:cucumber' ])

namespace(:test) do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/units/**/test_*.rb'
    test.verbose = true
  end

end

Cucumber::Rake::Task.new('test:cucumber')

task(:cleanup_rcov_files) do
  rm_rf('coverage.data')
end

namespace('test:cucumber') do
  desc('Run cucumber features using rcov')
  Cucumber::Rake::Task.new(:rcov => [ :cleanup_rcov_files ]) do |t|
    t.cucumber_opts = %w{--format progress}
    t.rcov = true
    t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
    t.rcov_opts << %[--text-report --sort coverage --aggregate coverage.data]
  end
end
