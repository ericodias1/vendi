# frozen_string_literal: true

module Backoffice
  class ProductImportsController < BaseController
    def index
      @product_imports = current_account.product_imports.order(created_at: :desc)
    end

    def new
      @account_config = current_account.account_config || current_account.build_account_config
      @import_defaults = {
        import_mode: "create_only",
        auto_generate_sku: @account_config.product_import_auto_generate_sku?,
        ignore_errors: @account_config.product_import_ignore_errors?
      }
    end

    def create
      # Aceitar tanto file (CSV) quanto xml_file (XML)
      file = params[:file] || params[:xml_file]
      source_type = params[:source_type] || (params[:xml_file].present? ? "xml" : "csv")

      if file.blank?
        redirect_to new_backoffice_product_import_path, alert: "Selecione um arquivo para importar"
        return
      end

      @product_import = current_account.product_imports.build(
        user: current_user,
        source_type: source_type,
        import_mode: permitted_import_mode(params[:import_mode]),
        auto_generate_sku: params[:auto_generate_sku] == "1",
        ignore_errors: params[:ignore_errors] == "1",
        name_normalization: permitted_name_normalization(params[:name_normalization])
      )

      @product_import.file.attach(file)

      if @product_import.save
        save_import_settings_to_account_config
        # O callback after_commit do model fará o parsing automaticamente
        redirect_to backoffice_product_import_path(@product_import), notice: "Arquivo enviado. Processando..."
      else
        flash.now[:error] = "Erro ao criar importação: #{@product_import.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @product_import = current_account.product_imports.find(params[:id])
      @account_config = current_account.account_config || current_account.build_account_config
    end

    def update
      @product_import = current_account.product_imports.find(params[:id])

      # Converter parsed_data de JSON string para array
      if params[:product_import][:parsed_data].present?
        begin
          parsed_data = JSON.parse(params[:product_import][:parsed_data])
          params[:product_import][:parsed_data] = parsed_data
        rescue JSON::ParserError
          flash.now[:error] = "Erro ao processar dados. Tente novamente."
          render :show, status: :unprocessable_entity
          return
        end
      end

      update_params = product_import_params.dup
      update_params[:parsed_data] = parsed_data if parsed_data.present?

      if @product_import.update(update_params)
        # Recalcular erros de duplicata após salvar (para refletir as edições do usuário)
        recalculate_duplicate_errors_for(@product_import) if parsed_data.present?
        redirect_to backoffice_product_import_path(@product_import), notice: "Alterações salvas com sucesso"
      else
        flash.now[:error] = "Erro ao salvar alterações: #{@product_import.errors.full_messages.join(', ')}"
        render :show, status: :unprocessable_entity
      end
    end

    def process_import
      @product_import = current_account.product_imports.find(params[:id])

      # Atualizar parsed_data se foi enviado no form
      if params[:parsed_data].present?
        begin
          parsed_data = JSON.parse(params[:parsed_data])
          @product_import.update(parsed_data: parsed_data)
        rescue JSON::ParserError
          redirect_to backoffice_product_import_path(@product_import), alert: "Erro ao processar dados. Tente novamente."
          return
        end
      end

      service = Backoffice::ProductImports::ProcessService.new(
        product_import: @product_import,
        account: current_account,
        current_user: current_user
      )

      if service.call
        # Recarregar para pegar o status atualizado
        @product_import.reload
        
        # Se importação foi concluída com sucesso, redirecionar para produtos
        if @product_import.status == 'completed' && @product_import.failed_rows == 0
          redirect_to backoffice_products_path, notice: "Importação concluída com sucesso! #{@product_import.successful_rows} produto(s) importado(s)."
        else
          redirect_to backoffice_product_import_path(@product_import), alert: "Importação concluída com erros. Verifique os detalhes abaixo."
        end
      else
        redirect_to backoffice_product_import_path(@product_import), alert: "Importação concluída com erros. Verifique os detalhes abaixo."
      end
    end

    def destroy
      @product_import = current_account.product_imports.find(params[:id])

      unless @product_import.deletable?
        redirect_to backoffice_product_imports_path, alert: "Não é possível excluir uma importação já concluída com sucesso."
        return
      end

      @product_import.discard!
      redirect_to backoffice_product_imports_path, notice: "Importação excluída da lista."
    end

    def revert
      @product_import = current_account.product_imports.find(params[:id])
      service = Backoffice::ProductImports::RevertService.new(
        product_import: @product_import,
        account: current_account
      )

      if service.call
        redirect_to backoffice_product_imports_path, notice: "Importação revertida. Os produtos importados foram removidos."
      else
        redirect_to backoffice_product_imports_path, alert: service.errors.full_messages.join(" ")
      end
    end

    def calculate_prices
      costs = normalize_costs_array(params[:costs])
      markup_percent = params[:markup_percent]
      rounding_mode = params[:rounding_mode]

      if markup_percent.blank? || rounding_mode.blank?
        render json: { error: "markup_percent e rounding_mode são obrigatórios" }, status: :unprocessable_entity
        return
      end

      prices = costs.map do |cost|
        result = AutomaticPricing::Calculator.calculate(cost, markup_percent, rounding_mode)
        result ? result.to_f.round(2) : nil
      end

      render json: { prices: prices }
    end

    private

    def product_import_params
      # parsed_data vem como JSON string, já convertido no update
      params.require(:product_import).permit(:observations)
    end

    def permitted_name_normalization(value)
      return nil if value.blank?
      return value if ProductImport::NAME_NORMALIZATION_MODES.include?(value.to_s)

      nil
    end

    def permitted_import_mode(value)
      return "create_only" if value.blank?
      return value if ProductImport::IMPORT_MODES.include?(value.to_s)

      "create_only"
    end

    # Garante um array com um elemento por índice (0, 1, 2, ...).
    # Rails pode receber JSON array como Hash com chaves "0", "1", "2"; .to_a quebraria a ordem.
    def normalize_costs_array(costs)
      case costs
      when Array
        costs
      when Hash, ActionController::Parameters
        n = costs.size
        (0...n).map { |i| costs[i] || costs[i.to_s] }
      else
        []
      end
    end

    def recalculate_duplicate_errors_for(product_import)
      return unless product_import.create_only?
      return unless product_import.parsed_data.present?

      # Remover erros antigos de duplicata
      cleaned_errors = (product_import.import_errors || []).reject do |error|
        next false unless error.is_a?(Hash)
        error_list = error['errors'] || error[:errors]
        next false unless error_list.is_a?(Array)
        error_list.all? do |e|
          e.is_a?(String) && (
            e.downcase.include?('produto duplicado') ||
            e.downcase.include?('nome duplicado') ||
            e.downcase.include?('também na linha')
          )
        end
      end

      # Calcular novas duplicatas por chave composta (nome + tamanho + marca + cor)
      key_map = {}
      product_import.parsed_data.each_with_index do |row_data, index|
        composite_key = Backoffice::ProductImports::DuplicateKey.from_row(row_data)
        next unless composite_key.present?
        product_name = row_data['nome'] || row_data[:nome]
        key_map[composite_key] ||= []
        key_map[composite_key] << { row: index + 1, name: product_name, data: row_data }
      end

      new_errors = []
      key_map.each do |_key, entries|
        next if entries.length <= 1
        entries.each do |entry|
          other_rows = entries.reject { |e| e[:row] == entry[:row] }.map { |e| e[:row] }
          new_errors << {
            'row' => entry[:row],
            'data' => entry[:data],
            'errors' => ["Produto duplicado: \"#{entry[:name]}\" com mesmo tamanho/marca/cor (também na linha #{other_rows.join(', ')})"]
          }
        end
      end

      product_import.update_column(:import_errors, cleaned_errors + new_errors)
    end

    def save_import_settings_to_account_config
      config = current_account.account_config || current_account.create_account_config!
      config.update(
        product_import_auto_generate_sku: params[:auto_generate_sku] == "1",
        product_import_ignore_errors: params[:ignore_errors] == "1",
        product_import_name_normalization: permitted_name_normalization(params[:name_normalization])
      )
    end
  end
end
