# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gradient2base64/version'

Gem::Specification.new do |spec|
  spec.name          = "compass-gradient2base64"
  spec.version       = Gradient2base64::VERSION
  spec.authors       = ["Alexander Pinchuk"]
  spec.email         = ["front.end.developing@gmail.com"]
  spec.description   = "Sass/Compass extension to convert css3 gradient to base64"
  spec.summary       = "Convert css3 gradient to base64 hash"
  spec.homepage      = "https://github.com/frontenddeveloping/compass-gradient2base64"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sass"
  spec.add_development_dependency "compass"
  spec.add_development_dependency "rmagick"
  spec.add_development_dependency "tinypng"
end