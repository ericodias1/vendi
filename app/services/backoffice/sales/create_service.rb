# frozen_string_literal: true

module Backoffice
  module Sales
    class CreateService < Service
      attr_reader :sale, :account, :current_user

      def initialize(account:, current_user:, items:, payment_method:, customer_id: nil, discount_amount: 0, discount_percentage: nil, observations: nil, send_payment_link: false, payment_received: false)
        super()
        @account = account
        @current_user = current_user
        @items = items
        @payment_method = payment_method
        @customer_id = customer_id
        @discount_amount = discount_amount.to_f
        @discount_percentage = discount_percentage
        @observations = observations
        @send_payment_link = send_payment_link
        @payment_received = payment_received
      end

      def call
        return false unless valid?

        execute_with_transaction do
          create_sale
          create_sale_items
          create_payment
          update_stock
          calculate_totals
          finalize_sale
        end
      end

      private

      def valid?
        validate_stock &&
        errors.empty?
      end

      def validate_stock
        @items.each do |item|
          product = Product.find_by(id: item[:product_id], account: @account)
          next unless product

          quantity = item[:quantity].to_i
          if product.stock_quantity < quantity
            errors.add(:base, "Estoque insuficiente para #{product.name}")
          end
        end

        errors[:base].empty?
      end

      def create_sale
        @sale = create_model!(
          @account.sales,
          {
            user: @current_user,
            customer_id: @customer_id,
            status: determine_initial_status,
            observations: @observations,
            discount_amount: @discount_amount,
            discount_percentage: @discount_percentage
          },
          raise_on_error: true
        )
      end

      def create_sale_items
        @items.each do |item_data|
          product = Product.find_by(id: item_data[:product_id], account: @account)
          unless product
            errors.add(:items, "Produto não encontrado")
            raise ActiveRecord::Rollback
          end

          quantity = item_data[:quantity].to_i
          unit_price = item_data[:unit_price].to_f

          sale_item = create_model!(
            @sale.sale_items,
            {
              product: product,
              quantity: quantity,
              unit_price: unit_price,
              product_name: product.name,
              product_size: product.size,
              product_color: product.color,
              product_sku: product.sku
            },
            raise_on_error: true
          )
        end
      end

      def create_payment
        # Calcular subtotal dos itens que serão criados
        subtotal = @items.sum { |item| (item[:quantity].to_i * item[:unit_price].to_f) }
        discount = calculate_discount(subtotal)
        total = (subtotal - discount).round(2)

        payment_attributes = {
          method: @payment_method,
          status: determine_payment_status,
          amount: total
        }

        # Campos específicos por método
        if @payment_method == "credit_card"
          payment_attributes[:installments] = @items.first&.dig(:installments) || 1
        end

        payment = @sale.build_payment(payment_attributes)
        save_model!(payment, raise_on_error: true)
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
            account: @account,
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

      def calculate_totals
        @sale.calculate_totals
      end

      def finalize_sale
        if @payment_received || @payment_method == "cash"
          @sale.complete!
        end

        # TODO: Gerar token de link de pagamento se necessário
        # TODO: Enviar link WhatsApp se solicitado
        # TODO: Verificar alertas de estoque baixo
        # TODO: Verificar metas diárias
      end

      def determine_initial_status
        return "paid" if @payment_received || @payment_method == "cash"
        return "pending_payment" if @payment_method.in?(%w[pix credit_card debit_card fiado])

        "draft"
      end

      def determine_payment_status
        return "paid" if @payment_received || @payment_method == "cash"

        "pending"
      end

      def calculate_discount(subtotal)
        return @discount_amount if @discount_amount > 0
        return (subtotal * (@discount_percentage.to_f / 100)).round(2) if @discount_percentage.present?

        0
      end
    end
  end
end
