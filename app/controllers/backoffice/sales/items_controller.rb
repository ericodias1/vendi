# frozen_string_literal: true

module Backoffice
  module Sales
    class ItemsController < BaseController
      before_action :set_sale
      before_action :set_item, only: [:update, :destroy]

      def create
        @product = current_account.products.find(params[:product_id])
        quantity = params[:quantity].to_i
        unit_price = params[:unit_price].to_f || @product.base_price || 0

        # Validar estoque
        if @product.stock_quantity < quantity
          render turbo_stream: turbo_stream.append("toast-container") do
            render 'shared/ui/toast', type: :error, message: "Estoque insuficiente. Disponível: #{@product.stock_quantity} unidades"
          end
          return
        end

        # Verificar se item já existe (mesmo produto)
        existing_item = @sale.sale_items.find_by(product: @product)
        
        if existing_item
          # Atualizar quantidade
          new_quantity = existing_item.quantity + quantity
          if @product.stock_quantity < new_quantity
            render turbo_stream: turbo_stream.append("toast-container") do
              render 'shared/ui/toast', type: :error, message: "Estoque insuficiente. Disponível: #{@product.stock_quantity} unidades"
            end
            return
          end
          existing_item.update!(quantity: new_quantity)
          @item = existing_item
        else
          # Criar novo item
          @item = @sale.sale_items.create!(
            product: @product,
            quantity: quantity,
            unit_price: unit_price
          )
        end

        @sale.calculate_totals

        respond_to do |format|
          format.turbo_stream
        end
      end

      def update
        quantity = params[:quantity].to_i

        if quantity <= 0
          @item.destroy!
          @sale.calculate_totals
          respond_to do |format|
            format.turbo_stream { render :destroy }
          end
          return
        end

        # Validar estoque
        if @item.product.stock_quantity < quantity
          render turbo_stream: turbo_stream.append("toast-container") do
            render 'shared/ui/toast', type: :error, message: "Estoque insuficiente. Disponível: #{@item.product.stock_quantity} unidades"
          end
          return
        end

        @item.update!(quantity: quantity)
        @sale.calculate_totals

        respond_to do |format|
          format.turbo_stream
        end
      end

      def destroy
        @item.destroy!
        @sale.calculate_totals

        respond_to do |format|
          format.turbo_stream
        end
      end

      private

      def set_sale
        @sale = current_account.sales.with_drafts.draft.find(params[:sale_id])
      end

      def set_item
        @item = @sale.sale_items.find(params[:id])
      end
    end
  end
end
