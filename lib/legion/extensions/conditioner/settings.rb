# frozen_string_literal: true

require 'legion/settings'

module Legion
  module Extensions
    module Conditioner
      def self.default_settings
        {
          allowed_operators:   %w[equal not_equal greater_than less_than greater_or_equal less_or_equal between contains
                                  starts_with ends_with matches in_set not_in_set size_equal nil not_nil is_false is_true
                                  is_string is_array is_integer empty not_empty].to_h { |name| [name.to_sym, true] },
          consent_tiers:       %w[tier1 tier2 tier3],
          default_domain:      'default',
          unclassified_domain: 'unclassified',
          resolutions:         { primary: 'primary', secondary: 'secondary', none: 'none' },
          transport:           { exchange: 'task', queue: 'task.conditioner', binding_queue: 'conditioner',
                       legacy_route: 'task.subtask', success_route: 'task.conditioner.succeeded' }
        }
      end
    end
  end
end

Legion::Settings.merge_settings(:extensions, conditioner: Legion::Extensions::Conditioner.default_settings)
