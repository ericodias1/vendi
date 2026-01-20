# frozen_string_literal: true

class Product < ApplicationRecord
  belongs_to :account

  include Searchable
  searchable_columns :name, :description, :sku

  include Discard::Model
  default_scope { kept }

  validates :name, presence: true
  validates :account_id, presence: true

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.active ||= true
    self.custom_fields ||= {}
  end
end
