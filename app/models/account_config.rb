# frozen_string_literal: true

class AccountConfig < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true, uniqueness: true

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.daily_goal ||= 0
    self.stock_alerts_enabled ||= true
    self.stock_alert_threshold ||= 3
    self.pix_enabled ||= true
    self.card_enabled ||= true
    self.cash_enabled ||= true
    self.credit_enabled ||= false
    self.require_customer ||= false
    self.auto_send_payment_link ||= false
    self.additional_settings ||= {}
  end
end
