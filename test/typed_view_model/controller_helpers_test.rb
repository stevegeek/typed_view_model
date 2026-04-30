# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  class ControllerHelpersTest < ActiveSupport::TestCase
    # Stub controller-like host that satisfies the concern's `around_action`
    # call at include-time (no-op) so we can exercise the
    # `_typed_view_model_stash_view_context` wrapper directly. Real Rails
    # controllers wire it through ActiveSupport::Callbacks; that part is
    # standard Rails plumbing and not the gem's concern.
    class StubController
      def self.around_action(*)
      end

      include ::TypedViewModel::ControllerHelpers

      attr_accessor :view_context

      def stash(&block)
        _typed_view_model_stash_view_context(&block)
      end
    end

    test "_typed_view_model_stash_view_context sets current_helpers to view_context inside the block" do
      TypedViewModel.current_helpers = nil
      ctrl = StubController.new
      ctrl.view_context = Object.new

      captured = nil
      ctrl.stash { captured = TypedViewModel.current_helpers }

      assert_equal ctrl.view_context, captured
    ensure
      TypedViewModel.current_helpers = nil
    end

    test "_typed_view_model_stash_view_context restores previous value after the block" do
      TypedViewModel.current_helpers = nil
      previous = Object.new
      TypedViewModel.current_helpers = previous

      ctrl = StubController.new
      ctrl.view_context = Object.new
      ctrl.stash {}

      assert_equal previous, TypedViewModel.current_helpers
    ensure
      TypedViewModel.current_helpers = nil
    end

    test "_typed_view_model_stash_view_context restores previous value when block raises" do
      TypedViewModel.current_helpers = nil
      previous = Object.new
      TypedViewModel.current_helpers = previous

      ctrl = StubController.new
      ctrl.view_context = Object.new

      assert_raises(RuntimeError) do
        ctrl.stash { raise "boom" }
      end

      assert_equal previous, TypedViewModel.current_helpers
    ensure
      TypedViewModel.current_helpers = nil
    end
  end
end
