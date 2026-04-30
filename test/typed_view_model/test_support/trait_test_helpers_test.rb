# frozen_string_literal: true

require "test_helper"
require "typed_view_model/test_support/trait_test_helpers"

module TypedViewModel
  module TestSupport
    class TraitTestHelpersTest < ActiveSupport::TestCase
      include TypedViewModel::TestSupport::TraitTestHelpers

      # --- Inline test trait modules ---

      module SinglePropTrait
        extend TypedViewModel::Trait

        requires :user

        def user_name
          user.name
        end
      end

      module MultiPropTrait
        extend TypedViewModel::Trait

        requires :user, :account

        def user_and_account
          "#{user.name} @ #{account.company}"
        end
      end

      module NoPropTrait
        extend TypedViewModel::Trait

        def greeting
          "hello"
        end
      end

      module NestedMethodTrait
        extend TypedViewModel::Trait

        requires :order

        def order_total
          order.line_item&.price
        end
      end

      # --- testing_trait ---

      test "testing_trait sets @tested_trait" do
        testing_trait SinglePropTrait
        assert_equal SinglePropTrait, @tested_trait
      end

      # --- with_mock: basic usage ---

      test "with_mock auto-infers prop name from single-prop trait" do
        testing_trait SinglePropTrait
        instance = with_mock(name: "Alice")
        assert_equal "Alice", instance.user_name
      end

      test "with_mock converts nested hashes to MockObject" do
        testing_trait NestedMethodTrait
        instance = with_mock(line_item: {price: 99})
        assert_equal 99, instance.order_total
      end

      # --- with_mock: error cases ---

      test "with_mock raises if no trait set" do
        @tested_trait = nil
        error = assert_raises(RuntimeError) { with_mock(name: "Alice") }
        assert_match(/No trait set/, error.message)
      end

      test "with_mock raises if trait has no requirements" do
        testing_trait NoPropTrait
        error = assert_raises(RuntimeError) { with_mock(greeting: "hi") }
        assert_match(/no required props/, error.message)
      end

      test "with_mock raises if trait has multiple requirements" do
        testing_trait MultiPropTrait
        error = assert_raises(RuntimeError) { with_mock(name: "Alice") }
        assert_match(/multiple required props/, error.message)
      end

      # --- with_props: basic usage ---

      test "with_props creates instance with explicit props" do
        testing_trait SinglePropTrait
        instance = with_props(user: {name: "Bob"})
        assert_equal "Bob", instance.user_name
      end

      test "with_props works with multiple props" do
        testing_trait MultiPropTrait
        instance = with_props(
          user: {name: "Carol"},
          account: {company: "Acme"}
        )
        assert_equal "Carol @ Acme", instance.user_and_account
      end

      test "with_props converts hash values to MockObject recursively" do
        testing_trait NestedMethodTrait
        instance = with_props(order: {line_item: {price: 42}})
        assert_equal 42, instance.order_total
      end

      test "with_props deep nested hash conversion" do
        testing_trait NestedMethodTrait
        instance = with_props(order: {a: {b: {c: 1}}})
        assert_equal 1, instance.order.a.b.c
      end

      test "with_props passes non-hash values through unchanged" do
        testing_trait SinglePropTrait
        mock_user = mock_object(name: "Direct")
        instance = with_props(user: mock_user)
        assert_equal "Direct", instance.user_name
      end

      test "with_props raises if no trait set" do
        @tested_trait = nil
        error = assert_raises(RuntimeError) { with_props(user: {name: "X"}) }
        assert_match(/No trait set/, error.message)
      end

      # --- trait_harness ---

      test "trait_harness delegates to TraitTestHarness.create" do
        instance = trait_harness(SinglePropTrait, user: mock_object(name: "Eve"))
        assert_equal "Eve", instance.user_name
      end

      test "trait_harness raises on missing required props" do
        assert_raises(ArgumentError) { trait_harness(SinglePropTrait) }
      end

      # --- mock_object ---

      test "mock_object creates MockObject with given attributes" do
        mock = mock_object(name: "Test", age: 30)
        assert_equal "Test", mock.name
        assert_equal 30, mock.age
      end

      test "mock_object returns instance of MockObject" do
        mock = mock_object(x: 1)
        assert_instance_of TypedViewModel::TestSupport::MockObject, mock
      end

      # --- mock_chain ---

      test "mock_chain works same as mock_object" do
        inner = mock_object(sku: "ABC")
        chain = mock_chain(related_entity: inner)
        assert_equal "ABC", chain.related_entity.sku
      end

      test "mock_chain returns MockObject" do
        chain = mock_chain(a: 1)
        assert_instance_of TypedViewModel::TestSupport::MockObject, chain
      end

      # --- assert_trait_requires ---

      test "assert_trait_requires passes when props match" do
        assert_trait_requires SinglePropTrait, :user
      end

      test "assert_trait_requires passes with multiple props in any order" do
        assert_trait_requires MultiPropTrait, :account, :user
      end

      test "assert_trait_requires fails when props do not match" do
        error = assert_raises(Minitest::Assertion) do
          assert_trait_requires SinglePropTrait, :wrong_prop
        end
        assert_match(/require/, error.message)
      end

      test "assert_trait_requires fails with extra props" do
        error = assert_raises(Minitest::Assertion) do
          assert_trait_requires SinglePropTrait, :user, :extra
        end
        assert_match(/require/, error.message)
      end

      # --- assert_raises_missing_prop ---

      test "assert_raises_missing_prop passes on missing prop" do
        assert_raises_missing_prop SinglePropTrait, :user
      end

      test "assert_raises_missing_prop passes with partial props provided" do
        assert_raises_missing_prop MultiPropTrait, :account, user: mock_object(name: "X")
      end

      test "assert_raises_missing_prop fails when all props are provided" do
        assert_raises(Minitest::Assertion) do
          assert_raises_missing_prop SinglePropTrait, :user, user: mock_object(name: "Y")
        end
      end
    end
  end
end
