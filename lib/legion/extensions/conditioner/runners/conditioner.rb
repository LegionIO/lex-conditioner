require 'legion/extensions/conditioner/helpers/condition'

module Legion::Extensions::Conditioner
  module Runners
    module Conditioner
      def self.check(**payload) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
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

        unless payload[:task_id].nil?
          Legion::Transport::Messages::TaskUpdate.new(task_id: payload[:task_id], status: status).publish
        end

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

      def self.generate_task_log(task_id:, runner_class: to_s, function:, **payload)
        require 'legion/transport/messages/task_log'
        Legion::Transport::Messages::TaskLog.new(task_id:      task_id,
                                                 runner_class: runner_class,
                                                 function:     function,
                                                 entry:        payload).publish
      end
    end
  end
end
