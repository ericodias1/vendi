# frozen_string_literal: true

require "test_helper"

module AutomaticPricing
  class CalculatorTest < ActiveSupport::TestCase
    test "parse_cost with comma returns BigDecimal" do
      assert_equal BigDecimal("41.85"), Calculator.parse_cost("41,85")
      assert_equal BigDecimal("42"), Calculator.parse_cost("42")
    end

    test "parse_cost with invalid values returns nil" do
      assert_nil Calculator.parse_cost("")
      assert_nil Calculator.parse_cost("abc")
      assert_nil Calculator.parse_cost(nil)
      assert_nil Calculator.parse_cost("  ")
    end

    test "cost 41.85 markup 35% raw 56.50 down_9_90 gives 49.90" do
      raw = Calculator.raw_price(41.85, 35)
      assert_equal BigDecimal("56.50"), raw
      assert_equal BigDecimal("49.90"), Calculator.round(raw, "down_9_90")
    end

    test "cost 41.85 markup 35% up_9_90 gives 59.90" do
      raw = Calculator.raw_price(41.85, 35)
      assert_equal BigDecimal("59.90"), Calculator.round(raw, "up_9_90")
    end

    test "cost 41.85 markup 35% cents_90 gives 56.90" do
      raw = Calculator.raw_price(41.85, 35)
      assert_equal BigDecimal("56.90"), Calculator.round(raw, "cents_90")
    end

    test "cost 9.00 markup 0% down_9_90 applies min 9.90" do
      raw = Calculator.raw_price(9, 0)
      assert_equal BigDecimal("9.0"), raw
      assert_equal BigDecimal("9.90"), Calculator.round(raw, "down_9_90")
    end

    test "calculate with string cost and comma" do
      assert_equal BigDecimal("59.90"), Calculator.calculate("41,85", 35, "up_9_90")
    end

    test "calculate with invalid cost returns nil" do
      assert_nil Calculator.calculate("", 35, "up_9_90")
      assert_nil Calculator.calculate("abc", 35, "up_9_90")
      assert_nil Calculator.calculate(nil, 35, "up_9_90")
      assert_nil Calculator.calculate(0, 35, "up_9_90")
      assert_nil Calculator.calculate(-1, 35, "up_9_90")
    end

    test "59.91 up_9_90 gives 69.90" do
      assert_equal BigDecimal("69.90"), Calculator.round(BigDecimal("59.91"), "up_9_90")
    end

    test "10.00 down_9_90 gives 9.90" do
      assert_equal BigDecimal("9.90"), Calculator.round(BigDecimal("10"), "down_9_90")
    end
  end
end
