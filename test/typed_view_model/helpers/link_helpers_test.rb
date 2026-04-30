# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  module Helpers
    class LinkHelpersTest < ActiveSupport::TestCase
      class LinkHelpersHost
        include TypedViewModel::Helpers::LinkHelpers

        def helpers
          ActionController::Base.helpers
        end
      end

      class LinkHelpersVM < TypedViewModel::Base
        helpers :link
      end

      setup do
        @host = LinkHelpersHost.new
      end

      test "link_to renders an anchor with name and href" do
        assert_equal "<a href=\"/widgets\">Widgets</a>", @host.link_to("Widgets", "/widgets")
      end

      test "link_to accepts html_options" do
        assert_equal "<a class=\"btn\" href=\"/x\">x</a>", @host.link_to("x", "/x", class: "btn")
      end

      test "link_to accepts a block for the body" do
        result = @host.link_to("/x") { "body" }
        assert_equal "<a href=\"/x\">body</a>", result
      end

      test "mail_to renders a mailto anchor" do
        assert_equal "<a href=\"mailto:a@b.com\">a@b.com</a>", @host.mail_to("a@b.com")
      end

      test "mail_to with name uses name as the body" do
        assert_equal "<a href=\"mailto:a@b.com\">Email</a>", @host.mail_to("a@b.com", "Email")
      end

      test "phone_to renders a tel anchor" do
        assert_equal "<a href=\"tel:5551234\">5551234</a>", @host.phone_to("5551234")
      end

      test "sms_to renders an sms anchor" do
        assert_equal "<a href=\"sms:5551234;\">5551234</a>", @host.sms_to("5551234")
      end

      test "helpers :link resolves and includes LinkHelpers on a VM" do
        assert LinkHelpersVM.include?(TypedViewModel::Helpers::LinkHelpers)
      end

      test "LinkHelpers exposes current_page?" do
        assert TypedViewModel::Helpers::LinkHelpers.instance_method(:current_page?)
      end

      test "VM with helpers :link can call link_to when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = LinkHelpersVM.new
          assert_equal "<a href=\"/x\">x</a>", vm.send(:link_to, "x", "/x")
        end
      end

      test "VM with helpers :link can call mail_to when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = LinkHelpersVM.new
          assert_equal "<a href=\"mailto:a@b.com\">a@b.com</a>", vm.send(:mail_to, "a@b.com")
        end
      end

      test "VM with helpers :link raises when current_helpers is unset" do
        TypedViewModel.current_helpers = nil
        vm = LinkHelpersVM.new
        assert_raises(RuntimeError) { vm.send(:link_to, "x", "/x") }
      end
    end
  end
end
