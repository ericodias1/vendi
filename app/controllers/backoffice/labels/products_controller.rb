# frozen_string_literal: true

module Backoffice
  module Labels
    class ProductsController < Backoffice::BaseController
      ADD_ALL_LIMIT = 500

      def add
        ids = product_ids_from_params
        return redirect_back_with_alert if ids.empty?

        products = current_account.products.where(id: ids)
        count = 0
        products.find_each do |product|
          current_account.product_label_selections.find_or_create_by!(product: product)
          count += 1
        end

        respond_to do |format|
          format.json { render json: { selected_count: current_account.product_label_selections.count } }
          format.html { redirect_to backoffice_products_path(redirect_params), notice: "#{count} produto(s) adicionado(s) à seleção para etiquetas." }
        end
      end

      def remove
        ids = product_ids_from_params
        return redirect_back_with_alert if ids.empty?

        current_account.product_label_selections.where(product_id: ids).delete_all

        respond_to do |format|
          format.json { render json: { selected_count: current_account.product_label_selections.count } }
          format.html { redirect_to backoffice_products_path(redirect_params), notice: "Produto(s) removido(s) da seleção." }
        end
      end

      def add_all
        scope = products_scope_for_filter
        ids = scope.limit(ADD_ALL_LIMIT).pluck(:id)
        if ids.empty?
          return redirect_to backoffice_products_path(redirect_params), notice: "Nenhum produto encontrado com o filtro atual."
        end

        count = 0
        current_account.products.where(id: ids).find_each do |product|
          current_account.product_label_selections.find_or_create_by!(product: product)
          count += 1
        end
        redirect_to backoffice_products_path(redirect_params), notice: "#{count} produto(s) marcados para etiquetas."
      end

      def remove_all
        count = current_account.product_label_selections.count
        current_account.product_label_selections.destroy_all
        redirect_to backoffice_products_path(redirect_params), notice: "#{count} produto(s) desmarcados."
      end

      private

      def product_ids_from_params
        Array(params[:product_ids]).reject(&:blank?).map(&:to_i).uniq
      end

      def redirect_params
        {
          filter: params[:filter], search: params[:search], page: params[:page], per_page: params[:per_page],
          brand: params[:brand], size: params[:size], color: params[:color],
          supplier: params[:supplier], category: params[:category],
          product_import_id: params[:product_import_id],
          created_at_from: params[:created_at_from], created_at_to: params[:created_at_to]
        }.compact
      end

      def redirect_back_with_alert
        redirect_to backoffice_products_path(redirect_params), alert: "Nenhum produto selecionado."
      end

      def products_scope_for_filter
        scope = current_account.products.search(params[:search])

        # Filtros avançados (mesmos da listagem de produtos)
        scope = scope.where(brand: params[:brand]) if params[:brand].present?
        scope = scope.where(size: params[:size]) if params[:size].present?
        scope = scope.where(color: params[:color]) if params[:color].present?
        scope = scope.where(supplier: params[:supplier]) if params[:supplier].present?
        scope = scope.where(category: params[:category]) if params[:category].present?
        if params[:product_import_id].present?
          import = current_account.product_imports.find_by(id: params[:product_import_id])
          scope = scope.where(product_import_id: import&.id) if import
        end
        if params[:created_at_from].present? && params[:created_at_to].present?
          from = Time.zone.parse(params[:created_at_from]).beginning_of_day
          to = Time.zone.parse(params[:created_at_to]).end_of_day
          scope = scope.where(created_at: from..to)
        end

        case params[:filter]
        when "low_stock"
          scope = scope.with_low_stock.order(created_at: :desc)
        when "most_sold"
          product_ids = StockMovement
            .where(account: current_account, movement_type: "sale")
            .where.not(product_id: nil)
            .group(:product_id)
            .order(Arel.sql("COUNT(*) DESC"))
            .limit(50)
            .pluck(:product_id)
          if product_ids.any?
            order_sql = product_ids.map.with_index { |id, idx| "WHEN #{id} THEN #{idx}" }.join(" ")
            scope = scope.where(id: product_ids).order(Arel.sql("CASE id #{order_sql} ELSE 999 END"))
          else
            scope = scope.none
          end
        else
          scope = scope.order(created_at: :desc)
        end
        scope
      end
    end
  end
end
