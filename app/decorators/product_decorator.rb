# frozen_string_literal: true

class ProductDecorator < ApplicationDecorator
  # delegate_all is handled by method_missing in ApplicationDecorator
  # All Product methods are automatically delegated

  def stock_badge_variant
    case stock_status
    when :out_of_stock
      :error
    when :low_stock
      :warning
    else
      :success
    end
  end

  def stock_badge_text
    case stock_status
    when :out_of_stock
      "Sem estoque"
    when :low_stock
      "Baixo (#{stock_quantity})"
    else
      "Em estoque (#{stock_quantity})"
    end
  end

  def main_image
    images.first
  end

  def formatted_price
    return "—" if base_price.nil?

    ApplicationController.helpers.number_to_currency(
      base_price,
      unit: "R$ ",
      separator: ",",
      delimiter: "."
    )
  end
end
