# frozen_string_literal: true

# Rails fragment caching works by either expecting the cached key object to respond to `cache_key` or for that object
# to be an array or hash. Here we add a default `cache_key` implementation for classes like presenters that opt in
# via `with_cache_key`.
module TypedViewModel
  module WithCacheKey
    extend ActiveSupport::Concern

    included do
      # Pre-allocate @cache_key BEFORE Literal::Data freezes the instance.
      # The Hash itself isn't frozen so per-key writes from `cache_key` work.
      # Calls super only when the host already defines after_initialize so we
      # don't error against Literal's default no-op (which doesn't define one).
      def after_initialize
        super if defined?(super)
        @cache_key = {}
      end
    end

    class_methods do
      def inherited(subclass)
        subclass.instance_variable_set(
          :@named_cache_key_attributes,
          @named_cache_key_attributes.clone
        )
        super
      end

      def with_cache_key(*, name: :_collection)
        named_cache_key_includes(name, *)
      end

      attr_reader :named_cache_key_attributes

      private

      def named_cache_key_includes(name, *attrs)
        define_cache_key_method unless @named_cache_key_attributes
        @named_cache_key_attributes ||= {}
        @named_cache_key_attributes[name] = attrs
      end

      def define_cache_key_method
        # If the presenter defines cache key setup then define the method. Otherwise Rails assumes this
        # will return a valid key if the class will respond to this
        define_method :cache_key do |n = :_collection|
          return @cache_key[n] if @cache_key.key?(n)
          generate_cache_key(n)
          @cache_key[n]
        end
      end
    end

    # instance methods
    def cacheable?
      respond_to? :cache_key
    end

    # Override in your view-model subclass to scope cache keys (e.g. by app-level
    # cache version, deploy ID, locale). Returning nil/empty means no modifier.
    def cache_key_modifier
      nil
    end

    def cache_keys_for_sources(key_attributes)
      sources = key_attributes.flat_map { |n| n.is_a?(Proc) ? instance_eval(&n) : send(n) }
      sources.compact.map do |item|
        next if item == self
        ::TypedViewModel::HashedKey.call(item)
      end
    end

    def generate_cache_key(index)
      key_attributes = self.class.named_cache_key_attributes[index]
      return nil unless key_attributes
      key = "#{self.class.name}/#{cache_keys_for_sources(key_attributes).join("/")}"
      if key.blank? || key == "#{self.class.name}/"
        raise ::TypedViewModel::CacheKeyError,
          "Cache key for `#{self.class.name}` (slot `#{index.inspect}`) is blank — source list resolved to no values"
      end
      @cache_key[index] = cache_key_modifier.present? ? "#{key}/#{cache_key_modifier}" : key
    end
  end
end
