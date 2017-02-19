# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'peek-mongo/version'

Gem::Specification.new do |gem|
  gem.name          = 'peek-mongo'
  gem.version       = Peek::Mongo::VERSION
  gem.authors       = ['Garrett Bjerkhoel']
  gem.email         = ['me@garrettbjerkhoel.com']
  gem.description   = %q{Take a peek into the Mongo commands made within your Rails application.}
  gem.summary       = %q{Take a peek into the Mongo commands made within your Rails application.}
  gem.homepage      = 'https://github.com/peek/peek-mongo'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'peek'
  gem.add_dependency 'mongo', '>= 2.4.1'
  gem.add_dependency 'concurrent-ruby', '>= 1.0.4'
end
