# frozen_string_literal: true

module Backoffice
  module Reports
    class StagnantProductsService < BaseReportService
      attr_reader :stagnant_products,
                  :insights

      def initialize(account:, period: "month")
        super(account: account, period: period)

        calculate!
      end

      private

      def calculate!
        return unless validate_presence(:account, account)

        products_with_metrics = build_products_with_metrics
        @stagnant_products = sort_products(products_with_metrics)
        @insights = calculate_insights(products_with_metrics)
      end

      def build_products_with_metrics
        # Buscar produtos ativos com estoque > 0
        products = account.products.active.where("stock_quantity > 0")

        products.map do |product|
          build_product_metrics(product)
        end
      end

      def build_product_metrics(product)
        # Calcular dias sem vender
        days_without_selling = calculate_days_without_selling(product)

        # Calcular custo total parado
        cost_price = product.cost_price.to_f if product.cost_price.present?
        total_cost_stuck = product.stock_quantity * (cost_price || 0)

        # Última venda
        last_sale_date = product.last_sold_at || product.last_sale&.created_at

        # Categoria ou grupo
        category = product.category.presence || extract_group_from_name(product.name)

        OpenStruct.new(
          product_id: product.id,
          product_name: product.name,
          product: product,
          category: category,
          stock_quantity: product.stock_quantity,
          cost_price: cost_price || 0,
          total_cost_stuck: total_cost_stuck,
          days_without_selling: days_without_selling,
          last_sale_date: last_sale_date
        )
      end

      def calculate_days_without_selling(product)
        if product.last_sold_at.present?
          (Date.today - product.last_sold_at.to_date).to_i
        elsif product.created_at.present?
          (Date.today - product.created_at.to_date).to_i
        else
          0
        end
      end

      def extract_group_from_name(name)
        return "Sem categoria" if name.blank?

        # Pega a primeira palavra do nome como grupo
        name.split.first || "Sem categoria"
      end

      def sort_products(products_with_metrics)
        # Ordenar por: custo total parado (DESC) e depois dias sem vender (DESC)
        products_with_metrics.sort_by do |p|
          [-p.total_cost_stuck, -p.days_without_selling]
        end
      end

      def calculate_insights(products_with_metrics)
        # Valor total parado em estoque
        total_stuck_value = products_with_metrics.sum(&:total_cost_stuck)

        # Top categorias que mais travam dinheiro
        categories_data = products_with_metrics.group_by(&:category).map do |category, products|
          {
            category: category || "Sem categoria",
            total_stuck_value: products.sum(&:total_cost_stuck),
            product_count: products.count
          }
        end

        top_categories = categories_data.sort_by { |c| -c[:total_stuck_value] }.first(5)

        {
          total_stuck_value: total_stuck_value,
          top_categories: top_categories
        }
      end
    end
  end
end
