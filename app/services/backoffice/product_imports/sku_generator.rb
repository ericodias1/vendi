# frozen_string_literal: true

module Backoffice
  module ProductImports
    class SkuGenerator
      def initialize(account:, import_result:)
        @account = account
        @import_result = import_result
      end

      def generate(product_name)
        return nil if product_name.blank?

        base_sku = product_name.parameterize.upcase.gsub(/[^A-Z0-9]/, '')
        base_sku = base_sku[0..7] if base_sku.length > 8

        counter = 1
        sku = base_sku
        while sku_exists?(sku)
          suffix = counter.to_s.rjust(2, '0')
          sku = "#{base_sku[0..5]}#{suffix}"
          counter += 1
          break if counter > 99
        end

        sku
      end

      private

      def sku_exists?(sku)
        @import_result.sku_already_imported?(sku) ||
        @account.products.exists?(sku: sku)
      end
    end
  end
end
