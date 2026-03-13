# frozen_string_literal: true

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Queues
          class Conditioner < Legion::Transport::Queue
            def queue_name
              'task.conditioner'
            end
          end
        end
      end
    end
  end
end
