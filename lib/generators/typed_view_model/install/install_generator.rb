# frozen_string_literal: true

require "rails/generators/base"

module TypedViewModel
  module Generators
    # Generates the application-level view model scaffolding so a host app
    # can extend the gem cleanly. Background-job rendering is wired up by
    # the host directly: `include TypedViewModel::JobHelpers` in
    # `ApplicationJob`, and optionally
    # `include TypedViewModel::JobHelpers::ActiveStorageUrls` if the app
    # uses ActiveStorage.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_application_view_model
        template "application_view_model.rb.tt", "app/lib/application_view_model.rb"
      end

      def create_initializer
        template "initializer.rb.tt",
          "config/initializers/typed_view_model.rb"
      end
    end
  end
end
