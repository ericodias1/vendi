# frozen_string_literal: true

class Customer < ApplicationRecord
  belongs_to :account

  include Searchable
  searchable_columns :name, :phone, :email, :cpf

  include Discard::Model
  default_scope { kept }

  validates :name, presence: true
  validates :account_id, presence: true
  validate :unique_name_and_phone_per_account

  has_many :sales, dependent: :nullify

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.active ||= true
    self.total_purchases ||= 0
    self.total_spent ||= 0
  end

  def unique_name_and_phone_per_account
    return if account_id.blank? || name.blank?

    normalized_name = name.to_s.parameterize
    normalized_phone = normalize_phone(phone)

    scope = Customer.where(account_id: account_id).where.not(id: id)
    duplicate = scope.find_each.any? do |c|
      c.name.to_s.parameterize == normalized_name && normalize_phone(c.phone) == normalized_phone
    end

    errors.add(:base, "já existe um cliente com este nome e telefone nesta conta") if duplicate
  end

  def normalize_phone(value)
    value.to_s.gsub(/\D/, "").presence || ""
  end
end
