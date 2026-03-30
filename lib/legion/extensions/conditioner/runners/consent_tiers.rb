# frozen_string_literal: true

require 'legion/extensions/conditioner/helpers/condition'

module Legion
  module Extensions
    module Conditioner
      module Runners
        module ConsentTiers
          TIERS = %w[tier1 tier2 tier3].freeze

          def evaluate(conditions:, tier: nil, **payload)
            conditioner = Legion::Extensions::Conditioner::Condition.new(conditions: conditions,
                                                                         values:     payload.merge(tier: tier))

            granted_tier = if conditioner.valid? && TIERS.include?(tier.to_s)
                             tier.to_s
                           elsif conditioner.valid?
                             TIERS.first
                           end

            status = conditioner.valid? ? 'task.queued' : 'conditioner.failed'

            task_update(payload[:task_id], status, **payload) unless payload[:task_id].nil?

            { success: true, valid: conditioner.valid?, tier: granted_tier }
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
