# frozen_string_literal: true

# Policy única para todos os recursos do backoffice
class BackofficePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      # Para recursos multi-account, sempre filtra por account do usuário.
      # Para recursos globais (como Account), apenas admins enxergam tudo.
      if scope.column_names.include?("account_id")
        scope.where(account_id: user.account_id)
      else
        return scope.all if user.super_admin?
        scope.none
      end
    end
  end

  def index?
    return true if user&.super_admin?
    user.present?
  end

  def show?
    return user.super_admin? if account_resource?
    return true if user&.super_admin?
    user.present?
  end

  def create?
    return user.super_admin? if account_resource?
    return true if user&.super_admin?
    user.present?
  end

  def new?
    create?
  end

  def update?
    return user.super_admin? if account_resource?
    return true if user&.super_admin?
    user.present?
  end

  def edit?
    update?
  end

  def destroy?
    return user.super_admin? if account_resource?
    return true if user&.super_admin?
    user.present?
  end

  def impersonate?
    user&.super_admin?
  end

  def stop_impersonation?
    user&.super_admin?
  end

  private

  def account_resource?
    record.is_a?(Account) || record == Account
  end
end
