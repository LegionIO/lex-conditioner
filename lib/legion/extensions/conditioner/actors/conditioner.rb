# frozen_string_literal: true

module Legion
  module Extensions
    module Conditioner
      module Actor
        class Conditioner < Legion::Extensions::Actors::Subscription
          trusted_internal true

          def runner_function
            'check'
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end

          private

          def process_message(...)
            message = super
            # The destination task is an argument, not the Conditioner invocation's execution identity.
            message.slice(:message_id, :correlation_id, :principal_id, :principal_type, :worker_id, :tenant_id, :source, :deadline_at)
                   .merge(args: message)
          end
        end
      end
    end
  end
end
