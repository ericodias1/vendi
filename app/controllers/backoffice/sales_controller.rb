# frozen_string_literal: true

module Backoffice
  class SalesController < BaseController
    before_action :set_sale, only: [:show, :edit, :update, :destroy]

    def index
      @sales = current_account.sales
                              .search(params[:search])
                              .order(created_at: :desc)
      
      # Filtrar por período
      case params[:period]
      when 'today'
        @sales = @sales.where('created_at >= ?', Date.current.beginning_of_day)
        @active_period = 'today'
      when 'week'
        @sales = @sales.where('created_at >= ?', 7.days.ago.beginning_of_day)
        @active_period = 'week'
      when 'month'
        @sales = @sales.where('created_at >= ?', Date.current.beginning_of_month)
        @active_period = 'month'
      else
        @active_period = 'today'
        @sales = @sales.where('created_at >= ?', Date.current.beginning_of_day)
      end
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
