# frozen_string_literal: true

class ProductImport < ApplicationRecord
  belongs_to :account
  belongs_to :user

  has_many :products, dependent: :nullify
  has_one_attached :file

  default_scope { where(deleted_at: nil) }

  NAME_NORMALIZATION_MODES = %w[none uppercase sentence title].freeze
  IMPORT_MODES = %w[create_only update_only].freeze

  validates :source_type, presence: true, inclusion: { in: %w[csv xml] }
  validates :status, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :name_normalization, inclusion: { in: NAME_NORMALIZATION_MODES }, allow_nil: true
  validates :import_mode, presence: true, inclusion: { in: IMPORT_MODES }

  # Excluir (soft delete) só é permitido quando a importação NÃO foi concluída com sucesso
  def deletable?
    status != "completed"
  end

  def discard!
    update!(deleted_at: Time.current)
  end

  def create_only?
    import_mode == "create_only"
  end

  def update_only?
    import_mode == "update_only"
  end

  after_commit :parse_file, on: :create

  def revertible?
    return false unless status == "completed"

    # Não é reversível se algum produto da importação tiver vendas confirmadas (não rascunho)
    !products.joins(sale_items: :sale).where.not(sales: { status: "draft" }).exists?
  end

  def status_label
    case status
    when 'pending'
      'Pendente'
    when 'parsing'
      'Processando'
    when 'ready'
      'Pronto'
    when 'processing'
      'Importando'
    when 'completed'
      'Concluído'
    when 'reverted'
      'Revertido'
    when 'failed'
      'Falhou'
    else
      status.humanize
    end
  end

  private

  def parse_file
    return unless file.attached?

    case source_type
    when 'csv'
      Backoffice::ProductImports::ParseCsvService.new(product_import: self).call
    when 'xml'
      Backoffice::ProductImports::ParseXmlService.new(product_import: self).call
    end
  end
end
