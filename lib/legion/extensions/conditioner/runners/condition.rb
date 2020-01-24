require 'legion/extensions/conditioner/condition'
require 'legion/extensions/conditioner/transport/messages/conditioner'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module Condition
          def self.check(payload)
            conditioner = Legion::Extensions::Conditioner::Condition.new(conditions: payload[:conditions], task_id: 1, values: payload[:options])
            if conditioner.valid?
              Legion::Extensions::Conditioner::Transport::Messages::Conditioner.new(payload, 'succeeded').publish
              unless payload[:task_id].nil?
                Legion::Transport::Messages::TaskUpdate.new(payload[:task_id], 'transformer.queued').publish
              end
            else
              Legion::Extensions::Conditioner::Transport::Messages::Conditioner.new(payload, 'failed').publish
              unless payload[:task_id].nil?
                Legion::Transport::Messages::TaskUpdate.new(payload[:task_id], 'conditioner.failed').publish
              end
            end
            { success: true, valid: conditioner.valid? }
          rescue StandardError => e
            Legion::Logging.error 'LEX::Conditioner::Runners::Condition had an exception'
            Legion::Logging.warn e.message
            Legion::Logging.warn e.backtrace
            unless payload[:task_id].nil?
              Legion::Transport::Messages::TaskUpdate.new(payload[:task_id], 'conditioner.exception').publish
            end
          end
        end
      end
    end
  end
end
