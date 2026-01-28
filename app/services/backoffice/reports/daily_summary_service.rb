# frozen_string_literal: true

module Backoffice
  module Reports
    class DailySummaryService < Service
      attr_reader :account,
                  :sales_scope,
                  :total_revenue,
                  :sales_count,
                  :avg_ticket,
                  :total_profit,
                  :margin_percentage,
                  :top_products

      def initialize(account:)
        super()
        @account = account

        calculate!
      end

      private

      def calculate!
        return unless validate_presence(:account, account)

        range = today_range_for_account

        @sales_scope = account.sales.paid.where(created_at: range)
        @total_revenue = @sales_scope.sum(:total_amount)
        @sales_count = @sales_scope.count
        @avg_ticket = sales_count.positive? ? (@total_revenue / sales_count) : 0

        items_scope = SaleItem.joins(:sale)
                              .where(
                                sales: {
                                  account_id: account.id,
                                  status: "paid",
                                  created_at: range
                                }
                              )

        # Lucro total: (preço de venda - custo) * quantidade
        # Se não houver custo (cost_price nulo), o item é considerado com lucro 0 nesse cálculo.
        @total_profit = items_scope.sum(
          Arel.sql("COALESCE((sale_items.unit_price - sale_items.cost_price) * sale_items.quantity, 0)")
        )

        @margin_percentage = if @total_revenue.to_f.positive?
                               ((@total_profit.to_f / @total_revenue.to_f) * 100).round(1)
                             else
                               nil
                             end

        @top_products = build_top_products(items_scope)
      end

      def today_range_for_account
        zone = ActiveSupport::TimeZone.new(account.timezone || "America/Sao_Paulo")
        now = zone.now
        now.beginning_of_day..now.end_of_day
      end

      def build_top_products(items_scope)
        # Agrupa por produto utilizando os snapshots de venda em SaleItem
        items_scope.joins(:product)
                   .group("products.id", "products.name")
                   .select(
                     "products.id AS product_id",
                     "products.name AS product_name",
                     "SUM(sale_items.quantity) AS total_quantity",
                     "SUM(sale_items.total_amount) AS total_revenue",
                     "SUM(COALESCE((sale_items.unit_price - sale_items.cost_price) * sale_items.quantity, 0)) AS total_profit"
                   )
                   .order(Arel.sql("total_profit DESC"))
                   .limit(5)
      end
    end
  end
end

