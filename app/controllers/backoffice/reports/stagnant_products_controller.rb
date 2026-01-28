# frozen_string_literal: true

module Backoffice
  module Reports
    class StagnantProductsController < BaseController
      include ReportExportable

      def show
        @report = Backoffice::Reports::StagnantProductsService.new(
          account: current_account
        )
        @products = @report.stagnant_products
        @insights = @report.insights
      end
    end
  end
end
