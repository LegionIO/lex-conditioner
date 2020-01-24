module Legion
  module Extensions
    module Conditioner
      module Transport
        module Exchanges
          class Conditioner < Legion::Transport::Exchange
            def exchange_name
              'conditioner'
            end
          end
        end
      end
    end
  end
end
