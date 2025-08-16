# frozen_string_literal: true

require 'minitest/spec'
require 'minitest/autorun'

describe 'SpecTest' do
  describe 'addition' do
    it 'adds two numbers' do
      assert_equal 2 + 2, 5
    end
  end

  describe 'subtraction' do
    it 'subtracts two numbers' do
      assert_equal 3 - 2, 1
    end
  end
end
