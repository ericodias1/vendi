# frozen_string_literal: true

module Backoffice
  module ProductImports
    # Gera chave composta para detecção de duplicatas: nome + tamanho + marca + cor + código.
    # Produtos com mesmo nome/atributos mas código (SKU ou código fornecedor) diferente são permitidos.
    module DuplicateKey
      class << self
        def from_row(row_data)
          name = row_data['nome'] || row_data[:nome]
          size = row_data['tamanho'] || row_data[:tamanho]
          brand = row_data['marca'] || row_data[:marca]
          color = row_data['cor'] || row_data[:cor]
          sku = row_data['sku'] || row_data[:sku]
          supplier_code = row_data['codigo_fornecedor'] || row_data[:codigo_fornecedor]
          code = code_from(sku, supplier_code)
          build(name, size, brand, color, code)
        end

        def from_attributes(name:, size: nil, brand: nil, color: nil, sku: nil, supplier_code: nil)
          code = code_from(sku, supplier_code)
          build(name, size, brand, color, code)
        end

        # Normalização consistente para comparação (blank -> "").
        def normalize_value(value)
          value.to_s.strip.presence || ""
        end

        private

        def normalize(value)
          value.to_s.strip.presence || ""
        end

        def code_from(sku, supplier_code)
          (sku.to_s.strip.presence || supplier_code.to_s.strip.presence || "").to_s
        end

        def build(name, size, brand, color, code = "")
          return nil if name.blank?

          parameterized_name = name.to_s.strip.parameterize
          [
            parameterized_name,
            normalize(size),
            normalize(brand),
            normalize(color),
            normalize(code)
          ].join("|")
        end
      end
    end
  end
end
