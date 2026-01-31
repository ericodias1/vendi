# frozen_string_literal: true

module Backoffice
  module ProductImports
    class NameNormalizer
      # Modos: "none" (ou nil/blank = não alterar), "uppercase", "sentence", "title"
      def self.normalize(name, mode)
        return name.to_s if name.blank?
        return name.to_s if mode.blank? || mode.to_s == "none"

        str = name.to_s.strip
        return str if str.blank?

        case mode.to_s
        when "uppercase"
          str.mb_chars.upcase.to_s
        when "sentence"
          str.mb_chars.downcase.to_s.sub(/\A\p{L}/, &:upcase)
        when "title"
          str.mb_chars.titleize.to_s
        else
          str
        end
      end
    end
  end
end
