# frozen_string_literal: true

require_relative 'helpers/condition'

module Legion
  module Extensions
    module Conditioner
      class Client
        def evaluate(conditions:, values:)
          condition = Legion::Extensions::Conditioner::Condition.new(conditions: conditions, values: values)
          {
            valid:       condition.valid?,
            explanation: condition.explain
          }
        end
      end
    end
  end
end
