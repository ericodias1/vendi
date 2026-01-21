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

**Objetivo:** Implementar gestão completa de produtos com variações e controle de estoque.

### Tarefas

#### 2.1 Models de Produtos
- [x] Criar model `Product` (migration, validações, relacionamentos)
- [x] Implementar soft delete em Product (Discard)
- [x] Criar concern `Searchable` para busca
- [x] Criar scopes úteis (ativos, recentes)
- [ ] Criar model `ProductVariant` (tamanho e/ou cor)
- [ ] Criar model `StockMovement` (histórico de movimentações)
- [ ] Implementar métodos de cálculo de estoque disponível

#### 2.2 CRUD de Produtos
- [x] Criar `ProductsController` (index, show, new, create - básico)
- [x] Implementar busca de produtos (Searchable concern)
- [ ] Criar service `Backoffice::Products::CreateService` se necessário
- [ ] Criar service `Backoffice::Products::UpdateService` se necessário
- [ ] Criar service `Backoffice::Products::DestroyService` se necessário
- [ ] Criar views: index, show, new, edit
- [ ] Implementar filtros (todos, estoque baixo, mais vendidos)
- [ ] Implementar paginação

#### 2.3 Cadastro de Produtos
- [ ] Criar formulário de cadastro (foto, nome, preço)
- [ ] Implementar upload de múltiplas imagens (Active Storage)
- [ ] Implementar seleção de variações (tamanho e/ou cor)
- [ ] Criar interface para adicionar tamanhos
- [ ] Criar interface para adicionar cores
- [ ] Implementar criação de combinações (tamanho + cor)
- [ ] Implementar toggle "Informar estoque agora"
- [ ] Validações client-side e server-side

#### 2.4 Detalhe do Produto
- [ ] Criar view de detalhe com galeria de imagens
- [ ] Mostrar todas as variações com estoque
- [ ] Implementar badges de status (OK, BAIXO, SEM ESTOQUE)
- [ ] Criar botões de ação (Ajustar estoque, Editar)
- [ ] Implementar menu de três pontos (Ativar/Desativar, Excluir)

#### 2.5 Ajuste de Estoque
- [ ] Criar `Products::StockAdjustmentsController`
- [ ] Criar view de ajuste com steppers
- [ ] Implementar atualização de quantidades
- [ ] Criar `StockMovement` para auditoria
- [ ] Implementar validações e feedback visual

#### 2.6 Alertas de Estoque Baixo
- [ ] Criar rota e view `/products/low_stock`
- [ ] Implementar query para produtos com estoque baixo
- [ ] Criar cards de alerta organizados por severidade
- [ ] Implementar link direto para ajuste de estoque
- [ ] Criar sistema de notificações para estoque baixo

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
- [ ] Criar model `SaleItem` (com snapshot do produto)
- [ ] Criar model `Payment` (migration, validações)
- [ ] Implementar geração automática de número da venda

#### 3.2 Lista de Vendas
- [x] Criar `SalesController` (index, show, new, create - básico)
- [x] Implementar busca de vendas (Searchable concern)
- [ ] Criar view de lista com cards de vendas
- [ ] Implementar filtros de período (hoje, 7 dias, mês)
- [ ] Implementar filtros de status
- [ ] Criar paginação

#### 3.3 Detalhe da Venda
- [ ] Criar view de detalhe completa
- [ ] Mostrar todos os itens com snapshot
- [ ] Mostrar resumo financeiro
- [ ] Mostrar informações de pagamento
- [ ] Mostrar informações do cliente (se houver)
- [ ] Implementar ações (Confirmar pagamento, Reenviar link, Cancelar)

#### 3.4 Nova Venda - Passo 1: Selecionar Produtos
- [ ] Criar rota `/sales/new?step=1`
- [ ] Implementar barra de busca de produtos
- [ ] Criar chips de produtos recentes
- [ ] Criar lista de produtos com seleção de variação
- [ ] Implementar stepper de quantidade
- [ ] Criar resumo sticky no bottom (carrinho)
- [ ] Implementar validação de estoque disponível
- [ ] Salvar dados temporários na sessão

#### 3.5 Nova Venda - Passo 2: Forma de Pagamento
- [ ] Criar rota `/sales/new?step=2`
- [ ] Criar card de resumo do pedido
- [ ] Implementar grid de formas de pagamento (PIX, Cartão, Dinheiro, Fiado)
- [ ] Implementar campo de parcelas (se cartão)
- [ ] Implementar toggle de desconto (valor fixo ou porcentagem)
- [ ] Implementar toggle de adicionar cliente
- [ ] Criar autocomplete de clientes
- [ ] Criar modal de cadastro rápido de cliente
- [ ] Atualizar total em tempo real

