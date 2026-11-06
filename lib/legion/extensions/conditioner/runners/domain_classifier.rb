# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'
require 'legion/transport/task/protocol'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module DomainClassifier
          include Legion::Extensions::Helpers::Lex
          include Legion::Transport::Task::Protocol::Helper

          def classify(conditions:, domain: nil, **payload)
            condition = Legion::Extensions::Conditioner::Condition.new(conditions: conditions, values: payload.merge(domain: domain))
            classification = if condition.valid?
                               domain ? domain.to_s : settings.fetch(:default_domain)
                             else
                               settings.fetch(:unclassified_domain)
                             end
            status = task_status(name: condition.valid? ? :queued : :conditioner_failed)
            { success: condition.valid?, valid: condition.valid?, domain: classification, status: status }
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
