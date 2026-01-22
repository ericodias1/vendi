# frozen_string_literal: true

module Backoffice
  module SalesHelper
    def sale_items_description(sale)
      items = sale.sale_items
      return "Nenhum item" if items.empty?

      count = items.sum(&:quantity)
      names = items.limit(2).map { |item| item.product_name }
      
      if count == 1
        "1 item • #{names.first}"
      elsif items.count == 1
        "#{count} itens • #{names.first}"
      elsif items.count == 2
        "#{count} itens • #{names.join(' + ')}"
      else
        "#{count} itens • #{names.first} + outros"
      end
    end

    def payment_method_badge(payment)
      return "Sem pagamento" unless payment

      case payment.method
      when "pix"
        "Pix"
      when "credit_card"
        "Cartão de Crédito"
      when "debit_card"
        "Cartão de Débito"
      when "cash"
        "Dinheiro"
      when "fiado"
        "Fiado"
      else
        payment.method.humanize
      end
    end

    def format_sale_time(sale)
      sale_time = sale.created_at
      today = Date.current
      sale_date = sale_time.to_date

      if sale_date == today
        sale_time.strftime("%H:%M")
      elsif sale_date == today - 1.day
        "Ontem #{sale_time.strftime('%H:%M')}"
      else
        sale_time.strftime("%d/%m %H:%M")
      end
    end

    def sale_status_badge(sale)
      case sale.status
      when "paid"
        render 'shared/ui/badge', text: "PAGA", variant: :success
      when "pending_payment"
        render 'shared/ui/badge', text: "PENDENTE", variant: :warning
      when "cancelled"
        render 'shared/ui/badge', text: "CANCELADA", variant: :error
      else
        render 'shared/ui/badge', text: sale.status.humanize, variant: :info
      end
    end
  end
end
