lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'legion/extensions/conditioner/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-conditioner'
  spec.version       = Legion::Extensions::Conditioner::VERSION
  spec.authors       = ['Miverson']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX-Conditioner is used to apply conditional statements to tasks'
  spec.description   = 'Runs relationship conditional statements against tasks in a relationship'
  spec.homepage      = 'https://bitbucket.org/legion-io/lex-conditioner'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://bitbucket.org/legion-io/lex-conditioner'
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  end

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'legion-exceptions'
  spec.add_dependency 'legion-extensions'
end
