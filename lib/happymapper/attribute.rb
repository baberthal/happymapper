# frozen_string_literal: true

module HappyMapper
  class Attribute < Item
    attr_accessor :default

    # @see Item#initialize
    # Additional options:
    #   :default => Object The default value for this
    def initialize(name, type, options = {})
      super
      self.default = options[:default]
    end

    def find(node, _namespace, xpath_options)
      if options[:xpath]
        yield(node.xpath(options[:xpath], xpath_options))
      else
        yield(node.attributes[tag])
      end
    end
  end
end
