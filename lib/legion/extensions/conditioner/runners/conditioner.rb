# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module Conditioner
          def check(conditions:, **payload)
            conditioner = Legion::Extensions::Conditioner::Condition.new(conditions: conditions,
                                                                         values:     payload,
                                                                         type:       payload[:type])

            status = if conditioner.valid? && payload.key?(:transformation)
                       'transformation.queued'
                     elsif conditioner.valid? && payload.key?(:runner_routing_key)
                       'task.queued'
                     elsif conditioner.valid?
                       'task.exception'
                     else
                       'conditioner.failed'
                     end

            send_task(**payload) unless status == 'conditioner.failed'
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
            log_runner_exception(e)
            Legion::Logging.error(e.message) unless respond_to?(:log) && log
            task_update(payload[:task_id], 'conditioner.exception', **payload) unless payload[:task_id].nil?
          end

          def send_task(**opts)
            subtask_hash = {}
            %i[runner_routing_key relationship_id chain_id trigger_runner_id trigger_function_id function_id function runner_id runner_class transformation debug task_id results].each do |column| # rubocop:disable Layout/LineLength
              subtask_hash[column] = opts[column] if opts.key? column
            end

            subtask_hash[:routing_key] = if subtask_hash.key? :transformation
                                           'task.subtask.transform'
                                         elsif subtask_hash.key? :runner_routing_key
                                           subtask_hash[:runner_routing_key]
                                         end

            raise Legion::Exception::MissingArgument 'Missing :routing_key' unless subtask_hash.key? :routing_key

            Legion::Transport::Messages::SubTask.new(**subtask_hash).publish
          end

          include Legion::Extensions::Helpers::Lex
          include Legion::Extensions::Helpers::Task

          private

          def log_runner_exception(exception)
            return unless respond_to?(:log) && log

            if log.respond_to?(:log_exception)
              log.log_exception(exception, component_type: :runner)
            elsif log.respond_to?(:error)
              log.error("Unhandled exception in Conditioner::Runners::Conditioner#check: #{exception.class}: #{exception.message}")
              if exception.backtrace
                if log.respond_to?(:warn)
                  log.warn(exception.backtrace.join("\n"))
                else
                  log.error(exception.backtrace.join("\n"))
                end
              end
            end
          end
        end
      end
    end
  end
end
