# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'
require 'legion/transport/task/protocol'
require 'legion/transport'
require 'legion/transport/messages/subtask'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module Conditioner
          include Legion::Extensions::Helpers::Lex
          include Legion::Transport::Task::Protocol::Helper

          def check(conditions:, **payload)
            condition = Legion::Extensions::Conditioner::Condition.new(conditions: conditions, values: payload)
            if condition.valid?
              dispatch = send_task(**payload)
              log.debug "Condition forwarded task_id=#{payload[:task_id]} status=#{dispatch[:status]}"
              dispatch.merge(valid: true, explanation: condition.explain)
            else
              outcome = { success: false, valid: false, status: task_status(name: :skipped),
                          task_id: payload[:task_id], explanation: condition.explain }
              task_update(task_id: payload[:task_id], status: outcome[:status], results: outcome) if payload[:task_id]
              log.debug "Condition rejected task_id=#{payload[:task_id]}"
              outcome
            end
          rescue Legion::Transport::PublishRejected => e
            handle_exception(e, task_id: payload[:task_id], handled: false)
            raise
          rescue StandardError => e
            handle_exception(e, task_id: payload[:task_id])
            status = task_status(name: e.is_a?(Legion::Extensions::Conditioner::ConfigurationError) ? :conditioner_failed : :conditioner_exception)
            outcome = { success: false, valid: false, status: status, task_id: payload[:task_id], error: e.message }
            task_update(task_id: payload[:task_id], status: status, results: outcome) if payload[:task_id]
            outcome
          end

          def send_task(**opts)
            transformation = opts[:transformation]
            transform = transformation.is_a?(String) && !transformation.strip.empty?
            route = transform ? task_route(name: :transform) : opts[:runner_routing_key]
            unless route.is_a?(String) && !route.strip.empty?
              raise Legion::Extensions::Conditioner::ConfigurationError, 'Condition passed but no downstream routing key or transformation is configured'
            end

            fields = Legion::Transport::Task::Protocol::METADATA_FIELDS
            envelope = opts.slice(*fields, :transformation, :results, :args, :kwargs, :function_args, :payload, :runner_id)
            envelope[:routing_key] = route
            publication = Legion::Transport::Messages::SubTask.new(**envelope).publish!
            { success: true, task_id: opts[:task_id], status: task_status(name: transform ? :transformer_queued : :queued), publication: publication }
          end
        end
      end
    end
  end
end
