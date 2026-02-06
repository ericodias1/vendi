# frozen_string_literal: true

module Backoffice
  module Products
    class QuickSalesController < Backoffice::BaseController
      before_action :set_product

      def create

        if @product.stock_quantity < 1
          redirect_to backoffice_products_path, alert: "Estoque insuficiente para este produto."
          return
        end

        sale = current_account.sales.with_drafts.create!(
          account: current_account,
          user: current_user,
          status: "draft"
        )

        unit_price = @product.base_price || 0
        sale.sale_items.create!(
          product: @product,
          quantity: 1,
          unit_price: unit_price
        )
        sale.calculate_totals

        redirect_to edit_backoffice_sale_details_path(sale), notice: "Venda rápida iniciada. Conclua o pagamento abaixo."
      end

      private

      def set_product
        @product = current_account.products.find(params[:product_id])
      end
    end
  end
end
