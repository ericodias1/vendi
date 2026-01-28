# frozen_string_literal: true

module Backoffice
  module ProductImports
    class RowProcessor
      def initialize(
        account:,
        current_user:,
        product_import:,
        import_result:,
        sku_generator:,
        sku_validator:,
        name_validator:,
        product_builder:
      )
        @account = account
        @current_user = current_user
        @product_import = product_import
        @import_result = import_result
        @sku_generator = sku_generator
        @sku_validator = sku_validator
        @name_validator = name_validator
        @product_builder = product_builder
      end

      def process(row_data, row_number:)
        product_attributes = map_row_to_product_attributes(row_data)

        # Gerar SKU se necessário
        if product_attributes[:sku].blank? && @product_import.auto_generate_sku
          product_attributes[:sku] = @sku_generator.generate(product_attributes[:name])
        end

        # Validar SKU
        sku_errors = @sku_validator.validate(product_attributes[:sku])
        return { success: false, errors: sku_errors } if sku_errors.any?

        # Validar nome duplicado
        name_errors = @name_validator.validate(
          product_attributes[:name],
          prevent_duplicates: @product_import.prevent_duplicate_names
        )
        return { success: false, errors: name_errors } if name_errors.any?

        # Criar produto
        result = @product_builder.build_and_save(product_attributes, row_number: row_number)

        if result[:success]
          @import_result.track_name(product_attributes[:name].parameterize)
          @import_result.track_sku(product_attributes[:sku])
          @import_result.record_success
        else
          @import_result.record_failure(row_number, row_data, result[:errors])
        end

        result
      end

      private

      def map_row_to_product_attributes(row_data)
        {
          name: row_data['nome'] || row_data[:nome],
          description: row_data['descricao'] || row_data[:descricao],
          sku: row_data['sku'] || row_data[:sku],
          supplier_code: row_data['codigo_fornecedor'] || row_data[:codigo_fornecedor],
          base_price: row_data['preco_base'] || row_data[:preco_base],
          cost_price: row_data['preco_custo'] || row_data[:preco_custo],
          category: row_data['categoria'] || row_data[:categoria],
          brand: row_data['marca'] || row_data[:marca],
          color: row_data['cor'] || row_data[:cor],
          size: row_data['tamanho'] || row_data[:tamanho],
          stock_quantity: row_data['quantidade_estoque'] || row_data[:quantidade_estoque] || 0,
          active: row_data['ativo'] != false && row_data[:ativo] != false
        }
      end
    end
  end
end
