# frozen_string_literal: true

require "test_helper"
require "typed_view_model/test_support/mock_object"
require "typed_view_model/test_support/trait_test_harness"

module TypedViewModel
  module TestSupport
    class MockObjectTest < ActiveSupport::TestCase
      test "basic attribute access" do
        mock = MockObject.new(name: "Alice", age: 30)
        assert_equal "Alice", mock.name
        assert_equal 30, mock.age
      end

      test "boolean attributes ending in ?" do
        mock = MockObject.new(active?: true, deleted?: false)
        assert_equal true, mock.active?
        assert_equal false, mock.deleted?
      end

      test "proc values are called lazily" do
        counter = 0
        mock = MockObject.new(value: -> { counter += 1 })

        assert_equal 0, counter
        assert_equal 1, mock.value
        assert_equal 1, counter
        assert_equal 2, mock.value
        assert_equal 2, counter
      end

      test "stub adds attributes after creation" do
        mock = MockObject.new(name: "Alice")
        assert_equal "Alice", mock.name

        mock.stub(email: "alice@example.com")
        assert_equal "alice@example.com", mock.email
        assert_equal "Alice", mock.name
      end

      test "stub overwrites existing attributes" do
        mock = MockObject.new(name: "Alice")
        mock.stub(name: "Bob")
        assert_equal "Bob", mock.name
      end

      test "stub returns self for chaining" do
        mock = MockObject.new(a: 1)
        result = mock.stub(b: 2)
        assert_same mock, result
      end

      test "inspect includes attributes" do
        mock = MockObject.new(name: "Alice")
        assert_match(/MockObject/, mock.inspect)
        assert_match(/name/, mock.inspect)
        assert_match(/Alice/, mock.inspect)
      end

      test "to_s returns same as inspect" do
        mock = MockObject.new(name: "Alice")
        assert_equal mock.inspect, mock.to_s
      end

      test "undefined ? methods return nil via method_missing" do
        mock = MockObject.new
        assert_nil mock.unknown_method?
        assert_nil mock.something_else?
      end

      test "undefined non-? methods raise NoMethodError" do
        mock = MockObject.new
        assert_raises(NoMethodError) { mock.undefined_method }
        assert_raises(NoMethodError) { mock.another_missing }
      end

      test "respond_to_missing? returns true for ? methods" do
        mock = MockObject.new
        assert mock.respond_to?(:anything?)
        assert mock.respond_to?(:something_else?)
      end

      test "respond_to_missing? returns false for non-? methods not in attributes" do
        mock = MockObject.new(name: "Alice")
        refute mock.respond_to?(:unknown_method)
      end

      test "respond_to? returns true for defined attributes" do
        mock = MockObject.new(name: "Alice")
        assert mock.respond_to?(:name)
      end

      test "nested mock objects" do
        inner = MockObject.new(sku: "TEST-123", price: 1000)
        outer = MockObject.new(product: inner, quantity: 5)

        assert_equal 5, outer.quantity
        assert_equal "TEST-123", outer.product.sku
        assert_equal 1000, outer.product.price
      end

      test "symbol and string keys are interchangeable" do
        mock = MockObject.new(name: "Alice")
        # with_indifferent_access means both symbol and string keys work
        assert_equal "Alice", mock.name
      end

      test "nil attribute values are accessible" do
        mock = MockObject.new(value: nil)
        assert_nil mock.value
      end
    end

    class TraitTestHarnessTest < ActiveSupport::TestCase
      # A simple trait with no requirements
      module SimpleTrait
        def greeting
          "hello"
        end
      end

      # A trait with required props
      module TraitWithRequirements
        extend TypedViewModel::Trait

        requires :user, :account

        def user_name
          user.name
        end

        def account_name
          account.name
        end
      end

      # A trait with a single required prop
      module SinglePropTrait
        extend TypedViewModel::Trait

        requires :item

        def item_label
          "Item: #{item.name}"
        end
      end

      test "create with valid props returns working instance" do
        user_mock = MockObject.new(name: "Alice")
        account_mock = MockObject.new(name: "Acme")

        instance = TraitTestHarness.create(
          TraitWithRequirements,
          user: user_mock,
          account: account_mock
        )

        assert_equal "Alice", instance.user_name
        assert_equal "Acme", instance.account_name
      end

      test "create with missing required props raises ArgumentError" do
        user_mock = MockObject.new(name: "Alice")

        error = assert_raises(ArgumentError) do
          TraitTestHarness.create(TraitWithRequirements, user: user_mock)
        end

        assert_match(/Missing required props/, error.message)
        assert_match(/account/, error.message)
      end

      test "create sets up attr_readers for all provided props" do
        user_mock = MockObject.new(name: "Alice")
        account_mock = MockObject.new(name: "Acme")

        instance = TraitTestHarness.create(
          TraitWithRequirements,
          user: user_mock,
          account: account_mock
        )

        assert_equal user_mock, instance.user
        assert_equal account_mock, instance.account
      end

      test "required_props returns empty array for module without Trait" do
        result = TraitTestHarness.required_props(SimpleTrait)
        assert_equal [], result
      end

      test "required_props returns declared props for trait module" do
        result = TraitTestHarness.required_props(TraitWithRequirements)
        assert_equal [:user, :account], result
      end

      test "instance has access to trait methods" do
        instance = TraitTestHarness.create(SimpleTrait)
        assert_equal "hello", instance.greeting
      end

      test "create works with no props for trait with no requirements" do
        instance = TraitTestHarness.create(SimpleTrait)
        assert_equal "hello", instance.greeting
      end

      test "create accepts extra props beyond required ones" do
        user_mock = MockObject.new(name: "Alice")
        account_mock = MockObject.new(name: "Acme")

        instance = TraitTestHarness.create(
          TraitWithRequirements,
          user: user_mock,
          account: account_mock,
          extra_data: "bonus"
        )

        assert_equal "bonus", instance.extra_data
      end

      test "error message includes all missing prop names" do
        error = assert_raises(ArgumentError) do
          TraitTestHarness.create(TraitWithRequirements)
        end

        assert_match(/user/, error.message)
        assert_match(/account/, error.message)
      end

      test "error message includes trait module name" do
        error = assert_raises(ArgumentError) do
          TraitTestHarness.create(TraitWithRequirements)
        end

        assert_match(/TraitWithRequirements/, error.message)
      end
    end
  end
end
