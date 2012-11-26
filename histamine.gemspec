# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless ($LOAD_PATH.include?(lib))
require('histamine/version')

Gem::Specification.new do |gem|
  gem.name		= 'histamine'
  gem.version		= Histamine::VERSION
  gem.authors		= ['Ken Coar']
  gem.email		= ['The.Rodent.of.Unusual.Size@GMail.Com']
  gem.description	= %q{}
  gem.summary		= %q{Web app for storing/recalling/managing your bash history}
  gem.homepage		= ''
  gem.rubyforge_project	= 'histamine'
  gem.add_dependency('versionomy')
  gem.add_development_dependency('cucumber')
  gem.add_development_dependency('redcarpet')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('yard')
  gem.add_development_dependency('test-unit', [ '>= 2.3' ])
  gem.files		= `git ls-files`.split($/)
  gem.executables	= gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files	= gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths	= [ 'lib' ]
end
