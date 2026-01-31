# frozen_string_literal: true

module AutomaticPricing
  class Calculator
    MIN_PRICE_9_90 = BigDecimal("9.90")

    class << self
      # Parse cost from string (accepts comma or dot as decimal separator)
      # Returns BigDecimal or nil if invalid
      def parse_cost(value)
        return nil if value.blank?

        str = value.to_s.strip
        return nil if str.blank?

        normalized = str.gsub(",", ".")
        BigDecimal(normalized)
      rescue ArgumentError, TypeError
        nil
      end

      # Calculate sale price from cost, markup and rounding mode.
      # cost: Numeric or String (will be parsed)
      # markup_percent: Numeric (e.g. 35 for 35%)
      # rounding_mode: "down_9_90" | "up_9_90" | "cents_90"
      # Returns BigDecimal or nil if cost invalid
      def calculate(cost, markup_percent, rounding_mode)
        cost_bd = cost.is_a?(Numeric) ? BigDecimal(cost.to_s) : parse_cost(cost)
        return nil if cost_bd.nil? || cost_bd <= 0

        markup = BigDecimal(markup_percent.to_s)
        raw = raw_price(cost_bd, markup)
        round(raw, rounding_mode)
      end

      # Raw price before rounding: cost * (1 + markup/100), 2 decimals
      def raw_price(cost, markup_percent)
        multiplier = 1 + (BigDecimal(markup_percent.to_s) / 100)
        (cost * multiplier).round(2)
      end

      # Round according to mode; apply min 9.90 for 9_90 modes
      def round(raw_amount, rounding_mode)
        raw = raw_amount.is_a?(BigDecimal) ? raw_amount : BigDecimal(raw_amount.to_s)

        result = case rounding_mode.to_s
        when "down_9_90"
          round_down_9_90(raw)
        when "up_9_90"
          round_up_9_90(raw)
        when "cents_90"
          round_cents_90(raw)
        else
          raw
        end

        return result if result.nil?

        result = MIN_PRICE_9_90 if rounding_mode.to_s.in?(%w[down_9_90 up_9_90]) && result < MIN_PRICE_9_90
        result
      end

      private

      # Round down to previous X9,90 (e.g. 56.50 -> 49.90, 10.00 -> 9.90)
      def round_down_9_90(raw)
        int = raw.floor
        return MIN_PRICE_9_90 if int < 10

        # Find previous "X9" (9, 19, 29, ...)
        last_digit = int % 10
        base = last_digit >= 9 ? int : (int - (last_digit + 1))
        base = 9 if base < 9
        BigDecimal("#{base}.90")
      end

      # Round up to next X9,90 (e.g. 56.50 -> 59.90, 59.91 -> 69.90)
      def round_up_9_90(raw)
        int = raw.ceil
        return MIN_PRICE_9_90 if int <= 9

        last_digit = int % 10
        base = last_digit == 9 ? int : (int + (9 - last_digit))
        BigDecimal("#{base}.90")
      end

      # Keep integer part, set cents to .90 (e.g. 56.50 -> 56.90)
      def round_cents_90(raw)
        int = raw.floor
        BigDecimal("#{int}.90")
      end
    end
  end
end
