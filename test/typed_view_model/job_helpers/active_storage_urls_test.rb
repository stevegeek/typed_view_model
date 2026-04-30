# frozen_string_literal: true

require "test_helper"

# Minimal stand-ins for the ActiveStorage classes the concern dispatches on.
# Real ActiveStorage is not loaded in the test suite — the concern only
# references these constants at call time, so test doubles work as long as
# they answer the same question (`#url`, `#blob`).
unless defined?(::ActiveStorage)
  module ActiveStorage
    class Blob
      def initialize(url)
        @url = url
      end
      attr_reader :url
    end

    class VariantWithRecord
      def initialize(blob)
        @blob = blob
      end
      attr_reader :blob
    end
  end
end

module TypedViewModel
  module JobHelpers
    class ActiveStorageUrlsTest < ActiveSupport::TestCase
      class StubJob
        def self.around_perform(*)
        end

        include ::TypedViewModel::JobHelpers
        include ::TypedViewModel::JobHelpers::ActiveStorageUrls

        def view_context
          _typed_view_model_view_context
        end
      end

      test "url_for(blob) returns the blob's url" do
        blob = ::ActiveStorage::Blob.new("https://cdn.example/blob.png")
        assert_equal "https://cdn.example/blob.png", StubJob.new.view_context.url_for(blob)
      end

      test "url_for(variant_with_record) returns the underlying blob's url" do
        blob = ::ActiveStorage::Blob.new("https://cdn.example/variant.png")
        variant = ::ActiveStorage::VariantWithRecord.new(blob)
        assert_equal "https://cdn.example/variant.png", StubJob.new.view_context.url_for(variant)
      end

      test "url_for falls through to parent shim for non-ActiveStorage args" do
        assert_equal "#", StubJob.new.view_context.url_for(Object.new)
      end

      test "url_for falls through to parent shim for nil" do
        assert_equal "#", StubJob.new.view_context.url_for
      end
    end
  end
end
