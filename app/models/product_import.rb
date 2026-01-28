# frozen_string_literal: true

class ProductImport < ApplicationRecord
  belongs_to :account
  belongs_to :user

  has_one_attached :file

  validates :source_type, presence: true, inclusion: { in: %w[csv xml] }
  validates :status, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true

  after_commit :parse_file, on: :create

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
      # Backoffice::ProductImports::ParseXmlService.new(product_import: self).call
      # TODO: Implementar ParseXmlService no futuro
    end
  end
end
