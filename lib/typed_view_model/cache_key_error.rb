# frozen_string_literal: true

module TypedViewModel
  # Raised by WithCacheKey when a cache key cannot be generated (e.g. all
  # source attributes resolved to nil). Lets consumers `rescue` precisely
  # rather than catching every StandardError.
  class CacheKeyError < ::StandardError
  end
end
