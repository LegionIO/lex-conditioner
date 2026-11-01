# frozen_string_literal: true

require 'legion/extensions/conditioner/settings'
require 'legion/transport/exchanges/task'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Exchanges
          class Task < Legion::Transport::Exchanges::Task
            def exchange_name
              Legion::Settings[:extensions][:conditioner][:transport][:exchange]
            end
          end
        end
      end
    end
  end
end
