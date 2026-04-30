# frozen_string_literal: true

module TypedViewModel
  # Job-side wiring. Mirrors `ControllerHelpers`: wraps each `perform`
  # in `with_current_helpers(view_context) { yield }` so any view model
  # rendered inside the job can call `helpers` and resolve URL/format/i18n
  # helpers without a request.
  #
  #   class ApplicationJob < ActiveJob::Base
  #     include TypedViewModel::JobHelpers
  #   end
  #
  # The view-context shim is a minimal class that mixes in
  # `Rails.application.routes.url_helpers` and stubs `url_for` to `"#"`.
  # Override `build_view_context_class` to compose extra behaviour; call
  # `super` and wrap the returned class.
  module JobHelpers
    extend ::ActiveSupport::Concern

    included do
      around_perform :_typed_view_model_stash_view_context
    end

    private

    def _typed_view_model_stash_view_context(&block)
      ::TypedViewModel.with_current_helpers(_typed_view_model_view_context, &block)
    end

    def _typed_view_model_view_context
      @_typed_view_model_view_context ||= build_view_context_class.new
    end

    def build_view_context_class
      ::Class.new do
        include ::Rails.application.routes.url_helpers

        def default_url_options
          ::Rails.application.config.action_mailer.default_url_options
        end

        def url_for(options = nil)
          "#"
        end
      end
    end
  end
end

require "typed_view_model/job_helpers/active_storage_urls"
