# frozen_string_literal: true

module Backoffice
  class CustomersController < BaseController
    def search
      @customers = current_account.customers
                                  .search(params[:q])
                                  .limit(5)
                                  .order(created_at: :desc)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def create
      @customer = current_account.customers.build(customer_params)

      if @customer.save
        if params[:sale_id].present?
          persist_customer_on_sale_and_respond
        else
        @customers = current_account.customers
                                    .search(params[:q])
                                    .limit(5)
                                    .order(created_at: :desc)
          respond_to do |format|
            format.turbo_stream
          end
        end
      else
        respond_to do |format|
          format.turbo_stream { render :create_error, status: :unprocessable_entity }
        end
      end
    end

    private

    def customer_params
      params.require(:customer).permit(:name, :phone, :email)
    end

    def persist_customer_on_sale_and_respond
      @sale = Sale.unscoped.where(account: current_account).find_by(id: params[:sale_id])
      unless @sale
        @customers = current_account.customers.search(params[:q]).limit(5).order(created_at: :desc)
        render :create, status: :ok
        return
      end

      @sale.update!(customer_id: @customer.id)

      response.headers["X-Customer-Id"] = @customer.id.to_s
      response.headers["X-Customer-Name"] = ERB::Util.url_encode(@customer.name.to_s)

      @customers = []
      render :create
    end
  end
end
