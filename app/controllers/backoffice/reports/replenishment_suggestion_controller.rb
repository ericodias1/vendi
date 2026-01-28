# frozen_string_literal: true

module Backoffice
  module Reports
    class ReplenishmentSuggestionController < BaseController
      include ReportExportable

      def show
        sales_lookback_days = (params[:sales_lookback_days].presence || 30).to_i
        coverage_target_days = (params[:coverage_target_days].presence || 15).to_i
        min_stock_target = (params[:min_stock_target].presence || 3).to_i

        @report = Backoffice::Reports::ReplenishmentSuggestionService.new(
          account: current_account,
          sales_lookback_days: sales_lookback_days,
          coverage_target_days: coverage_target_days,
          min_stock_target: min_stock_target
        )

        @suggestions = @report.suggestions
        @insights = @report.insights
      end
    end
  end
end
