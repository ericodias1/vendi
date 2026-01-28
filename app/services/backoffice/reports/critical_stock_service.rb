# frozen_string_literal: true

module Backoffice
  module Reports
    class CriticalStockService < BaseReportService
      attr_reader :critical_products,
                  :critical_days_threshold,
                  :high_profit_margin_threshold,
                  :insights

      def initialize(account:, period: "month", critical_days_threshold: nil, high_profit_margin_threshold: nil)
        super(account: account, period: period)

        @critical_days_threshold = critical_days_threshold || account.account_config&.stock_alert_threshold || 7
        @high_profit_margin_threshold = high_profit_margin_threshold || account.account_config&.high_profit_margin_threshold || 50.0

        calculate!
      end

      private

      def calculate!
        return unless validate_presence(:account, account)

        products_with_metrics = build_products_with_metrics
        @critical_products = filter_and_sort_products(products_with_metrics)
        @insights = calculate_insights(products_with_metrics)
      end

      def build_products_with_metrics
        # Período para cálculo de venda média: últimos 30 dias
        sales_range = 30.days.ago.beginning_of_day..Time.current

        # Buscar todos os produtos da conta com estoque > 0 ou que tiveram vendas recentes
        products_with_recent_sales = SaleItem.joins(:sale)
                                              .where(sales: { account_id: account.id, status: "paid" })
                                              .where("sale_items.created_at >= ?", 30.days.ago)
                                              .select(:product_id)
                                              .distinct

        products = account.products.active
                         .where("stock_quantity > 0 OR id IN (?)", products_with_recent_sales)

        products.map do |product|
          build_product_metrics(product, sales_range)
        end
      end

      def build_product_metrics(product, sales_range)
        # Calcular venda média por dia (últimos 30 dias)
        total_quantity_sold = SaleItem.joins(:sale)
                                      .where(
                                        sales: {
                                          account_id: account.id,
                                          status: "paid"
                                        }
                                      )
                                      .where(created_at: sales_range)
                                      .where(product_id: product.id)
                                      .sum(:quantity)

        days_in_period = 30
        avg_sales_per_day = total_quantity_sold.to_f / days_in_period

        # Calcular preço médio de venda
        avg_selling_price = SaleItem.joins(:sale)
                                    .where(
                                      sales: {
                                        account_id: account.id,
                                        status: "paid"
                                      }
                                    )
                                    .where(created_at: sales_range)
                                    .where(product_id: product.id)
                                    .average(:unit_price)

        avg_selling_price = avg_selling_price.to_f if avg_selling_price.present?
        avg_selling_price ||= product.base_price.to_f if product.base_price.present?
        avg_selling_price ||= 0

        # Calcular dias de cobertura
        days_of_coverage = if avg_sales_per_day > 0
                            (product.stock_quantity.to_f / avg_sales_per_day).round(1)
                          else
                            nil # Produto sem vendas recentes
                          end

        # Calcular lucro potencial por dia
        cost_price = product.cost_price.to_f if product.cost_price.present?
        profit_per_unit = avg_selling_price - (cost_price || 0)
        profit_per_day = profit_per_unit * avg_sales_per_day

        # Calcular margem de lucro
        margin_percentage = if avg_selling_price > 0 && cost_price.present?
                             ((profit_per_unit / avg_selling_price) * 100).round(1)
                           else
                             nil
                           end

        # Determinar se é crítico e alto lucro
        critical = days_of_coverage.present? && days_of_coverage <= @critical_days_threshold
        high_profit = margin_percentage.present? && margin_percentage > @high_profit_margin_threshold

        OpenStruct.new(
          product_id: product.id,
          product_name: product.name,
          product: product,
          stock_quantity: product.stock_quantity,
          avg_sales_per_day: avg_sales_per_day.round(2),
          days_of_coverage: days_of_coverage,
          profit_per_day: profit_per_day.round(2),
          margin_percentage: margin_percentage,
          avg_selling_price: avg_selling_price.round(2),
          critical?: critical,
          high_profit?: high_profit
        )
      end

      def filter_and_sort_products(products_with_metrics)
        # Ordenar por criticidade (dias ASC, depois por lucro potencial DESC)
        products_with_metrics.sort_by do |p|
          [
            p.days_of_coverage.nil? ? Float::INFINITY : p.days_of_coverage,
            -p.profit_per_day
          ]
        end
      end

      def calculate_insights(products_with_metrics)
        critical_count = products_with_metrics.count { |p| p.critical? }
        high_profit_low_stock_count = products_with_metrics.count do |p|
          p.high_profit? && (p.stock_quantity <= 3 || p.critical?)
        end

        {
          critical_count: critical_count,
          high_profit_low_stock_count: high_profit_low_stock_count,
          critical_days_threshold: @critical_days_threshold,
          high_profit_margin_threshold: @high_profit_margin_threshold
        }
      end
    end
  end
end
