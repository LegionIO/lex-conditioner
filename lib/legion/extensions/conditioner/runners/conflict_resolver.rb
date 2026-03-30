# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module ConflictResolver
          def resolve(conditions:, competing_conditions: nil, **payload)
            primary = Legion::Extensions::Conditioner::Condition.new(conditions: conditions,
                                                                     values:     payload)

            resolution = if competing_conditions.nil?
                           primary.valid? ? 'primary' : 'none'
                         else
                           secondary = Legion::Extensions::Conditioner::Condition.new(
                             conditions: competing_conditions,
                             values:     payload
                           )

                           if primary.valid?
                             'primary'
                           elsif secondary.valid?
                             'secondary'
                           else
                             'none'
                           end
                         end

            status = resolution == 'none' ? 'conditioner.failed' : 'task.queued'
            task_update(payload[:task_id], status, **payload) unless payload[:task_id].nil?

            { success: true, valid: resolution != 'none', resolution: resolution }
          rescue StandardError => e
            log.log_exception(e, component_type: :runner)
            task_update(payload[:task_id], 'conditioner.exception', **payload) unless payload[:task_id].nil?
          end

          include Legion::Extensions::Helpers::Lex
          include Legion::Extensions::Helpers::Task
        end
      end
    end
  end
end
