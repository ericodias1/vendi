# Vendi Gestão - Cronograma de Desenvolvimento

## 📋 Visão Geral

Este documento apresenta o cronograma completo de desenvolvimento da plataforma Vendi Gestão, organizado por fases e prioridades. O projeto está dividido em **6 fases principais**, com estimativa total de **12-16 semanas** de desenvolvimento.

---

## 🎯 Fase 0: Setup e Infraestrutura (Semana 1)

**Objetivo:** Configurar ambiente de desenvolvimento e infraestrutura base.

### Tarefas

#### 0.1 Setup do Projeto
- [x] Criar projeto Rails 8
- [x] Configurar PostgreSQL
- [x] Configurar Solid Cache/Queue/Cable (substituindo Redis/Sidekiq)
- [x] Configurar Active Storage (local configurado, S3 preparado)
- [x] Configurar autenticação (has_secure_password - padrão Núcleo)
- [x] Configurar Tailwind CSS
- [x] Configurar Hotwire (Turbo + Stimulus)
- [x] Configurar ambiente de desenvolvimento
- [x] Configurar ambiente de staging/produção (básico)

#### 0.2 Estrutura Base
- [x] Criar estrutura de diretórios (controllers, services, policies)
- [x] Configurar rotas base
- [x] Criar layouts responsivos (desktop e mobile - básico)
- [x] Configurar Cursor Rules (.cursorrules)

#### 0.3 Componentes UI Base
- [x] Criar componentes shared/ui (card, button, table, heading, back_link, badge, toast)
- [x] Criar componentes de formulário base (form_input, form_select, form_textarea, label)
- [x] Criar sistema de navegação (sidebar desktop, bottom nav mobile)
- [x] Configurar sistema de cores e design tokens (colors.css com cores Vendi)
- [x] Criar controllers Stimulus (sidebar, toast, dropdown)
- [x] Configurar layout backoffice com sidebar e bottom nav

**Estimativa:** 1 semana
**Prioridade:** Crítica

---

## 🏗️ Fase 1: Modelagem e Autenticação (Semanas 2-3)

**Objetivo:** Criar toda a estrutura de dados e sistema de autenticação.

### Tarefas

#### 1.1 Models Base
- [x] Criar model `Account` (migration, model, validações)
- [x] Criar model `AccountConfig` (migration, model, relacionamento 1:1 com Account)
- [x] Criar model `User` (migration, model, has_secure_password)
- [x] Configurar relacionamentos Account ↔ User
- [x] Criar models adicionais: `Product`, `Sale`, `Customer` (estrutura básica)
- [ ] Criar seeds básicos para desenvolvimento

#### 1.2 Autenticação
- [x] Configurar has_secure_password (padrão Núcleo)
- [x] Criar concern `Authentication` (current_user, current_account)
- [x] Implementar autorização básica (Pundit + BackofficePolicy)
- [x] Criar controllers de autenticação (sessions)
- [x] Criar views de login e registro
- [x] Implementar recuperação de senha

#### 1.3 Layouts Responsivos
- [x] Criar layout backoffice básico
- [x] Criar layout desktop com sidebar
- [x] Criar layout mobile com bottom navigation
- [x] Implementar toggle sidebar no mobile (último item do bottom nav)
- [x] Implementar sistema de navegação responsiva

**Estimativa:** 2 semanas
**Prioridade:** Crítica

---

## 📦 Fase 2: Produtos e Estoque (Semanas 4-6)

**Objetivo:** Implementar gestão completa de produtos e controle de estoque.

### Tarefas

#### 2.1 Models de Produtos
- [x] Criar model `Product` (migration, validações, relacionamentos)
- [x] Implementar soft delete em Product (Discard)
- [x] Criar concern `Searchable` para busca
- [x] Criar scopes úteis (ativos, recentes, estoque baixo, sem estoque)
- [x] Adicionar campos de estoque diretamente no Product (stock_quantity, size, color)
- [x] Criar model `StockMovement` (histórico de movimentações - referencia Product diretamente)
- [x] Implementar métodos de cálculo de estoque disponível (available_quantity, low_stock?, out_of_stock?)

#### 2.2 CRUD de Produtos
- [x] Criar `ProductsController` (index, show, new, create, edit, update, destroy)
- [x] Implementar busca de produtos (Searchable concern)
- [x] Criar views: index, show, new, edit
- [x] Implementar filtros (todos, estoque baixo, mais vendidos)
- [x] Implementar paginação
- [x] Corrigir bug de paginação (valores nil)

