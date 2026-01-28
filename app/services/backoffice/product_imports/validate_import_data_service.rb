# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ValidateImportDataService
      def initialize(product_import:)
        @product_import = product_import
      end

      def call
        return [] unless @product_import.prevent_duplicate_names
        return [] unless @product_import.parsed_data.present?

        detect_duplicate_names_in_csv
      end

      private

      def detect_duplicate_names_in_csv
        errors = []
        name_map = {}

        @product_import.parsed_data.each_with_index do |row_data, index|
          product_name = row_data['nome'] || row_data[:nome]
          next unless product_name.present?

          parameterized_name = product_name.to_s.parameterize
          name_map[parameterized_name] ||= []
          name_map[parameterized_name] << { row: index + 1, name: product_name, data: row_data }
        end

        name_map.each do |parameterized_name, entries|
          next if entries.length <= 1

          entries.each do |entry|
            other_rows = entries.reject { |e| e[:row] == entry[:row] }
            other_rows_text = other_rows.map { |e| "linha #{e[:row]}" }.join(", ")

            errors << {
              row: entry[:row],
              data: entry[:data],
              errors: ["Nome duplicado: \"#{entry[:name]}\" (também na #{other_rows_text})"]
            }
          end
        end

        errors
      end
    end
  end
end
