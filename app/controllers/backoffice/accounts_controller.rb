# frozen_string_literal: true

module Backoffice
  class AccountsController < BaseController
    before_action :set_account, only: [:show, :edit, :update, :impersonate]

    def index
      authorize Account

      @search = params[:search].to_s.strip
      @accounts = Account.active.order(created_at: :desc)
      @accounts = @accounts.where("name ILIKE ?", "%#{@search}%") if @search.present?
      @accounts = @accounts.limit(50)
    end

    def show
      authorize @account
    end

    def new
      authorize Account
      @account = Account.new
    end

    def create
      authorize Account
      @account = Account.new(account_params)

      if @account.save
        redirect_to backoffice_accounts_path, notice: "Conta criada com sucesso."
      else
        flash.now[:alert] = "Não foi possível criar a conta. Verifique os campos abaixo."
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @account
    end

    def update
      authorize @account

      if @account.update(account_params)
        redirect_to backoffice_account_path(@account), notice: "Conta atualizada com sucesso."
      else
        flash.now[:alert] = "Não foi possível atualizar a conta. Verifique os campos abaixo."
        render :edit, status: :unprocessable_entity
      end
    end

    def impersonate
      authorize @account, :impersonate?

      session[:impersonated_account_id] = @account.id

      redirect_to backoffice_root_path,
                  notice: "Você agora está visualizando a conta \"#{@account.name}\"."
    end

    def stop_impersonation
      authorize Account, :stop_impersonation?

      session.delete(:impersonated_account_id)

      redirect_to backoffice_root_path,
                  notice: "Você voltou para a sua própria conta."
    end

    private

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :slug, :whatsapp, :store_type, :logo_url, :timezone, :active)
    end
  end
end

