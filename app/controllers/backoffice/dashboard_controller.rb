# frozen_string_literal: true

module Backoffice
  class DashboardController < BaseController
    def index
      @account = current_account
      @today_sales = current_account.sales
                                    .where(status: 'paid')
                                    .where('created_at >= ?', Date.current.beginning_of_day)
      @today_total = @today_sales.sum(:total_amount)
      @today_count = @today_sales.count
      @avg_ticket = @today_count > 0 ? @today_total / @today_count : 0
      
      # TODO: Implementar quando AccountConfig estiver pronto
      @daily_goal = current_account.account_config&.daily_goal || 0
    end
  end
end
