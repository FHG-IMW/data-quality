# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'data_quality/version'

Gem::Specification.new do |gem|
  gem.name          = "data_quality"
  gem.version       = DataQuality::VERSION
  gem.authors       = ["Max Kießling"]
  gem.email         = ["max.kiessling@moez.fraunhofer.de"]
  gem.description   = %q{Test the data quality}
  gem.summary       = %q{Test the quality of your data}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activerecord"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "simplecov"
end
