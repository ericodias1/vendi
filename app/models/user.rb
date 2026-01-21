# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :account

  has_secure_password

  validates :email, presence: true, uniqueness: { scope: :account_id }
  validates :account_id, presence: true
  validates :role, inclusion: { in: %w[owner employee] }

  has_many :sales, dependent: :nullify

  scope :active, -> { where(active: true) }

  after_initialize :set_defaults, if: :new_record?

  def super_admin?
    false # Para futuro, se necessário
  end

  def generate_password_reset_token!
    self.password_reset_token = SecureRandom.urlsafe_base64(32)
    self.password_reset_sent_at = Time.current
    save!
  end

  def clear_password_reset_token!
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    save!
  end

  def password_reset_token_valid?
    return false if password_reset_token.blank?
    return false if password_reset_sent_at.blank?
    
    # Token válido por 2 horas
    password_reset_sent_at > 2.hours.ago
  end

  private

  def set_defaults
    self.role ||= "employee"
    self.active ||= true
  end
end
