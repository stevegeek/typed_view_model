# frozen_string_literal: true

require_relative "lib/typed_view_model/version"

Gem::Specification.new do |spec|
  spec.name = "typed_view_model"
  spec.version = TypedViewModel::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "Typed Rails view-model objects on top of Literal::Data, with reusable presentation traits."
  spec.description = "View-model base class for Rails: typed, immutable presentation objects via Literal::Data, " \
                     "composable traits, opt-in Rails helper mixins, fragment-cache key generation, and a " \
                     "background-job-friendly fake view context."
  spec.homepage = "https://github.com/stevegeek/typed_view_model"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    %w[README.md CHANGELOG.md LICENSE.txt] +
      Dir["lib/**/*.{rb,tt}"] +
      Dir["sig/**/*.rbs"]
  end
  spec.require_paths = ["lib"]

  # Runtime
  spec.add_dependency "literal", ">= 1.9"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "actionpack", ">= 7.0"

  # Development
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "railties", ">= 7.0"
end
