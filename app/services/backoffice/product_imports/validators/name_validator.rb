# frozen_string_literal: true

module Backoffice
  module ProductImports
    module Validators
      class NameValidator
        def initialize(account:, import_result:)
          @account = account
          @import_result = import_result
        end

        def validate(product_name, prevent_duplicates: true, exclude_product_id: nil)
          return [] unless prevent_duplicates
          return [] if product_name.blank?

          parameterized_name = product_name.parameterize

          unless exclude_product_id.present?
            if @import_result.name_already_imported?(parameterized_name)
              return ["Já existe um produto com o nome '#{product_name}' nesta importação"]
            end
          end

          scope = @account.products.where(parameterized_name: parameterized_name)
          scope = scope.where.not(id: exclude_product_id) if exclude_product_id.present?
          if scope.exists?
            return ["Já existe um produto com o nome '#{product_name}' no sistema"]
          end

          []
        end
      end
    end
  end
end