#### 2.3 Cadastro de Produtos
- [x] Criar formulário de cadastro (foto, nome, preço)
- [x] Implementar upload de múltiplas imagens (Active Storage)
- [x] Implementar campos opcionais (tamanho, cor) diretamente no produto
- [x] Implementar campo de estoque inicial (stock_quantity)
- [x] Implementar toggle "Informar estoque agora" (mostra/oculta campo de estoque, padrão: 1)
- [x] Validações client-side e server-side

#### 2.4 Detalhe do Produto
- [x] Criar view de detalhe com galeria de imagens
- [x] Mostrar informações do produto (nome, preço, tamanho, cor, estoque)
- [x] Implementar badges de status (OK, BAIXO, SEM ESTOQUE)
- [x] Criar botões de ação (Ajustar estoque, Editar)
- [x] Implementar menu de três pontos (Editar, Excluir) - Ativar/Desativar removido do MVP

#### 2.5 Ajuste de Estoque
- [x] Criar `Products::StockAdjustmentsController`
- [x] Criar view de ajuste com steppers
- [x] Implementar atualização de quantidades
- [x] Criar `StockMovement` para auditoria (referencia Product diretamente)
- [x] Implementar validações e feedback visual

#### 2.6 Alertas de Estoque Baixo
- [x] Criar rota e view `/products/low_stock` (usa mesma view index com filtro)
- [x] Implementar query para produtos com estoque baixo (scope `with_low_stock`)
- [x] Criar cards de alerta (usando `_product_card` com badges de status)
- [x] Implementar link direto para ajuste de estoque (via card → show → ajustar estoque)
- [ ] Criar sistema de notificações para estoque baixo (model Notification ainda não existe)

**Estimativa:** 3 semanas
**Prioridade:** Crítica

---

## 💰 Fase 3: Vendas (Semanas 7-10)

**Objetivo:** Implementar o fluxo completo de vendas, o mais crítico do sistema.

### Tarefas

#### 3.1 Models de Vendas
- [x] Criar model `Sale` (migration, validações, relacionamentos)
- [x] Criar model `Customer` (migration, validações)
- [x] Criar enums para status (draft, pending_payment, paid, cancelled)
- [x] Implementar cálculo de totais (subtotal, desconto, total - campos básicos)
- [x] Implementar geração automática de número da venda
- [x] Criar model `Payment` (migration, validações)
- [x] Definir estrutura de armazenamento de itens da venda (SaleItems - tabela separada)

#### 3.2 Lista de Vendas
- [x] Criar `SalesController` (index, show, new, create - básico)
- [x] Implementar busca de vendas (Searchable concern)
- [x] Criar view de lista com cards de vendas
- [x] Implementar filtros de período (hoje, 7 dias, mês)
- [x] Implementar scopes no model (today, this_week, this_month, by_period)
- [x] Mostrar drafts separadamente na listagem
- [ ] Implementar filtros de status
- [ ] Criar paginação

#### 3.3 Detalhe da Venda
- [x] Criar view de detalhe completa
- [x] Mostrar todos os produtos vendidos (via SaleItems)
- [x] Mostrar resumo financeiro (subtotal, desconto, total)
- [x] Mostrar informações de pagamento (método, status - traduzido para português)
- [x] Mostrar informações do cliente (se houver)
- [x] Implementar ações (Confirmar pagamento, Reenviar link, Cancelar via destroy)

#### 3.4 Nova Venda - Passo 1: Selecionar Produtos
- [x] Criar rota `/sales/:id/products/edit` (refatorado para ProductsController)
- [x] Implementar barra de busca de produtos
- [x] Criar chips de produtos recentes
- [x] Criar lista de produtos com variações (ProductVariants)
- [x] Implementar stepper de quantidade
- [x] Criar resumo sticky no bottom (carrinho)
- [x] Implementar validação de estoque disponível (verifica stock_quantity do Product)
- [x] Salvar dados em draft (Sale com status draft)

#### 3.5 Nova Venda - Passo 2: Forma de Pagamento
- [x] Criar rota `/sales/:id/details/edit` (refatorado para DetailsController)
- [x] Criar card de resumo do pedido (com imagens sobrepostas e resumo de produtos)
- [x] Implementar grid de formas de pagamento (PIX, Cartão de Crédito, Cartão de Débito, Dinheiro, Fiado)
- [x] Implementar toggle de desconto (valor fixo ou porcentagem) com cálculo em tempo real
- [x] Implementar toggle de adicionar cliente
- [x] Criar autocomplete de clientes (com Turbo Frames)
- [x] Criar modal de cadastro rápido de cliente
- [x] Atualizar total em tempo real (Alpine.js)
- [x] Separar actions: update_payment, update_discount, update_customer

