# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  module Helpers
    class UrlHelpersTest < ActiveSupport::TestCase
      class UrlHelpersHost
        include TypedViewModel::Helpers::UrlHelpers
      end

      setup do
        @host = UrlHelpersHost.new
      end

      test "url_for delegates to Rails route url_helpers" do
        assert @host.respond_to?(:url_for)
      end

      test "url_for with a string returns the string" do
        result = @host.url_for("/test/path")
        assert_equal "/test/path", result
      end
    end
  end
end
