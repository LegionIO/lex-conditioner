require 'legion/extensions/conditioner/helpers/condition'

module Legion::Extensions::Conditioner
  module Runners
    module Conditioner
      def self.check(**payload) # rubocop:disable Metrics/AbcSize
        conditioner = Legion::Extensions::Conditioner::Condition.new(conditions: payload[:conditions],
                                                                     task_id:    payload[:task_id],
                                                                     values:     payload,
                                                                     type:       payload[:type])
        if conditioner.valid?
          Legion::Extensions::Conditioner::Transport::Messages::Conditioner.new(**payload).publish
          status = 'task.queued'
        else
          status = 'conditioner.failed'
        end

        task_update(payload[:task_id], status, **payload) unless payload[:task_id].nil?

        if payload[:debug] && payload.key?(:task_id)
          generate_task_log(task_id:    payload[:task_id],
                            function:   'check',
                            valid:      conditioner.valid?,
                            conditions: payload[:conditions],
                            values:     payload)
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

      include Legion::Extensions::Helpers::Lex
      include Legion::Extensions::Helpers::Task
    end
  end
end
