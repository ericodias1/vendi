# frozen_string_literal: true

class Product < ApplicationRecord
  belongs_to :account
  belongs_to :product_import, optional: true

  has_many :stock_movements, dependent: :destroy
  has_many_attached :images

  before_save :set_parameterized_name, if: :will_save_change_to_name?
  before_save :set_parameterized_category, if: :will_save_change_to_category?
  before_save :set_parameterized_supplier, if: :will_save_change_to_supplier?

  # Verificar se produto tem vendas atreladas
  def has_sales?
    stock_movements.where(movement_type: 'sale').exists?
  end

  # Obter última venda do produto
  def last_sale
    stock_movements.where(movement_type: 'sale').order(created_at: :desc).first
  end

  # Formatar data da última venda
  def last_sale_text
    return nil unless last_sale

    sale_date = last_sale.created_at.to_date
    today = Date.today
    yesterday = today - 1.day

    if sale_date == today
      "hoje"
    elsif sale_date == yesterday
      "ontem"
    elsif sale_date >= today - 7.days
      "#{(today - sale_date).to_i} dias atrás"
    else
      sale_date.strftime("%d/%m/%Y")
    end
  end

  include Searchable
  searchable_columns :name, :description, :sku

  include Discard::Model
  default_scope { kept }

  include CurrentUserTrackable

  validates :name, presence: true
  validates :account_id, presence: true
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_low_stock, -> {
    where("stock_quantity > 0 AND stock_quantity <= ?", 3)
  }
  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :low_stock, -> { where("stock_quantity > 0 AND stock_quantity <= ?", 3) }
  scope :out_of_stock, -> { where(stock_quantity: 0) }
  scope :from_import, ->(import) { where(product_import_id: import&.id) }

  after_initialize :set_defaults, if: :new_record?
  after_create :create_initial_stock_movement, if: -> { stock_quantity.positive? }
  after_update :create_stock_movement_on_change, if: :saved_change_to_stock_quantity?

  def available_quantity
    stock_quantity
  end

  def low_stock?(threshold: 3)
    stock_quantity > 0 && stock_quantity <= threshold
  end

  def out_of_stock?
    stock_quantity.zero?
  end

  def in_stock?
    stock_quantity > 0
  end

  def stock_status
    return :out_of_stock if out_of_stock?
    return :low_stock if low_stock?

    :in_stock
  end

  def display_variation
    parts = []
    parts << "Tam #{size}" if size.present?
    parts << color if color.present?
    parts.join(" - ").presence || "Sem variação"
  end

  private

  def set_parameterized_name
    self.parameterized_name = name&.parameterize
  end

  def set_parameterized_category
    self.parameterized_category = category&.parameterize
  end

  def set_parameterized_supplier
    self.parameterized_supplier = supplier&.parameterize
  end

  def set_defaults
    if new_record?
      self.active ||= true
      self.custom_fields ||= {}
      self.stock_quantity ||= 1
    end
  end

  def create_initial_stock_movement
    return unless current_user.present?

    StockMovement.create!(
      product: self,
      account: account,
      user: current_user,
      movement_type: :initial,
      quantity_change: stock_quantity,
      quantity_before: 0,
      quantity_after: stock_quantity,
      observations: "Estoque inicial"
    )
  end

  def create_stock_movement_on_change
    return unless current_user.present?

    quantity_before = saved_change_to_stock_quantity[0]
    quantity_after = saved_change_to_stock_quantity[1]
    quantity_change = quantity_after - quantity_before

    return if quantity_change.zero?

    StockMovement.create!(
      product: self,
      account: account,
      user: current_user,
      movement_type: quantity_change.positive? ? :adjustment_in : :adjustment_out,
      quantity_change: quantity_change.abs,
      quantity_before: quantity_before,
      quantity_after: quantity_after,
      observations: "Ajuste de estoque"
    )
  end
end

