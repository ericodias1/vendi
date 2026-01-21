# frozen_string_literal: true

module Backoffice
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = current_account.products
                                  .search(params[:search])
                                  .order(created_at: :desc)

      @products = @products.with_low_stock if params[:filter] == "low_stock"
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
      params.require(:product).permit(
        :name, :description, :sku, :base_price, :cost_price, :category, :brand, :color, :material, :active,
        :size, :stock_quantity,
        images: []
      )
    end
  end
end

