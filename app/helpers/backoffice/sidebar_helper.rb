# frozen_string_literal: true

module Backoffice
  module SidebarHelper
    def sidebar_menu_items
      items = [
        {
          path: backoffice_root_path,
          label: "Início",
          icon: "dashboard",
          active_paths: [backoffice_root_path],
          exact_match: true
        },
        {
          path: backoffice_sales_path,
          label: "Vendas",
          icon: "receipt_long",
          active_paths: [backoffice_sales_path, "/backoffice/sales"]
        },
        {
          path: backoffice_products_path,
          label: "Produtos",
          icon: "inventory_2",
          active_paths: [backoffice_products_path, "/backoffice/products"]
        },
        {
          path: backoffice_reports_path,
          label: "Relatórios",
          icon: "bar_chart",
          active_paths: [backoffice_reports_path, "/backoffice/reports"]
        },
        {
          path: backoffice_account_config_path,
          label: "Configurações",
          icon: "settings",
          active_paths: [backoffice_account_config_path, "/backoffice/account_config"]
        }
      ]

      if current_user&.admin?
        items << {
          divider: true,
          label: "Admin"
        }

        items << {
          path: backoffice_accounts_path,
          label: "Contas",
          icon: "admin_panel_settings",
          active_paths: [backoffice_accounts_path, "/backoffice/accounts"]
        }

        items << {
          path: backoffice_users_path,
          label: "Usuários",
          icon: "group",
          active_paths: [backoffice_users_path, "/backoffice/users"]
        }
      end

      items
    end

    def sidebar_item_classes(item, current_path)
      base_classes = "flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors cursor-pointer text-sm"
      
      if sidebar_item_active?(item, current_path)
        "#{base_classes} bg-[#E7F8F2] text-primary font-bold"
      else
        "#{base_classes} text-slate-500 hover:bg-slate-50 font-medium"
      end
    end

    def sidebar_item_active?(item, current_path)
      return false if item[:divider]

      return false if item[:active_paths].empty?
      
      item[:active_paths].any? do |active_path|
        next current_path == active_path if item[:exact_match]

        current_path == active_path || current_path.start_with?(active_path.to_s)
      end
    end

    def sidebar_icon(icon_name)
      content_tag :span, icon_name, class: "material-symbols-outlined text-xl shrink-0 leading-none"
    end
  end
end
