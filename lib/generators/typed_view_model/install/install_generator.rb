# frozen_string_literal: true

require "rails/generators/base"

module TypedViewModel
  module Generators
    # Generates the application-level view model scaffolding so a host app
    # can extend the gem cleanly. Optional --with-job-view-context flag
    # creates a Concern that provides `view_context` for use in background
    # jobs (where there's no request); --[no-]active-storage controls
    # whether the JobViewContext concern handles ActiveStorage::Blob /
    # VariantWithRecord URLs.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :with_job_view_context,
        type: :boolean,
        default: false,
        desc: "Generate a JobViewContext concern for background-job view-model use"

      class_option :active_storage,
        type: :boolean,
        default: true,
        desc: "Include ActiveStorage::Blob/VariantWithRecord url_for handling in the JobViewContext concern"

      def create_application_view_model
        template "application_view_model.rb.tt", "app/lib/application_view_model.rb"
      end

      def create_job_view_context_concern
        return unless options[:with_job_view_context]
        template "job_view_context.rb.tt",
          "app/lib/application_view_model_concerns/job_view_context.rb"
      end

      def create_initializer
        template "initializer.rb.tt",
          "config/initializers/typed_view_model.rb"
      end

      private

      def active_storage?
        options[:active_storage]
      end

      def with_job_view_context?
        options[:with_job_view_context]
      end
    end
  end
end
