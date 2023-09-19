require 'non_exising_file'
require 'minitest/autorun'
require 'active_support/test_case'

class RailsUnitErroringTest < ActiveSupport::TestCase
  def test_addition
    assert_equal 1 + 1, 2
  end
end
