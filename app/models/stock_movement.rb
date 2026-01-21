# frozen_string_literal: true

class StockMovement < ApplicationRecord
  belongs_to :product
  belongs_to :account
  belongs_to :user, optional: true

  str_enum :movement_type, %w[sale adjustment adjustment_in adjustment_out return initial]

  validates :product_id, presence: true
  validates :account_id, presence: true
  validates :movement_type, presence: true
  validates :quantity_change, presence: true, numericality: { other_than: 0 }
  validates :quantity_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_after, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :set_defaults, if: :new_record?

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(movement_type: type) }

  private

  def set_defaults
    if new_record?
      self.metadata ||= {}
    end
  end
end
