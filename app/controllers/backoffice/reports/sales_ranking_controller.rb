# frozen_string_literal: true

module Backoffice
  module Reports
    class SalesRankingController < BaseController
      include ReportExportable

      def show
        @criterion = (params[:criterion].presence || "category").to_s
        @period = (params[:period].presence || "last_30_days").to_s
        @order = (params[:order].presence || "revenue").to_s

        @report = Backoffice::Reports::SalesRankingService.new(
          account: current_account,
          period: @period,
          criterion: @criterion,
          order: @order
        )

        @widgets = @report.widgets
        @rows = @report.rows
      end
    end
  end
end

