# frozen_string_literal: true

require "csv"

module Backoffice
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = current_account.products
                                  .search(params[:search])

      # Filtros avançados (modal)
      @products = @products.where(brand: params[:brand]) if params[:brand].present?
      @products = @products.where(size: params[:size]) if params[:size].present?
      @products = @products.where(color: params[:color]) if params[:color].present?
      @products = @products.where(supplier: params[:supplier]) if params[:supplier].present?
      @products = @products.where(category: params[:category]) if params[:category].present?
      import = current_account.product_imports.find_by(id: params[:product_import_id]) if params[:product_import_id].present?
      @products = @products.from_import(import) if import
      if params[:created_at_from].present? && params[:created_at_to].present?
        from = Time.zone.parse(params[:created_at_from]).beginning_of_day
        to = Time.zone.parse(params[:created_at_to]).end_of_day
        @products = @products.where(created_at: from..to)
      end

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

      # Paginação
      @page = params[:page].to_i
      @page = 1 if @page < 1
      allowed_per_page = [20, 50, 100, 200]
      @per_page = params[:per_page].to_i
      @per_page = 20 unless allowed_per_page.include?(@per_page)
      @total_count = @products.count || 0
      @products = @products.limit(@per_page).offset((@page - 1) * @per_page)

      # Carregar configuração de visualização
      @account_config = current_account.account_config || current_account.build_account_config
      # IDs selecionados para impressão de etiquetas
      @selected_product_ids = current_account.product_label_selections.pluck(:product_id)
      # Opções para o modal de filtros avançados
      load_product_filter_options
    end

    def update_view_mode
      @account_config = current_account.account_config || current_account.create_account_config!
      view_mode = params[:view_mode]

      if AccountConfig::PRODUCTS_VIEW_MODES.include?(view_mode)
        @account_config.update(products_view_mode: view_mode)
      end

      redirect_params = {
        filter: params[:filter], search: params[:search], page: params[:page], per_page: params[:per_page],
        brand: params[:brand], size: params[:size], color: params[:color],
        supplier: params[:supplier], category: params[:category],
        product_import_id: params[:product_import_id],
        created_at_from: params[:created_at_from], created_at_to: params[:created_at_to]
      }.compact
      redirect_to backoffice_products_path(redirect_params)
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

    def load_product_filter_options
      base = current_account.products
      @filter_brands = base.where.not(brand: [nil, ""]).distinct.pluck(:brand).compact.sort
      @filter_suppliers = base.where.not(supplier: [nil, ""]).distinct.pluck(:supplier).compact.sort
      @filter_categories = base.where.not(category: [nil, ""]).distinct.pluck(:category).compact.sort
      product_sizes = base.where.not(size: [nil, ""]).distinct.pluck(:size).compact
      product_colors = base.where.not(color: [nil, ""]).distinct.pluck(:color).compact
      @filter_sizes = (@account_config&.enabled_sizes_list.to_a | product_sizes).sort
      @filter_colors = (@account_config&.enabled_colors_list.to_a | product_colors).sort
      @filter_imports = current_account.product_imports.joins(:products).distinct.order(created_at: :desc)
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

