# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/test_case'

class RailsUnitTest < ActiveSupport::TestCase
  test 'adds two numbers' do
    assert_equal 2 + 2, 4
  end
  test 'subtracts two numbers' do
    assert_equal 3 - 2, 1
  end
end
