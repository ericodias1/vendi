# frozen_string_literal: true

module ProductHelper
  def product_stock_status(product)
    decorated = decorate(product)
    decorated.stock_status
  end

  def product_stock_badge_variant(product)
    decorated = decorate(product)
    decorated.stock_badge_variant
  end

  def product_image_url(product, size: :medium)
    decorated = decorate(product)
    main_image = decorated.main_image
    # `main_image` aqui é um ActiveStorage::Attachment (ex: product.images.first),
    # que não responde a `attached?`. Basta checar presença.
    return nil unless main_image.present?

    case size
    when :thumbnail
      url_for(main_image.variant(resize_to_limit: [100, 100]))
    when :small
      url_for(main_image.variant(resize_to_limit: [200, 200]))
    when :medium
      url_for(main_image.variant(resize_to_limit: [400, 400]))
    when :large
      url_for(main_image.variant(resize_to_limit: [800, 800]))
    else
      url_for(main_image)
    end
  rescue StandardError
    nil
  end

  def format_price(amount)
    return "—" if amount.nil?

    number_to_currency(amount, unit: "R$ ", separator: ",", delimiter: ".")
  end

end
