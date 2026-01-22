# Plano: Mudança de Arquitetura - Vendas com Sale Draft

## Objetivo
Mudar o fluxo de criação de vendas para criar uma Sale draft imediatamente ao acessar `sales/new`, permitindo gerenciar itens via Turbo Streams com um controller dedicado.

## Arquitetura Atual vs Nova

### Arquitetura Atual
- `sales/new` → Exibe formulário multi-step
- Itens armazenados na sessão (`session[:draft_sale_items]`)
- Dados passados via params entre steps
- Service cria Sale do zero no final

### Arquitetura Nova
- `sales/new` → Cria Sale draft imediatamente
- Itens armazenados como `SaleItem` na Sale draft
- Adição/remoção de itens via Turbo Streams
- Controller dedicado `Sales::ItemsController`
- Service finaliza Sale draft ao invés de criar do zero

## Benefícios
1. **Persistência real**: Dados salvos no banco, não perdidos se sessão expirar
2. **Turbo Streams**: Atualizações em tempo real sem recarregar página
3. **Controller dedicado**: Lógica mais simples e organizada
4. **Validações no model**: Validações de SaleItem no próprio model
5. **Histórico**: Vendas draft podem ser recuperadas

## Implementação

### 1. Modificar SalesController#new
- Criar Sale draft se não existir uma ativa para o usuário
- Redirecionar para `sales/:id/edit` ao invés de `sales/new?step=1`
- Buscar Sale draft existente ou criar nova

### 2. Criar Sales::ItemsController
- `create`: Adicionar produto à venda draft
- `update`: Atualizar quantidade de um item
- `destroy`: Remover item da venda
- Todas as actions retornam Turbo Streams

### 3. Criar Service: Sales::FinalizeService
- Substituir `CreateService` por `FinalizeService`
- Recebe Sale draft existente
- Valida e finaliza a venda (cria payment, atualiza estoque, etc)

### 4. Atualizar Views
- Step 1: Usar Turbo Streams para adicionar/remover itens
- Exibir itens da Sale draft diretamente do banco
- Atualizar resumo em tempo real via Turbo Streams

### 5. Limpeza de Drafts
- Job para limpar drafts antigas (mais de 24h)
- Ou limpar ao criar nova venda draft

## Estrutura de Arquivos

### Novos Arquivos
- `app/controllers/backoffice/sales/items_controller.rb`
- `app/services/backoffice/sales/finalize_service.rb`
- `app/views/backoffice/sales/items/create.turbo_stream.erb`
- `app/views/backoffice/sales/items/update.turbo_stream.erb`
- `app/views/backoffice/sales/items/destroy.turbo_stream.erb`
- `app/views/backoffice/sales/items/_sale_item.html.erb` (partial para item no carrinho)

### Arquivos Modificados
- `app/controllers/backoffice/sales_controller.rb` (new, create → finalize)
- `app/views/backoffice/sales/new.html.erb` → `edit.html.erb`
- `app/views/backoffice/sales/steps/_step1_select_products.html.erb`
- `app/views/backoffice/sales/steps/_step2_payment.html.erb`
- `app/views/backoffice/sales/steps/_step3_confirmation.html.erb`
- `config/routes.rb`

## Rotas

```ruby
namespace :backoffice do
  resources :sales, only: [:index, :show, :new, :create, :edit, :update] do
    resources :items, only: [:create, :update, :destroy], controller: "sales/items"
    member do
      patch :finalize  # Finalizar venda draft
      patch :complete
      patch :cancel
      post :send_payment_link
    end
  end
end
```

## Fluxo de Uso

1. Usuário acessa `/sales/new`
2. Sistema cria Sale draft (ou busca existente)
3. Redireciona para `/sales/:id/edit?step=1`
4. Usuário adiciona produtos → POST `/sales/:id/items` (Turbo Stream)
5. Item aparece no carrinho via Turbo Stream
6. Usuário continua para step 2 → `/sales/:id/edit?step=2`
7. Usuário escolhe pagamento → Atualiza Sale draft
8. Usuário continua para step 3 → `/sales/:id/edit?step=3`
9. Usuário confirma → PATCH `/sales/:id/finalize`
10. Service finaliza a venda (cria payment, atualiza estoque, etc)

## Validações

- Sale draft só pode ter itens enquanto status = "draft"
- Não pode finalizar venda sem itens
- Não pode finalizar venda sem método de pagamento
- Validações de estoque ao adicionar item
