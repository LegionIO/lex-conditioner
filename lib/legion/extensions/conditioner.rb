# frozen_string_literal: true

require 'legion/extensions/conditioner/version'
require_relative 'conditioner/client'

module Legion
  module Extensions
    module Conditioner
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false
    end
  end
end
