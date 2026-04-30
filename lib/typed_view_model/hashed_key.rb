# frozen_string_literal: true

module TypedViewModel
  module HashedKey
    def self.call(item)
      if item.respond_to? :cache_key_with_version
        # ActiveRecord
        item.cache_key_with_version
      elsif item.respond_to? :cache_key
        # Presenters, ViewComponent etc
        item.cache_key
      elsif item.is_a?(String)
        ::Digest::SHA1.hexdigest(item)
      else
        # Anything else
        ::Digest::SHA1.hexdigest(::Marshal.dump(item))
      end
    end
  end
end
