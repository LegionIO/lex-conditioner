# frozen_string_literal: true

require 'legion/extensions/conditioner/settings'
require 'legion/extensions/conditioner/transport/exchanges/task'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Messages
          class Conditioner < Legion::Transport::Message
            include Legion::Settings::Helper

            def routing_key
              settings[:transport][:success_route]
            end

            def exchange
              Legion::Extensions::Conditioner::Transport::Exchanges::Task
            end
          end
        end
      end
    end
  end
end
