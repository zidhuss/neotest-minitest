# frozen_string_literal: true

require 'minitest/autorun'

class SpecTest < Minitest::Spec
  describe '#add' do
    test 'adds two numbers' do
      assert_equal 2 + 2, 4
    end
  end

  describe '#subtract' do
    test 'subtracts two numbers' do
      assert_equal 3 - 2, 1
    end
  end
end
