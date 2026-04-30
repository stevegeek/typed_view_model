# frozen_string_literal: true

module TypedViewModel
  module Helpers
    # Provides access to Rails path/URL helpers in view model objects
    # Include this module when your view model needs to generate paths or URLs
    module PathHelpers
      # Access to Rails route helpers
      def url_helpers
        Rails.application.routes.url_helpers
      end

      # Delegate path/url methods to url_helpers
      private

      def method_missing(method_name, *args, **kwargs, &block)
        if method_name.to_s.end_with?("_path", "_url") && url_helpers.respond_to?(method_name)
          url_helpers.public_send(method_name, *args, **kwargs, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        (method_name.to_s.end_with?("_path", "_url") && url_helpers.respond_to?(method_name)) || super
      end
    end
  end
end
