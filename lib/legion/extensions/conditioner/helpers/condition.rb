# frozen_string_literal: true

require 'legion/json'
require 'legion/json/helper'
require 'legion/logging'
require_relative '../settings'
require_relative 'comparator'

module Legion
  module Extensions
    module Conditioner
      class ConfigurationError < ArgumentError; end

      class Condition
        include Legion::Logging::Helper
        include Legion::JSON::Helper

        BINARY_METHODS = %w[equal not_equal greater_than less_than greater_or_equal less_or_equal between contains
                            starts_with ends_with matches in_set not_in_set size_equal].to_h { |name| [name, :"#{name}?"] }.freeze
        UNARY_METHODS = {
          'nil' => :nil?, 'not_nil' => :not_nil?, 'is_false' => :false?, 'is_true' => :true?,
          'is_string' => :string?, 'is_array' => :array?, 'is_integer' => :integer?,
          'empty' => :empty?, 'not_empty' => :not_empty?
        }.freeze
        private_constant :BINARY_METHODS, :UNARY_METHODS

        def initialize(conditions:, values:)
          raise ConfigurationError, 'values must be a Hash' unless values.is_a?(Hash)

          @values = values
          @conditions = conditions.is_a?(String) ? json_load(conditions) : conditions
          @operators = Legion::Settings[:extensions][:conditioner][:allowed_operators]
          unless @operators.is_a?(Hash) && @operators.all? do |name, enabled|
                   (BINARY_METHODS.key?(name.to_s) || UNARY_METHODS.key?(name.to_s)) && [true, false].include?(enabled)
                 end
            raise ConfigurationError, 'allowed_operators must map supported operator names to true or false'
          end

          @operators = @operators.transform_keys(&:to_s)

          @explanation = condition_evaluate_group(conditions: @conditions)
        rescue StandardError => e
          handle_exception(e, handled: false)
          raise if e.is_a?(ConfigurationError)

          raise ConfigurationError, "Invalid condition: #{e.message}"
        end

        def valid?
          @explanation[:valid]
        end

        def explain
          @explanation
        end

        private

        def condition_evaluate_group(conditions:)
          raise ConfigurationError, 'condition group must be a Hash' unless conditions.is_a?(Hash)

          conditions = conditions.transform_keys(&:to_sym)
          group = conditions.keys.first
          unless conditions.size == 1 && %i[all any].include?(group) && conditions[group].is_a?(Array)
            raise ConfigurationError, 'condition group must contain exactly one all or any Array'
          end

          rules = conditions[group].map { |rule| condition_evaluate_rule(rule: rule) }
          valid = group == :all ? rules.all? { |rule| rule[:result] } : rules.any? { |rule| rule[:result] }
          { valid: valid, group: group, rules: rules }
        end

        def condition_evaluate_rule(rule:)
          raise ConfigurationError, 'condition rule must be a Hash' unless rule.is_a?(Hash)

          rule = rule.transform_keys(&:to_sym)
          if rule.key?(:all) || rule.key?(:any)
            nested = condition_evaluate_group(conditions: rule)
            return { group: nested[:group], rules: nested[:rules], result: nested[:valid] }
          end

          condition_validate_rule(rule: rule)
          actual = condition_fact_value(fact: rule[:fact])
          arguments = { fact: rule[:fact], values: { rule[:fact] => actual } }
          arguments[:value] = rule[:value] if BINARY_METHODS.key?(rule[:operator])
          method = BINARY_METHODS[rule[:operator]] || UNARY_METHODS.fetch(rule[:operator])
          result = Legion::Extensions::Conditioner::Comparator.public_send(method, **arguments)
          explanation = { fact: rule[:fact], operator: rule[:operator], actual: actual, result: result }
          explanation[:value] = rule[:value] if rule.key?(:value)
          explanation
        end

        def condition_validate_rule(rule:)
          unless (rule.keys - %i[fact operator value]).empty? && rule[:fact].is_a?(String) && !rule[:fact].empty?
            raise ConfigurationError, 'rule requires a nonempty fact path and only fact, operator, value keys'
          end
          raise ConfigurationError, "Unknown or disabled condition operator: #{rule[:operator].inspect}" unless @operators[rule[:operator]] == true
          raise ConfigurationError, "Operator #{rule[:operator]} requires value" if BINARY_METHODS.key?(rule[:operator]) && !rule.key?(:value)
          raise ConfigurationError, "Operator #{rule[:operator]} does not accept value" if UNARY_METHODS.key?(rule[:operator]) && rule.key?(:value)
          return unless rule[:operator] == 'between' && (!rule[:value].is_a?(Array) || rule[:value].size != 2)

          raise ConfigurationError, 'between requires a two-element value Array'
        end

        def condition_fact_value(fact:)
          return @values[fact] if @values.key?(fact)

          fact.split('.').reduce(@values) do |value, segment|
            case value
            when Hash
              value.key?(segment) ? value[segment] : value[segment.to_sym]
            when Array
              break nil unless segment.match?(/\A\d+\z/)

              value[segment.to_i]
            else
              break nil
            end
          end
        end
      end
    end
  end
end
