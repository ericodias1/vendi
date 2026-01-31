# frozen_string_literal: true

module Backoffice
  module ProductImports
    module Validators
      class SkuValidator
        def initialize(account:, import_result:)
          @account = account
          @import_result = import_result
        end

        def validate(sku, exclude_product_id: nil)
          return [] if sku.blank?

          unless exclude_product_id.present?
            if @import_result.sku_already_imported?(sku)
              return ["SKU '#{sku}' já foi usado nesta importação"]
            end
          end

          scope = @account.products.where(sku: sku)
          scope = scope.where.not(id: exclude_product_id) if exclude_product_id.present?
          if scope.exists?
            return ["SKU '#{sku}' já existe no sistema"]
          end

          []
        end
      end
    end
  end
end
