# frozen_string_literal: true

module TypedViewModel
  module Helpers
    module LinkHelpers
      def link_to(name = nil, options = nil, html_options = nil, &block)
        helpers.link_to(name, options, html_options, &block)
      end

      def mail_to(email_address, name = nil, html_options = {}, &block)
        helpers.mail_to(email_address, name, html_options, &block)
      end

      def phone_to(phone_number, name = nil, html_options = {}, &block)
        helpers.phone_to(phone_number, name, html_options, &block)
      end

      def sms_to(phone_number, name = nil, html_options = {}, &block)
        helpers.sms_to(phone_number, name, html_options, &block)
      end

      def current_page?(options = nil, check_parameters: false, **options_kwargs)
        helpers.current_page?(options, check_parameters: check_parameters, **options_kwargs)
      end
    end
  end
end
