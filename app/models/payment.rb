# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :sale

  str_enum :method, %w[pix credit_card debit_card cash fiado]
  str_enum :status, %w[pending processing paid failed refunded]

  validates :sale_id, presence: true, uniqueness: true
  validates :method, presence: true
  validates :status, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  after_initialize :set_defaults, if: :new_record?

  scope :paid, -> { where(status: "paid") }
  scope :pending, -> { where(status: "pending") }

  def mark_as_paid!
    update!(status: "paid", paid_at: Time.current)
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.metadata ||= {}
  end
end
