# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ProcessService < Service
      attr_reader :product_import, :account, :current_user

      def initialize(product_import:, account:, current_user:)
        super()
        @product_import = product_import
        @account = account
        @current_user = current_user
      end

      def call
        return false unless valid?

        execute_with_transaction do
          process_import
        end
      end

      private

      def valid?
        validate_presence(:product_import, @product_import) &&
        validate_presence(:account, @account) &&
        validate_presence(:current_user, @current_user) &&
        validate_parsed_data &&
        errors.empty?
      end

      def validate_parsed_data
        return true if @product_import.parsed_data.present? && @product_import.parsed_data.is_a?(Array)

        errors.add(:parsed_data, "Dados parseados não encontrados ou inválidos")
        false
      end

      def process_import
        @product_import.update(status: 'processing')

        # Validar erros de parsing se ignore_errors=false
        return false if should_fail_due_to_parsing_errors?

        # Recalcular e verificar erros de duplicata de nome (modo create_only)
        duplicate_errors = calculate_duplicate_name_errors
        if duplicate_errors.any?
          if @product_import.ignore_errors
            # Salvar erros e continuar
            @product_import.update(import_errors: duplicate_errors)
          else
            # Falhar completamente - salvar erros E status em um único update
            errors.add(:base, "Existem produtos duplicados no arquivo (mesmo nome, tamanho, marca e cor). Corrija antes de importar.")
            @product_import.update(
              import_errors: duplicate_errors,
              status: 'failed'
            )
            return false
          end
        else
          # Limpar erros de duplicata antigos se não há mais duplicatas
          clean_duplicate_errors
        end

        # Inicializar componentes
        import_result = ImportResult.new
        sku_generator = SkuGenerator.new(account: @account, import_result: import_result)
        sku_validator = Validators::SkuValidator.new(account: @account, import_result: import_result)
        name_validator = Validators::NameValidator.new(account: @account, import_result: import_result)
        product_builder = ProductBuilder.new(
          account: @account,
          current_user: @current_user,
          product_import: @product_import
        )
        row_processor = RowProcessor.new(
          account: @account,
          current_user: @current_user,
          product_import: @product_import,
          import_result: import_result,
          sku_generator: sku_generator,
          sku_validator: sku_validator,
          name_validator: name_validator,
          product_builder: product_builder
        )

        # Processar cada linha
        @product_import.parsed_data.each_with_index do |row_data, index|
          row_number = index + 1

          begin
            result = row_processor.process(row_data, row_number: row_number)

            # Se ignore_errors=false e houver erro, falhar completamente
            unless @product_import.ignore_errors
              unless result[:success]
                return fail_import(import_result)
              end
            end
          rescue StandardError => e
            import_result.record_failure(row_number, row_data, ["Erro inesperado: #{e.message}"])
            return fail_import(import_result) unless @product_import.ignore_errors
          end
        end

        # Finalizar importação
        finalize_import(import_result)
      end

      def calculate_duplicate_name_errors
        return [] unless @product_import.create_only?
        return [] unless @product_import.parsed_data.present?

        key_map = {}
        @product_import.parsed_data.each_with_index do |row_data, index|
          composite_key = DuplicateKey.from_row(row_data)
          next unless composite_key.present?

          product_name = row_data['nome'] || row_data[:nome]
          key_map[composite_key] ||= []
          key_map[composite_key] << { row: index + 1, name: product_name, data: row_data }
        end

        duplicate_errors = []
        key_map.each do |_key, entries|
          next if entries.length <= 1

          entries.each do |entry|
            other_rows = entries.reject { |e| e[:row] == entry[:row] }
            other_rows_text = other_rows.map { |e| e[:row] }.join(", ")

            duplicate_errors << {
              'row' => entry[:row],
              'data' => entry[:data],
              'errors' => ["Produto duplicado: \"#{entry[:name]}\" com mesmo tamanho/marca/cor (também na linha #{other_rows_text})"]
            }
          end
        end

        duplicate_errors
      end

      def clean_duplicate_errors
        cleaned = (@product_import.import_errors || []).reject do |error|
          next false unless error.is_a?(Hash)

          error_list = error['errors'] || error[:errors]
          next false unless error_list.is_a?(Array)

          error_list.all? do |err|
            err.is_a?(String) && (
              err.downcase.include?('produto duplicado') ||
              err.downcase.include?('nome duplicado') ||
              err.downcase.include?('também na linha')
            )
          end
        end

        @product_import.update(import_errors: cleaned) if cleaned != @product_import.import_errors
      end

      def should_fail_due_to_parsing_errors?
        return false if @product_import.ignore_errors

        parsing_errors = @product_import.import_errors.select { |e| e.is_a?(Hash) && e['row'].present? }
        if parsing_errors.any?
          errors.add(:base, "Existem erros no arquivo. Desmarque 'Ignorar linhas com erro' para ver os detalhes.")
          @product_import.update(status: 'failed')
          return true
        end

        false
      end

      def fail_import(import_result)
        errors.add(:base, "Importação cancelada devido a erros. Verifique os detalhes abaixo.")
        @product_import.update(
          processed_rows: import_result.processed_rows,
          successful_rows: import_result.successful_rows,
          failed_rows: import_result.failed_rows,
          import_errors: @product_import.import_errors + import_result.errors,
          status: 'failed'
        )
        false
      end

      def finalize_import(import_result)
        final_status = import_result.failed_rows == import_result.processed_rows ? 'failed' : 'completed'

        @product_import.update(
          processed_rows: import_result.processed_rows,
          successful_rows: import_result.successful_rows,
          failed_rows: import_result.failed_rows,
          import_errors: @product_import.import_errors + import_result.errors,
          status: final_status
        )

        true
      end
    end
  end
end
