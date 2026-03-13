# frozen_string_literal: true

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Messages
          class Conditioner < Legion::Transport::Message
            def routing_key
              'task.conditioner.succeeded'
            end

            def exchange
              Legion::Transport::Exchanges::Task
            end
          end
        end
      end
    end
  end
end
