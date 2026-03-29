# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module DomainClassifier
          def classify(conditions:, domain: nil, **payload)
            conditioner = Legion::Extensions::Conditioner::Condition.new(conditions: conditions,
                                                                          values:     payload.merge(domain: domain))

            classification = if domain
                               conditioner.valid? ? domain.to_s : 'unclassified'
                             else
                               conditioner.valid? ? 'default' : 'unclassified'
                             end

            task_update(payload[:task_id], 'task.queued', **payload) unless payload[:task_id].nil?

            { success: true, valid: conditioner.valid?, domain: classification }
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
