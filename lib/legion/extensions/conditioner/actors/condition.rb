module Legion
  module Extensions
    module Conditioner
      module Actor
        class Condition < Legion::Extensions::Actors::Subscription
          def queue
            Legion::Extensions::Conditioner::Transport::Queues::Conditioner
          end

          def class_path
            'legion/extensions/conditioner/runners/condition'
          end

          def runner_class
            Legion::Extensions::Conditioner::Runners::Condition
          end

          def runner_method
            'check'
          end
        end
      end
    end
  end
end
