# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user&.super_admin?

      scope.all
    end
  end

  def index?
    user&.super_admin?
  end

  def show?
    user&.super_admin?
  end

  def impersonate?
    user&.super_admin?
  end

  def stop_impersonation?
    user&.super_admin?
  end
end

