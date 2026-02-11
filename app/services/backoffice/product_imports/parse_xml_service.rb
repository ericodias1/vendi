# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ParseXmlService < Service
      NFE_NAMESPACE = "http://www.portalfiscal.inf.br/nfe"

      attr_reader :product_import

      def initialize(product_import:)
        super()
        @product_import = product_import
      end

      def call
        return false unless valid?

        execute_with_transaction do
          parse_xml_file
        end
      end

      private

      def valid?
        validate_presence(:product_import, @product_import) &&
          validate_file_attached &&
          errors.empty?
      end

      def validate_file_attached
        return true if @product_import.file.attached?

        errors.add(:file, "Arquivo não anexado")
        false
      end

      def parse_xml_file
        @product_import.update(status: "parsing")

        file_content = @product_import.file.download.force_encoding("UTF-8")
        doc = Nokogiri::XML(file_content)
        doc.remove_namespaces!

        det_elements = doc.xpath("//det")
        if det_elements.empty?
          @product_import.update(
            parsed_data: [],
            import_errors: [{ "row" => 0, "errors" => ["Nenhum item de produto encontrado no XML (elementos det)."] }],
            total_rows: 0,
            status: "ready"
          )
          return true
        end

        parsed_rows = []
        parse_errors = []
        row_number = 0

        det_elements.each do |det|
          row_number += 1
          row_data = extract_row_from_det(det)
          validation_errors = validate_row(row_data, row_number)

          if validation_errors.empty?
            parsed_rows << row_data
          else
            parse_errors << {
              "row" => row_number,
              "data" => row_data,
              "errors" => validation_errors
            }
          end
        end

        grouped_rows = group_by_supplier_code(parsed_rows)

        @product_import.update(
          parsed_data: grouped_rows,
          import_errors: parse_errors,
          total_rows: row_number,
          status: "ready"
        )

        true
      rescue Nokogiri::XML::SyntaxError => e
        @product_import.update(
          status: "failed",
          import_errors: [{ "row" => 0, "errors" => ["Arquivo XML inválido ou não é uma NF-e: #{e.message}"] }]
        )
        errors.add(:base, "Arquivo XML inválido: #{e.message}")
        false
      rescue StandardError => e
        @product_import.update(
          status: "failed",
          import_errors: [{ "row" => 0, "errors" => ["Erro inesperado ao processar XML: #{e.message}"] }]
        )
        errors.add(:base, "Erro inesperado: #{e.message}")
        false
      end

      def extract_row_from_det(det)
        prod = det.at_xpath("prod")
        return build_empty_row unless prod

        nome = text_at(prod, "xProd")
        q_com = decimal_at(prod, "qCom")
        quantidade_estoque = q_com ? q_com.to_i : 0
        v_un_com = decimal_at(prod, "vUnCom")
        v_un_trib = decimal_at(prod, "vUnTrib")
        preco_custo = v_un_com || v_un_trib

        c_prod = text_at(prod, "cProd")
        c_barra = text_at(prod, "cBarra")
        codigo = c_prod.presence || c_barra.presence

        ncm = text_at(prod, "NCM")
        u_com = text_at(prod, "uCom")
        desc_parts = []
        desc_parts << "NCM: #{ncm}" if ncm.present?
        desc_parts << "Un: #{u_com}" if u_com.present?
        descricao = desc_parts.join(" | ").presence

        {
          nome: nome,
          quantidade_estoque: quantidade_estoque,
          preco_custo: preco_custo,
          sku: codigo,
          codigo_fornecedor: codigo,
          descricao: descricao,
          preco_venda: nil,
          preco_base: nil,
          categoria: nil,
          marca: nil,
          cor: nil,
          tamanho: nil,
          ativo: true
        }
      end

      def build_empty_row
        {
          nome: nil,
          quantidade_estoque: 0,
          preco_custo: nil,
          sku: nil,
          codigo_fornecedor: nil,
          descricao: nil,
          preco_venda: nil,
          preco_base: nil,
          categoria: nil,
          marca: nil,
          cor: nil,
          tamanho: nil,
          ativo: true
        }
      end

      def text_at(node, path)
        el = node.at_xpath(path)
        el&.text&.strip.presence
      end

      def decimal_at(node, path)
        el = node.at_xpath(path)
        return nil unless el&.text.present?

        value = el.text.strip
        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

      def validate_row(row_data, row_number)
        errors = []

        if row_data[:nome].blank?
          errors << "Nome é obrigatório"
        end

        if row_data[:quantidade_estoque].nil?
          errors << "Quantidade de estoque é obrigatória"
        elsif row_data[:quantidade_estoque] < 0
          errors << "Quantidade de estoque deve ser maior ou igual a zero"
        end

        if row_data[:preco_custo].present? && row_data[:preco_custo] < 0
          errors << "Preço de custo deve ser maior ou igual a zero"
        end

        errors
      end

      # Agrupa linhas pelo mesmo codigo_fornecedor: uma linha por grupo com quantidade somada.
      # Linhas sem codigo_fornecedor não são agrupadas.
      def group_by_supplier_code(rows)
        with_code = []
        without_code = []

        rows.each do |row|
          code = row[:codigo_fornecedor].to_s.strip
          if code.present?
            with_code << row
          else
            without_code << row
          end
        end

        grouped = with_code.group_by { |r| r[:codigo_fornecedor].to_s.strip }

        result = grouped.map do |_code, group_rows|
          first = group_rows.first
          total_qty = group_rows.sum { |r| r[:quantidade_estoque].to_i }
          first.merge(quantidade_estoque: total_qty)
        end

        result + without_code
      end
    end
  end
end
