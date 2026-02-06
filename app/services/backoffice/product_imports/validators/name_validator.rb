# frozen_string_literal: true

module Backoffice
  module ProductImports
    module Validators
      class NameValidator
        def initialize(account:, import_result:)
          @account = account
          @import_result = import_result
        end

        def validate(product_name, prevent_duplicates: true, exclude_product_id: nil, size: nil, brand: nil, color: nil)
          return [] unless prevent_duplicates
          return [] if product_name.blank?

          composite_key = DuplicateKey.from_attributes(
            name: product_name,
            size: size,
            brand: brand,
            color: color
          )
          return [] unless composite_key.present?

          unless exclude_product_id.present?
            if @import_result.name_already_imported?(composite_key)
              return ["Já existe um produto com o mesmo nome, tamanho, marca e cor nesta importação"]
            end
          end

          scope = scope_for_duplicate_check(
            product_name,
            size: size,
            brand: brand,
            color: color,
            exclude_product_id: exclude_product_id
          )
          if scope.exists?
            return ["Já existe um produto com o mesmo nome, tamanho, marca e cor no sistema"]
          end

          []
        end

        private

        def scope_for_duplicate_check(product_name, size:, brand:, color:, exclude_product_id:)
          parameterized_name = product_name.to_s.strip.parameterize
          norm_size = DuplicateKey.normalize_value(size)
          norm_brand = DuplicateKey.normalize_value(brand)
          norm_color = DuplicateKey.normalize_value(color)

          scope = @account.products.where(parameterized_name: parameterized_name)
          scope = scope.where("TRIM(COALESCE(size, '')) = ?", norm_size)
          scope = scope.where("TRIM(COALESCE(brand, '')) = ?", norm_brand)
          scope = scope.where("TRIM(COALESCE(color, '')) = ?", norm_color)
          scope = scope.where.not(id: exclude_product_id) if exclude_product_id.present?
          scope
        end
      end
    end
  end
end
