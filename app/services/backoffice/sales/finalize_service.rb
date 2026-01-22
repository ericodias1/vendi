# frozen_string_literal: true

module Backoffice
  module Sales
    class FinalizeService < Service
      attr_reader :sale, :current_user

      def initialize(sale:, current_user:, send_payment_link: false, payment_received: false)
        super()
        @sale = sale
        @current_user = current_user
        @send_payment_link = send_payment_link
        @payment_received = payment_received
      end

      def call
        return false unless valid?

        execute_with_transaction do
          validate_stock
          create_payment_if_needed
          update_stock
          finalize_sale
        end
      end

      private

      def valid?
        validate_sale &&
        validate_items &&
        validate_payment &&
        errors.empty?
      end

      def validate_sale
        validate_presence(:sale, @sale) &&
        validate_condition(
          @sale.draft?,
          attribute: :base,
          message: "Venda não está em status draft"
        )
      end

      def validate_items
        if @sale.sale_items.empty?
          errors.add(:base, "Venda deve ter pelo menos um item")
          return false
        end
        true
      end

      def validate_payment
        unless @sale.payment.present?
          errors.add(:base, "Método de pagamento deve ser selecionado")
          return false
        end
        true
      end

      def validate_stock
        @sale.sale_items.each do |sale_item|
          product = sale_item.product
          if product.stock_quantity < sale_item.quantity
            errors.add(:base, "Estoque insuficiente para #{product.name}. Disponível: #{product.stock_quantity}")
            raise ActiveRecord::Rollback
          end
        end
      end

      def create_payment_if_needed
        # Payment já deve estar criado no update do controller
        # Apenas validar que existe
        return if @sale.payment.present?

        errors.add(:base, "Método de pagamento não foi selecionado")
        raise ActiveRecord::Rollback
      end

      def update_stock
        @sale.sale_items.each do |sale_item|
          product = sale_item.product
          old_quantity = product.stock_quantity
          new_quantity = old_quantity - sale_item.quantity

          update_model!(
            product,
            { stock_quantity: new_quantity },
            raise_on_error: true
          )

          # Criar StockMovement
          StockMovement.create!(
            product: product,
            account: @sale.account,
            user: @current_user,
            movement_type: :sale,
            quantity_change: -sale_item.quantity,
            quantity_before: old_quantity,
            quantity_after: new_quantity,
            observations: "Venda ##{@sale.sale_number}",
            metadata: { sale_id: @sale.id, sale_item_id: sale_item.id }
          )
        end
      end

      def finalize_sale
        # Atualizar status da venda
        if @payment_received || @sale.payment.method == "cash"
          @sale.complete!
        else
          @sale.update!(status: "pending_payment")
        end

        # TODO: Gerar token de link de pagamento se necessário
        # TODO: Enviar link WhatsApp se solicitado
        # TODO: Verificar alertas de estoque baixo
        # TODO: Verificar metas diárias
      end
    end
  end
end
