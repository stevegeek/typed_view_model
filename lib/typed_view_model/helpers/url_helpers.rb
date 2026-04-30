# frozen_string_literal: true

module TypedViewModel
  module Helpers
    # Provides access to Rails url_for helper in view model objects
    # Include this module when your view model needs to generate URLs for ActiveStorage attachments
    module UrlHelpers
      def url_for(source)
        Rails.application.routes.url_helpers.url_for(source)
      end
    end
  end
end
