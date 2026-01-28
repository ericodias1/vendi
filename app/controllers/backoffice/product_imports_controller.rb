# frozen_string_literal: true

module Backoffice
  class ProductImportsController < BaseController
    def new
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
        auto_generate_sku: params[:auto_generate_sku] == "1",
        ignore_errors: params[:ignore_errors] == "1",
        prevent_duplicate_names: params[:prevent_duplicate_names] == "1"
      )

      @product_import.file.attach(file)

      if @product_import.save
        # O callback after_commit do model fará o parsing automaticamente
        redirect_to backoffice_product_import_path(@product_import), notice: "Arquivo enviado. Processando..."
      else
        flash.now[:error] = "Erro ao criar importação: #{@product_import.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @product_import = current_account.product_imports.find(params[:id])
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

    private

    def product_import_params
      # parsed_data vem como JSON string, já convertido no update
      params.require(:product_import).permit(:observations)
    end
  end
end
