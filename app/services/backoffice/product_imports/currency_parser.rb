# frozen_string_literal: true

module Backoffice
  module ProductImports
    # Aceita formatos comuns de valor monetário no CSV:
    # R$10,00 | R$ 10,00 | 10,00 | 10.00 | 1.000,50
    module CurrencyParser
      class << self
        # Converte string (ou número) para Float. Retorna nil se vazio ou inválido.
        def parse(value)
          return nil if value.blank?
          return value.to_f if value.is_a?(Numeric)

          s = value.to_s.strip
          # Remove prefixo R$ (com ou sem espaço)
          s = s.gsub(/\A\s*R\s*\$\s*/i, "").strip
          return nil if s.blank?

          # Formato BR (vírgula = decimal, ponto = milhar): 1.000,50 ou 10,00
          # Formato US (ponto = decimal): 10.00
          if s.include?(",")
            s = s.gsub(".", "")  # remove separador de milhar
            s = s.tr(",", ".")   # vírgula vira decimal
          end

          Float(s)
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
