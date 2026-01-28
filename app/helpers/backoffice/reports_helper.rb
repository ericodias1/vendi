# frozen_string_literal: true

module Backoffice
  module ReportsHelper
    def format_currency(value, size: :regular)
      return "—" if value.nil?

      size_classes = {
        large: "text-3xl font-bold",
        regular: "text-lg font-bold",
        small: "text-sm font-semibold"
      }

      content_tag :span,
        number_to_currency(value, unit: "R$ ", separator: ",", delimiter: "."),
        class: "#{size_classes[size]} text-primary"
    end

    def format_percentage(value, size: :regular)
      return "—" if value.nil?

      size_classes = {
        large: "text-2xl font-bold",
        regular: "text-lg font-semibold",
        small: "text-sm font-medium"
      }

      content_tag :span,
        "#{number_with_precision(value, precision: 1)}%",
        class: "#{size_classes[size]} text-slate-900"
    end

    def format_change(value, positive: true)
      return "—" if value.nil?

      color_class = positive ? "text-primary" : "text-error-500"
      icon = positive ? "↑" : "↓"

      content_tag :span, class: "text-sm #{color_class} flex items-center gap-1" do
        concat icon
        concat "#{value.abs}%"
      end
    end

    def report_category_title(category_key)
      titles = {
        overview: "Visão Geral",
        sales_profit: "Vendas & Lucro",
        stock_purchase: "Estoque & Compra",
        coming_soon: "Em breve"
      }
      titles[category_key] || category_key.to_s.humanize
    end

    def report_category_icon(category_key)
      icons = {
        overview: "bar_chart",
        sales_profit: "trending_up",
        stock_purchase: "inventory_2",
        coming_soon: "rocket_launch"
      }
      icons[category_key] || "description"
    end

    def format_days_without_selling(days)
      return "—" if days.nil?

      days = days.to_i
      return "hoje" if days <= 0
      return "ontem" if days == 1
      return "#{days} dias" if days < 30

      months = (days / 30.0).round(1)
      "#{months} meses"
    end

    def format_last_sale_date(date)
      return "Nunca vendeu" if date.blank?

      sale_date = date.to_date
      today = Date.current
      yesterday = today - 1.day

      if sale_date == today
        "hoje"
      elsif sale_date == yesterday
        "ontem"
      elsif sale_date >= today - 7.days
        "#{(today - sale_date).to_i} dias atrás"
      else
        sale_date.strftime("%d/%m/%Y")
      end
    end
  end
end
