# frozen_string_literal: true

require "minitest/autorun"
require "active_support/message_encryptor"
require "active_support/dependencies/autoload"
require "active_support/test_case"
require "action_controller/template_assertions"
require "action_dispatch/http/mime_type"
require "action_dispatch/testing/assertions"
require "action_dispatch/testing/test_process"
require "action_dispatch/testing/request_encoder"
require "action_dispatch/routing"
require "action_dispatch/testing/integration"

module FooController
end

class FooController::FooControllerTest < ActionDispatch::IntegrationTest
  test "should pass" do
  end
end
