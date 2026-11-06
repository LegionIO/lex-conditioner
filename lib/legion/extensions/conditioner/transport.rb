# frozen_string_literal: true

require 'legion/extensions/transport'
require 'legion/transport/task/protocol'

module Legion
  module Extensions
    module Conditioner
      module Transport
        extend Legion::Extensions::Transport
        extend Legion::Transport::Task::Protocol::Helper

        def self.additional_e_to_q
          [
            { from: 'task', to: 'conditioner', routing_key: 'task.subtask' },
            { from: 'task', to: 'conditioner', routing_key: task_route(name: :conditioner) }
          ]
        end
      end
    end
  end
end
