# frozen_string_literal: true

require "test_helper"

module TypedViewModel
  module Helpers
    class TextHelpersTest < ActiveSupport::TestCase
      class TextHelpersHost
        include TypedViewModel::Helpers::TextHelpers

        def helpers
          ActionController::Base.helpers
        end
      end

      class TextHelpersVM < TypedViewModel::Base
        helpers :text
      end

      DomModelName = Data.define(:singular, :param_key) do
        def initialize(singular:, param_key: singular)
          super
        end
      end

      DomTarget = Data.define(:id) do
        def to_key
          [id]
        end

        def model_name
          DomModelName.new(singular: "widget")
        end

        def persisted?
          true
        end
      end

      setup do
        @host = TextHelpersHost.new
      end

      test "truncate shortens text to the requested length" do
        result = @host.truncate("hello world", length: 8)
        assert_equal "hello...", result
      end

      test "pluralize formats count with singular/plural" do
        assert_equal "1 post", @host.pluralize(1, "post")
        assert_equal "2 posts", @host.pluralize(2, "post")
      end

      test "pluralize accepts an explicit plural" do
        assert_equal "2 octopi", @host.pluralize(2, "octopus", "octopi")
      end

      test "simple_format wraps text in paragraph tags" do
        result = @host.simple_format("a\n\nb")
        assert_equal "<p>a</p>\n\n<p>b</p>", result
      end

      test "excerpt extracts a fragment around a phrase" do
        result = @host.excerpt("this is a long sentence", "long", radius: 2)
        assert_equal "...a long s...", result
      end

      test "highlight wraps phrase in mark tags" do
        result = @host.highlight("hello world", "world")
        assert_equal "hello <mark>world</mark>", result
      end

      test "word_wrap breaks long lines at line_width" do
        result = @host.word_wrap("one two three", line_width: 5)
        assert_equal "one\ntwo\nthree", result
      end

      test "dom_id returns a record-scoped DOM id" do
        record = DomTarget.new(id: 42)
        assert_equal "widget_42", @host.dom_id(record)
      end

      test "dom_class returns a record-scoped DOM class" do
        record = DomTarget.new(id: 42)
        assert_equal "widget", @host.dom_class(record)
      end

      test "class_names compacts truthy class names" do
        result = @host.class_names("a", {"b" => true, "c" => false})
        assert_equal "a b", result
      end

      test "token_list compacts truthy tokens" do
        result = @host.token_list("a", {"b" => true, "c" => false})
        assert_equal "a b", result
      end

      test "helpers :text resolves and includes TextHelpers on a VM" do
        assert TextHelpersVM.include?(TypedViewModel::Helpers::TextHelpers)
      end

      test "VM with helpers :text can call truncate when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = TextHelpersVM.new
          assert_equal "hello...", vm.send(:truncate, "hello world", length: 8)
        end
      end

      test "VM with helpers :text can call pluralize when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = TextHelpersVM.new
          assert_equal "1 post", vm.send(:pluralize, 1, "post")
        end
      end

      test "VM with helpers :text can call dom_id when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = TextHelpersVM.new
          record = DomTarget.new(id: 7)
          assert_equal "widget_7", vm.send(:dom_id, record)
        end
      end

      test "VM with helpers :text can call class_names when current_helpers is set" do
        TypedViewModel.with_current_helpers(ActionController::Base.helpers) do
          vm = TextHelpersVM.new
          assert_equal "a b", vm.send(:class_names, "a", {"b" => true, "c" => false})
        end
      end

      test "VM with helpers :text raises when current_helpers is unset" do
        TypedViewModel.current_helpers = nil
        vm = TextHelpersVM.new
        assert_raises(RuntimeError) { vm.send(:truncate, "x", length: 1) }
      end
    end
  end
end
