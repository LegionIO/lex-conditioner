require 'legion/extensions/conditioner/transport/exchanges/conditioner'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module Messages
          class Conditioner < Legion::Transport::Message
            def initialize(payload, status, options = {})
              @payload = payload
              @options = options
              @status = status
              @routing_key = "conditioner.#{status}"
              validate
            end

            def routing_key
              "conditioner.#{@status}"
            end

            def exchange
              Legion::Extensions::Conditioner::Transport::Exchanges::Conditioner
            end

            def message(payload = @payload, _options = {})
              Legion::JSON.dump(payload)
            end

            def validate(status = @status)
              raise unless valid_status.include? status

              @valid = true
            end

            def valid_status
              %w[failed succeeded]
            end
          end
        end
      end
    end
  end
end
