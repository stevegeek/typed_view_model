# frozen_string_literal: true

require_relative "mock_object"
require_relative "trait_test_harness"

module TypedViewModel
  module TestSupport
    # Helper methods for testing view model traits
    # Include this module in your test classes to get convenient helper methods
    #
    # Example:
    #   class MyTraitTest < ActiveSupport::TestCase
    #     include TypedViewModel::TestSupport::TraitTestHelpers
    #
    #     test "trait behavior" do
    #       instance = trait_harness(MyTrait, user: mock_object(name: "Alice"))
    #       assert_equal "Alice", instance.user_name
    #     end
    #   end
    module TraitTestHelpers
      # Create a test instance with the given trait included
      #
      # @param trait_module [Module] The trait to test
      # @param props [Hash] Props to initialize the instance with
      # @return [Object] Test instance with the trait included
      def trait_harness(trait_module, **props)
        TraitTestHarness.create(trait_module, **props)
      end

      # Create a mock object with the given attributes
      #
      # @param attributes [Hash] Attributes for the mock object
      # @return [MockObject] A mock object that responds to the given attributes
      def mock_object(**attributes)
        MockObject.new(attributes)
      end

      # Assert that a trait requires specific props
      #
      # @param trait_module [Module] The trait to test
      # @param expected_props [Array<Symbol>] The expected required props
      def assert_trait_requires(trait_module, *expected_props)
        actual_props = TraitTestHarness.required_props(trait_module)
        assert_equal expected_props.sort, actual_props.sort,
          "Expected #{trait_module.name} to require #{expected_props.inspect}, but it requires #{actual_props.inspect}"
      end

      # Assert that creating a trait harness without required props raises an error
      #
      # @param trait_module [Module] The trait to test
      # @param missing_prop [Symbol] The prop to omit
      # @param provided_props [Hash] Props to provide (without the missing one)
      def assert_raises_missing_prop(trait_module, missing_prop, **provided_props)
        error = assert_raises(ArgumentError) do
          trait_harness(trait_module, **provided_props)
        end
        assert_match(/Missing required props.*#{missing_prop}/, error.message)
      end

      # Create a mock that chains other mocks
      # Useful for testing methods that call chained methods like user.account.name
      #
      # @param attributes [Hash] Attributes where values can be other mocks
      # @return [MockObject] A mock that can return other mocks
      #
      # Example:
      #   mock_chain(
      #     related_entity: mock_object(
      #       sku: "TEST-123",
      #       price: 1000
      #     )
      #   )
      def mock_chain(**attributes)
        mock_object(**attributes)
      end

      # DSL for cleaner trait testing - sets up a trait for the whole test class
      # Call this in your setup method to reduce boilerplate
      #
      # Example:
      #   def setup
      #     testing_trait MyApp::ViewTraits::ImportRowMethods
      #   end
      #
      #   test "something" do
      #     instance = with_props(import_row: { number: 5 })
      #     assert_equal 6, instance.import_row_display_number
      #   end
      def testing_trait(trait_module)
        @tested_trait = trait_module
      end

      # Create an instance with the tested trait, automatically creating mocks
      #
      # @param props [Hash] Props where values can be:
      #   - A Hash (will be converted to mock_object)
      #   - A MockObject (used as-is)
      #   - Any other value (used as-is)
      #
      # Example:
      #   with_props(
      #     import_row: { number: 5, valid?: true },
      #     show_actions: true
      #   )
      def with_props(**props)
        raise "No trait set. Call testing_trait(MyTrait) in setup first" unless @tested_trait

        # Convert hash values to mock objects recursively
        converted_props = props.transform_values do |value|
          convert_to_mock(value)
        end

        trait_harness(@tested_trait, **converted_props)
      end

      private

      # Convert hashes to mock objects, but only symbol-keyed hashes
      # (which represent mock attributes). String-keyed hashes are treated
      # as literal data and left as-is.
      def convert_to_mock(value)
        case value
        when Hash
          if value.keys.all? { |k| k.is_a?(Symbol) }
            converted_hash = value.transform_values { |v| convert_to_mock(v) }
            mock_object(**converted_hash)
          else
            value
          end
        else
          value
        end
      end

      public

      # Shorthand for creating instance with a single prop
      # The prop name is inferred from the trait's requirements
      #
      # Example:
      #   # If trait requires :import_row
      #   with_mock(number: 5, valid?: true)
      #   # Is equivalent to:
      #   with_props(import_row: { number: 5, valid?: true })
      def with_mock(**attributes)
        raise "No trait set. Call testing_trait(MyTrait) in setup first" unless @tested_trait

        # Get the first required prop (usually there's only one)
        required = TraitTestHarness.required_props(@tested_trait)
        if required.empty?
          raise "Trait has no required props, use with_props instead"
        elsif required.size > 1
          raise "Trait has multiple required props (#{required.join(", ")}), use with_props instead"
        end

        prop_name = required.first
        with_props(prop_name => attributes)
      end
    end
  end
end
