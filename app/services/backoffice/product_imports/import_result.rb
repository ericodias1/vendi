# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ImportResult
      attr_reader :processed_rows, :successful_rows, :failed_rows, :errors

      def initialize
        @processed_rows = 0
        @successful_rows = 0
        @failed_rows = 0
        @errors = []
        @imported_names = Set.new
        @imported_skus = Set.new
      end

      def record_success
        @successful_rows += 1
        @processed_rows += 1
      end

      def record_failure(row_number, row_data, error_messages)
        @failed_rows += 1
        @processed_rows += 1
        @errors << { row: row_number, data: row_data, errors: error_messages }
      end

      def track_name(parameterized_name)
        @imported_names << parameterized_name
      end

      def track_sku(sku)
        @imported_skus << sku if sku.present?
      end

      def name_already_imported?(parameterized_name)
        @imported_names.include?(parameterized_name)
      end

      def sku_already_imported?(sku)
        @imported_skus.include?(sku)
      end
    end
  end
end
