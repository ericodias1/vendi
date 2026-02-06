# frozen_string_literal: true

module Backoffice
  module ProductImports
    # Gera chave composta para detecção de duplicatas: nome + tamanho + marca + cor.
    # Produtos com mesmo nome mas tamanho/marca/cor diferentes não são considerados duplicados.
    module DuplicateKey
      class << self
        def from_row(row_data)
          name = row_data['nome'] || row_data[:nome]
          size = row_data['tamanho'] || row_data[:tamanho]
          brand = row_data['marca'] || row_data[:marca]
          color = row_data['cor'] || row_data[:cor]
          build(name, size, brand, color)
        end

        def from_attributes(name:, size: nil, brand: nil, color: nil)
          build(name, size, brand, color)
        end

        # Normalização consistente para comparação (blank -> "").
        def normalize_value(value)
          value.to_s.strip.presence || ""
        end

        private

        def normalize(value)
          value.to_s.strip.presence || ""
        end

        def build(name, size, brand, color)
          return nil if name.blank?

          parameterized_name = name.to_s.strip.parameterize
          [
            parameterized_name,
            normalize(size),
            normalize(brand),
            normalize(color)
          ].join("|")
        end
      end
    end
  end
end
