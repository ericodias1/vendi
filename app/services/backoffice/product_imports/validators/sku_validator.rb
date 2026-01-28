# frozen_string_literal: true

module Backoffice
  module ProductImports
    module Validators
      class SkuValidator
        def initialize(account:, import_result:)
          @account = account
          @import_result = import_result
        end

        def validate(sku)
          return [] if sku.blank?

          if @import_result.sku_already_imported?(sku)
            return ["SKU '#{sku}' já foi usado nesta importação"]
          end

          if @account.products.exists?(sku: sku)
            return ["SKU '#{sku}' já existe no sistema"]
          end

          []
        end
      end
    end
  end
end
