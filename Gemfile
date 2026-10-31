# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

dependency_root = File.directory?(File.join(__dir__, '.ci-dependencies')) ? File.join(__dir__, '.ci-dependencies') : File.expand_path('..', __dir__)
%w[legion-settings legion-transport].each do |name|
  path = File.join(dependency_root, name)
  gem name, path: path if File.file?(File.join(path, "#{name}.gemspec"))
end

group :test do
  gem 'rake'
  gem 'rspec', '~> 3.13'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '~> 1.75'
  gem 'rubocop-legion', '~> 0.1', require: false
  gem 'rubocop-rspec'
  gem 'simplecov'
end
