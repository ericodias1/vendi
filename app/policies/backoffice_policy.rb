# frozen_string_literal: true

# Policy única para todos os recursos do backoffice
class BackofficePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user.present?

      # Filtra pelo account do usuário
      scope.where(account: user.account)
    end
  end

  def show?
    return true if user&.super_admin?
    user.present?
  end

  def create?
    return true if user&.super_admin?
    user.present?
  end

  def new?
    create?
  end

  def update?
    return true if user&.super_admin?
    user.present?
  end

  def edit?
    update?
  end

  def destroy?
    return true if user&.super_admin?
    user.present?
  end
end
