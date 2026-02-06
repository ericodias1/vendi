# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ApplyPricingService
      def initialize(product_import:, account_config:)
        @product_import = product_import
        @account_config = account_config
      end

      def call
        return false unless @product_import.parsed_data.is_a?(Array)

        markup = @account_config.automatic_pricing_markup_percent&.to_f || 35
        mode = @account_config.automatic_pricing_rounding_mode.presence || "up_9_90"

        updated = @product_import.parsed_data.map do |row|
          row = row.respond_to?(:to_h) ? row.to_h : row
          cost = parse_cost(row["preco_custo"] || row[:preco_custo])

          if cost.present? && cost.positive?
            price = AutomaticPricing::Calculator.calculate(cost, markup, mode)
            if price
              row = row.dup
              row["preco_venda"] = price.to_f.round(2)
              row["preco_venda_auto"] = true
            else
              row = row.dup
              row["preco_venda_auto"] = false
            end
          else
            # Sem custo: nunca aplicar AUTO; manter preco_venda como está se use_csv_when_empty
            row = row.dup
            row["preco_venda_auto"] = false
          end

          row
        end

        @product_import.update(parsed_data: updated)
      end

      private

      def parse_cost(value)
        CurrencyParser.parse(value)
      end
    end
  end
end
