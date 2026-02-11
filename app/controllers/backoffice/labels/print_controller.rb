# frozen_string_literal: true

module Backoffice
  module Labels
    class PrintController < Backoffice::BaseController
      PRINT_LIMIT = 200

      def show
        product_ids = current_account.product_label_selections.pluck(:product_id)
        if product_ids.empty?
          redirect_to backoffice_products_path, alert: "Selecione ao menos um produto para imprimir etiquetas."
          return
        end

        base_products = current_account.products.where(id: product_ids).limit(PRINT_LIMIT).to_a
        @por_estoque = ActiveModel::Type::Boolean.new.cast(params[:por_estoque])

        @products = if @por_estoque
          expand_products_by_stock(base_products)
        else
          base_products
        end

        @account_config = current_account.account_config || current_account.build_account_config
        @label_settings = @account_config.label_settings
        render layout: "print"
      end

      private

      def expand_products_by_stock(products)
        result = []
        products.each do |product|
          qty = [product.stock_quantity.to_i, 0].max
          qty = 1 if qty.zero?
          qty.times do
            break if result.size >= PRINT_LIMIT
            result << product
          end
        end
        result
      end
    end
  end
end
