# frozen_string_literal: true

module Legion
  module Extensions
    module Conditioner
      class Comparator
        def self.equal?(fact, value, values)
          values[fact] == value
        end

        def self.not_equal?(fact, value, values)
          values[fact] != value
        end

        def self.nil?(fact, values)
          values[fact].nil?
        end

        def self.not_nil?(fact, values)
          !values[fact].nil?
        end

        def self.false?(fact, values)
          values[fact] ? false : true
        end

        def self.true?(fact, values)
          values[fact]
        end

        def self.array?(fact, values)
          values[fact].is_a? Array
        end

        def self.string?(fact, values)
          values[fact].is_a? String
        end

        def self.integer?(fact, values)
          values[fact].is_a? Integer
        end

        def self.greater_than?(fact, value, values)
          values[fact] > value
        end

        def self.less_than?(fact, value, values)
          values[fact] < value
        end

        def self.greater_or_equal?(fact, value, values)
          values[fact] >= value
        end

        def self.less_or_equal?(fact, value, values)
          values[fact] <= value
        end

        def self.between?(fact, value, values)
          values[fact].between?(value[0], value[1])
        end

        def self.contains?(fact, value, values)
          values[fact].to_s.include?(value.to_s)
        end

        def self.starts_with?(fact, value, values)
          values[fact].to_s.start_with?(value.to_s)
        end

        def self.ends_with?(fact, value, values)
          values[fact].to_s.end_with?(value.to_s)
        end

        def self.matches?(fact, value, values)
          Regexp.new(value).match?(values[fact].to_s)
        end

        def self.in_set?(fact, value, values)
          Array(value).include?(values[fact])
        end

        def self.not_in_set?(fact, value, values)
          !Array(value).include?(values[fact])
        end

        def self.empty?(fact, values)
          val = values[fact]
          val.nil? || (val.respond_to?(:empty?) && val.empty?)
        end

        def self.not_empty?(fact, values)
          val = values[fact]
          !val.nil? && !(val.respond_to?(:empty?) && val.empty?)
        end

        def self.size_equal?(fact, value, values)
          val = values[fact]
          val.respond_to?(:size) && val.size == value
        end
      end
    end
  end
end
