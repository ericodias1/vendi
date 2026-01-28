# frozen_string_literal: true

require 'ostruct'

module Backoffice
  module Reports
    class BaseReportService < Service
      attr_reader :account,
                  :period,
                  :date_range

      def initialize(account:, period: "month")
        super()
        @account = account
        @period = (period.presence || "month").to_s
      end

      protected

      def period_range_for_account
        zone = ActiveSupport::TimeZone.new(account.timezone || "America/Sao_Paulo")
        now = zone.now

        case @period
        when "today"
          now.beginning_of_day..now.end_of_day
        when "last_7_days"
          (now - 7.days).beginning_of_day..now.end_of_day
        when "last_30_days"
          (now - 30.days).beginning_of_day..now.end_of_day
        when "month"
          now.beginning_of_month..now.end_of_month
        else
          # Default para mês atual
          now.beginning_of_month..now.end_of_month
        end
      end
    end
  end
end
