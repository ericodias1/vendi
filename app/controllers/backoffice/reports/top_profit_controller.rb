# frozen_string_literal: true

module Backoffice
  module Reports
    class TopProfitController < BaseController
      include ReportExportable

      def show
        @period = params[:period].presence || "month"

        @report = Backoffice::Reports::TopProfitService.new(
          account: current_account,
          period: @period
        )
      end
    end
  end
end
