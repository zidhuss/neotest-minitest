# frozen_string_literal: true

# RailsSpecTest captures what it looks like to write a Rails TestCase using
# minitest DSL. One way to enable this in a Rails project is by using:
# https://github.com/metaskills/minitest-spec-rails
class RailsSpecTest < ActiveSupport::TestCase
  context 'addition' do
    test 'adds two numbers' do
      assert_equal 2 + 2, 5
    end
  end

  context 'subtraction' do
    test 'subtracts two numbers' do
      assert_equal 3 - 2, 1
    end
  end
end
