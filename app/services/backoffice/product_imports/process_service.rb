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

        # Validar duplicatas no CSV se prevent_duplicate_names=true
        duplicate_errors = ValidateImportDataService.new(product_import: @product_import).call
        if duplicate_errors.any?
          if @product_import.ignore_errors
            # Adicionar erros mas continuar
            @product_import.update(import_errors: @product_import.import_errors + duplicate_errors)
          else
            # Falhar completamente
            errors.add(:base, "Existem nomes duplicados no arquivo. Corrija antes de importar.")
            @product_import.update(
              import_errors: @product_import.import_errors + duplicate_errors,
              status: 'failed'
            )
            return false
          end
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
