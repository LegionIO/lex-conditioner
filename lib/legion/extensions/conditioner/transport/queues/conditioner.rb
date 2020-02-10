module Legion::Extensions::Conditioner
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
