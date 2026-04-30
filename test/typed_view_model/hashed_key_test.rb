# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  class HashedKeyTest < ActiveSupport::TestCase
    # Stand-in for an ActiveRecord instance: responds to cache_key_with_version.
    class FakeRecord
      def cache_key_with_version
        "admins/42-20250101000000"
      end
    end

    # Stand-in for a presenter / view component that responds to cache_key.
    class FakePresenter
      def cache_key
        "/86f7e437faa5a7fce15d1ddcb9eaeaea377667b8"
      end
    end

    setup do
      @record = FakeRecord.new
      @presenter = FakePresenter.new
    end

    test "generates a key from an active-record-like instance via cache_key_with_version" do
      assert_match(/^admins\//, HashedKey.call(@record))
    end

    test "generates a key from an object responding to cache_key" do
      assert_equal "/86f7e437faa5a7fce15d1ddcb9eaeaea377667b8", HashedKey.call(@presenter)
    end

    test "generates a key from an array" do
      assert_equal "59d2728452ee6cb3214f5b0deafd86214a2c6ddb", HashedKey.call([1, 2, 3])
    end

    test "generates a key from a hash" do
      assert_equal "58df4c0192c6a26f9921bba82704457b9e40e755", HashedKey.call(a: 1, b: 2)
    end

    test "generates a key from a string" do
      assert_equal "dda58a50939583b3c85b4a980653063ea18aa71e", HashedKey.call("dlkjw")
    end
  end
end
