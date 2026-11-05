# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'
require 'legion/transport/task/protocol'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module ConsentTiers
          include Legion::Extensions::Helpers::Lex
          include Legion::Transport::Task::Protocol::Helper

          def evaluate(conditions:, tier: nil, **payload)
            condition = Legion::Extensions::Conditioner::Condition.new(conditions: conditions, values: payload.merge(tier: tier))
            tiers = settings.fetch(:consent_tiers)
            unless tiers.is_a?(Array) && !tiers.empty? && tiers.all? { |value| value.is_a?(String) && !value.empty? }
              raise Legion::Extensions::Conditioner::ConfigurationError, 'consent_tiers must be a nonempty Array of tier names'
            end

            granted_tier = (tiers.include?(tier.to_s) ? tier.to_s : tiers.first) if condition.valid?
            status = task_status(name: condition.valid? ? :queued : :conditioner_failed)
            outcome = { success: condition.valid?, valid: condition.valid?, tier: granted_tier, status: status }
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
