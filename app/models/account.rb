# frozen_string_literal: true

class Account < ApplicationRecord
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :timezone, presence: true

  has_one :account_config, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :customers, dependent: :destroy

  include Discard::Model
  default_scope { kept }

  scope :active, -> { where(active: true) }

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.timezone ||= "America/Sao_Paulo"
    self.active ||= true
  end
end
