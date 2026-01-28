# frozen_string_literal: true

require "ostruct"

module Backoffice
  module Reports
    class SalesRankingService < BaseReportService
      CRITERIA = %w[brand category size color supplier price_range].freeze
      ORDERS = %w[revenue qty].freeze

      attr_reader :criterion, :order, :rows, :widgets

      def initialize(account:, period: "last_30_days", criterion: "category", order: "revenue")
        super(account: account, period: period)

        @criterion = normalize_criterion(criterion)
        @order = normalize_order(order)

        calculate!
      end

      private

      def calculate!
        return unless validate_presence(:account, account)

        @date_range = period_range_for_account

        items_scope = SaleItem.joins(:sale)
                              .joins(:product)
                              .where(
                                sales: {
                                  account_id: account.id,
                                  status: "paid",
                                  created_at: @date_range
                                }
                              )

        @rows = build_rows(items_scope)
        @widgets = build_widgets(items_scope, @rows)
      end

      def normalize_criterion(value)
        value = value.to_s
        CRITERIA.include?(value) ? value : "category"
      end

      def normalize_order(value)
        value = value.to_s
        ORDERS.include?(value) ? value : "revenue"
      end

      def criterion_expression
        case criterion
        when "brand"
          "COALESCE(products.brand, 'Sem marca')"
        when "category"
          "COALESCE(products.category, 'Sem categoria')"
        when "supplier"
          "COALESCE(products.supplier, 'Sem fornecedor')"
        when "size"
          "COALESCE(sale_items.product_size, 'Sem tamanho')"
        when "color"
          "COALESCE(sale_items.product_color, 'Sem cor')"
        when "price_range"
          # Faixas simples com base no preço unitário do item vendido (snapshot)
          <<~SQL.squish
            CASE
              WHEN sale_items.unit_price < 50 THEN 'R$ 0–49'
              WHEN sale_items.unit_price < 100 THEN 'R$ 50–99'
              WHEN sale_items.unit_price < 200 THEN 'R$ 100–199'
              ELSE 'R$ 200+'
            END
          SQL
        else
          "COALESCE(products.category, 'Sem categoria')"
        end
      end

      def build_rows(items_scope)
        criterion_sql = criterion_expression

        rows = items_scope
               .group(Arel.sql(criterion_sql))
               .select(
                 "#{criterion_sql} AS criterion_value",
                 "SUM(sale_items.quantity) AS qty_sold",
                 "SUM(sale_items.total_amount) AS revenue",
                 "SUM(COALESCE(sale_items.cost_price, 0) * sale_items.quantity) AS cost",
                 "SUM(COALESCE((sale_items.unit_price - sale_items.cost_price) * sale_items.quantity, 0)) AS profit",
                 "SUM(products.stock_quantity) AS current_stock"
               )

        order_sql = case order
                    when "qty" then "qty_sold DESC"
                    else "revenue DESC"
                    end

        rows = rows.order(Arel.sql(order_sql)).limit(50)

        # Adiciona margin_pct como método dinâmico
        rows.map do |row|
          margin_pct = if row.revenue.to_f.positive?
                         ((row.profit.to_f / row.revenue.to_f) * 100).round(1)
                       else
                         nil
                       end
          row.define_singleton_method(:margin_pct) { margin_pct }
          row
        end
      end

      def build_widgets(items_scope, rows)
        # Usar colunas totalmente qualificadas para evitar ambiguidade com joins
        total_revenue = items_scope.sum(Arel.sql("sale_items.total_amount")).to_f
        total_profit = items_scope.sum(
          Arel.sql("COALESCE((sale_items.unit_price - sale_items.cost_price) * sale_items.quantity, 0)")
        ).to_f

        avg_margin_pct = if total_revenue.positive?
                           ((total_profit / total_revenue) * 100).round(1)
                         else
                           nil
                         end

        champion = rows.first&.criterion_value

        {
          total_revenue: total_revenue.round(2),
          total_profit: total_profit.round(2),
          avg_margin_pct: avg_margin_pct,
          champion_criterion: champion
        }
      end
    end
  end
end

