# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ValidateImportDataService
      def initialize(product_import:)
        @product_import = product_import
      end

      def call
        # No modo update_only, não validar duplicatas (estamos atualizando por ID)
        return [] if @product_import.update_only?
        # No modo create_only, sempre validar duplicatas
        return [] unless @product_import.parsed_data.present?

        detect_duplicate_names_in_csv
      end

      private

      def detect_duplicate_names_in_csv
        errors = []
        key_map = {}

        @product_import.parsed_data.each_with_index do |row_data, index|
          composite_key = DuplicateKey.from_row(row_data)
          next unless composite_key.present?

          product_name = row_data['nome'] || row_data[:nome]
          key_map[composite_key] ||= []
          key_map[composite_key] << { row: index + 1, name: product_name, data: row_data }
        end

        key_map.each do |_key, entries|
          next if entries.length <= 1

          entries.each do |entry|
            other_rows = entries.reject { |e| e[:row] == entry[:row] }
            other_rows_text = other_rows.map { |e| "linha #{e[:row]}" }.join(", ")

            errors << {
              row: entry[:row],
              data: entry[:data],
              errors: ["Produto duplicado: \"#{entry[:name]}\" com mesmo tamanho/marca/cor (também na #{other_rows_text})"]
            }
          end
        end

        errors
      end
    end
  end
end
