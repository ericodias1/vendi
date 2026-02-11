# frozen_string_literal: true

class ProductLabelSelection < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validates :product_id, uniqueness: { scope: :account_id }
  validate :product_belongs_to_account

  private

  def product_belongs_to_account
    return if product.blank? || account.blank?
    return if product.account_id == account_id

    errors.add(:product, "deve pertencer à conta")
  end
end
