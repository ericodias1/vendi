# frozen_string_literal: true

class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product

  validates :sale_id, presence: true
  validates :product_id, presence: true
  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :snapshot_product_data, if: -> { product.present? && product_name.blank? }
  before_validation :calculate_totals, if: -> { quantity.present? && unit_price.present? }

  def display_variation
    parts = []
    parts << "Tam #{product_size}" if product_size.present?
    parts << product_color if product_color.present?
    parts.join(" - ").presence || "Sem variação"
  end

  private

  def snapshot_product_data
    self.product_name = product.name
    self.product_size = product.size
    self.product_color = product.color
    self.product_sku = product.sku
    self.cost_price = product.cost_price
  end

  def calculate_totals
    self.subtotal = (quantity * unit_price).round(2)
    self.discount_amount ||= 0
    self.total_amount = (subtotal - discount_amount).round(2)
  end
end
