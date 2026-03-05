# frozen_string_literal: true

module Backoffice
  module Reports
    class SalesDetailService < BaseReportService
      attr_reader :sales, :total_sales, :total_discounts

      def initialize(account:, period: "last_30_days", customer_id: nil)
        super(account: account, period: period)
        @customer_id = customer_id.presence
        calculate!
      end

      private

      def calculate!
        return unless validate_presence(:account, account)

        range = period_range_for_account
        scope = account.sales.paid
                       .where(created_at: range)
                       .includes(:customer, :sale_items)
                       .order(created_at: :desc)
        scope = scope.where(customer_id: @customer_id) if @customer_id.present?

        @sales = scope
        @total_sales = @sales.sum(:total_amount)
        @total_discounts = @sales.sum(:discount_amount)
      end
    end
  end
end
