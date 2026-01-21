# frozen_string_literal: true

class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Account attributes
  attribute :account_name, :string
  attribute :whatsapp, :string

  # User attributes
  attribute :name, :string
  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  # Validations
  validates :account_name, presence: true
  validates :whatsapp, presence: true
  validates :email, presence: true
  validates :password, presence: true, length: { minimum: 6 }
  validates :password_confirmation, presence: true
  validate :password_confirmation_matches

  # Accessors for models
  def account_attributes
    {
      name: account_name,
      whatsapp: whatsapp,
      active: true
    }
  end

  def user_attributes
    {
      name: name,
      email: email&.downcase&.strip,
      password: password,
      password_confirmation: password_confirmation,
      role: "owner"
    }
  end

  private

  def password_confirmation_matches
    return if password.blank? || password_confirmation.blank?

    unless password == password_confirmation
      errors.add(:password_confirmation, "não confere")
    end
  end
end
