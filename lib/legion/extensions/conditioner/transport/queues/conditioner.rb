# frozen_string_literal: true

require 'legion/extensions/conditioner/settings'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Queues
          class Conditioner < Legion::Transport::Queue
            include Legion::Settings::Helper

            def queue_name
              settings[:transport][:queue]
            end
          end
        end
      end
    end
  end
end
