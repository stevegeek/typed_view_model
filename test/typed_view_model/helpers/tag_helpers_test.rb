# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  module Helpers
    class TagHelpersTest < ActiveSupport::TestCase
      class TagHelpersHost
        include TypedViewModel::Helpers::TagHelpers

        def helpers
          ActionController::Base.helpers
        end
      end

      class TagHelpersVM < TypedViewModel::Base
        helpers :tag
      end

      setup do
        @host = TagHelpersHost.new
      end

      test "content_tag wraps content in the given tag" do
        result = @host.content_tag(:p, "hello")
        assert_equal "<p>hello</p>", result
      end

      test "content_tag accepts options" do
        result = @host.content_tag(:p, "hello", class: "x")
        assert_equal "<p class=\"x\">hello</p>", result
      end

      test "content_tag accepts a block" do
        result = @host.content_tag(:div) { "inside" }
        assert_equal "<div>inside</div>", result
      end

      test "sanitize strips disallowed tags" do
        result = @host.sanitize("<p>kept</p><script>alert('x')</script>")
        assert_equal "<p>kept</p>alert('x')", result
      end

      test "safe_join joins an array with a separator" do
        result = @host.safe_join(["a", "b"], ", ")
        assert_equal "a, b", result
      end

      test "tag emits a self-closing tag" do
        result = @host.tag.br
        assert_equal "<br>", result
      end

      test "helpers :tag resolves and includes TagHelpers on a VM" do
        assert TagHelpersVM.include?(TypedViewModel::Helpers::TagHelpers)
      end

      test "VM with helpers :tag can call content_tag when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = TagHelpersVM.new
          assert_equal "<p>x</p>", vm.send(:content_tag, :p, "x")
        end
      end

      test "VM with helpers :tag raises when current_helpers is unset" do
        TypedViewModel.current_helpers = nil
        vm = TagHelpersVM.new
        assert_raises(RuntimeError) { vm.send(:content_tag, :p, "x") }
      end
    end
  end
end
