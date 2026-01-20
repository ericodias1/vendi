# frozen_string_literal: true

class Sale < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :customer, optional: true

  include Searchable
  searchable_columns :sale_number, :observations

  validates :sale_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true

  str_enum :status, %w[draft pending_payment paid cancelled]

  scope :recent, -> { order(created_at: :desc) }
  scope :paid, -> { where(status: "paid") }

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.status ||= "draft"
    self.subtotal ||= 0
    self.discount_amount ||= 0
    self.total_amount ||= 0
    self.total_items ||= 0
  end
end
