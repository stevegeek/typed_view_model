# frozen_string_literal: true

module TypedViewModel
  module TestSupport
    # Creates a minimal test harness for testing traits in isolation
    # Dynamically generates a class that includes the trait and provides required props
    class TraitTestHarness
      class << self
        # Create an instance of a test class that includes the given trait
        #
        # @param trait_module [Module] The trait module to test
        # @param props [Hash] The props to initialize the test instance with
        # @return [Object] An instance of the test class with the trait included
        #
        # Example:
        #   instance = TraitTestHarness.create(
        #     MyTraits::UserMethods,
        #     user: MockObject.new(name: "Alice")
        #   )
        def create(trait_module, **props)
          # Create a new class that includes the trait
          test_class = Class.new do
            include trait_module

            # Create attr_readers for all props
            props.each_key do |prop_name|
              attr_reader prop_name
            end

            # Mirrors Literal::Data's generated initializer: set props, then
            # invoke after_initialize if the trait defines it.
            define_method :initialize do |**init_props|
              init_props.each do |key, value|
                instance_variable_set("@#{key}", value)
              end
              after_initialize if respond_to?(:after_initialize)
            end
          end

          # Check if the trait has requirements and validate them
          required = required_props(trait_module)
          missing = required - props.keys

          unless missing.empty?
            raise ArgumentError, "Missing required props for #{trait_module.name}: #{missing.join(", ")}"
          end

          # Create and return an instance
          test_class.new(**props)
        end

        # Get the required props for a trait
        #
        # @param trait_module [Module] The trait module
        # @return [Array<Symbol>] The required prop names
        def required_props(trait_module)
          trait_module.respond_to?(:required_props) ? trait_module.required_props : []
        end
      end
    end
  end
end
