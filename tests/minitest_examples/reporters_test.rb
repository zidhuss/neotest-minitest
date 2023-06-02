# frozen_string_literal: true

require 'minitest/autorun'
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

class ReportersTest < Minitest::Test
  def test_addition
    assert_equal 2, 1 + 1
  end
end
