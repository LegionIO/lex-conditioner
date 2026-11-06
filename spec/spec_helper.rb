# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'legion/logging'
require 'legion/settings'
require 'legion/json'
require 'legion/transport'
require 'legion/extensions/conditioner'

Legion::Logging.setup(level: 'fatal')

module Legion
  module Extensions
    module Helpers
      module Task; end

      module Lex
        include Legion::Logging::Helper
        include Legion::Settings::Helper
        include Legion::JSON::Helper
        include Legion::Extensions::Helpers::Task
      end
    end
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.before do
    Legion::Settings[:extensions][:conditioner] = Legion::Extensions::Conditioner.default_settings
  end
end
