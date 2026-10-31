# frozen_string_literal: true

require 'legion/extensions/transport'
require 'legion/extensions/conditioner/settings'
require 'legion/settings/task_execution'

module Legion
  module Extensions
    module Conditioner
      module Transport
        extend Legion::Extensions::Transport
        extend Legion::Settings::Helper
        extend Legion::Settings::TaskExecution::Helper

        def self.additional_e_to_q
          [
            { from: settings[:transport][:exchange], to: settings[:transport][:binding_queue], routing_key: settings[:transport][:legacy_route] },
            { from: settings[:transport][:exchange], to: settings[:transport][:binding_queue], routing_key: task_route(name: :conditioner) }
          ]
        end
      end
    end
  end
end
