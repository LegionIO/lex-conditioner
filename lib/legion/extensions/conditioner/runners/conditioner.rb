require 'legion/extensions/conditioner/helpers/condition'

module Legion::Extensions::Conditioner
  module Runners
    module Conditioner
      def self.check(payload)
        conditioner = Legion::Extensions::Conditioner::Condition.new(conditions: payload[:conditions], task_id: payload[:task_id], values: payload[:options])
        if conditioner.valid?
          Legion::Extensions::Conditioner::Transport::Messages::Conditioner.new(payload: payload, status: 'succeeded').publish
        else
          Legion::Extensions::Conditioner::Transport::Messages::Conditioner.new(payload).publish
        end
        unless payload[:task_id].nil?
          Legion::Transport::Messages::TaskUpdate.new(task_id: payload[:task_id], status: 'conditioner.failed').publish
        end

        { success: true, valid: conditioner.valid? }
      rescue StandardError => e
        Legion::Logging.error 'LEX::Conditioner::Runners::Condition had an exception'
        Legion::Logging.warn e.message
        Legion::Logging.warn e.backtrace
        unless payload[:task_id].nil?
          Legion::Transport::Messages::TaskUpdate.new(task_id: payload[:task_id], status: 'conditioner.failed').publish
        end
      end
    end
  end
end
