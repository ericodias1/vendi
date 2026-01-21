# frozen_string_literal: true

module Backoffice
  module Products
    class StockAdjustmentsController < BaseController
      before_action :set_product

      def edit
      end

      def update
        # Definir current_user para os callbacks
        Product.set_current_user(current_user)
        
        old_stock = @product.stock_quantity
        
        if @product.update(stock_adjustment_params)
          redirect_to backoffice_product_path(@product), notice: "Estoque ajustado com sucesso"
        else
          render :edit, status: :unprocessable_entity
        end
      ensure
        # Limpar current_user após uso
        Product.set_current_user(nil)
      end

      private

      def set_product
        @product = current_account.products.find(params[:product_id])
      end

      def stock_adjustment_params
        params.require(:product).permit(:stock_quantity)
      end
    end
  end
end
