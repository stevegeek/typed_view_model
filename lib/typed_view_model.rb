# frozen_string_literal: true

require "literal"
require "active_support"
require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "digest"

require "typed_view_model/version"

module TypedViewModel
  module Helpers
  end

  class << self
    # Set of namespaces searched by `Base.helpers(*names)`. Accepts Module
    # references or String constant names; Strings are resolved lazily so
    # Zeitwerk can autoload them.
    #
    #   TypedViewModel.helper_namespaces << MyApp::ViewModelHelpers
    #   TypedViewModel.helper_namespaces << "MyApp::ViewModelHelpers"
    def helper_namespaces
      @helper_namespaces ||= ::Set.new([TypedViewModel::Helpers])
    end

    def current_helpers
      helpers_storage[HELPERS_STORAGE_KEY]
    end

    def current_helpers=(value)
      helpers_storage[HELPERS_STORAGE_KEY] = value
    end

    def with_current_helpers(value)
      previous = current_helpers
      self.current_helpers = value
      yield
    ensure
      self.current_helpers = previous
    end
  end
end

require "typed_view_model/trait"
require "typed_view_model/helpers/format_helpers"
require "typed_view_model/helpers/i18n_helpers"
require "typed_view_model/helpers/path_helpers"
require "typed_view_model/helpers/tag_helpers"
require "typed_view_model/helpers/text_helpers"
require "typed_view_model/helpers/link_helpers"
require "typed_view_model/helpers/url_helpers"
require "typed_view_model/base"
require "typed_view_model/controller_helpers"
require "typed_view_model/job_helpers"
require "typed_view_model/hashed_key"
require "typed_view_model/cache_key_error"
require "typed_view_model/with_cache_key"
