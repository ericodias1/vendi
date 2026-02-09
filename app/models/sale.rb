# frozen_string_literal: true

class Sale < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :customer, optional: true

  has_many :sale_items, dependent: :destroy
  has_one :payment, dependent: :destroy

  include Searchable
  searchable_columns :sale_number, :observations

  validates :sale_number, presence: true, uniqueness: { scope: :account_id }
  validates :status, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :discount_cannot_exceed_subtotal

  str_enum :status, %w[draft pending_payment paid cancelled]

  default_scope { where.not(status: "draft") }

  scope :recent, -> { order(created_at: :desc) }
  scope :paid, -> { where(status: "paid") }
  # Apenas remove o default_scope (not draft), mantendo demais escopos (ex.: account da associação).
  scope :with_drafts, -> { unscope(where: :status) }
  scope :draft, -> { where(status: "draft") }
  scope :today, -> { where('created_at >= ?', Date.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', 7.days.ago.beginning_of_day) }
  scope :this_month, -> { where('created_at >= ?', Date.current.beginning_of_month) }
  scope :by_period, ->(period) {
    case period.to_s
    when 'today' then today
    when 'week' then this_week
    when 'month' then this_month
    else today
    end
  }

  before_validation :generate_sale_number, on: :create, if: -> { sale_number.blank? }
  after_create :calculate_totals

  # Rede de segurança: se outro processo gerou o mesmo número (ex.: timezone/replica),
  # regenera e tenta salvar uma vez.
  def save(*args, **kwargs)
    super(*args, **kwargs)
  rescue ActiveRecord::RecordNotUnique => e
    raise unless unique_violation_sale_number?(e)
    raise if @_sale_number_retry

    @_sale_number_retry = true
    self.sale_number = nil
    generate_sale_number
    self.save(*args, **kwargs)
  end

  def generate_sale_number
    return if sale_number.present?
    
    date_prefix = Date.current.strftime("%Y%m%d")
    last_sale = Sale.with_drafts.where(account: account)
                    .where("sale_number LIKE ?", "#{date_prefix}-%")
                    .order(sale_number: :desc)
                    .first

    if last_sale
      last_number = last_sale.sale_number.split("-").last.to_i
      next_number = last_number + 1
    else
      next_number = 1
    end

    self.sale_number = "#{date_prefix}-#{next_number.to_s.rjust(4, '0')}"
  end

  def calculate_totals
    self.subtotal = sale_items.sum(&:subtotal).round(2)
    self.discount_amount ||= 0
    self.total_amount = (subtotal - discount_amount).round(2)
    self.total_items = sale_items.sum(&:quantity)
    save(validate: false) if persisted?
  end

  def complete!
    update!(
      status: "paid",
      completed_at: Time.current
    )
    payment&.mark_as_paid!
  end

  def cancel!(reason: nil, user: nil)
    transaction do
      update!(
        status: "cancelled",
        cancelled_at: Time.current,
        cancellation_reason: reason
      )

      # Reverter estoque
      sale_items.each do |item|
        product = item.product
        old_quantity = product.stock_quantity
        new_quantity = old_quantity + item.quantity

        product.update!(stock_quantity: new_quantity)

        StockMovement.create!(
          product: product,
          account: account,
          user: user,
          movement_type: :return,
          quantity_change: item.quantity,
          quantity_before: old_quantity,
          quantity_after: new_quantity,
          observations: "Cancelamento da venda ##{sale_number}",
          metadata: { sale_id: id, sale_item_id: item.id }
        )
      end
    end
  end

  def can_cancel?
    return false if cancelled?
    return true if pending_payment?
    return true if paid? && completed_at && completed_at > 24.hours.ago

    false
  end

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.status ||= "draft"
    self.subtotal ||= 0
    self.discount_amount ||= 0
    self.total_amount ||= 0
    self.total_items ||= 0
  end

  def discount_cannot_exceed_subtotal
    return if discount_amount.blank? || subtotal.blank?
    return if discount_amount.zero?

    if discount_amount > subtotal
      errors.add(:discount_amount, "não pode ser maior que o subtotal")
    end
  end

  def unique_violation_sale_number?(exception)
    return true if exception.message.include?("index_sales_on_account_id_and_sale_number")
    return true if exception.message.include?("index_sales_on_sale_number")
    return true if exception.message.include?("sale_number")

    cause = exception.cause
    cause.is_a?(PG::UniqueViolation) && cause.message.include?("sale_number")
  end
end
