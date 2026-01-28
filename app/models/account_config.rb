# frozen_string_literal: true

class AccountConfig < ApplicationRecord
  include ProductVariations

  belongs_to :account

  validates :account_id, presence: true, uniqueness: true
  validates :daily_goal, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :stock_alert_threshold, numericality: { greater_than: 0 }, allow_nil: true
  validate :enabled_sizes_are_valid
  validate :enabled_colors_are_valid
  validate :at_least_one_payment_method_enabled

  after_initialize :set_defaults, if: :new_record?

  def enabled_sizes_list
    enabled_sizes.presence || ProductVariations::SIZES
  end

  def enabled_colors_list
    enabled_colors.presence || ProductVariations::COLORS
  end

  private

  def at_least_one_payment_method_enabled
    payment_flags = [
      pix_enabled,
      card_enabled,
      cash_enabled,
      fiado_enabled
    ]

    return if payment_flags.any?

    errors.add(:base, "Pelo menos uma forma de pagamento deve estar ativa")
  end

  def set_defaults
    self.daily_goal ||= 0
    self.stock_alerts_enabled ||= true
    self.stock_alert_threshold ||= 3
    self.high_profit_margin_threshold ||= 50.0
    self.pix_enabled ||= true
    self.card_enabled ||= true
    self.cash_enabled ||= true
    self.fiado_enabled ||= false
    self.require_customer ||= false
    self.auto_send_payment_link ||= false
    self.additional_settings ||= {}
    self.enabled_sizes ||= []
    self.enabled_colors ||= []
  end

  def enabled_sizes_are_valid
    return if enabled_sizes.blank?

    invalid_sizes = enabled_sizes - ProductVariations::SIZES
    return if invalid_sizes.empty?

    errors.add(:enabled_sizes, "contém tamanhos inválidos: #{invalid_sizes.join(', ')}")
  end

  def enabled_colors_are_valid
    return if enabled_colors.blank?

    invalid_colors = enabled_colors - ProductVariations::COLORS
    return if invalid_colors.empty?

    errors.add(:enabled_colors, "contém cores inválidas: #{invalid_colors.join(', ')}")
  end
end
