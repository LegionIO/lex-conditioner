require 'legion/extensions/conditioner/version'

module Legion
  module Extensions
    module Conditioner
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
