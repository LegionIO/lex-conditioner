# frozen_string_literal: true

require 'legion/extensions/conditioner/settings'
require 'legion/transport/exchanges/task'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Exchanges
          class Task < Legion::Transport::Exchanges::Task
            include Legion::Settings::Helper

            def exchange_name
              settings[:transport][:exchange]
            end
          end
        end
      end
    end
  end
end