#### 3.6 Nova Venda - Passo 3: Confirmação
- [x] Criar rota `/sales/:id/finalize/edit` (refatorado para FinalizeController)
- [x] Mostrar resumo completo da venda (itens, pagamento, cliente, totais)
- [x] Mostrar informações do cliente (se existir)
- [x] Implementar opções de finalização (link WhatsApp ou pagamento em mãos)
- [x] Criar service `Backoffice::Sales::FinalizeService`
- [x] Implementar finalização de Sale (com SaleItems)
- [x] Implementar decremento de estoque (atualiza stock_quantity do Product)
- [x] Criar StockMovements para auditoria (referencia Product diretamente)
- [ ] Implementar geração de token de link de pagamento
- [ ] Verificar alertas de estoque baixo
- [ ] Verificar metas diárias

#### 3.7 Ações de Venda
- [x] Implementar "Confirmar pagamento" (PATCH /sales/:id/complete)
- [x] Implementar "Reenviar link WhatsApp" (POST /sales/:id/send_payment_link)
- [x] Implementar "Cancelar venda" (DELETE /sales/:id via destroy)
- [x] Implementar reversão de estoque no cancelamento
- [x] Criar StockMovement do tipo "return"

#### 3.8 Clientes
- [x] Criar `CustomersController` (search, create)
- [x] Implementar busca de clientes (com Turbo Frames)
- [x] Criar modal de cadastro rápido de cliente (no fluxo de venda)
- [x] Implementar validação de cliente obrigatório para pagamento em fiado
- [ ] Criar views: index, show, new, edit (CRUD completo)
- [ ] Implementar estatísticas do cliente (total de compras, valor gasto)
- [ ] Criar view de histórico de compras do cliente

#### 3.9 Refactoring da Arquitetura de Vendas
- [x] Refatorar `SalesController` dividindo em controllers especializados
- [x] Criar `ProductsController` para step 1 (seleção de produtos)
- [x] Criar `DetailsController` para step 2 (pagamento, desconto, cliente) com actions separadas
- [x] Criar `FinalizeController` para step 3 (confirmação)
- [x] Adicionar scopes no model Sale (today, this_week, this_month, by_period)
- [x] Permitir múltiplos drafts simultâneos
- [x] Implementar cancelamento via destroy
- [x] Renomear views de steps para padrão semântico (_products, _details, _finalize)

**Estimativa:** 4 semanas
**Prioridade:** Crítica
**Status:** ~85% concluído

---

## 📊 Fase 4: Dashboard e Relatórios (Semanas 11-12)

**Objetivo:** Implementar visão geral e métricas do negócio.

### Tarefas

#### 4.1 Dashboard
- [x] Criar `DashboardController`
- [x] Criar view básica do dashboard
- [x] Implementar query de vendas do dia
- [x] Criar card de "Vendas de Hoje" com valor total
- [x] Calcular e mostrar ticket médio
- [x] Criar card de "Estoque Baixo" (condicional)
- [x] Implementar saudação contextual (bom dia/tarde/noite)
- [x] Corrigir formatação de data (mês em português)
- [x] Mostrar badge de meta diária
- [ ] Criar empty state quando não há vendas
- [ ] Implementar FAB (Floating Action Button)
- [ ] Implementar atualização em tempo real (Turbo Streams)

#### 4.2 Relatórios
- [x] Criar `ReportsController`
- [x] Implementar filtros de período (hoje, 7 dias, 30 dias, mês) via `BaseReportService`
- [x] Criar estrutura base de relatórios (controllers, services, views)
- [x] Implementar relatório "Resumo do Dia" (total vendido, quantidade, ticket médio, top produtos)
- [x] Implementar relatório "Top Lucro" (produtos com maior margem de lucro)
- [x] Implementar relatório "Estoque Crítico" (produtos que podem faltar)
- [x] Implementar relatório "Produtos Parados" (dinheiro travado em estoque)
- [x] Implementar relatório "Sugestão de Reposição" (lista de compra baseada em giro e lucro)
- [x] Implementar relatório "Ranking por Critério" (marca, categoria, tamanho, cor, fornecedor, faixa de preço)
- [x] Criar widgets de métricas (total vendido, lucro, margem, etc.)
- [x] Implementar sistema de insights automáticos nos relatórios
- [ ] Implementar comparação com período anterior
- [ ] Criar gráfico de vendas (Chart.js ou ApexCharts) - opcional

**Estimativa:** 2 semanas
**Prioridade:** Alta

