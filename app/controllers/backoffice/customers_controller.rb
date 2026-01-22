# frozen_string_literal: true

module Backoffice
  class CustomersController < BaseController
    def search
      @customers = current_account.customers
                                  .search(params[:q])
                                  .limit(10)
                                  .order(created_at: :desc)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def create
      @customer = current_account.customers.build(customer_params)

      if @customer.save
        @customers = current_account.customers
                                    .search(params[:q])
                                    .limit(10)
                                    .order(created_at: :desc)
        respond_to do |format|
          format.turbo_stream
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
  end
end
