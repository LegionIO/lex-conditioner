# frozen_string_literal: true

require_relative 'helpers/condition'

module Legion
  module Extensions
    module Conditioner
      class Client
        def evaluate(conditions:, values:)
          conditions_json = conditions.is_a?(String) ? conditions : Legion::JSON.dump(conditions)
          condition = Condition.new(conditions: conditions_json, values: values)
          {
            valid:       condition.valid?,
            explanation: condition.explain
          }
        end
      end
    end
  end
end
