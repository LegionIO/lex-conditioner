# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'
require 'legion/transport/task/protocol'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module ConflictResolver
          include Legion::Extensions::Helpers::Lex
          include Legion::Transport::Task::Protocol::Helper

          def resolve(conditions:, competing_conditions: nil, **payload)
            primary = Legion::Extensions::Conditioner::Condition.new(conditions: conditions, values: payload)
            unless primary.valid? || competing_conditions.nil?
              secondary = Legion::Extensions::Conditioner::Condition.new(conditions: competing_conditions, values: payload)
            end
            selection = if primary.valid?
                          :primary
                        elsif secondary&.valid?
                          :secondary
                        else
                          :none
                        end
            valid = selection != :none
            status = task_status(name: valid ? :queued : :conditioner_failed)
            { success: valid, valid: valid, resolution: settings.fetch(:resolutions).fetch(selection), status: status }
          rescue StandardError => e
            handle_exception(e, task_id: payload[:task_id])
            status = task_status(name: :conditioner_exception)
            { success: false, valid: false, status: status, error: e.message }
          end
        end
      end
    end
  end
end
