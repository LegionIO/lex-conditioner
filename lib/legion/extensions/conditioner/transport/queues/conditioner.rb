# frozen_string_literal: true

require 'legion/extensions/conditioner/settings'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Queues
          class Conditioner < Legion::Transport::Queue
            def queue_name
              Legion::Settings[:extensions][:conditioner][:transport][:queue]
            end
          end
        end
      end
    end
  end
end
