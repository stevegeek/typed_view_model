# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  module Helpers
    class FormatHelpersTest < ActiveSupport::TestCase
      class FormatHelpersHost
        include TypedViewModel::Helpers::FormatHelpers

        def helpers
          ActionController::Base.helpers
        end
      end

      setup do
        @host = FormatHelpersHost.new
      end

      test "helpers returns ActionController::Base.helpers" do
        assert_equal ActionController::Base.helpers, @host.helpers
      end

      test "helpers returns consistent object" do
        first_call = @host.helpers
        second_call = @host.helpers
        assert_equal first_call, second_call
      end

      test "number_to_currency formats a number as currency" do
        result = @host.number_to_currency(1234.56)
        assert_equal "$1,234.56", result
      end

      test "number_to_currency accepts options" do
        result = @host.number_to_currency(1234.56, unit: "£", precision: 0)
        assert_equal "£1,235", result
      end

      test "number_with_precision formats number with decimal places" do
        result = @host.number_with_precision(3.14159, precision: 2)
        assert_equal "3.14", result
      end

      test "number_to_percentage formats number as percentage" do
        result = @host.number_to_percentage(85.5)
        assert_equal "85.500%", result
      end

      test "number_to_percentage accepts precision option" do
        result = @host.number_to_percentage(85.5, precision: 0)
        assert_equal "86%", result
      end

      test "number_with_delimiter adds delimiter to number" do
        result = @host.number_with_delimiter(1234567)
        assert_equal "1,234,567", result
      end

      test "distance_of_time_in_words describes time difference" do
        from = Time.current
        to = from + 2.hours
        result = @host.distance_of_time_in_words(from, to)
        assert_equal "about 2 hours", result
      end

      test "distance_of_time_in_words uses Time.current as default to_time" do
        from = 30.minutes.ago
        result = @host.distance_of_time_in_words(from)
        assert_match(/30 minutes/, result)
      end

      test "time_ago_in_words describes time elapsed" do
        time = 3.days.ago
        result = @host.time_ago_in_words(time)
        assert_equal "3 days", result
      end

      test "number_to_human formats large numbers in human-readable form" do
        result = @host.number_to_human(1_234_000)
        assert_equal "1.23 Million", result
      end

      test "number_to_human accepts precision option" do
        result = @host.number_to_human(1_234_000, precision: 4)
        assert_equal "1.234 Million", result
      end

      test "number_to_human_size formats byte counts" do
        result = @host.number_to_human_size(1024)
        assert_equal "1 KB", result
      end

      test "number_to_human_size accepts precision option" do
        result = @host.number_to_human_size(1_500_000, precision: 2)
        assert_equal "1.4 MB", result
      end

      test "number_to_phone formats a phone number" do
        result = @host.number_to_phone(1235551234)
        assert_equal "123-555-1234", result
      end

      test "number_to_phone accepts area_code option" do
        result = @host.number_to_phone(1235551234, area_code: true)
        assert_equal "(123) 555-1234", result
      end
    end

    class I18nHelpersTest < ActiveSupport::TestCase
      class I18nHelpersHost
        include TypedViewModel::Helpers::I18nHelpers
      end

      setup do
        @host = I18nHelpersHost.new
      end

      test "t delegates to I18n.t" do
        expected = I18n.t("activerecord.errors.messages.blank")
        result = @host.t("activerecord.errors.messages.blank")
        assert_equal expected, result
      end

      test "t passes options through to I18n.t" do
        result = @host.t("nonexistent.key", default: "fallback value")
        assert_equal "fallback value", result
      end

      test "l delegates to I18n.l for Date" do
        date = Date.new(2025, 6, 15)
        expected = I18n.l(date)
        result = @host.l(date)
        assert_equal expected, result
      end

      test "l delegates to I18n.l for Time" do
        time = Time.utc(2025, 6, 15, 10, 30, 0)
        expected = I18n.l(time)
        result = @host.l(time)
        assert_equal expected, result
      end

      test "l accepts format option" do
        date = Date.new(2025, 6, 15)
        expected = I18n.l(date, format: :short)
        result = @host.l(date, format: :short)
        assert_equal expected, result
      end

      test "translate is an alias for t" do
        expected = @host.t("activerecord.errors.messages.blank")
        result = @host.translate("activerecord.errors.messages.blank")
        assert_equal expected, result
      end

      test "localize is an alias for l" do
        date = Date.new(2025, 6, 15)
        expected = @host.l(date)
        result = @host.localize(date)
        assert_equal expected, result
      end
    end

    class PathHelpersTest < ActiveSupport::TestCase
      class PathHelpersHost
        include TypedViewModel::Helpers::PathHelpers
      end

      setup do
        @host = PathHelpersHost.new
      end

      test "url_helpers returns Rails route helpers module" do
        assert_equal Rails.application.routes.url_helpers, @host.url_helpers
      end

      test "methods ending in _path are delegated to url_helpers" do
        result = @host.send(:root_path)
        expected = Rails.application.routes.url_helpers.root_path
        assert_equal expected, result
      end

      test "methods ending in _url are delegated to url_helpers" do
        result = @host.send(:root_url, host: "example.com")
        expected = Rails.application.routes.url_helpers.root_url(host: "example.com")
        assert_equal expected, result
      end

      test "non-path/url methods raise NoMethodError" do
        assert_raises(NoMethodError) do
          @host.send(:some_random_method)
        end
      end

      test "path methods that do not exist on url_helpers raise NoMethodError" do
        assert_raises(NoMethodError) do
          @host.send(:nonexistent_fake_thing_path)
        end
      end

      test "respond_to_missing? returns true for existing path methods" do
        assert @host.respond_to?(:root_path, true)
      end

      test "respond_to_missing? returns true for existing url methods" do
        assert @host.respond_to?(:root_url, true)
      end

      test "respond_to_missing? returns false for non-path/url methods" do
        refute @host.respond_to?(:some_random_method, true)
      end

      test "respond_to_missing? returns false for path methods that do not exist on url_helpers" do
        refute @host.respond_to?(:nonexistent_fake_thing_path, true)
      end

      test "path methods are accessible via method_missing dispatch" do
        # Even though method_missing is declared private, calling root_path
        # still works because method_missing intercepts it
        result = @host.root_path
        expected = Rails.application.routes.url_helpers.root_path
        assert_equal expected, result
      end
    end
  end
end
