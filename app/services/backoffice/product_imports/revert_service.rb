# frozen_string_literal: true

module Backoffice
  module ProductImports
    class RevertService < Service
      attr_reader :product_import, :account

      def initialize(product_import:, account:)
        super()
        @product_import = product_import
        @account = account
      end

      def call
        return false unless valid?

        execute_with_transaction do
          revert_products
        end
      end

      private

      def valid?
        validate_presence(:product_import, @product_import) &&
          validate_presence(:account, @account) &&
          validate_import_belongs_to_account &&
          validate_import_completed &&
          validate_no_products_with_sales &&
          errors.empty?
      end

      def validate_import_belongs_to_account
        return true if @product_import.account_id == @account.id

        errors.add(:base, "Importação não pertence a esta conta")
        false
      end

      def validate_import_completed
        return true if @product_import.status == "completed"

        errors.add(:base, "Só é possível reverter importações concluídas")
        false
      end

      def validate_no_products_with_sales
        products_from_import = @account.products.from_import(@product_import)
        with_sales = products_from_import.select(&:has_sales?)
        return true if with_sales.none?

        errors.add(:base, "Não é possível reverter: #{with_sales.size} produto(s) já possuem vendas registradas")
        false
      end

      def revert_products
        @account.products.from_import(@product_import).find_each(&:destroy)
        @product_import.update!(status: "reverted")
      end
    end
  end
end
