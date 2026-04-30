# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] ||= "test"
require "rails"
require "action_controller/railtie"

class TestApp < Rails::Application
  config.root = File.expand_path("..", __dir__)
  config.eager_load = false
  config.logger = ::Logger.new(IO::NULL)
  config.secret_key_base = "test"
  config.hosts.clear
end
TestApp.initialize!

Rails.application.routes.draw do
  root to: proc { [200, {}, ["ok"]] }
end

require "typed_view_model"

require "active_support/test_case"
require "minitest/autorun"
