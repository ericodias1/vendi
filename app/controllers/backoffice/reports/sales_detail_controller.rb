# frozen_string_literal: true

module Backoffice
  module Reports
    class SalesDetailController < BaseController
      include ReportExportable

      def show
        @period = (params[:period].presence || "last_30_days").to_s
        @customer_id = params[:customer_id].presence

        @report = Backoffice::Reports::SalesDetailService.new(
          account: current_account,
          period: @period,
          customer_id: @customer_id
        )

        @sales = @report.sales
        @total_sales = @report.total_sales
        @total_discounts = @report.total_discounts
        @customers = current_account.customers.order(:name)
      end
    end
  end
end
