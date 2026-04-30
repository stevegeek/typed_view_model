# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  class TraitTest < ActiveSupport::TestCase
    test "required_props defaults to empty array when nothing declared" do
      trait = Module.new { extend TypedViewModel::Trait }
      assert_equal [], trait.required_props
    end

    test "requires stores prop names" do
      trait = Module.new do
        extend TypedViewModel::Trait

        requires :user
      end
      assert_equal [:user], trait.required_props
    end

    test "requires stores multiple prop names" do
      trait = Module.new do
        extend TypedViewModel::Trait

        requires :user, :account, :order
      end
      assert_equal [:user, :account, :order], trait.required_props
    end

    test "requires replaces previously declared props" do
      trait = Module.new do
        extend TypedViewModel::Trait

        requires :user
        requires :account, :order
      end
      assert_equal [:account, :order], trait.required_props
    end

    test "required_props returns empty array when nothing declared" do
      trait = Module.new { extend TypedViewModel::Trait }
      assert_equal [], trait.required_props
    end

    test "required_props returns empty array when @required_props is nil" do
      # Test the fallback in required_props method (|| [])
      trait = Module.new { extend TypedViewModel::Trait }
      trait.instance_variable_set(:@required_props, nil)
      assert_equal [], trait.required_props
    end

    test "trait methods are available when included in a class" do
      trait = Module.new do
        extend TypedViewModel::Trait

        requires :name

        def formatted_name
          name.upcase
        end
      end

      klass = Class.new do
        include trait

        attr_reader :name

        def initialize(name)
          @name = name
        end
      end

      instance = klass.new("hello")
      assert_equal "HELLO", instance.formatted_name
    end

    test "multiple traits can coexist independently on different modules" do
      trait_a = Module.new do
        extend TypedViewModel::Trait

        requires :user, :account
      end

      trait_b = Module.new do
        extend TypedViewModel::Trait

        requires :order
      end

      assert_equal [:user, :account], trait_a.required_props
      assert_equal [:order], trait_b.required_props
    end

    test "multiple traits can be included in the same class" do
      trait_a = Module.new do
        extend TypedViewModel::Trait

        requires :user

        def user_name
          user.to_s
        end
      end

      trait_b = Module.new do
        extend TypedViewModel::Trait

        requires :order

        def order_id
          order.to_s
        end
      end

      klass = Class.new do
        include trait_a
        include trait_b

        attr_reader :user, :order

        def initialize(user:, order:)
          @user = user
          @order = order
        end
      end

      instance = klass.new(user: "Alice", order: 42)
      assert_equal "Alice", instance.user_name
      assert_equal "42", instance.order_id
    end

    test "trait required_props are accessible as module-level metadata" do
      trait = Module.new do
        extend TypedViewModel::Trait

        requires :import_row
      end

      assert_includes trait.required_props, :import_row
      assert_kind_of Array, trait.required_props
    end
  end
end
