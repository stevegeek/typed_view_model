# frozen_string_literal: true

module TypedViewModel
  module JobHelpers
    # Opt-in extension for hosts using ActiveStorage. Decorates the shim
    # view-context's `url_for` to return real URLs for `ActiveStorage::Blob`
    # and `ActiveStorage::VariantWithRecord` arguments; everything else
    # falls through to the parent shim's `url_for`.
    #
    #   class ApplicationJob < ActiveJob::Base
    #     include TypedViewModel::JobHelpers
    #     include TypedViewModel::JobHelpers::ActiveStorageUrls
    #   end
    #
    # The `::ActiveStorage::*` constants are referenced inside the override
    # at call time, so the file is safe to load even when ActiveStorage is
    # not in the host Gemfile — but including this module without
    # ActiveStorage installed will raise `NameError` on first job run.
    module ActiveStorageUrls
      extend ::ActiveSupport::Concern

      private

      def build_view_context_class
        ::Class.new(super) do
          def url_for(options = nil)
            case options
            when ::ActiveStorage::Blob
              options.url
            when ::ActiveStorage::VariantWithRecord
              options.blob.url
            else
              super
            end
          end
        end
      end
    end
  end
end
