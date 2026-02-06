# frozen_string_literal: true

require "csv"

module Backoffice
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = current_account.products
                                  .search(params[:search])

      case params[:filter]
      when "low_stock"
        @products = @products.with_low_stock.order(created_at: :desc)
      when "most_sold"
        # Produtos mais vendidos baseado em StockMovements do tipo 'sale'
        # Subquery para contar vendas por produto
        product_ids = StockMovement
          .where(account: current_account, movement_type: 'sale')
          .where.not(product_id: nil)
          .group(:product_id)
          .order(Arel.sql('COUNT(*) DESC'))
          .limit(50)
          .pluck(:product_id)
        
        if product_ids.any?
          # Ordenar pelos mais vendidos primeiro usando CASE WHEN
          order_sql = product_ids.map.with_index { |id, idx| "WHEN #{id} THEN #{idx}" }.join(' ')
          @products = @products.where(id: product_ids)
                              .order(Arel.sql("CASE id #{order_sql} ELSE 999 END"))
        else
          @products = @products.none
        end
      else
        @products = @products.order(created_at: :desc)
      end

      # Paginação simples (20 por página)
      @page = params[:page].to_i
      @page = 1 if @page < 1
      @per_page = 20
      @total_count = @products.count || 0
      @products = @products.limit(@per_page).offset((@page - 1) * @per_page)

      # Carregar configuração de visualização
      @account_config = current_account.account_config || current_account.build_account_config
    end

    def update_view_mode
      @account_config = current_account.account_config || current_account.create_account_config!
      view_mode = params[:view_mode]

      if AccountConfig::PRODUCTS_VIEW_MODES.include?(view_mode)
        @account_config.update(products_view_mode: view_mode)
      end

      redirect_to backoffice_products_path(filter: params[:filter], search: params[:search], page: params[:page])
    end

    def show
    end

    def new
      @product = current_account.products.build
      set_variation_options
    end

    def create
      # Definir current_user para os callbacks
      Product.set_current_user(current_user)
      
      @product = current_account.products.build(product_params)
      
      if @product.save
        redirect_to backoffice_product_path(@product), notice: "Produto criado com sucesso"
      else
        set_variation_options
        render :new, status: :unprocessable_entity
      end
    ensure
      # Limpar current_user após uso
      Product.set_current_user(nil)
    end

    def edit
      set_variation_options
    end

    def update
      # Definir current_user para os callbacks
      Product.set_current_user(current_user)
      
      if @product.update(product_params)
        redirect_to backoffice_product_path(@product), notice: "Produto atualizado com sucesso"
      else
        set_variation_options
        render :edit, status: :unprocessable_entity
      end
    ensure
      # Limpar current_user após uso
      Product.set_current_user(nil)
    end

    def destroy
      if @product.has_sales?
        redirect_to backoffice_product_path(@product), alert: "Não é possível excluir o produto pois ele possui vendas atreladas."
      else
        @product.discard
        redirect_to backoffice_products_path, notice: "Produto excluído com sucesso"
      end
    end

    def low_stock
      @products = current_account.products.with_low_stock.order(created_at: :desc)
      render :index
    end

    def export_csv
      products = current_account.products.order(:id).limit(10_000)
      filename = "conciliacao-produtos-#{Time.zone.now.strftime('%Y%m%d')}.csv"

      csv_string = CSV.generate(headers: true, col_sep: ",", encoding: "UTF-8") do |csv|
        csv << %w[id nome descricao sku codigo_fornecedor preco_custo preco_venda categoria marca cor tamanho quantidade_estoque ativo]
        products.find_each do |p|
          csv << [
            p.id,
            p.name,
            p.description,
            p.sku,
            p.supplier_code,
            p.cost_price&.to_f,
            p.base_price&.to_f,
            p.category,
            p.brand,
            p.color,
            p.size,
            p.stock_quantity,
            p.active? ? "sim" : "não"
          ]
        end
      end

      send_data csv_string,
                filename: filename,
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    end

    private

    def set_product
      @product = current_account.products.find(params[:id])
    end

    def set_variation_options
      @account_config = current_account.account_config || current_account.build_account_config
      @available_sizes = @account_config.enabled_sizes_list
      @available_colors = @account_config.enabled_colors_list
    end

    def product_params
      permitted = params.require(:product).permit(
        :name, :description, :sku, :base_price, :cost_price, :category, :brand, :color, :material, :supplier, :active,
        :size, :stock_quantity,
        images: []
      )
      
      # Definir stock_quantity como 1 se não foi informado
      permitted[:stock_quantity] = 1 if permitted[:stock_quantity].blank?
      
      permitted
    end
  end
end

