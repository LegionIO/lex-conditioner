# frozen_string_literal: true

require_relative 'lib/legion/extensions/conditioner/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-conditioner'
  spec.version       = Legion::Extensions::Conditioner::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Conditional rule engine for LegionIO task chains'
  spec.description   = 'Evaluates JSON-based rules against task payloads with 18+ operators, structured explanations, and standalone client support'
  spec.homepage      = 'https://github.com/LegionIO/lex-conditioner'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-conditioner'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-conditioner'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-conditioner/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-conditioner/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
end
