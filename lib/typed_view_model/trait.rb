# frozen_string_literal: true

module TypedViewModel
  # Base module for creating view traits that can be mixed into view model classes.
  # Provides DSL for declaring prop requirements for documentation and introspection.
  #
  # Note: When traits are used in TypedViewModel::Base subclasses, Literal::Data's typed
  # props already enforce that required data is present and correctly typed at instantiation.
  # The `requires` declaration serves as documentation and is used by the test harness
  # (TraitTestHarness) to validate that test setups provide the necessary props.
  module Trait
    # Declare which props this trait expects to be available.
    # These are the props that the hosting ViewModel class (or test harness) must provide.
    #
    # Usage:
    #   module MyTrait
    #     extend TypedViewModel::Trait
    #     requires :user, :account
    #   end
    # Note: calling requires again replaces the previous declaration (does not merge).
    def requires(*props)
      @required_props = props
    end

    # Introspect the required props for this trait
    def required_props
      @required_props || []
    end
  end
end
