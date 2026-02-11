# frozen_string_literal: true

module ApplicationHelper
  def decorate(object)
    return nil if object.nil?

    decorator_class = "#{object.class.name}Decorator".constantize
    decorator_class.decorate(object)
  rescue NameError
    object
  end

  def label_value_for_product(product, field_key)
    return "" unless product && field_key.present?
    return "" unless AccountConfig::LABEL_AVAILABLE_FIELDS.include?(field_key.to_s)

    value = case field_key.to_s
            when "base_price" then decorate(product).formatted_price
            when "variation" then product.display_variation
            when "stock_quantity" then product.stock_quantity.to_s
            else product.public_send(field_key).to_s.presence
            end
    value.to_s
  end
end
