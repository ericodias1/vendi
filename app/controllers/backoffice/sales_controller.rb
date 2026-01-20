# frozen_string_literal: true

module Backoffice
  class SalesController < BaseController
    before_action :set_sale, only: [:show, :edit, :update, :destroy]

    def index
      @sales = current_account.sales
                              .search(params[:search])
                              .order(created_at: :desc)
    end

    def show
    end

    def new
      @sale = current_account.sales.build(user: current_user)
    end

    def create
      @sale = current_account.sales.build(sale_params.merge(user: current_user))

      if @sale.save
        redirect_to backoffice_sales_path, notice: "Venda criada com sucesso"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_sale
      @sale = Sale.find(params[:id])
    end

    def sale_params
      params.require(:sale).permit(:customer_id, :status, :subtotal, :total_amount, :observations)
    end
  end
end
