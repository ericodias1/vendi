# frozen_string_literal: true

module VendiHelper
  def price_display(amount, size: :regular)
    return content_tag(:span, "—", class: "text-slate-400") if amount.nil? || amount.zero?

    size_classes = {
      large: "text-3xl font-bold",
      regular: "text-lg font-bold",
      small: "text-sm font-semibold"
    }

    content_tag :span,
      number_to_currency(amount, unit: "R$ ", separator: ",", delimiter: "."),
      class: size_classes[size],
      style: "color: var(--color-primary);"
  end

  def stock_status_variant(product)
    total_stock = product.total_stock
    return :error if total_stock <= 0
    return :warning if total_stock <= 3
    :success
  end

  def stock_status_label(product)
    total_stock = product.total_stock
    return "SEM ESTOQUE" if total_stock <= 0
    return "BAIXO (#{total_stock})" if total_stock <= 3
    "EM ESTOQUE"
  end

  def payment_method_badge(method)
    method_labels = {
      'pix' => 'PIX',
      'credit_card' => 'CARTÃO DE CRÉDITO',
      'debit_card' => 'CARTÃO DE DÉBITO',
      'cash' => 'DINHEIRO',
      'fiado' => 'FIADO'
    }

    label = method_labels[method.to_s.downcase] || method.to_s.upcase

    content_tag :span,
      label,
      class: "inline-flex items-center px-2.5 py-1 rounded-md text-xs font-semibold uppercase",
      style: "background-color: var(--color-primary-light); color: var(--color-primary-dark);"
  end

  def greeting
    hour = Time.current.hour
    if hour >= 5 && hour < 12
      "Bom dia"
    elsif hour >= 12 && hour < 18
      "Boa tarde"
    else
      "Boa noite"
    end
  end
end
