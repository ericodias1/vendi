# frozen_string_literal: true

module Backoffice
  module Accounts
    class CreateService < Service
      attr_reader :account, :user, :account_config

      def initialize(form:)
        super()
        @form = form
        @account = nil
        @user = nil
        @account_config = nil
      end

      def call
        return false unless @form.valid?

        execute_with_transaction do
          create_account
          create_user
          create_account_config
        end
      end

      private

      def create_account
        @account = Account.new(
          @form.account_attributes.merge(slug: generate_slug(@form.account_name))
        )
        save_model!(@account, raise_on_error: true)
      end

      def create_user
        @user = User.new(
          @form.user_attributes.merge(account: @account)
        )
        save_model!(@user, raise_on_error: true)
      end

      def create_account_config
        @account_config = @account.build_account_config(
          stock_alerts_enabled: true,
          stock_alert_threshold: 5,
          pix_enabled: true,
          card_enabled: true,
          cash_enabled: true,
          credit_enabled: false,
          require_customer: false,
          auto_send_payment_link: false
        )
        save_model!(@account_config, raise_on_error: true)
      end

      def generate_slug(name)
        base_slug = name.parameterize
        slug = base_slug
        counter = 1
        
        while Account.exists?(slug: slug)
          slug = "#{base_slug}-#{counter}"
          counter += 1
        end
        
        slug
      end
    end
  end
end
