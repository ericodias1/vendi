# frozen_string_literal: true

module Backoffice
  class UsersController < BaseController
    before_action :set_user, only: [:edit, :update, :destroy]

    def index
      authorize User

      @users = current_account.users.order(created_at: :asc)
    end

    def new
      authorize User
      @user = current_account.users.build
    end

    def create
      authorize User
      @user = current_account.users.build(user_params)

      if @user.save
        redirect_to backoffice_users_path, notice: "Usuário criado com sucesso."
      else
        flash.now[:alert] = "Não foi possível criar o usuário. Verifique os campos abaixo."
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      permitted = user_params
      if permitted[:password].blank?
        permitted = permitted.except(:password, :password_confirmation)
      end

      if @user.update(permitted)
        redirect_to backoffice_users_path, notice: "Usuário atualizado com sucesso."
      else
        flash.now[:alert] = "Não foi possível atualizar o usuário. Verifique os campos abaixo."
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user

      @user.destroy
      redirect_to backoffice_users_path, notice: "Usuário removido com sucesso."
    end

    private

    def set_user
      @user = current_account.users.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :name,
        :email,
        :phone,
        :role,
        :active,
        :password,
        :password_confirmation
      )
    end
  end
end

