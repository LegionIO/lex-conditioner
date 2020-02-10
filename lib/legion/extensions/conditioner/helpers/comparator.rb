module Legion
  module Extensions
    module Conditioner
      class Comparator
        def self.equal(fact, value, values)
          values[fact] == value
        end

        def self.not_equal(fact, value, values)
          values[fact] != value
        end

        def self.nil(fact, values)
          values[fact].nil?
        end

        def self.not_nil(fact, values)
          !values[fact].nil?
        end

        def self.is_false(fact, values) # rubocop:disable Naming/PredicateName
          true unless values[fact]
        end

        def self.is_true(fact, values) # rubocop:disable Naming/PredicateName
          values[fact]
        end

        def self.is_array(fact, values) # rubocop:disable Naming/PredicateName
          !values[fact]
        end

        def self.is_string(fact, values) # rubocop:disable Naming/PredicateName
          values[fact].is_a? String
        end
      end
    end
  end
end
