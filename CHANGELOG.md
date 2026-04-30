# Changelog

## [1.0.0]

First release. Initial public extraction.

- `TypedViewModel::Base` — `Literal::Data` subclass with `use` (trait composition) and `helpers` (helper-module mixin) DSL. `helpers` searches `TypedViewModel.helper_namespaces`, which accepts Module references or String constant names (resolved lazily via `Object.const_get` so Zeitwerk autoload works from initializers).
- `TypedViewModel::Trait` — module-level DSL for declaring required props with introspection. `Base.use` validates on first instantiation that every name a trait `requires` is available on the host (as a declared `prop` or instance method).
- `TypedViewModel::WithCacheKey` — fragment-cache key generator (`with_cache_key :attrs, name: :slot`) with overridable `cache_key_modifier`. Pre-allocates its memo hash via `after_initialize` so it works on Literal::Data-frozen instances.
- `TypedViewModel::CacheKeyError` — typed exception raised by `WithCacheKey` when source attributes resolve to no values.
- `TypedViewModel::HashedKey` — module providing generic cache-key hashing for ActiveRecord records, presenters, strings, and arbitrary objects.
- Helper modules opt-in via `helpers :name`:
  - `:i18n` — `I18nHelpers` (`t`, `translate`, `l`, `localize`)
  - `:format` — `FormatHelpers` (`number_to_currency`, `number_with_precision`, `number_to_percentage`, `number_with_delimiter`, `number_to_human`, `number_to_human_size`, `number_to_phone`, `distance_of_time_in_words`, `time_ago_in_words`)
  - `:path` — `PathHelpers` (any `*_path` / `*_url` via `method_missing`)
  - `:url` — `UrlHelpers` (`url_for` for ActiveStorage attachments)
  - `:tag` — `TagHelpers` (`content_tag`, `tag`, `sanitize`, `safe_join`)
  - `:text` — `TextHelpers` (`truncate`, `pluralize`, `simple_format`, `excerpt`, `highlight`, `word_wrap`, `dom_class`, `dom_id`, `class_names`, `token_list`)
  - `:link` — `LinkHelpers` (`link_to`, `mail_to`, `phone_to`, `sms_to`, `current_page?`)
- `TypedViewModel::TestSupport::{MockObject, TraitTestHarness, TraitTestHelpers}` — trait testing without ActiveRecord.
- Per-request view-context stash via `TypedViewModel.current_helpers` / `with_current_helpers(value) { ... }` and the `TypedViewModel::ControllerHelpers` concern (an `around_action` that wraps each request). Fiber-safe via `ActiveSupport::IsolatedExecutionState`.
- `TypedViewModel::JobHelpers` — opt-in `around_perform` concern mirroring `ControllerHelpers` for background jobs. Wraps `perform` in `with_current_helpers(shim) { ... }`. `build_view_context_class` is the override hook. No `activejob` runtime dependency.
- `TypedViewModel::JobHelpers::ActiveStorageUrls` — opt-in extension that decorates the shim's `url_for` to handle `ActiveStorage::Blob` and `ActiveStorage::VariantWithRecord`. No `activestorage` runtime dependency.
- `rails g typed_view_model:install` generator scaffolds `ApplicationViewModel` and a stub initializer.

Hard runtime dependencies: `literal`, `activesupport`, `actionpack`.
