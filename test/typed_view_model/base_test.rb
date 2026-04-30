# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  class BaseTest < ActiveSupport::TestCase
    # --- Inline test traits and view model classes ---

    module TestTraitA
      extend TypedViewModel::Trait

      requires :thing

      def thing_display_name
        "Display: #{thing.name}"
      end
    end

    module TestTraitB
      extend TypedViewModel::Trait

      requires :other

      def other_label
        "Label: #{other.label}"
      end
    end

    module TestTraitNoRequires
      extend TypedViewModel::Trait

      def static_value
        42
      end
    end

    # Simple ViewModel with one trait
    class SingleTraitViewModel < TypedViewModel::Base
      use TestTraitA

      prop :thing, _Any
    end

    # ViewModel composing multiple traits
    class MultiTraitViewModel < TypedViewModel::Base
      use TestTraitA
      use TestTraitB

      prop :thing, _Any
      prop :other, _Any
    end

    # ViewModel with helpers
    class WithHelpersViewModel < TypedViewModel::Base
      helpers :i18n, :format

      prop :value, _Any
    end

    # ViewModel with trait and helpers
    class FullViewModel < TypedViewModel::Base
      use TestTraitA
      helpers :i18n, :path, :format

      prop :thing, _Any
      prop :active, _Boolean, default: false
    end

    # ViewModel with a trait that has no requires
    class NoRequiresViewModel < TypedViewModel::Base
      use TestTraitNoRequires

      prop :placeholder, _Nilable(String), default: nil
    end

    # ViewModel with typed prop
    class TypedPropViewModel < TypedViewModel::Base
      prop :name, String
      prop :count, Integer, default: 0
    end

    # --- Tests for `use` class method ---

    test "use includes trait module methods" do
      thing = Data.define(:name).new(name: "Widget")
      view_model = SingleTraitViewModel.new(thing: thing)

      assert_equal "Display: Widget", view_model.thing_display_name
    end

    # --- Tests for multiple traits ---

    test "multiple traits compose correctly" do
      thing = Data.define(:name).new(name: "Widget")
      other = Data.define(:label).new(label: "Category")
      view_model = MultiTraitViewModel.new(thing: thing, other: other)

      assert_equal "Display: Widget", view_model.thing_display_name
      assert_equal "Label: Category", view_model.other_label
    end

    test "trait with no requires works" do
      view_model = NoRequiresViewModel.new
      assert_equal 42, view_model.static_value
    end

    # --- Tests for `use` requires validation ---
    #
    # Validation runs on first `.new()` (deferred) so the conventional
    # `use Trait` before `prop :foo` ordering still works.

    test "first instantiation raises ArgumentError when trait requires are not satisfied" do
      missing_trait = Module.new do
        extend TypedViewModel::Trait

        requires :user, :missing_field
      end

      klass = Class.new(TypedViewModel::Base) do
        use missing_trait
        prop :user, _Any
      end

      error = assert_raises(ArgumentError) do
        klass.new(user: "alice")
      end
      assert_match(/requires/, error.message)
      assert_match(/missing_field/, error.message)
      assert_match(/neither a declared `prop` nor an instance method matches/, error.message)
    end

    test "use validates regardless of declaration order (use before prop)" do
      sat_trait = Module.new do
        extend TypedViewModel::Trait

        requires :alpha
      end

      klass = Class.new(TypedViewModel::Base) do
        use sat_trait
        prop :alpha, _Any
      end

      instance = klass.new(alpha: "ok")
      assert_kind_of TypedViewModel::Base, instance
    end

    test "use validates regardless of declaration order (prop before use)" do
      sat_trait = Module.new do
        extend TypedViewModel::Trait

        requires :beta
      end

      klass = Class.new(TypedViewModel::Base) do
        prop :beta, _Any
        use sat_trait
      end

      assert_kind_of TypedViewModel::Base, klass.new(beta: "ok")
    end

    test "use accepts a plain module without requires" do
      plain_module = Module.new do
        def hello
          "world"
        end
      end

      klass = Class.new(TypedViewModel::Base) do
        prop :x, _Any
        use plain_module
      end

      assert_equal "world", klass.new(x: 1).hello
    end

    # --- Tests for `helpers` DSL ---

    test "helpers includes i18n helper methods" do
      view_model = WithHelpersViewModel.new(value: "test")
      assert view_model.respond_to?(:t)
      assert view_model.respond_to?(:translate)
    end

    test "helpers includes format helper methods" do
      view_model = WithHelpersViewModel.new(value: "test")
      assert view_model.respond_to?(:number_to_currency)
      assert view_model.respond_to?(:number_with_precision)
    end

    test "helpers raises ArgumentError for unknown helper" do
      error = assert_raises(ArgumentError) do
        Class.new(TypedViewModel::Base) do
          helpers :nonexistent_thing
        end
      end
      assert_match(/Unknown helper: nonexistent_thing/, error.message)
    end

    test "multiple helpers included at once" do
      view_model = FullViewModel.new(thing: Data.define(:name).new(name: "X"))
      assert view_model.respond_to?(:t)
      assert view_model.respond_to?(:number_to_currency)
      # PathHelpers uses method_missing so respond_to? for specific paths
      # is checked via respond_to_missing?
    end

    test "helper_namespaces is a Set so re-registering is idempotent" do
      ns = Module.new
      assert_kind_of ::Set, TypedViewModel.helper_namespaces

      before = TypedViewModel.helper_namespaces.size
      TypedViewModel.helper_namespaces << ns
      TypedViewModel.helper_namespaces << ns
      TypedViewModel.helper_namespaces << ns
      begin
        assert_equal before + 1, TypedViewModel.helper_namespaces.size,
          "registering the same namespace multiple times must not duplicate"
      ensure
        TypedViewModel.helper_namespaces.delete(ns)
      end
    end

    test "helpers DSL searches additional registered namespaces" do
      custom_ns = Module.new
      custom_ns.const_set(:CustomyHelpers, Module.new {
        def custom_method
          "custom!"
        end
      })

      TypedViewModel.helper_namespaces << custom_ns
      begin
        klass = Class.new(TypedViewModel::Base) do
          helpers :customy
        end
        instance = klass.new
        assert_equal "custom!", instance.custom_method
      ensure
        TypedViewModel.helper_namespaces.delete(custom_ns)
      end
    end

    test "helpers DSL resolves String-named namespaces via Object.const_get" do
      Object.const_set(:LazyHelperNamespaceForTest, Module.new {
        const_set(:LazyHelpers, Module.new {
          def lazy_method
            "lazy!"
          end
        })
      })

      TypedViewModel.helper_namespaces << "LazyHelperNamespaceForTest"
      begin
        klass = Class.new(TypedViewModel::Base) do
          helpers :lazy
        end
        assert_equal "lazy!", klass.new.lazy_method
      ensure
        TypedViewModel.helper_namespaces.delete("LazyHelperNamespaceForTest")
        Object.send(:remove_const, :LazyHelperNamespaceForTest)
      end
    end

    test "helpers DSL error message lists String-named namespaces" do
      TypedViewModel.helper_namespaces << "Some::Missing::Namespace"
      begin
        error = assert_raises(NameError) do
          Class.new(TypedViewModel::Base) { helpers :anything }
        end
        assert_match(/Some::Missing::Namespace/, error.message)
      ensure
        TypedViewModel.helper_namespaces.delete("Some::Missing::Namespace")
      end
    end

    # --- Tests for Literal::Data typed props ---

    test "props with correct types instantiate successfully" do
      view_model = TypedPropViewModel.new(name: "test")
      assert_equal "test", view_model.name
      assert_equal 0, view_model.count
    end

    test "props with defaults use default value when not provided" do
      view_model = FullViewModel.new(thing: Data.define(:name).new(name: "X"))
      assert_equal false, view_model.active
    end

    test "props with explicit value override default" do
      view_model = FullViewModel.new(thing: Data.define(:name).new(name: "X"), active: true)
      assert_equal true, view_model.active
    end

    test "typed prop rejects wrong type" do
      assert_raises(Literal::TypeError) do
        TypedPropViewModel.new(name: 123)
      end
    end

    test "missing required prop raises error" do
      assert_raises(ArgumentError) do
        TypedPropViewModel.new
      end
    end

    # --- Integration tests ---

    test "full view model with trait and helpers works end to end" do
      thing = Data.define(:name).new(name: "Widget")
      view_model = FullViewModel.new(thing: thing, active: true)

      assert_equal "Display: Widget", view_model.thing_display_name
      assert_equal true, view_model.active

      TypedViewModel.with_current_helpers(::ActionController::Base.helpers) do
        assert_includes view_model.number_to_currency(19.99), "19.99"
        assert_kind_of String, view_model.t("number.currency.format.unit")
      end
    end

    test "format helper raises a clear error when no current_helpers is set" do
      TypedViewModel.current_helpers = nil
      view_model = FullViewModel.new(thing: Data.define(:name).new(name: "X"))
      error = assert_raises(RuntimeError) { view_model.number_to_currency(1) }
      assert_match(/no helper context set/, error.message)
      assert_match(/ControllerHelpers/, error.message)
    end

    test "view model objects are frozen (immutable)" do
      view_model = TypedPropViewModel.new(name: "test")
      assert view_model.frozen?
    end

    # --- Tests for instance #helpers method (private — plumbing only) ---

    test "helpers instance method is private (DSL is the canonical interface)" do
      vm = TypedPropViewModel.new(name: "x")
      refute_includes vm.public_methods, :helpers
      assert_includes vm.private_methods, :helpers
    end

    # --- Tests for the public TypedViewModel.current_helpers API ---

    test "current_helpers reads back what current_helpers= wrote" do
      TypedViewModel.current_helpers = nil
      assert_nil TypedViewModel.current_helpers

      stash = Object.new
      TypedViewModel.current_helpers = stash
      begin
        assert_equal stash, TypedViewModel.current_helpers
      ensure
        TypedViewModel.current_helpers = nil
      end
    end

    test "current_helpers writes through to helpers_storage[HELPERS_STORAGE_KEY]" do
      TypedViewModel.current_helpers = nil
      stash = Object.new
      TypedViewModel.current_helpers = stash
      begin
        assert_equal stash, TypedViewModel.helpers_storage[TypedViewModel::HELPERS_STORAGE_KEY]
      ensure
        TypedViewModel.current_helpers = nil
      end
    end

    test "with_current_helpers sets, yields, then restores previous value" do
      TypedViewModel.current_helpers = nil
      previous = Object.new
      TypedViewModel.current_helpers = previous
      begin
        inner = Object.new
        captured = nil
        TypedViewModel.with_current_helpers(inner) do
          captured = TypedViewModel.current_helpers
        end
        assert_equal inner, captured
        assert_equal previous, TypedViewModel.current_helpers
      ensure
        TypedViewModel.current_helpers = nil
      end
    end

    test "with_current_helpers restores previous value when nothing was set" do
      TypedViewModel.current_helpers = nil
      inner = Object.new
      TypedViewModel.with_current_helpers(inner) do
        assert_equal inner, TypedViewModel.current_helpers
      end
      assert_nil TypedViewModel.current_helpers
    end

    test "with_current_helpers restores previous value when block raises" do
      TypedViewModel.current_helpers = nil
      previous = Object.new
      TypedViewModel.current_helpers = previous
      begin
        assert_raises(RuntimeError) do
          TypedViewModel.with_current_helpers(Object.new) do
            raise "boom"
          end
        end
        assert_equal previous, TypedViewModel.current_helpers
      ensure
        TypedViewModel.current_helpers = nil
      end
    end
  end
end
