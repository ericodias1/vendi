# frozen_string_literal: true

module ProductVariationsHelper
  def available_sizes_for_account
    return ProductVariations::SIZES unless current_account&.account_config

    current_account.account_config.enabled_sizes_list
  end

  def available_colors_for_account
    return ProductVariations::COLORS unless current_account&.account_config

    current_account.account_config.enabled_colors_list
  end
end
