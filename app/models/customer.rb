# frozen_string_literal: true

class Customer < ApplicationRecord
  belongs_to :account

  include Searchable
  searchable_columns :name, :phone, :email, :cpf

  include Discard::Model
  default_scope { kept }

  validates :name, presence: true
  validates :account_id, presence: true

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
end
