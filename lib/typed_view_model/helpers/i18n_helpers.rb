# frozen_string_literal: true

module TypedViewModel
  module Helpers
    # Provides i18n helpers in view model objects
    # Include this module when your view model needs translations
    module I18nHelpers
      def t(key, **options)
        I18n.t(key, **options)
      end

      def l(object, **options)
        I18n.l(object, **options)
      end

      # Alias for consistency with Rails views
      alias_method :translate, :t
      alias_method :localize, :l
    end
  end
end
