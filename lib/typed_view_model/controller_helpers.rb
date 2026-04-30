# frozen_string_literal: true

module TypedViewModel
  module ControllerHelpers
    extend ::ActiveSupport::Concern

    included do
      around_action :_typed_view_model_stash_view_context
    end

    private

    def _typed_view_model_stash_view_context
      ::TypedViewModel.with_current_helpers(view_context) { yield }
    end
  end
end
