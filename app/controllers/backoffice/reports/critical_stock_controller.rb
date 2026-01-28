# frozen_string_literal: true

module Backoffice
  module Reports
    class CriticalStockController < BaseController
      include ReportExportable

      def show
        @filter = params[:filter].presence || "all"

        @report = Backoffice::Reports::CriticalStockService.new(
          account: current_account
        )

        # Aplicar filtro aos produtos
        @products = case @filter
                    when "critical"
                      @report.critical_products.select(&:critical?)
                    when "low_stock"
                      @report.critical_products.select { |p| p.stock_quantity <= 3 }
                    else
                      @report.critical_products
                    end
      end
    end
  end
end
