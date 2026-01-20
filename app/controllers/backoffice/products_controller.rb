# frozen_string_literal: true

module Backoffice
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = current_account.products
                                  .search(params[:search])
                                  .order(created_at: :desc)
    end

    def show
    end

    def new
      @product = current_account.products.build
    end

    def create
      @product = current_account.products.build(product_params)

      if @product.save
        redirect_to backoffice_products_path, notice: "Produto criado com sucesso"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :sku, :base_price, :active)
    end
  end
end
