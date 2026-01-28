# frozen_string_literal: true

namespace :sales do
  desc "Popula dados de teste de vendas para uma account específica"
  task :populate, [:account_id, :count] => :environment do |_t, args|
    # Métodos auxiliares definidos dentro do bloco da task
    def generate_sale_number(account, date)
      date_prefix = date.strftime("%Y%m%d")
      last_sale = Sale.with_drafts.where(account: account)
                      .where("sale_number LIKE ?", "#{date_prefix}-%")
                      .order(sale_number: :desc)
                      .first

      if last_sale
        last_number = last_sale.sale_number.split("-").last.to_i
        next_number = last_number + 1
      else
        next_number = 1
      end

      "#{date_prefix}-#{next_number.to_s.rjust(4, '0')}"
    end

    def create_sample_products(account)
      product_names = [
        "Vestido Floral Infantil",
        "Conjunto Short e Camiseta",
        "Calça Jeans Infantil",
        "Blusa Manga Longa",
        "Saia Plissada",
        "Macacão Estampado",
        "Bermuda Esportiva",
        "Vestido de Festa",
        "Camiseta Básica",
        "Legging Estampada",
        "Blusa de Frio",
        "Shorts Jeans",
        "Vestido Midi",
        "Conjunto Pijama",
        "Blusa Regata"
      ]

      sizes = %w[PP P M G GG]
      colors = %w[Azul Rosa Branco Preto Vermelho Amarelo Verde]
      categories = %w[Vestidos Conjuntos Calças Blusas Shorts]

      products = []
      15.times do |i|
        product = Product.create!(
          account: account,
          name: product_names[i] || "Produto #{i + 1}",
          category: categories.sample,
          size: sizes.sample,
          color: colors.sample,
          base_price: rand(30.0..120.0).round(2),
          cost_price: rand(15.0..60.0).round(2),
          stock_quantity: rand(5..50),
          active: true,
          sku: "SKU-#{account.id}-#{i + 1}-#{rand(1000..9999)}"
        )
        products << product
      end

      products
    end

    def create_sample_user(account)
      User.create!(
        account: account,
        name: "Usuário Teste",
        email: "teste-#{account.id}@vendi.com",
        password: "password123",
        password_confirmation: "password123",
        role: "owner",
        active: true
      )
    end

    def create_sample_customers(account)
      customer_names = [
        "Maria Silva",
        "João Santos",
        "Ana Costa",
        "Pedro Oliveira",
        "Julia Ferreira",
        "Carlos Souza",
        "Fernanda Lima",
        "Lucas Alves",
        "Mariana Rocha",
        "Rafael Martins"
      ]

      customers = []
      customer_names.each do |name|
        customer = Customer.create!(
          account: account,
          name: name,
          phone: "(11) 9#{rand(1000..9999)}-#{rand(1000..9999)}",
          email: "#{name.parameterize}@email.com",
          active: true
        )
        customers << customer
      end

      customers
    end

    # Início da execução da task
    account_id = args[:account_id]&.to_i
    count = (args[:count] || 50).to_i

    unless account_id
      puts "❌ Erro: É necessário informar o ID da account"
      puts "Uso: rake sales:populate[account_id,count]"
      puts "Exemplo: rake sales:populate[2,50]"
      exit 1
    end

    account = Account.find_by(id: account_id)
    unless account
      puts "❌ Erro: Account com ID #{account_id} não encontrada"
      exit 1
    end

    puts "📦 Populando #{count} vendas para a account: #{account.name} (ID: #{account.id})"
    puts ""

    # Garantir que existem produtos
    products = account.products.active
    if products.empty?
      puts "⚠️  Nenhum produto encontrado. Criando produtos de exemplo..."
      products = create_sample_products(account)
      puts "✅ #{products.count} produtos criados"
    else
      puts "✅ #{products.count} produtos encontrados"
    end

    # Garantir que existe um usuário
    user = account.users.active.first
    if user.nil?
      puts "⚠️  Nenhum usuário encontrado. Criando usuário de exemplo..."
      user = create_sample_user(account)
      puts "✅ Usuário criado: #{user.email}"
    else
      puts "✅ Usuário encontrado: #{user.email}"
    end

    # Garantir que existem clientes (opcional, mas útil para relatórios)
    customers = account.customers.active
    if customers.empty?
      puts "⚠️  Nenhum cliente encontrado. Criando clientes de exemplo..."
      customers = create_sample_customers(account)
      puts "✅ #{customers.count} clientes criados"
    else
      puts "✅ #{customers.count} clientes encontrados"
    end

    puts ""
    puts "🔄 Criando vendas..."

    # Métodos de pagamento disponíveis
    payment_methods = %w[pix cash credit_card debit_card]
    payment_methods << "fiado" if account.account_config&.fiado_enabled

    # Status possíveis (maioria será "paid" para relatórios)
    statuses = %w[paid paid paid paid pending_payment] # 80% paid, 20% pending

    created_count = 0
    failed_count = 0

    count.times do |i|
      begin
        # Data aleatória nos últimos 3 meses
        days_ago = rand(0..90)
        created_at = days_ago.days.ago + rand(0..86400).seconds

        # Status aleatório (maioria paid)
        status = statuses.sample

        # Cliente aleatório (ou nil)
        customer = rand < 0.7 ? customers.sample : nil

        # Gerar número da venda manualmente para respeitar a data
        sale_number = generate_sale_number(account, created_at.to_date)

        # Criar venda primeiro
        sale = Sale.create!(
          account: account,
          user: user,
          customer: customer,
          status: status,
          sale_number: sale_number,
          created_at: created_at,
          updated_at: created_at
        )

        # Criar itens da venda (1 a 5 produtos por venda)
        items_count = rand(1..5)
        selected_products = products.sample(items_count)

        selected_products.each do |product|
          quantity = rand(1..3)
          unit_price = product.base_price || product.cost_price || rand(20.0..150.0).round(2)
          # Aplicar desconto ocasional (10% das vendas)
          discount_amount = rand < 0.1 ? (unit_price * quantity * rand(0.05..0.15)).round(2) : 0

          SaleItem.create!(
            sale: sale,
            product: product,
            product_name: product.name,
            product_size: product.size,
            product_color: product.color,
            product_sku: product.sku,
            quantity: quantity,
            unit_price: unit_price,
            cost_price: product.cost_price,
            discount_amount: discount_amount,
            created_at: created_at,
            updated_at: created_at
          )
        end

        # Calcular totais da venda
        sale.reload
        sale.calculate_totals

        # Aplicar desconto na venda ocasionalmente (5% das vendas)
        if rand < 0.05 && sale.subtotal > 0
          sale.discount_amount = (sale.subtotal * rand(0.05..0.10)).round(2)
          sale.total_amount = (sale.subtotal - sale.discount_amount).round(2)
        end

        # Garantir que total_amount seja maior que zero
        if sale.total_amount <= 0
          sale.total_amount = sale.subtotal
          sale.discount_amount = 0
        end

        sale.save!

        # Criar pagamento
        payment_method = payment_methods.sample
        payment_status = status == "paid" ? "paid" : "pending"

        # Garantir que o amount seja maior que zero
        payment_amount = [sale.total_amount, 0.01].max

        payment = Payment.create!(
          sale: sale,
          method: payment_method,
          status: payment_status,
          amount: payment_amount,
          paid_at: payment_status == "paid" ? created_at : nil,
          created_at: created_at,
          updated_at: created_at
        )

        # Se a venda está paga, marcar como completa
        if status == "paid"
          sale.update!(
            status: "paid",
            completed_at: created_at
          )
          payment.mark_as_paid! if payment_status == "paid"
        end

        # Criar movimentações de estoque para cada item
        sale.sale_items.each do |item|
          product = item.product
          quantity_before = product.stock_quantity
          quantity_after = [0, quantity_before - item.quantity].max

          # Atualizar estoque do produto
          product.update_column(:stock_quantity, quantity_after)

          # Criar movimentação de estoque
          StockMovement.create!(
            product: product,
            account: account,
            user: user,
            movement_type: :sale,
            quantity_change: -item.quantity,
            quantity_before: quantity_before,
            quantity_after: quantity_after,
            observations: "Venda ##{sale.sale_number}",
            metadata: { sale_id: sale.id, sale_item_id: item.id },
            created_at: created_at,
            updated_at: created_at
          )

          # Atualizar last_sold_at do produto
          if product.last_sold_at.nil? || created_at > product.last_sold_at
            product.update_column(:last_sold_at, created_at)
          end
        end

        created_count += 1
        print "." if (i + 1) % 10 == 0
      rescue StandardError => e
        failed_count += 1
        error_message = e.message
        if e.is_a?(ActiveRecord::RecordInvalid) && e.record
          error_message = "#{e.message} - #{e.record.errors.full_messages.join(', ')}"
        end
        puts "\n⚠️  Erro ao criar venda #{i + 1}: #{error_message}"
        puts "   Backtrace: #{e.backtrace.first(3).join("\n   ")}" if ENV['DEBUG']
      end
    end

    puts ""
    puts ""
    puts "✅ Concluído!"
    puts "   - Vendas criadas: #{created_count}"
    puts "   - Vendas com erro: #{failed_count}"
    puts ""
    puts "📊 Estatísticas:"
    puts "   - Total de vendas na account: #{account.sales.count}"
    puts "   - Vendas pagas: #{account.sales.paid.count}"
    puts "   - Vendas pendentes: #{account.sales.where(status: 'pending_payment').count}"
    puts "   - Total arrecadado: R$ #{account.sales.paid.sum(:total_amount).round(2)}"
  end
end
