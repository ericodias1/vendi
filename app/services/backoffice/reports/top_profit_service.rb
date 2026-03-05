# frozen_string_literal: true

module Backoffice
  module Reports
    class TopProfitService < BaseReportService
      attr_reader :top_products

      def initialize(account:, period: "month")
        super(account: account, period: period)

        calculate!
      end

      private

      def calculate!
        return unless validate_presence(:account, account)

        @date_range = period_range_for_account

        items_scope = SaleItem.joins(:sale)
                              .where(
                                sales: {
                                  account_id: account.id,
                                  status: "paid",
                                  created_at: @date_range
                                }
                              )

        @top_products = build_top_products(items_scope)
      end

      def build_top_products(items_scope)
        prorated_revenue_sql = "(sale_items.subtotal / NULLIF(sales.subtotal, 0)) * sales.total_amount"
        products_data = items_scope.joins(:product)
                                   .group("products.id", "products.name")
                                   .select(
                                     "products.id AS product_id",
                                     "products.name AS product_name",
                                     "SUM(sale_items.quantity) AS total_quantity",
                                     "SUM(#{prorated_revenue_sql}) AS total_revenue",
                                     "SUM(COALESCE((sale_items.unit_price - sale_items.cost_price) * sale_items.quantity, 0)) AS total_profit"
                                   )
                                   .having("SUM(COALESCE((sale_items.unit_price - sale_items.cost_price) * sale_items.quantity, 0)) > 0")
                                   .order(Arel.sql("total_profit DESC"))
                                   .limit(20)

        # Adiciona cálculo de margem para cada produto
        products_data.map do |product_row|
          margin = if product_row.total_revenue.to_f.positive?
                    ((product_row.total_profit.to_f / product_row.total_revenue.to_f) * 100).round(1)
                  else
                    nil
                  end

          # Adiciona margin_percentage como método dinâmico
          product_row.define_singleton_method(:margin_percentage) { margin }
          product_row
        end
      end
    end
  end
end