#### 3.6 Nova Venda - Passo 3: Confirmação
- [ ] Criar rota `/sales/new?step=3`
- [ ] Mostrar resumo completo da venda
- [ ] Implementar opções de finalização (link WhatsApp ou pagamento em mãos)
- [ ] Criar service `Sales::CreateService`
- [ ] Implementar criação de Sale, SaleItems e Payment
- [ ] Implementar decremento de estoque
- [ ] Criar StockMovements para auditoria
- [ ] Implementar geração de token de link de pagamento
- [ ] Verificar alertas de estoque baixo
- [ ] Verificar metas diárias

#### 3.7 Ações de Venda
- [ ] Implementar "Confirmar pagamento" (PATCH /sales/:id/complete)
- [ ] Implementar "Reenviar link WhatsApp" (POST /sales/:id/send_payment_link)
- [ ] Implementar "Cancelar venda" (PATCH /sales/:id/cancel)
- [ ] Implementar reversão de estoque no cancelamento
- [ ] Criar StockMovement do tipo "return"

#### 3.8 Clientes
- [ ] Criar `CustomersController` (CRUD completo)
- [ ] Criar views: index, show, new, edit
- [ ] Implementar busca de clientes
- [ ] Implementar estatísticas do cliente (total de compras, valor gasto)
- [ ] Criar view de histórico de compras do cliente

**Estimativa:** 4 semanas
**Prioridade:** Crítica

---

## 📊 Fase 4: Dashboard e Relatórios (Semanas 11-12)

**Objetivo:** Implementar visão geral e métricas do negócio.

### Tarefas

#### 4.1 Dashboard
- [x] Criar `DashboardController`
- [x] Criar view básica do dashboard
- [ ] Implementar query de vendas do dia
- [ ] Criar card de "Vendas de Hoje" com valor total
- [ ] Calcular e mostrar ticket médio
- [ ] Criar card de "Estoque Baixo" (condicional)
- [ ] Implementar saudação contextual (bom dia/tarde/noite)
- [ ] Mostrar badge de meta diária
- [ ] Criar empty state quando não há vendas
- [ ] Implementar FAB (Floating Action Button)
- [ ] Implementar atualização em tempo real (Turbo Streams)

#### 4.2 Relatórios
- [ ] Criar `ReportsController`
- [ ] Implementar filtros de período (hoje, 7 dias, mês, customizado)
- [ ] Criar card principal "Total Vendido"
- [ ] Calcular e mostrar quantidade de vendas
- [ ] Calcular e mostrar ticket médio
- [ ] Implementar comparação com período anterior
- [ ] Criar seção "Mais Vendidos" (top 10)
- [ ] Implementar query de produtos mais vendidos
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

- ✅ **Fase 0:** Setup e Infraestrutura (parcialmente completo - falta componentes UI e testes)
- ✅ **Fase 1:** Modelagem e Autenticação (autenticação completa, falta layouts responsivos avançados)
- ⚠️ **Fase 2:** Produtos e Estoque (models criados, falta CRUD completo e variações)
- ⚠️ **Fase 3:** Vendas (estrutura básica criada, falta fluxo completo)
- ⚠️ **Fase 4:** Dashboard básico (controller e view básicos criados)

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
5. **Auditoria:** Sempre criar `StockMovement` para rastreabilidade
6. **Snapshot:** Dados de produto em vendas devem ser snapshot (não referência)

---

## 🚀 Próximos Passos

1. Revisar e aprovar este cronograma
2. Definir equipe e responsabilidades
3. Configurar ferramentas de gestão (Trello, Jira, etc)
4. Iniciar **Fase 0: Setup e Infraestrutura**
5. Realizar reuniões semanais de acompanhamento

---

**Última atualização:** 2025-01-20
**Versão:** 1.1

## 📊 Progresso Atual

### ✅ Concluído
- Setup completo do projeto Rails 8
- Configuração de banco de dados (PostgreSQL + Solid Cache/Queue/Cable)
- Estrutura base de arquitetura (Service, BaseController, Policies, Concerns)
- Models principais criados (Account, AccountConfig, User, Product, Sale, Customer)
- Migrations com índices e constraints
- Controllers básicos (Dashboard, Products, Sales)
- Rotas configuradas no namespace backoffice
- Layout backoffice básico
- Autenticação completa (SessionsController, views de login e registro)
- Recuperação de senha (PasswordResetsController, mailer)

### 🚧 Em Progresso
- CRUD completo de produtos e vendas
- Componentes UI reutilizáveis

### 📝 Próximos Passos
1. Implementar CRUD completo de produtos com views
2. Criar componentes UI base (shared/ui)
3. Implementar sistema de navegação responsiva
