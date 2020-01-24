module Legion
  module Extensions
    module Conditioner
      module Transport
        module Queues
          class Conditioner < Legion::Transport::Queue
            def queue_name
              'conditioner'
            end
          end
        end
      end
    end
  end
end
