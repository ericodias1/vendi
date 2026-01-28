# frozen_string_literal: true

module Backoffice
  module Reports
    class DailySummaryController < BaseController
      include ReportExportable

      def show
        @summary = Backoffice::Reports::DailySummaryService.new(
          account: current_account
        )
      end
    end
  end
end
