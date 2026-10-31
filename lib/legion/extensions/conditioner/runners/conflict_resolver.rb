# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'
require 'legion/transport/task_protocol'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module ConflictResolver
          include Legion::Extensions::Helpers::Lex
          include Legion::Transport::TaskProtocol::Helper

          def resolve(conditions:, competing_conditions: nil, **payload)
            primary = Legion::Extensions::Conditioner::Condition.new(conditions: conditions, values: payload)
            secondary = Legion::Extensions::Conditioner::Condition.new(conditions: competing_conditions, values: payload) unless competing_conditions.nil?
            selection = if primary.valid?
                          :primary
                        elsif secondary&.valid?
                          :secondary
                        else
                          :none
                        end
            valid = selection != :none
            status = task_status(name: valid ? :queued : :conditioner_failed)
            outcome = { success: valid, valid: valid, resolution: settings.fetch(:resolutions).fetch(selection), status: status }
            task_update(task_id: payload[:task_id], status: status, results: outcome) if payload[:task_id]
            outcome
          rescue StandardError => e
            handle_exception(e, task_id: payload[:task_id])
            status = task_status(name: :conditioner_exception)
            outcome = { success: false, valid: false, status: status, error: e.message }
            task_update(task_id: payload[:task_id], status: status, results: outcome) if payload[:task_id]
            outcome
          end
        end
      end
    end
  end
end
