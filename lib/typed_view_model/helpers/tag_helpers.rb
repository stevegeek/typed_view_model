# frozen_string_literal: true

module TypedViewModel
  module Helpers
    module TagHelpers
      def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
        helpers.content_tag(name, content_or_options_with_block, options, escape, &block)
      end

      def sanitize(html, options = {})
        helpers.sanitize(html, options)
      end

      def safe_join(array, sep = $,)
        helpers.safe_join(array, sep)
      end

      def tag(*args, **opts, &block)
        helpers.tag(*args, **opts, &block)
      end
    end
  end
end
