# frozen_string_literal: true

module Backoffice
  class ReportsController < BaseController
    def index
      # Organizar relatórios por categorias para o menu
      @report_categories = {
        overview: [
          {
            id: :daily_summary,
            name: "Resumo do Dia",
            description: "Vendas, lucro, margem, ticket médio e top produtos",
            icon: "bar_chart",
            path: daily_summary_backoffice_reports_path,
            available: true
          }
        ],
        sales_profit: [
          {
            id: :top_profit,
            name: "Top Lucro",
            description: "Produtos com maior margem de lucro",
            icon: "trending_up",
            path: top_profit_backoffice_reports_path,
            available: true
          },
          {
            id: :sales_ranking,
            name: "Ranking por Critério",
            description: "Ranking por marca, categoria, tamanho, cor e mais",
            icon: "tune",
            path: sales_ranking_backoffice_reports_path,
            available: true
          },
          {
            id: :category_performance,
            name: "Desempenho Categorias",
            description: "Análise setorial de vendas",
            icon: "category",
            path: "#",
            available: false
          }
        ],
        stock_purchase: [
          {
            id: :critical_stock,
            name: "Estoque Crítico",
            description: "Produtos que podem faltar em até 48h",
            icon: "warning",
            path: critical_stock_backoffice_reports_path,
            available: true
          },
          {
            id: :stagnant_products,
            name: "Produtos Parados",
            description: "Estoque parado e dinheiro travado",
            icon: "inventory",
            path: stagnant_products_backoffice_reports_path,
            available: true
          },
          {
            id: :replenishment_suggestion,
            name: "Sugestão de Reposição",
            description: "Lista de compra baseada em giro e lucro",
            icon: "shopping_cart",
            path: replenishment_suggestion_backoffice_reports_path,
            available: true
          }
        ],
        coming_soon: [
          {
            id: :trend_analysis,
            name: "Análise de Tendências",
            description: "Em breve",
            icon: "show_chart",
            path: "#",
            available: false
          },
          {
            id: :supplier_comparison,
            name: "Comparativo Fornecedores",
            description: "Em breve",
            icon: "people",
            path: "#",
            available: false
          }
        ]
      }
    end
  end
end
