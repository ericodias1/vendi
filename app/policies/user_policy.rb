# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Admin pode gerenciar usuários da conta atual (incluindo conta impersonada)
      return scope.none unless user&.super_admin?

      scope.where(account_id: user.account_id)
    end
  end

  def index?
    user&.super_admin?
  end

  def show?
    user&.super_admin?
  end

  def create?
    user&.super_admin?
  end

  def update?
    user&.super_admin?
  end

  def destroy?
    user&.super_admin?
  end
end

