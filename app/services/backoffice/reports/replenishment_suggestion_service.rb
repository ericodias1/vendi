# frozen_string_literal: true

require "ostruct"

module Backoffice
  module Reports
    class ReplenishmentSuggestionService < BaseReportService
      attr_reader :suggestions, :insights

      def initialize(account:, sales_lookback_days: 30, coverage_target_days: 15, min_stock_target: 3)
        super(account: account, period: "month")

        @sales_lookback_days = sales_lookback_days.to_i
        @coverage_target_days = coverage_target_days.to_i
        @min_stock_target = min_stock_target.to_i

        normalize_params!
        calculate!
      end

      private

      attr_reader :sales_lookback_days, :coverage_target_days, :min_stock_target

      def normalize_params!
        @sales_lookback_days = 30 if sales_lookback_days <= 0
        @coverage_target_days = 15 if coverage_target_days <= 0
        @min_stock_target = 3 if min_stock_target < 0
      end

      def calculate!
        return unless validate_presence(:account, account)

        range = sales_lookback_days.days.ago.beginning_of_day..Time.current
        products = account.products.active.where.not(cost_price: nil)

        sales_stats_by_product_id = sales_stats(range)

        suggestions = products.map do |product|
          stats = sales_stats_by_product_id[product.id] || {}
          build_suggestion(product, stats)
        end

        @suggestions = suggestions
          .select { |s| s.suggested_qty.to_i.positive? }
          .sort_by { |s| [-s.suggested_profit.to_f, -s.avg_sales_per_day.to_f] }

        @insights = build_insights(@suggestions)
      end

      def sales_stats(range)
        rows = SaleItem
          .joins(:sale)
          .where(
            sales: {
              account_id: account.id,
              status: "paid"
            }
          )
          .where(created_at: range)
          .group(:product_id)
          .select(
            :product_id,
            "SUM(sale_items.quantity) AS total_quantity_sold",
            "AVG(sale_items.unit_price) AS avg_unit_price"
          )

        rows.each_with_object({}) do |row, acc|
          acc[row.product_id] = {
            total_quantity_sold: row.total_quantity_sold.to_f,
            avg_unit_price: row.avg_unit_price.to_f
          }
        end
      end

      def build_suggestion(product, stats)
        total_quantity_sold = stats.fetch(:total_quantity_sold, 0).to_f
        avg_sales_per_day = total_quantity_sold / sales_lookback_days.to_f

        avg_selling_price = stats.fetch(:avg_unit_price, 0).to_f
        avg_selling_price = product.base_price.to_f if avg_selling_price <= 0 && product.base_price.present?

        stock_quantity = product.stock_quantity.to_i
        # A partir daqui, `cost_price` sempre existe (filtrado no calculate!)
        cost_price = product.cost_price.to_f
        profit_per_unit = avg_selling_price - cost_price

        suggested_qty, reason = suggested_qty_and_reason(avg_sales_per_day, stock_quantity)

        suggested_cost = (suggested_qty.to_i * cost_price).round(2)
        suggested_profit = (suggested_qty.to_i * profit_per_unit).round(2)

        OpenStruct.new(
          product_id: product.id,
          product_name: product.name,
          product: product,
          category: product.category.presence || "Sem categoria",
          stock_quantity: stock_quantity,
          avg_sales_per_day: avg_sales_per_day.round(2),
          avg_selling_price: avg_selling_price.round(2),
          cost_price: cost_price.round(2),
          profit_per_unit: profit_per_unit.round(2),
          suggested_qty: suggested_qty,
          suggested_cost: suggested_cost,
          suggested_profit: suggested_profit,
          reason: reason
        )
      end

      def suggested_qty_and_reason(avg_sales_per_day, stock_quantity)
        if avg_sales_per_day.to_f.positive?
          target_stock = (avg_sales_per_day.to_f * coverage_target_days.to_i)
          suggested_qty = [target_stock.ceil - stock_quantity.to_i, 0].max
          reason = "Atingir #{coverage_target_days} dias de cobertura"
          return [suggested_qty, reason]
        end

        suggested_qty = [min_stock_target.to_i - stock_quantity.to_i, 0].max
        reason = "Estoque mínimo"
        [suggested_qty, reason]
      end

      def build_insights(suggestions)
        total_units = suggestions.sum { |s| s.suggested_qty.to_i }
        total_cost = suggestions.sum { |s| s.suggested_cost.to_f }.round(2)
        total_profit = suggestions.sum { |s| s.suggested_profit.to_f }.round(2)

        top_categories = suggestions
          .group_by(&:category)
          .map do |category, rows|
            {
              category: category,
              total_cost: rows.sum { |r| r.suggested_cost.to_f }.round(2),
              total_profit: rows.sum { |r| r.suggested_profit.to_f }.round(2),
              product_count: rows.count
            }
          end
          .sort_by { |row| -row[:total_cost].to_f }
          .first(5)

        {
          total_units: total_units,
          total_cost: total_cost,
          total_profit: total_profit,
          top_categories: top_categories,
          sales_lookback_days: sales_lookback_days,
          coverage_target_days: coverage_target_days,
          min_stock_target: min_stock_target
        }
      end
    end
  end
end

