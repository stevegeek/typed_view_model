# frozen_string_literal: true

module TypedViewModel
  module Helpers
    module TextHelpers
      def truncate(text, options = {}, &block)
        helpers.truncate(text, options, &block)
      end

      def pluralize(count, singular, plural_arg = nil, plural: plural_arg, locale: ::I18n.locale)
        helpers.pluralize(count, singular, plural_arg, plural: plural, locale: locale)
      end

      def simple_format(text, html_options = {}, options = {})
        helpers.simple_format(text, html_options, options)
      end

      def excerpt(text, phrase, options = {})
        helpers.excerpt(text, phrase, options)
      end

      def highlight(text, phrases, options = {}, &block)
        helpers.highlight(text, phrases, options, &block)
      end

      def word_wrap(text, line_width: 80, break_sequence: "\n")
        helpers.word_wrap(text, line_width: line_width, break_sequence: break_sequence)
      end

      def dom_class(record_or_class, prefix = nil)
        helpers.dom_class(record_or_class, prefix)
      end

      def dom_id(record_or_class, prefix = nil)
        helpers.dom_id(record_or_class, prefix)
      end

      def class_names(*args)
        helpers.class_names(*args)
      end

      def token_list(*args)
        helpers.token_list(*args)
      end
    end
  end
end
