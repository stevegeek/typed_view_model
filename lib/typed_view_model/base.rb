# frozen_string_literal: true

module TypedViewModel
  # Storage backend for the per-request view-context stash. Uses
  # ActiveSupport::IsolatedExecutionState when available (Rails 7+) so the
  # stash is fiber-safe and follows Rails' own request-isolation model.
  # Falls back to Thread.current otherwise.
  HELPERS_STORAGE_KEY = :typed_view_model_helpers

  def self.helpers_storage
    if defined?(::ActiveSupport::IsolatedExecutionState)
      ::ActiveSupport::IsolatedExecutionState
    else
      ::Thread.current
    end
  end

  # Base class for all view model objects
  # Provides common functionality and structure
  class Base < Literal::Data
    # Subclasses can use the helpers DSL to include helper modules:
    #   helpers :i18n, :paths, :format

    class << self
      # Use a trait module that provides model-specific presentation logic.
      # Records the trait so we can validate on first instantiation that
      # every prop the trait `requires` is declared on the host class.
      # Validation is deferred to `new` because the conventional pattern
      # is `use Foo` before `prop :bar` — class-define-time validation
      # would false-positive on every VM that follows that ordering.
      def use(trait_module)
        include trait_module

        if trait_module.respond_to?(:required_props) && trait_module.required_props.any?
          (@__used_traits_with_requires ||= []) << trait_module
        end
      end

      # Validates that every name a `use`d trait lists in `requires` is
      # available on the host class — either as a declared `prop` or as an
      # instance method. (The trait's runtime contract is "I will call `.foo`
      # on `self`"; the host can satisfy that with either form.) Idempotent
      # and cheap on warm classes — clears the pending list after the first
      # pass so subsequent `.new` calls are a single `defined?` check.
      def __validate_trait_requirements!
        return unless defined?(@__used_traits_with_requires)
        return if @__used_traits_with_requires.blank?
        declared = literal_properties.map { |p| p.name.to_sym }.to_set
        @__used_traits_with_requires.each do |trait_module|
          missing = trait_module.required_props.reject do |p|
            sym = p.to_sym
            declared.include?(sym) || method_defined?(sym) || private_method_defined?(sym)
          end
          next if missing.empty?
          raise ArgumentError,
            "TypedViewModel: trait `#{trait_module.name || trait_module.inspect}` " \
            "requires #{missing.inspect} on host class `#{name || inspect}` but neither " \
            "a declared `prop` nor an instance method matches. Add the missing prop/method " \
            "or remove the entry from the trait's `requires` declaration."
        end
        @__used_traits_with_requires = nil
      end

      def new(...)
        __validate_trait_requirements!
        super
      end

      # DSL for including helper modules.
      # Looks up `"#{Name}Helpers"` in each module listed in
      # `TypedViewModel.helper_namespaces`. Host apps can register their own
      # namespaces:
      #
      #   TypedViewModel.helper_namespaces << MyApp::ViewModelHelpers
      #
      # Usage:
      #   helpers :i18n, :path, :format
      def helpers(*names)
        names.each do |name|
          helper_class_name = "#{name.to_s.camelize}Helpers"
          helper_module = nil
          ::TypedViewModel.helper_namespaces.each do |ns|
            ns_module = resolve_helper_namespace(ns)
            next unless ns_module.const_defined?(helper_class_name, false)
            helper_module = ns_module.const_get(helper_class_name, false)
            break
          end
          unless helper_module
            searched = ::TypedViewModel.helper_namespaces.map { |ns| ns.is_a?(::String) ? ns : ns.name }.join(", ")
            raise ArgumentError,
              "Unknown helper: #{name}. Searched: #{searched}"
          end
          include helper_module
        end
      end

      private

      def resolve_helper_namespace(ns)
        return ns unless ns.is_a?(::String)
        ::Object.const_get(ns)
      rescue ::NameError => e
        raise ::NameError,
          "TypedViewModel: helper namespace `#{ns}` (registered as a String) " \
          "could not be resolved — #{e.message}. Make sure the constant is " \
          "loadable (e.g. via Zeitwerk autoload) by the time `helpers` is called."
      end

      public
    end

    private

    def helpers
      ::TypedViewModel.current_helpers ||
        raise("TypedViewModel: no helper context set. Include `TypedViewModel::ControllerHelpers` in your ApplicationController, or set `TypedViewModel.current_helpers` directly (e.g. in a job).")
    end
  end
end
