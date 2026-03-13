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
          true unless values[fact]
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
      end
    end
  end
end
