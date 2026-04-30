# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  class WithCacheKeyTest < ActiveSupport::TestCase
    # --- Inline test view models ---

    class SimpleVM < TypedViewModel::Base
      include TypedViewModel::WithCacheKey

      prop :name, String

      with_cache_key :name
    end

    class MultiSlotVM < TypedViewModel::Base
      include TypedViewModel::WithCacheKey

      prop :a, String
      prop :b, String

      with_cache_key :a, name: :main
      with_cache_key :b, name: :alt
    end

    class ProcSourceVM < TypedViewModel::Base
      include TypedViewModel::WithCacheKey

      prop :counter, Integer

      with_cache_key proc { computed_value }

      def computed_value
        "computed-#{counter}"
      end
    end

    class ModifierVM < TypedViewModel::Base
      include TypedViewModel::WithCacheKey

      prop :name, String

      with_cache_key :name

      def cache_key_modifier
        "v9"
      end
    end

    class AllNilVM < TypedViewModel::Base
      include TypedViewModel::WithCacheKey

      prop :missing, _Nilable(String), default: nil

      with_cache_key :missing
    end

    class ParentVM < TypedViewModel::Base
      include TypedViewModel::WithCacheKey

      prop :name, String

      with_cache_key :name
    end

    class ChildVM < ParentVM
    end

    class ChildWithOwnKeyVM < ParentVM
      prop :extra, String

      with_cache_key :name, :extra, name: :detailed
    end

    # --- Tests ---

    test "cache_key on a Base subclass does not raise FrozenError (freeze fix)" do
      vm = SimpleVM.new(name: "alice")
      assert_nothing_raised { vm.cache_key }
    end

    test "default :_collection slot produces a stable key" do
      vm = SimpleVM.new(name: "alice")
      key = vm.cache_key
      assert_kind_of String, key
      assert_match(/^TypedViewModel::WithCacheKeyTest::SimpleVM\//, key)

      # Same instance returns the same key
      assert_equal key, SimpleVM.new(name: "alice").cache_key
    end

    test "multiple named slots produce distinct keys" do
      vm = MultiSlotVM.new(a: "alpha", b: "beta")
      main_key = vm.cache_key(:main)
      alt_key = vm.cache_key(:alt)

      assert_kind_of String, main_key
      assert_kind_of String, alt_key
      refute_equal main_key, alt_key
    end

    test "cache_key memoises the same string instance per slot" do
      vm = SimpleVM.new(name: "alice")
      first = vm.cache_key
      second = vm.cache_key
      assert_same first, second
    end

    test "cache_key_modifier override appends to the key" do
      vm = ModifierVM.new(name: "alice")
      assert_match(/\/v9\z/, vm.cache_key)
    end

    test "Proc sources are evaluated lazily via instance_eval" do
      vm = ProcSourceVM.new(counter: 7)
      key = vm.cache_key
      # The proc returns "computed-7", which becomes a hashed segment.
      digest = ::Digest::SHA1.hexdigest("computed-7")
      assert_includes key, digest
    end

    test "unrecognised slot returns nil from cache_key" do
      vm = SimpleVM.new(name: "alice")
      assert_nil vm.cache_key(:does_not_exist)
    end

    test "subclass inherits parent's with_cache_key declarations" do
      child = ChildVM.new(name: "bob")
      assert_match(/^TypedViewModel::WithCacheKeyTest::ChildVM\//, child.cache_key)
    end

    test "subclass adding its own with_cache_key does not leak to parent" do
      assert_nil ParentVM.named_cache_key_attributes[:detailed]
      assert_equal [:name, :extra], ChildWithOwnKeyVM.named_cache_key_attributes[:detailed]
    end

    test "all-nil source list raises CacheKeyError" do
      vm = AllNilVM.new
      assert_raises(::TypedViewModel::CacheKeyError) do
        vm.cache_key
      end
    end

    test "cacheable? is true when WithCacheKey is included and with_cache_key called" do
      vm = SimpleVM.new(name: "alice")
      assert vm.cacheable?
    end
  end
end
