# `typed_view_model`

Typed, immutable Rails view-model objects on top of `Literal::Data`, with composable presentation traits.

---

## What it provides

Typed, frozen view-model objects on top of `Literal::Data` for Rails apps. Adds a helper-mixin DSL (`helpers :i18n, :path, …`), a `Trait` module system for sharing presentation logic across view-models, fragment-cache key generation (`WithCacheKey`), and a generated host-app shim that makes view-models usable from `ActiveJob`. Instances are unit-testable in isolation — no controller, request, or view context required.

---

## Installation

```ruby
# Gemfile
gem "typed_view_model"
```

```bash
bundle install
```

Requires Rails ≥ 7.0 and Ruby ≥ 3.2. Hard runtime dependencies: `literal`, `activesupport`, `actionpack`.

After bundling, scaffold the host-app integration:

```bash
bin/rails generate typed_view_model:install
```

See [Background-job view context](#background-job-view-context) for the `--with-job-view-context` flag.

---

## 30-second quickstart

```ruby
# app/views_models/product_card_view_model.rb
class ProductCardViewModel < ApplicationViewModel
  helpers :i18n, :path, :format

  prop :product, ::Product

  def title
    product.name
  end

  def detail_path
    product_path(product)
  end

  def humanized_price
    number_to_currency(product.price)
  end
end
```

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  def show
    @card = ProductCardViewModel.new(product: Product.find(params[:id]))
  end
end
```

```erb
<%# app/views/products/show.html.erb %>
<article>
  <h3><%= link_to @card.title, @card.detail_path %></h3>
  <p><%= @card.humanized_price %></p>
</article>
```

Instantiate in the controller (or in a parent VM, or pass to a ViewComponent). Instances are frozen and value-equal on attributes; unit-test them without a request or view context.

---

## Core concepts

### `TypedViewModel::Base`

A subclass of `Literal::Data`. Subclass it (typically via your generated `ApplicationViewModel`) and declare props with `prop`. All `Literal::Data` semantics apply: typed kwarg initializer, frozen instances, value equality, `?` predicate methods for `_Boolean` props.

```ruby
class MyViewModel < ApplicationViewModel
  prop :user, ::User
  prop :compact, _Boolean, default: false
end
```

For the type system itself (`_Boolean`, `_Array(T)`, `_Nilable(T)`, etc.) refer to the [Literal documentation](https://github.com/joeldrapper/literal).

### The `helpers(*names)` DSL

Class-level. For each name passed, looks up `"#{Name}Helpers"` in each module in `TypedViewModel.helper_namespaces` (in order, first match wins, no inheritance lookup) and includes the matching module. Raises `ArgumentError` if no namespace defines a matching constant.

```ruby
class MyViewModel < ApplicationViewModel
  helpers :i18n, :path, :format, :url
end
```

`helpers :name` includes a helper module's methods directly into the view model class. The methods become first-class on the receiver: declare what you need, then call it.

```ruby
class ProductCardViewModel < ApplicationViewModel
  helpers :i18n, :format

  prop :product, ::Product

  def humanized_price
    number_to_currency(product.price)
  end

  def label
    t("products.card.label")
  end
end
```

### Per-request view-context stash

`TypedViewModel.current_helpers` is a per-request slot for the host's Rails view context. The stash backend is fiber-safe on Rails 7+ (`ActiveSupport::IsolatedExecutionState`) and `Thread.current` otherwise.

Include the shipped controller concern in your `ApplicationController` to populate it automatically:

```ruby
class ApplicationController < ActionController::Base
  include TypedViewModel::ControllerHelpers
end
```

`ControllerHelpers` installs an `around_action` that wraps each request in `TypedViewModel.with_current_helpers(view_context) { … }`, restoring the previous value on exit (including on raise).

If you need to set the stash manually (e.g. inside a job, or from a non-controller code path):

```ruby
TypedViewModel.with_current_helpers(some_view_context) do
  # view models constructed inside the block can call their helper-DSL methods
end

# or unscoped:
TypedViewModel.current_helpers = some_view_context
```

---

## Helpers

Seven opt-in helper modules ship with the gem. Each is included via `helpers :name`.

### `:i18n`

`I18nHelpers`. Forwards `t` / `translate` and `l` / `localize` to `I18n`.

```ruby
helpers :i18n
# ...
t("shopping.cart.empty") # => "Your cart is empty"
```

### `:format`

`FormatHelpers`. Number and date formatting: `number_to_currency`, `number_with_precision`, `number_to_percentage`, `number_with_delimiter`, `number_to_human`, `number_to_human_size`, `number_to_phone`, `distance_of_time_in_words`, `time_ago_in_words`.

```ruby
helpers :format
# ...
number_to_currency(product.price_cents / 100.0)
```

### `:path`

`PathHelpers`. `url_helpers` returns `Rails.application.routes.url_helpers`. Any `*_path` / `*_url` method that exists on it is forwarded via `method_missing` (with `respond_to_missing?`).

```ruby
helpers :path
# ...
product_path(product)
```

### `:url`

`UrlHelpers`. Provides `url_for(source)` via `Rails.application.routes.url_helpers.url_for`. Useful for `ActiveStorage` attachments without dragging in the full path-helper module.

```ruby
helpers :url
# ...
url_for(product.image_attachment)
```

### `:tag`

`TagHelpers`. Forwards `content_tag`, `sanitize`, `safe_join`, `tag` to the per-request view context. Raises `RuntimeError` if `current_helpers` is unset.

```ruby
helpers :tag
# ...
content_tag(:p, "hello")
sanitize(rich_html)
```

### `:text`

`TextHelpers`. Forwards `truncate`, `pluralize`, `simple_format`, `excerpt`, `highlight`, `word_wrap`, `dom_class`, `dom_id`, `class_names`, `token_list` to the per-request view context. Raises `RuntimeError` if `current_helpers` is unset.

```ruby
helpers :text
# ...
truncate(product.description, length: 120)
pluralize(cart.item_count, "item")
dom_id(record)
```

### `:link`

`LinkHelpers`. Forwards `link_to`, `mail_to`, `phone_to`, `sms_to`, `current_page?` to the per-request view context. Raises `RuntimeError` if `current_helpers` is unset.

```ruby
helpers :link
# ...
link_to(product.name, product_path(product))
mail_to(user.email)
```

### Adding your own helper namespace

Register a namespace in an initializer. Each helper inside it must be named `"<Name>Helpers"`.

```ruby
# config/initializers/typed_view_model.rb
module MyApp
  module ViewModelHelpers
    module CurrencyHelpers
      def humanize_currency(cents, model)
        # ...
      end
    end
  end
end

TypedViewModel.helper_namespaces << MyApp::ViewModelHelpers
```

Then `helpers :currency` resolves to `MyApp::ViewModelHelpers::CurrencyHelpers`. The gem's own namespace is searched first; subsequent registrations are searched in order.

---

## Traits

Traits are mixin modules carrying view-specific presentation logic that is shared across multiple view-models. Extend the trait module with `TypedViewModel::Trait` and declare what props it expects.

```ruby
# app/view_traits/message.rb
module Messages
  module ViewTraits
    module Message
      extend TypedViewModel::Trait

      requires :message

      def sent_at_ms
        (message.sent_at.to_f * 1000).round
      end
    end
  end
end
```

Mix into a view-model with `use`:

```ruby
class MessageViewModel < ApplicationViewModel
  use Messages::ViewTraits::Message

  prop :message, ::Message
end
```

`requires` is checked by `Base.use` on first instantiation: if the host class fails to declare a prop matching every required entry, `.new` raises `ArgumentError` with the missing list. The check is deferred to first instantiation so the conventional `use Foo` before `prop :bar` ordering still works. Introspect with `MyTrait.required_props`.

---

## Cache keys

Opt in by including `TypedViewModel::WithCacheKey`. Declare cache-key sources with `with_cache_key`:

```ruby
class ProductCardViewModel < ApplicationViewModel
  prop :product, ::Product
  prop :variant, ::Variant

  with_cache_key :product, :variant
end
```

Each named source (Symbol → `send`'d on `self`; Proc → `instance_eval`'d) is hashed via `TypedViewModel::HashedKey.call`. The view-model itself is filtered out to avoid recursion. The result is memoised under the named slot:

```erb
<% cache @card do %>
  <%= render @card %>
<% end %>
```

The generated `cache_key(name = :_collection)` produces `"<class_name>/<hashed_source_1>/<hashed_source_2>/..."`, optionally suffixed with `cache_key_modifier` (defaults to `nil`). Override `cache_key_modifier` to scope keys app-wide:

```ruby
class ApplicationViewModel < TypedViewModel::Base
  include TypedViewModel::WithCacheKey

  private

  def cache_key_modifier
    "#{Rails.application.config.cache_id}/#{I18n.locale}"
  end
end
```

Multiple named slots are supported via `with_cache_key :a, :b, name: :summary`; access with `cache_key(:summary)`.

---

## `HashedKey` utility

`TypedViewModel::HashedKey.call(item)` turns any object into a stable cache-key fragment, in this dispatch order:

| Input | Output |
|---|---|
| Responds to `cache_key_with_version` (ActiveRecord) | `item.cache_key_with_version` |
| Responds to `cache_key` (presenter / view component) | `item.cache_key` |
| `String` | `Digest::SHA1.hexdigest(item)` |
| anything else | `Digest::SHA1.hexdigest(Marshal.dump(item))` |

Used internally by `WithCacheKey`; exposed for direct use.

```ruby
TypedViewModel::HashedKey.call(product)        # => AR cache_key_with_version
TypedViewModel::HashedKey.call("v1/manifest")  # => SHA1 of the string
```

**Marshal-fallback stability.** `HashedKey.call` falls back to `Digest::SHA1.hexdigest(Marshal.dump(item))` for objects that don't respond to `cache_key_with_version` or `cache_key`. Marshal output is not guaranteed stable across Ruby major versions or library upgrades that change object structure — a deploy that bumps Ruby or changes the in-memory shape of an object will silently invalidate cached fragments keyed off it. Pass developer-trusted values whose Marshal-shape is known stable (`Hash`, `Array`, `Numeric`, primitives, `String`). For arbitrary AR-like objects, prefer giving them a `cache_key` method.

---

## Background-job view context

View-models that call helpers (URL helpers, `url_for`, etc.) from inside an `ActiveJob` have no request and no `view_context`. The install generator scaffolds a host-app concern that fakes one and stashes it via `TypedViewModel.current_helpers=`:

```bash
bin/rails generate typed_view_model:install --with-job-view-context
# omit ActiveStorage handling:
bin/rails generate typed_view_model:install --with-job-view-context --no-active-storage
```

This produces `app/lib/application_view_model_concerns/job_view_context.rb` with a `view_context` method, a default `url_for` (handling `ActiveStorage::Blob` and `ActiveStorage::VariantWithRecord` when active-storage is on), and a `build_view_context_class` extension point. Include it in your `ApplicationViewModel` (the generator does this automatically).

The concern is **app-owned** — edit it to splice in your own helper includes (`CurrentHelper`, `TimezoneHelper`, currency formatting, etc.) without subclassing-with-`super` gymnastics.

---

## Test support

Trait testing without ActiveRecord. Require in your test boot:

```ruby
# test/test_helper.rb
require "typed_view_model/test_support/trait_test_helpers"

class ApplicationTraitTestCase < ActiveSupport::TestCase
  include TypedViewModel::TestSupport::TraitTestHelpers
end
```

Then test traits in isolation, with `MockObject` standing in for the AR record:

```ruby
class MessageTraitTest < ApplicationTraitTestCase
  setup { testing_trait Messages::ViewTraits::Message }

  test "sent_at_ms returns milliseconds since epoch" do
    instance = with_mock(sent_at: Time.utc(2026, 1, 1))
    assert_equal 1_767_225_600_000, instance.sent_at_ms
  end

  test "requires :message" do
    assert_trait_requires @tested_trait, :message
    assert_raises_missing_prop @tested_trait, :message
  end
end
```

`with_mock(**attrs)` infers the prop name from the trait's `required_props` (must be exactly one). For multi-prop traits, use `with_props(prop_a: {...}, prop_b: ...)` — symbol-keyed hashes are recursively converted to `MockObject` instances.

---

## Configuration

Top-level globals:

| Setting | Default | Purpose |
|---|---|---|
| `TypedViewModel.helper_namespaces` | `Set[TypedViewModel::Helpers]` | Namespaces searched by `Base.helpers(*names)`. Append Modules or Strings (Strings are `const_get`'d lazily): `TypedViewModel.helper_namespaces << "MyApp::ViewModelHelpers"`. |
| `TypedViewModel.current_helpers` | `nil` | Per-request view-context stash. Read internally by the shipped helper modules when they delegate to Rails helpers. Set via `TypedViewModel::ControllerHelpers` or `TypedViewModel.with_current_helpers(value) { … }`. Fiber-safe on Rails 7+. |

Mutating `helper_namespaces` after `helpers` calls have already run does not retroactively re-resolve — they're resolved at class-definition time.

---

## API reference

### `TypedViewModel::Base < Literal::Data`

| Method | Kind | Description |
|---|---|---|
| `use(trait_module)` | class | `include` the trait. Validates `requires` on first `.new()`. |
| `helpers(*names)` | class | Include each `"#{Name}Helpers"` resolved from `TypedViewModel.helper_namespaces`. Raises `ArgumentError` if unknown. |
| `prop(name, type, **opts)` | class (Literal) | Declare a typed prop. Full `Literal::Data` API available. |

### `TypedViewModel::Trait`

Module mixed via `extend`.

| Method | Description |
|---|---|
| `requires(*names)` | Declare required prop names. **Replaces**, does not merge. |
| `required_props` | `Array<Symbol>`; `[]` if `requires` never called. |

### `TypedViewModel::HashedKey`

| Method | Description |
|---|---|
| `.call(item)` | Returns a stable hash for `item`. See dispatch table above. |

### `TypedViewModel::WithCacheKey`

`ActiveSupport::Concern`. Opt in with `include`.

| Method | Kind | Description |
|---|---|---|
| `with_cache_key(*sources, name: :_collection)` | class | Register named cache-key sources (Symbols `send`'d, Procs `instance_eval`'d). |
| `named_cache_key_attributes` | class | Read-only Hash of registered slots. |
| `cache_key(name = :_collection)` | instance | Memoised cache-key String. Format: `"<class>/<hash1>/<hash2>/.../<modifier?>"`. Raises if blank. |
| `cacheable?` | instance | `true` if `cache_key` is defined. |
| `cache_key_modifier` | instance | `nil` by default. Override to append app-wide scope. |

### `TypedViewModel::Helpers::*`

| Module | Methods |
|---|---|
| `I18nHelpers` | `t`, `translate`, `l`, `localize` |
| `FormatHelpers` | `number_to_currency`, `number_with_precision`, `number_to_percentage`, `number_with_delimiter`, `number_to_human`, `number_to_human_size`, `number_to_phone`, `distance_of_time_in_words`, `time_ago_in_words` |
| `PathHelpers` | `url_helpers`, plus `*_path` / `*_url` via `method_missing` |
| `UrlHelpers` | `url_for(source)` |
| `TagHelpers` | `content_tag`, `sanitize`, `safe_join`, `tag` |
| `TextHelpers` | `truncate`, `pluralize`, `simple_format`, `excerpt`, `highlight`, `word_wrap`, `dom_class`, `dom_id`, `class_names`, `token_list` |
| `LinkHelpers` | `link_to`, `mail_to`, `phone_to`, `sms_to`, `current_page?` |

### `TypedViewModel::TestSupport::*`

| Class / module | Description |
|---|---|
| `MockObject` | Lightweight mock; attribute methods defined as singleton methods (Procs called lazily). Unknown `*?` methods return `nil`. |
| `TraitTestHarness.create(trait, **props)` | Anonymous class including `trait` with `attr_reader`s; raises `ArgumentError` on missing required props. Calls `after_initialize` if defined. |
| `TraitTestHarness.required_props(trait)` | `[]` for unextended modules. |
| `TraitTestHelpers` | Mixin: `trait_harness`, `mock_object` / `mock_chain`, `assert_trait_requires`, `assert_raises_missing_prop`, `testing_trait`, `with_props`, `with_mock`. |

### `TypedViewModel` (top-level)

| Method | Description |
|---|---|
| `.helper_namespaces` | Mutable `Set<Module \| String>`; default `Set[TypedViewModel::Helpers]`. |
| `.current_helpers` | Reader for the per-request view-context stash. |
| `.current_helpers=` | Writer for the per-request view-context stash. |
| `.with_current_helpers(value) { … }` | Set the stash for the duration of the block; restore previous value on exit (including on raise). |

### `TypedViewModel::ControllerHelpers`

`ActiveSupport::Concern`. Include in `ApplicationController` to install an `around_action` that wraps each request in `TypedViewModel.with_current_helpers(view_context) { … }`.

### Generator

`rails generate typed_view_model:install [--with-job-view-context] [--[no-]active-storage]`

Writes `app/lib/application_view_model.rb`, optionally `app/lib/application_view_model_concerns/job_view_context.rb`, and `config/initializers/typed_view_model.rb`. The generated files are yours to edit.

---

## What this does NOT do

- **Render anything.** No partial dispatch, no `template`, no `call`. Use ViewComponent or plain partials for rendering.
- **Forward to a wrapped record.** No `method_missing` to the underlying model. Declare props or expose via explicit methods.
- **Enforce trait `requires` at runtime.** That's `Literal::Data`'s job on the host class.
- **Provide a real view context inside jobs.** The generated `JobViewContext` is a *shim* — URL helpers and a stubbed `url_for`. It does not run partials, evaluate ERB, or expose the full `ActionView::Base` surface.
- **Validate.** View-models are display objects; data is assumed to already be valid by the time it gets here. For input validation see `typed_form_model`.

---

## Stability

Pre-1.0. The API is what's in production use across the parent codebase, but:

- The shape of `TestSupport` (especially `with_mock`'s single-prop assumption) may shift.
- RBS sigs are partial.
- `WithCacheKey` is exercised through host-app integration tests rather than the in-gem suite.

Pin to an exact version. Expect breaking changes in `0.x`.

---

## Development & contributing

```bash
bin/setup
bundle exec rake test
```

Style: `standardrb`. RBS signatures live under `sig/` (partial coverage).

PRs welcome. If you change public API, update the README and `CHANGELOG.md` in the same commit.

---

## License

MIT. See `LICENSE.txt`.
