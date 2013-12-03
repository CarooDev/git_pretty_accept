# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_pretty_accept/version'

Gem::Specification.new do |spec|
  spec.name          = "git_pretty_accept"
  spec.version       = GitPrettyAccept::VERSION
  spec.authors       = ["George Mendoza"]
  spec.email         = ["gsmendoza@gmail.com"]
  spec.description   = %q{
    `git-pretty-accept` is a script that rebases a pull request before
    merging to master. Pull requests are _always_ merged recursively. The
    result is a linear history with merge bubbles indicating pull requests.
    In short, pretty.
  }.gsub(/\s+/, ' ')

  spec.summary       = %q{Accept pull requests, the pretty way}
  spec.homepage      = "https://github.com/gsmendoza/git_pretty_accept"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'git'
  spec.add_dependency 'methadone', '~> 1.3.1'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-example_steps'
end