---

## ⚙️ Fase 5: Configurações e Onboarding (Semanas 13-14)

**Objetivo:** Implementar configurações da conta e fluxo de onboarding.

### Tarefas

#### 5.1 Onboarding
- [ ] Criar `OnboardingController`
- [ ] Criar tela de boas-vindas (Passo 0)
- [ ] Criar Passo 1: Configurar a Conta (nome, WhatsApp, tipo, alertas)
- [ ] Criar Passo 2: Personalizar (metas, estoque baixo, formas de pagamento)
- [ ] Implementar salvamento de cada passo
- [ ] Marcar onboarding como completo
- [ ] Redirecionar para dashboard após conclusão

#### 5.2 Configurações
- [ ] Criar `SettingsController`
- [ ] Criar view de configurações organizada em seções
- [ ] Implementar edição de dados da conta (nome, WhatsApp, logo)
- [ ] Implementar edição de metas (diária, semanal, mensal)
- [ ] Implementar configuração de alertas (toggle, threshold)
- [ ] Implementar configuração de formas de pagamento (toggles)
- [ ] Implementar preferências (exigir cliente, enviar link automático)
- [ ] Criar service `Settings::UpdateService`
- [ ] Implementar validações

#### 5.3 Notificações
- [ ] Criar model `Notification` (migration, validações)
- [ ] Criar `NotificationsController` (index, mark_as_read, mark_all_as_read)
- [ ] Criar view de lista de notificações
- [ ] Implementar badge de contagem no ícone do sino
- [ ] Criar sistema de criação de notificações (estoque baixo, meta atingida)
- [ ] Implementar deduplicação de notificações
- [ ] Implementar auto-arquivo de notificações lidas

**Estimativa:** 2 semanas
**Prioridade:** Média

---

## 🔗 Fase 6: Integrações e Polimento (Semanas 15-16)

**Objetivo:** Finalizar integrações, otimizações e testes.

### Tarefas

#### 6.1 Link de Pagamento Público
- [ ] Criar `Public::PaymentLinksController` (sem autenticação)
- [ ] Criar view pública do link de pagamento
- [ ] Mostrar resumo da compra
- [ ] Implementar validação de token e expiração
- [ ] Criar interface de pagamento (PIX ou Cartão) - mockup inicial
- [ ] Implementar processamento de pagamento (futuro - gateway)

#### 6.2 Storage de Imagens
- [ ] Configurar Active Storage com AWS S3
- [ ] Implementar variants (thumbnail, medium, large)
- [ ] Configurar CDN para performance
- [ ] Implementar compressão automática
- [ ] Testar upload e exibição de imagens

#### 6.3 Otimizações
- [ ] Implementar counter cache onde necessário
- [ ] Otimizar queries (includes, joins)
- [ ] Implementar paginação eficiente
- [ ] Adicionar índices no banco de dados
- [ ] Otimizar assets (CSS, JS)
- [ ] Implementar cache de queries pesadas

#### 6.4 Testes
- [ ] Escrever testes de models
- [ ] Escrever testes de services
- [ ] Escrever testes de controllers
- [ ] Escrever testes de integração (fluxos completos)
- [ ] Testes de responsividade (desktop e mobile)

#### 6.5 Documentação e Deploy
- [ ] Documentar APIs (se houver)
- [ ] Criar README completo
- [ ] Documentar variáveis de ambiente
- [ ] Configurar CI/CD
- [ ] Preparar deploy para produção
- [ ] Configurar monitoramento (Sentry, etc)

**Estimativa:** 2 semanas
**Prioridade:** Média

---

## 📅 Resumo do Cronograma

| Fase | Descrição | Duração | Prioridade |
|------|-----------|---------|------------|
| **Fase 0** | Setup e Infraestrutura | 1 semana | Crítica |
| **Fase 1** | Modelagem e Autenticação | 2 semanas | Crítica |
| **Fase 2** | Produtos e Estoque | 3 semanas | Crítica |
| **Fase 3** | Vendas | 4 semanas | Crítica |
| **Fase 4** | Dashboard e Relatórios | 2 semanas | Alta |
| **Fase 5** | Configurações e Onboarding | 2 semanas | Média |
| **Fase 6** | Integrações e Polimento | 2 semanas | Média |
| **TOTAL** | | **16 semanas** | |

---

## 🎯 MVP (Minimum Viable Product)

Para um lançamento inicial, as fases críticas são:

