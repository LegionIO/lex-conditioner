require_relative 'comparator'

module Legion
  module Extensions
    module Conditioner
      class Condition
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

        def validate_test(conditions = @conditions) # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity,Metrics/AbcSize
          conditions.each do |condition|
            condition[1].each do |rule|
              result = validate_test('conditions' => { 'all' => rule[:all] }) if rule.include? :all
              result = validate_test('conditions' => { 'any' => rule[:any] }) if rule.include? :any
              case rule[:operator]
              when 'equal'
                result = Legion::Extensions::Conditioner::Comparator.equal?(rule[:fact], rule[:value], @values)
              when 'not_equal'
                result = Legion::Extensions::Conditioner::Comparator.not_equal?(rule[:fact], rule[:value], @values)
              when 'nil'
                result = Legion::Extensions::Conditioner::Comparator.nil?(rule[:fact], @values)
              when 'not_nil'
                result = Legion::Extensions::Conditioner::Comparator.not_nil?(rule[:fact], @values)
              when 'is_false'
                result = Legion::Extensions::Conditioner::Comparator.is_false?(rule[:fact], @values)
              when 'is_true'
                result = Legion::Extensions::Conditioner::Comparator.is_true?(rule[:fact], @values)
              when 'is_string'
                result = Legion::Extensions::Conditioner::Comparator.is_string?(rule[:fact], @values)
              when 'is_array'
                result = Legion::Extensions::Conditioner::Comparator.is_array?(rule[:fact], @values)
              when 'is_integer'
                result = Legion::Extensions::Conditioner::Comparator.is_integer?(rule[:fact], @values)
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
