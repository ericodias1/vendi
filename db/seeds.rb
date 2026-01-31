# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Super admin user (idempotent: create or update)
account = Account.find_or_create_by!(slug: "admin") do |a|
  a.name = "Admin"
  a.whatsapp = "00000000000"
end
account.update!(name: "Admin", whatsapp: "00000000000") if account.whatsapp.blank?

account.account_config || account.create_account_config!

user = User.find_or_initialize_by(email: "ericodias1@gmail.com")
user.assign_attributes(
  name: "Super Admin",
  password: "123123123",
  password_confirmation: "123123123",
  role: "owner",
  admin: true,
  active: true
)
user.save!

puts "Super admin criado/atualizado: ericodias1@gmail.com (senha: 123123123)"
