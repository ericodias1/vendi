# frozen_string_literal: true

module Backoffice
  module ProductImports
    class SkuGenerator
      NUMBERS_ONLY_LENGTH = 8
      NUMBERS_AND_LETTERS_LENGTH = 6
      ALPHANUMERIC_CHARS = ("A".."Z").to_a + ("0".."9").to_a

      def initialize(account:, import_result:, mode: "name_prefix")
        @account = account
        @import_result = import_result
        @mode = mode.presence || "name_prefix"
      end

      def generate(product_name = nil)
        case @mode
        when "numbers_only"
          generate_numbers_only
        when "numbers_and_letters"
          generate_numbers_and_letters
        else
          generate_name_prefix(product_name)
        end
      end

      private

      def generate_name_prefix(product_name)
        return nil if product_name.blank?

        base_sku = product_name.parameterize.upcase.gsub(/[^A-Z0-9]/, "")
        base_sku = base_sku[0..7] if base_sku.length > 8

        counter = 1
        sku = base_sku
        while sku_exists?(sku)
          suffix = counter.to_s.rjust(2, "0")
          sku = "#{base_sku[0..5]}#{suffix}"
          counter += 1
          break if counter > 99
        end

        sku
      end

      def generate_numbers_only
        max_attempts = 1000
        max_attempts.times do
          sku = rand(10**(NUMBERS_ONLY_LENGTH - 1)..10**NUMBERS_ONLY_LENGTH - 1).to_s
          return sku unless sku_exists?(sku)
        end
        nil
      end

      def generate_numbers_and_letters
        max_attempts = 1000
        max_attempts.times do
          sku = NUMBERS_AND_LETTERS_LENGTH.times.map { ALPHANUMERIC_CHARS.sample }.join
          return sku unless sku_exists?(sku)
        end
        nil
      end

      def sku_exists?(sku)
        @import_result.sku_already_imported?(sku) ||
          @account.products.exists?(sku: sku)
      end
    end
  end
end
