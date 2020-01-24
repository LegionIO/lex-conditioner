require_relative 'comparator'
# require 'legion/exceptions/missingargument'
# require 'legion/exceptions/wrongtype'

module Legion
  module Extensions
    module Conditioner
      class Condition
        attr_accessor :conditions, :values, :taskid, :valid

        def initialize(args)
          @conditions = Legion::JSON.load(args[:conditions])
          @values = to_dotted_hash(args[:values])
          @task_id = args[:task_id]
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
          raise Legion::Exception::MissingArgument, '@task_id is nil' if @task_id.nil?
          raise Legion::Exception::WrongType::Hash, @values.class unless @values.is_a? Hash
          raise Legion::Exception::WrongType::Integer, @task_id.class unless @task_id.is_a? Integer
          raise Legion::Exception::WrongType::Hash, @conditions.class unless @conditions.is_a? Hash
        end

        def validate_test(conditions = @conditions)
          conditions.each do |condition|
            condition[1].each do |rule|
              result = validate_test('conditions' => { 'all' => rule[:all] }) if rule.include? :all
              result = validate_test('conditions' => { 'any' => rule[:any] }) if rule.include? :any
              if rule[:operator] == 'equal'
                result = Legion::Extensions::Conditioner::Comparator.equal(rule[:fact], rule[:value], @values)
              elsif rule[:operator] == 'notequal'
                result = Legion::Extensions::Conditioner::Comparator.not_equal(rule[:fact], rule[:value], @values)
              end

              return true if condition[0] == :any && result == true
              return false if condition[0] == :all && result == false
            end
            return false if condition[0] == :any
            return true if condition[0] == :all
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
