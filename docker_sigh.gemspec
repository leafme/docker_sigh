# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker_sigh/version'

Gem::Specification.new do |spec|
  spec.name          = "docker_sigh"
  spec.version       = DockerSigh::VERSION
  spec.authors       = ["Ed Ropple"]
  spec.email         = ["ed+dockersigh@edropple.com"]

  spec.summary       = %q{A set of helper Rake tasks to make dealing with Docker a little less horrible.}
  spec.homepage      = "https://github.com/eropple/docker_sigh"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"

  spec.add_runtime_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency 'erber', '~> 0.1.1'
end
