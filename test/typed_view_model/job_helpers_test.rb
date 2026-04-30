# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  class JobHelpersTest < ActiveSupport::TestCase
    # Stub job-like host that satisfies the concern's `around_perform`
    # call at include-time (no-op) so we can exercise the wrapper directly.
    class StubJob
      def self.around_perform(*)
      end

      include ::TypedViewModel::JobHelpers

      def stash(&block)
        _typed_view_model_stash_view_context(&block)
      end

      def view_context
        _typed_view_model_view_context
      end
    end

    test "_typed_view_model_stash_view_context sets current_helpers to the shim view-context inside the block" do
      TypedViewModel.current_helpers = nil
      job = StubJob.new

      captured = nil
      job.stash { captured = TypedViewModel.current_helpers }

      assert_same job.view_context, captured
    ensure
      TypedViewModel.current_helpers = nil
    end

    test "_typed_view_model_stash_view_context restores previous value after the block" do
      TypedViewModel.current_helpers = nil
      previous = Object.new
      TypedViewModel.current_helpers = previous

      StubJob.new.stash {}

      assert_equal previous, TypedViewModel.current_helpers
    ensure
      TypedViewModel.current_helpers = nil
    end

    test "_typed_view_model_stash_view_context restores previous value when block raises" do
      TypedViewModel.current_helpers = nil
      previous = Object.new
      TypedViewModel.current_helpers = previous

      assert_raises(RuntimeError) do
        StubJob.new.stash { raise "boom" }
      end

      assert_equal previous, TypedViewModel.current_helpers
    ensure
      TypedViewModel.current_helpers = nil
    end

    test "view-context is memoised per job instance" do
      job = StubJob.new
      assert_same job.view_context, job.view_context
    end

    test "different job instances get distinct view-contexts" do
      refute_same StubJob.new.view_context, StubJob.new.view_context
    end

    test "default url_for returns '#'" do
      assert_equal "#", StubJob.new.view_context.url_for(Object.new)
    end

    test "default url_for handles a nil argument" do
      assert_equal "#", StubJob.new.view_context.url_for
    end

    test "build_view_context_class is overridable; subclass receives wrapped class" do
      subclass = Class.new(StubJob) do
        def build_view_context_class
          ::Class.new(super) do
            def url_for(options = nil)
              "custom:#{options.inspect}"
            end
          end
        end
      end

      assert_equal "custom:42", subclass.new.view_context.url_for(42)
    end
  end
end
