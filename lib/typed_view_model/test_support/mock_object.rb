# frozen_string_literal: true

require "active_support/hash_with_indifferent_access"

module TypedViewModel
  module TestSupport
    # Simple mock object for testing traits without ActiveRecord dependencies
    #
    # Usage:
    #   mock = MockObject.new(
    #     number: 5,
    #     entity_valid?: true,
    #     related_entity: nil
    #   )
    #   mock.number # => 5
    #   mock.entity_valid? # => true
    class MockObject
      def initialize(attributes = {})
        @attributes = attributes.with_indifferent_access
        define_attribute_methods!
      end

      # Allow adding more attributes after initialization
      def stub(additional_attributes)
        @attributes.merge!(additional_attributes.with_indifferent_access)
        define_attribute_methods!
        self
      end

      # For debugging and test output
      def inspect
        "#<MockObject #{@attributes.inspect}>"
      end

      def to_s
        inspect
      end

      private

      def define_attribute_methods!
        @attributes.each do |name, value|
          # Convert name to string to handle symbols and special characters
          method_name = name.to_s

          # Check if method already exists as a singleton method
          if singleton_class.method_defined?(method_name)
            singleton_class.send(:remove_method, method_name)
          end

          # Define the method with the current value
          define_singleton_method(method_name) do
            # If the value is a Proc, call it (allows dynamic values)
            value.is_a?(Proc) ? value.call : value
          end
        end
      end

      # Handle methods that might be chained (like related_entity&.sku)
      def method_missing(method_name, *args, **kwargs, &block)
        # Support safe navigation by returning nil for undefined methods
        if method_name.to_s.end_with?("?") || @attributes.key?(method_name)
          nil
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.end_with?("?") || super
      end
    end
  end
end
