# frozen_string_literal: true

module Legion
  module Extensions
    module Conditioner
      module Actor
        class Conditioner < Legion::Extensions::Actors::Subscription
          def runner_function
            'check'
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
