# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'legion/extensions/conditioner/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-conditioner'
  spec.version       = Legion::Extensions::Conditioner::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX-Conditioner is used to apply conditional statements to tasks'
  spec.description   = 'Runs relationship conditional statements against tasks in a relationship'
  spec.homepage      = 'https://github.com/LegionIO/lex-conditioner'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-conditioner'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-conditioner'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-conditioner'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-conditioner/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'legionio'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'

  spec.add_dependency 'legion-exceptions'
end
