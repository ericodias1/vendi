# frozen_string_literal: true

module Backoffice
  class DashboardController < BaseController
    def index
      @account = current_account
      @user = current_user
      
      @dashboard_data = DashboardDataService.new(
        account: @account,
        user: @user
      )
      
      # Expor dados para a view
      @today_sales = @dashboard_data.today_sales
      @today_total = @dashboard_data.today_total
      @today_count = @dashboard_data.today_count
      @avg_ticket = @dashboard_data.avg_ticket
      @growth_percentage = @dashboard_data.growth_percentage
      @orders_change = @dashboard_data.orders_change
      @ticket_change = @dashboard_data.ticket_change
      @low_stock_products = @dashboard_data.low_stock_products
      @daily_goal = @dashboard_data.daily_goal
      @day_name = @dashboard_data.day_name
      @last_week_total = @dashboard_data.last_week_total
    end
  end
end
