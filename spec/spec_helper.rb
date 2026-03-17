# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler/setup'

unless defined?(Legion::Logging)
  module Legion
    module Logging
      def self.info(*); end
      def self.debug(*); end
      def self.warn(*); end
      def self.error(*); end
    end
  end
end

$LOADED_FEATURES << 'legion/logging' unless $LOADED_FEATURES.include?('legion/logging')

unless defined?(Legion::JSON)
  module Legion
    module JSON
      def self.load(str)
        require 'json'
        ::JSON.parse(str, symbolize_names: true)
      end

      def self.dump(obj)
        require 'json'
        ::JSON.generate(obj)
      end
    end
  end
end

$LOADED_FEATURES << 'legion/json' unless $LOADED_FEATURES.include?('legion/json')

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
