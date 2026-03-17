# frozen_string_literal: true

require_relative 'comparator'

module Legion
  module Extensions
    module Conditioner
      class Condition
        def initialize(args)
          @conditions = Legion::JSON.load(args[:conditions])
          @values = to_dotted_hash(args[:values])
        end

        def to_dotted_hash(source, target = {}, namespace = nil)
          prefix = "#{namespace}." if namespace
          case source
          when Hash
            source.each do |key, value|
              to_dotted_hash(value, target, "#{prefix}#{key}")
            end
          when Array
            source.each_with_index do |value, index|
              to_dotted_hash(value, target, "#{prefix}#{index}")
            end
          else
            target[namespace] = source
          end
          target
        end

        def validate_vars
          raise Legion::Exception::MissingArgument, '@conditions is nil' if @conditions.nil?
          raise Legion::Exception::MissingArgument, '@values is nil' if @values.nil?
          raise Legion::Exception::WrongType::Hash, @values.class unless @values.is_a? Hash
          raise Legion::Exception::WrongType::Hash, @conditions.class unless @conditions.is_a? Hash
        end

        BINARY_OPS = %w[equal not_equal greater_than less_than greater_or_equal less_or_equal between contains starts_with ends_with matches in_set not_in_set
                        size_equal].freeze
        UNARY_OPS = %w[nil not_nil is_false is_true is_string is_array is_integer empty not_empty].freeze
        UNARY_METHOD_MAP = {
          'is_false' => :false?, 'is_true' => :true?,
          'is_string' => :string?, 'is_array' => :array?, 'is_integer' => :integer?,
          'empty' => :empty?, 'not_empty' => :not_empty?
        }.freeze

        def validate_test(conditions = @conditions)
          conditions.each do |condition|
            condition[1].each do |rule|
              result = evaluate_rule(rule)
              return true if condition[0] == :any && result == true
              return false if condition[0] == :all && result == false
            end
            return false if condition[0] == :any
            return true if condition[0] == :all
          end
        end

        def evaluate_rule(rule)
          return validate_test(all: rule[:all]) if rule.include?(:all)
          return validate_test(any: rule[:any]) if rule.include?(:any)

          comp = Legion::Extensions::Conditioner::Comparator
          op = rule[:operator]

          if BINARY_OPS.include?(op)
            comp.send(:"#{op}?", rule[:fact], rule[:value], @values)
          elsif UNARY_OPS.include?(op)
            method_name = UNARY_METHOD_MAP[op] || :"#{op}?"
            comp.send(method_name, rule[:fact], @values)
          end
        end

        def valid?
          @valid = validate_test if @valid.nil?
          @valid
        end
      end
    end
  end
end
