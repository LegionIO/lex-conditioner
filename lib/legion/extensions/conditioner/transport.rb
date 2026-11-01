# frozen_string_literal: true

require 'legion/extensions/transport'
require 'legion/extensions/conditioner/settings'
require 'legion/transport/task_protocol'

module Legion
  module Extensions
    module Conditioner
      module Transport
        extend Legion::Extensions::Transport
        extend Legion::Transport::TaskProtocol::Helper

        def self.additional_e_to_q
          transport = Legion::Settings[:extensions][:conditioner][:transport]
          [
            { from: transport[:exchange], to: transport[:binding_queue], routing_key: transport[:legacy_route] },
            { from: transport[:exchange], to: transport[:binding_queue], routing_key: task_route(name: :conditioner) }
          ]
        end
      end
    end
  end
end
