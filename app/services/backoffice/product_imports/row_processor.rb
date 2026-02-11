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
        product_id = product_attributes.delete(:product_id)

        if @product_import.update_only?
          process_update_mode(product_attributes, product_id, row_number, row_data)
        else
          process_create_mode(product_attributes, row_number, row_data)
        end
      end

      private

      def process_update_mode(product_attributes, product_id, row_number, row_data)
        # Exigir ID válido
        if product_id.blank?
          result = { success: false, errors: ["Coluna 'id' é obrigatória no modo de atualização"] }
          track_result(result, product_attributes, row_number, row_data)
          return result
        end

        existing = @account.products.find_by(id: product_id)
        unless existing
          result = { success: false, errors: ["Produto com ID #{product_id} não encontrado"] }
          track_result(result, product_attributes, row_number, row_data)
          return result
        end

        # Normalizar nome e gerar SKU se necessário
        apply_name_normalization(product_attributes)
        generate_sku_if_needed(product_attributes)

        # Validar SKU/nome excluindo produto atual
        sku_errors = @sku_validator.validate(product_attributes[:sku], exclude_product_id: existing.id)
        if sku_errors.any?
          result = { success: false, errors: sku_errors }
          track_result(result, product_attributes, row_number, row_data)
          return result
        end

        name_errors = @name_validator.validate(
          product_attributes[:name],
          prevent_duplicates: true,
          exclude_product_id: existing.id,
          size: product_attributes[:size],
          brand: product_attributes[:brand],
          color: product_attributes[:color]
        )
        if name_errors.any?
          result = { success: false, errors: name_errors }
          track_result(result, product_attributes, row_number, row_data)
          return result
        end

        result = @product_builder.update_existing(existing, product_attributes, row_number: row_number)
        track_result(result, product_attributes, row_number, row_data)
        result
      end

      def process_create_mode(product_attributes, row_number, row_data)
        # Mesmo código do fornecedor: não duplicar produto, apenas somar quantidade
        if product_attributes[:supplier_code].present?
          existing = @account.products.find_by(supplier_code: product_attributes[:supplier_code])
          if existing
            result = @product_builder.add_quantity_to_existing(
              existing,
              product_attributes[:stock_quantity],
              row_number: row_number
            )
            track_result_for_existing(result, existing, row_number, row_data)
            return result
          end
        end

        apply_name_normalization(product_attributes)
        generate_sku_if_needed(product_attributes)

        # Sempre validar duplicatas no modo criação
        sku_errors = @sku_validator.validate(product_attributes[:sku])
        if sku_errors.any?
          result = { success: false, errors: sku_errors }
          track_result(result, product_attributes, row_number, row_data)
          return result
        end

        name_errors = @name_validator.validate(
          product_attributes[:name],
          prevent_duplicates: true,
          size: product_attributes[:size],
          brand: product_attributes[:brand],
          color: product_attributes[:color]
        )
        if name_errors.any?
          result = { success: false, errors: name_errors }
          track_result(result, product_attributes, row_number, row_data)
          return result
        end

        result = @product_builder.build_and_save(product_attributes, row_number: row_number)
        track_result(result, product_attributes, row_number, row_data)
        result
      end

      def apply_name_normalization(product_attributes)
        mode = @product_import.name_normalization
        if mode.present? && product_attributes[:name].present?
          product_attributes[:name] = NameNormalizer.normalize(product_attributes[:name], mode)
        end
      end

      def generate_sku_if_needed(product_attributes)
        if product_attributes[:sku].blank? && @product_import.auto_generate_sku
          product_attributes[:sku] = @sku_generator.generate(product_attributes[:name])
        end
      end

      def track_result(result, product_attributes, row_number, row_data)
        if result[:success]
          composite_key = DuplicateKey.from_attributes(
            name: product_attributes[:name],
            size: product_attributes[:size],
            brand: product_attributes[:brand],
            color: product_attributes[:color]
          )
          @import_result.track_name(composite_key)
          @import_result.track_sku(product_attributes[:sku])
          @import_result.record_success
        else
          @import_result.record_failure(row_number, row_data, result[:errors])
        end
      end

      def track_result_for_existing(result, existing_product, row_number, row_data)
        if result[:success]
          composite_key = DuplicateKey.from_attributes(
            name: existing_product.name,
            size: existing_product.size,
            brand: existing_product.brand,
            color: existing_product.color
          )
          @import_result.track_name(composite_key)
          @import_result.track_sku(existing_product.sku)
          @import_result.record_success
        else
          @import_result.record_failure(row_number, row_data, result[:errors])
        end
      end

      def map_row_to_product_attributes(row_data)
        id_value = row_data['id'] || row_data[:id]
        product_id = id_value.present? ? id_value.to_i : nil
        product_id = nil if product_id.to_i < 1

        {
          product_id: product_id,
          name: row_data['nome'] || row_data[:nome],
          description: row_data['descricao'] || row_data[:descricao],
          sku: row_data['sku'] || row_data[:sku],
          supplier_code: row_data['codigo_fornecedor'] || row_data[:codigo_fornecedor],
          base_price: row_data['preco_venda'] || row_data[:preco_venda] || row_data['preco_base'] || row_data[:preco_base],
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
