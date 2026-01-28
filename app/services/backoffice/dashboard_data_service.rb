# frozen_string_literal: true

module Backoffice
  class DashboardDataService
    attr_reader :account, :user, :today_sales, :today_total, :today_count, :avg_ticket,
                :growth_percentage, :orders_change, :ticket_change, :low_stock_products,
                :daily_goal, :day_name, :last_week_total

    def initialize(account:, user:)
      @account = account
      @user = user
      calculate_metrics
    end

    private

    def calculate_metrics
      calculate_today_sales
      calculate_week_comparison
      calculate_yesterday_comparison
      calculate_low_stock_products
      calculate_daily_goal
      calculate_day_name
    end

    def calculate_today_sales
      @today_sales = @account.sales.paid.today
      @today_total = @today_sales.sum(:total_amount)
      @today_count = @today_sales.count
      @avg_ticket = @today_count > 0 ? (@today_total / @today_count) : 0
    end

    def calculate_week_comparison
      same_day_last_week_start = 1.week.ago.beginning_of_day
      same_day_last_week_end = 1.week.ago.end_of_day
      same_day_last_week = @account.sales.paid
        .where('created_at >= ? AND created_at < ?', same_day_last_week_start, same_day_last_week_end)
      @last_week_total = same_day_last_week.sum(:total_amount)

      @growth_percentage = if @last_week_total > 0
        ((@today_total - @last_week_total) / @last_week_total * 100).round(1)
      else
        @today_total > 0 ? 100.0 : 0.0
      end
    end

    def calculate_yesterday_comparison
      yesterday_start = Date.yesterday.beginning_of_day
      yesterday_end = Date.yesterday.end_of_day
      yesterday_sales = @account.sales.paid
        .where('created_at >= ? AND created_at < ?', yesterday_start, yesterday_end)
      yesterday_count = yesterday_sales.count
      yesterday_total = yesterday_sales.sum(:total_amount)
      yesterday_avg = yesterday_count > 0 ? (yesterday_total / yesterday_count) : 0

      @orders_change = @today_count - yesterday_count
      @ticket_change = @avg_ticket - yesterday_avg
    end

    def calculate_low_stock_products
      @low_stock_products = @account.products
        .low_stock
        .limit(5)
        .includes(:images_attachments)
    end

    def calculate_daily_goal
      @daily_goal = @account.account_config&.daily_goal || 0
    end

    def calculate_day_name
      day_name_key = Date.current.strftime('%A').downcase
      @day_name = I18n.t("date.day_names.#{day_name_key}", default: day_name_key).downcase
    end
  end
end