- ✅ **Fase 0:** Setup e Infraestrutura (completo - componentes UI criados)
- ✅ **Fase 1:** Modelagem e Autenticação (completo - autenticação e layouts responsivos)
- ⚠️ **Fase 2:** Produtos e Estoque (models criados, estrutura simplificada - falta CRUD completo)
- ⚠️ **Fase 3:** Vendas (estrutura básica criada, falta fluxo completo)
- ⚠️ **Fase 4:** Dashboard básico (controller e view básicos criados, falta métricas reais)

**Estimativa MVP:** 12 semanas

Funcionalidades que podem ser adiadas para pós-MVP:
- Relatórios avançados (Fase 4 - parcial)
- Onboarding completo (Fase 5 - pode ser simplificado)
- Link de pagamento público funcional (Fase 6 - pode ser mockup)
- Otimizações avançadas (Fase 6)

---

## 📝 Notas Importantes

### Dependências Entre Fases

1. **Fase 1** deve ser completada antes de todas as outras
2. **Fase 2** (Produtos) deve ser completada antes da **Fase 3** (Vendas)
3. **Fase 3** (Vendas) deve ser completada antes da **Fase 4** (Dashboard)
4. **Fase 5** (Configurações) pode ser desenvolvida em paralelo com **Fase 4**
5. **Fase 6** (Integrações) pode ser desenvolvida em paralelo com outras fases

### Prioridades de Desenvolvimento

**Crítico (Bloqueador):**
- Setup e infraestrutura
- Autenticação e autorização
- CRUD de produtos
- Fluxo completo de vendas
- Dashboard básico

**Alto (Importante):**
- Relatórios
- Alertas de estoque
- Configurações básicas

**Médio (Desejável):**
- Onboarding completo
- Notificações avançadas
- Otimizações
- Link de pagamento público

### Considerações Técnicas

1. **Responsividade:** Sempre desenvolver pensando em desktop E mobile simultaneamente
2. **Multi-Account:** Toda query deve filtrar por `account_id`
3. **Services:** Lógica complexa sempre em services, não em controllers
4. **Validações:** Validações tanto client-side quanto server-side
5. **Auditoria:** Sempre criar `StockMovement` para rastreabilidade (referencia Product diretamente)
6. **Estrutura Simplificada:** Produtos não têm mais variações separadas - estoque, tamanho e cor são campos diretos do Product
7. **Estoque Direto:** StockMovement referencia Product diretamente (não ProductVariant)

---

## 🚀 Próximos Passos

1. Revisar e aprovar este cronograma
2. Definir equipe e responsabilidades
3. Configurar ferramentas de gestão (Trello, Jira, etc)
4. Iniciar **Fase 0: Setup e Infraestrutura**
5. Realizar reuniões semanais de acompanhamento

---

**Última atualização:** 2025-01-23
**Versão:** 1.3

## 📊 Progresso Atual

### ✅ Concluído
- Setup completo do projeto Rails 8
- Configuração de banco de dados (PostgreSQL + Solid Cache/Queue/Cable)
- Estrutura base de arquitetura (Service, BaseController, Policies, Concerns)
- Models principais criados (Account, AccountConfig, User, Product, Sale, Customer, StockMovement)
- **Mudança estrutural:** ProductVariant removido - estoque agora está diretamente no Product
- **Mudança estrutural:** StockMovement referencia Product diretamente (não ProductVariant)
- Product com campos diretos: stock_quantity, size, color
- Migrations com índices e constraints
- Controllers básicos (Dashboard, Products, Sales, Products::StockAdjustments)
- Rotas configuradas no namespace backoffice
- Layout backoffice básico
- Autenticação completa (SessionsController, views de login e registro)
- Recuperação de senha (PasswordResetsController, mailer)
- Componentes UI base (shared/ui: heading, button, card, badge, toast, back_link, form_input, etc)
- View de detalhe do produto (show.html.erb)
- View de ajuste de estoque (stock_adjustments/edit.html.erb)
- Sistema de navegação responsiva (sidebar desktop, bottom nav mobile)
- CRUD completo de produtos (index, show, new, create, edit, update, destroy)
- Dashboard com métricas básicas (vendas do dia, ticket médio, estoque baixo)
- Saudação contextual (bom dia/tarde/noite) com formatação de data em português
- Paginação de produtos corrigida

### 🚧 Em Progresso
- Views de vendas (lista, detalhe, nova venda multi-step)
- Dashboard com métricas reais (queries implementadas, falta empty state e FAB)

### 📝 Próximos Passos
1. Completar dashboard (empty state, FAB, atualização em tempo real)
2. Implementar fluxo completo de vendas (3 passos)
3. Criar sistema de notificações
4. Implementar relatórios básicos
