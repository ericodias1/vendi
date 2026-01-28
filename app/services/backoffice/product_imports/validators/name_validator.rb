# frozen_string_literal: true

module Backoffice
  module ProductImports
    module Validators
      class NameValidator
        def initialize(account:, import_result:)
          @account = account
          @import_result = import_result
        end

        def validate(product_name, prevent_duplicates: true)
          return [] unless prevent_duplicates
          return [] if product_name.blank?

          parameterized_name = product_name.parameterize

          if @import_result.name_already_imported?(parameterized_name)
            return ["Já existe um produto com o nome '#{product_name}' nesta importação"]
          end

          if @account.products.exists?(parameterized_name: parameterized_name)
            return ["Já existe um produto com o nome '#{product_name}' no sistema"]
          end

          []
        end
      end
    end
  end
end
