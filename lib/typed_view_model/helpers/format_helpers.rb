# frozen_string_literal: true

module TypedViewModel
  module Helpers
    # Provides access to Rails formatting helpers in view model objects
    # Include this module when your view model needs number/currency/date formatting
    module FormatHelpers
      def number_to_currency(amount, options = {})
        helpers.number_to_currency(amount, options)
      end

      def number_with_precision(number, options = {})
        helpers.number_with_precision(number, options)
      end

      def number_to_percentage(number, options = {})
        helpers.number_to_percentage(number, options)
      end

      def number_with_delimiter(number, options = {})
        helpers.number_with_delimiter(number, options)
      end

      def number_to_human(number, options = {})
        helpers.number_to_human(number, options)
      end

      def number_to_human_size(number, options = {})
        helpers.number_to_human_size(number, options)
      end

      def number_to_phone(number, options = {})
        helpers.number_to_phone(number, options)
      end

      def distance_of_time_in_words(from_time, to_time = Time.current, options = {})
        helpers.distance_of_time_in_words(from_time, to_time, options)
      end

      def time_ago_in_words(time, options = {})
        helpers.time_ago_in_words(time, options)
      end
    end
  end
end
