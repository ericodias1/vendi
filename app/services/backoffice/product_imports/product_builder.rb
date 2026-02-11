# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ProductBuilder
      def initialize(account:, current_user:, product_import:)
        @account = account
        @current_user = current_user
        @product_import = product_import
      end

      def build_and_save(attributes, row_number:)
        product = @account.products.build(attributes.merge(product_import_id: @product_import.id))

        return { success: false, product: product, errors: product.errors.full_messages } unless product.save

        create_initial_stock_movement(product, row_number) if product.stock_quantity > 0

        { success: true, product: product, errors: [] }
      end

      def update_existing(product, attributes, row_number:)
        permitted = attributes.slice(
          :name, :description, :sku, :supplier_code, :base_price, :cost_price,
          :category, :brand, :color, :size, :stock_quantity, :active
        )
        Product.set_current_user(@current_user)
        ok = product.update(permitted)
        { success: ok, product: product, errors: ok ? [] : product.errors.full_messages }
      ensure
        Product.set_current_user(nil)
      end

      # Adiciona quantidade ao estoque de um produto existente (ex.: mesmo código fornecedor na importação).
      def add_quantity_to_existing(product, quantity_to_add, row_number:)
        return { success: false, product: product, errors: ["Quantidade deve ser positiva"] } if quantity_to_add.to_i <= 0

        quantity_before = product.stock_quantity
        quantity_after = quantity_before + quantity_to_add.to_i

        Product.set_current_user(@current_user)
        product.update!(stock_quantity: quantity_after)

        StockMovement.create!(
          product: product,
          account: @account,
          user: @current_user,
          movement_type: :adjustment_in,
          quantity_change: quantity_to_add.to_i,
          quantity_before: quantity_before,
          quantity_after: quantity_after,
          observations: "Entrada - Importação ##{@product_import.id} (código fornecedor)",
          metadata: { product_import_id: @product_import.id, row: row_number }
        )

        { success: true, product: product, errors: [] }
      ensure
        Product.set_current_user(nil)
      end

      private

      def create_initial_stock_movement(product, row_number)
        StockMovement.create!(
          product: product,
          account: @account,
          user: @current_user,
          movement_type: :initial,
          quantity_change: product.stock_quantity,
          quantity_before: 0,
          quantity_after: product.stock_quantity,
          observations: "Estoque inicial - Importação ##{@product_import.id}",
          metadata: { product_import_id: @product_import.id, row: row_number }
        )
      end
    end
  end
end
