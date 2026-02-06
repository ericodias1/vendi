# frozen_string_literal: true

require 'csv'

module Backoffice
  module ProductImports
    class ParseCsvService < Service
      attr_reader :product_import

      def initialize(product_import:)
        super()
        @product_import = product_import
      end

      def call
        return false unless valid?

        execute_with_transaction do
          parse_csv_file
        end
      end

      private

      def valid?
        validate_presence(:product_import, @product_import) &&
        validate_file_attached &&
        errors.empty?
      end

      def validate_file_attached
        return true if @product_import.file.attached?

        errors.add(:file, "Arquivo não anexado")
        false
      end

      def parse_csv_file
        @product_import.update(status: 'parsing')

        parsed_rows = []
        parse_errors = []
        row_number = 0

        begin
          # Download e ler arquivo
          file_content = @product_import.file.download

          # Parse CSV
          CSV.parse(file_content, headers: true, encoding: 'UTF-8') do |row|
            row_number += 1
            row_data = normalize_row(row.to_h)
            validation_errors = validate_row(row_data, row_number)

            if validation_errors.empty?
              parsed_rows << row_data
            else
              parse_errors << {
                row: row_number,
                data: row_data,
                errors: validation_errors
              }
            end
          end

          # Atualizar ProductImport
          @product_import.update(
            parsed_data: parsed_rows,
            import_errors: parse_errors,
            total_rows: row_number,
            status: parse_errors.empty? ? 'ready' : 'ready' # Sempre ready mesmo com erros, para permitir review
          )

          true
        rescue CSV::MalformedCSVError => e
          @product_import.update(
            status: 'failed',
            import_errors: [{ row: 0, errors: ["Erro ao parsear CSV: #{e.message}"] }]
          )
          errors.add(:base, "Erro ao parsear CSV: #{e.message}")
          false
        rescue StandardError => e
          @product_import.update(
            status: 'failed',
            import_errors: [{ row: 0, errors: ["Erro inesperado: #{e.message}"] }]
          )
          errors.add(:base, "Erro inesperado: #{e.message}")
          false
        end
      end

      def normalize_row(row_hash)
        normalized = {}

        # Normalizar chaves (remover espaços, converter para símbolos)
        row_hash.each do |key, value|
          normalized_key = key.to_s.strip.downcase.to_sym
          normalized[normalized_key] = value.try(:strip) || value
        end

        # Converter booleanos
        if normalized[:ativo].present?
          normalized[:ativo] = normalize_boolean(normalized[:ativo])
        else
          normalized[:ativo] = true # Default
        end

        # Converter números (preco_venda: coluna nova; preco_base mantido para compatibilidade com CSVs antigos)
        normalized[:id] = normalize_integer(normalized[:id])
        normalized[:preco_custo] = normalize_decimal(normalized[:preco_custo])
        normalized[:preco_venda] = normalize_decimal(normalized[:preco_venda] || normalized[:preco_base])
        normalized[:quantidade_estoque] = normalize_integer(normalized[:quantidade_estoque])

        # Campos opcionais podem ser nil se vazios
        normalized[:descricao] = normalized[:descricao].presence
        normalized[:sku] = normalized[:sku].presence
        normalized[:codigo_fornecedor] = normalized[:codigo_fornecedor].presence
        normalized[:categoria] = normalized[:categoria].presence
        normalized[:marca] = normalized[:marca].presence
        normalized[:cor] = normalized[:cor].presence
        normalized[:tamanho] = normalized[:tamanho].presence

        normalized
      end

      def normalize_boolean(value)
        return true if value.blank?

        normalized = value.to_s.strip.downcase.parameterize

        return true if normalized.in?(%w[sim true 1])

        return false if normalized.in?(%w[nao nao false 0])

        true
      end

      def normalize_decimal(value)
        decimal = CurrencyParser.parse(value)
        return nil if decimal.nil? || decimal < 0
        decimal
      end

      def normalize_integer(value)
        return nil if value.blank?

        integer = Integer(value.to_s.strip)
        return nil if integer < 0
        integer
      rescue ArgumentError, TypeError
        nil
      end

      def validate_row(row_data, row_number)
        errors = []

        # Nome obrigatório
        if row_data[:nome].blank?
          errors << "Nome é obrigatório"
        end

        # Quantidade estoque obrigatória
        if row_data[:quantidade_estoque].nil?
          errors << "Quantidade de estoque é obrigatória"
        elsif row_data[:quantidade_estoque] < 0
          errors << "Quantidade de estoque deve ser maior ou igual a zero"
        end

        # Preços devem ser positivos se informados
        if row_data[:preco_custo].present? && row_data[:preco_custo] < 0
          errors << "Preço de custo deve ser maior ou igual a zero"
        end

        if row_data[:preco_venda].present? && row_data[:preco_venda] < 0
          errors << "Preço de venda deve ser maior ou igual a zero"
        end

        # ID (quando presente) deve ser inteiro positivo
        if row_data[:id].present? && row_data[:id].to_i < 1
          errors << "ID do produto deve ser um número inteiro positivo"
        end

        errors
      end

    end
  end
end
