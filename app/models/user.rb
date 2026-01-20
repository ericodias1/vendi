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

  private

  def set_defaults
    self.role ||= "employee"
    self.active ||= true
  end
end
