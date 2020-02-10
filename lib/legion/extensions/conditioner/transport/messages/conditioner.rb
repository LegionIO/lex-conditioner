module Legion::Extensions::Conditioner
  module Transport
    module Messages
      class Conditioner < Legion::Transport::Message
        def message(payload = @options, _options = {})
          Legion::JSON.dump(payload)
        end

        def validate
          @valid = true
        end

        def valid_status
          %w[failed succeeded]
        end

        def routing_key
          'task.conditioner.succeeded'
        end

        def exchange
          Legion::Transport::Exchanges::Task
        end
      end
    end
  end
end
