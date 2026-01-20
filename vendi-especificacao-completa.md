# Vendi Gestão - Especificação Técnica Completa

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Modelagem de Dados](#2-modelagem-de-dados)
3. [Estrutura de Rotas e Controllers](#3-estrutura-de-rotas-e-controllers)
4. [Fluxos de Telas](#4-fluxos-de-telas)
5. [Especificação Detalhada das Telas](#5-especificação-detalhada-das-telas)
6. [Regras de Negócio](#6-regras-de-negócio)
7. [Integrações Externas](#7-integrações-externas)

---

## 1. Visão Geral

### 1.1 Sobre o Projeto

O **Vendi Gestão** é um sistema web mobile-first criado para pequenos lojistas de roupa infantil gerenciarem suas vendas e estoque de forma rápida e simples. O objetivo principal é permitir que o dono da loja registre uma venda em menos de 1 minuto, diretamente pelo celular.

### 1.2 Características Principais

- **Interface Responsiva**: Layout otimizado para desktop (laptop) e mobile (com navegação inferior)
- **Cadastro Rápido**: Permite vender mesmo sem ter produtos previamente cadastrados
- **Gestão de Estoque**: Controle automático de estoque com alertas
- **Links de Pagamento**: Geração de links para enviar ao cliente via WhatsApp
- **Múltiplas Variações**: Suporte para produtos com diferentes tamanhos e/ou cores
- **Relatórios Simples**: Métricas essenciais do dia, semana e mês

### 1.3 Stack Tecnológica

- **Backend**: Ruby on Rails 7.1+
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Banco de Dados**: PostgreSQL
- **Cache**: Redis
- **Jobs**: Sidekiq
- **Storage**: Active Storage com AWS S3
- **Autenticação**: Devise

---

## 2. Modelagem de Dados

### 2.1 Visão Geral das Entidades

O sistema possui 12 entidades principais organizadas em 4 grupos:

**Grupo 1: Loja e Usuários**
- Account (Conta/Loja)
- AccountConfig (Configurações da Conta)
- User (Usuários/Vendedores)

**Grupo 2: Produtos**
- Product (Produto)
- ProductVariant (Variação de Tamanho e/ou Cor)
- StockMovement (Movimentação de Estoque)

**Grupo 3: Vendas**
- Sale (Venda)
- SaleItem (Item da Venda)
- Payment (Pagamento)

**Grupo 4: Relacionamentos**
- Customer (Cliente)
- Notification (Notificação)

### 2.2 Entidade: Account (Conta/Loja)

Representa a conta/loja do usuário. Cada conta é um "tenant" isolado no sistema.

**Campos principais:**
- Nome da conta/loja (ex: "Universo Kids")
- Slug único para URL amigável
- WhatsApp da conta (formato brasileiro)
- Tipo de loja (roupa infantil, adulta, etc)
- URL do logo
- Timezone (padrão: America/Sao_Paulo)
- Flag de ativo/inativo
- Data de conclusão do onboarding

**Relacionamentos:**
- Possui um AccountConfig
- Possui muitos Users (vendedores)
- Possui muitos Products
- Possui muitas Sales
- Possui muitos Customers
- Possui muitas Notifications

### 2.3 Entidade: AccountConfig (Configurações)

Armazena todas as preferências e configurações personalizadas da loja.

**Metas:**
- Meta diária de vendas (valor em reais)
- Meta semanal (opcional)
- Meta mensal (opcional)

**Alertas de Estoque:**
- Alertas habilitados? (sim/não)
- Quantidade mínima para alertar (padrão: 3 unidades)

**Formas de Pagamento:**
- PIX habilitado? (sim/não)
- Cartão habilitado? (sim/não)
- Dinheiro habilitado? (sim/não)
- Fiado habilitado? (sim/não)

**Outras Configurações:**
- Exigir cliente em toda venda?
- Enviar link de pagamento automático via WhatsApp?
- Configurações adicionais (JSON flexível)

### 2.4 Entidade: User (Usuário)

Representa os vendedores/funcionários da loja.

**Campos principais:**
- Email (único no sistema)
- Senha criptografada (Devise)
- Nome completo
- Telefone
- Papel/função (owner/employee)
- Flag de ativo/inativo

**Campos do Devise:**
- Token de reset de senha
- Contador de logins
- IP do último login
- Data do último acesso

**Relacionamentos:**
- Pertence a uma Account
- Registrou muitas Sales

### 2.5 Entidade: Product (Produto)

Representa um produto do catálogo da loja. Um produto pode ter múltiplas variações de tamanho e/ou cor.

**Informações Básicas:**
- Nome do produto (obrigatório)
- Descrição detalhada (opcional)
- SKU interno (opcional)
- Código de referência do fornecedor (opcional)

**Precificação:**
- Preço base (valor padrão)
- Preço de custo (para cálculo de margem)

**Categorização:**
- Categoria (ex: Vestidos, Conjuntos)
- Marca
- Cor
- Material

**Controle:**
- Ativo/Inativo (soft delete)
- Posição para ordenação manual
- Campos customizados (JSON)
- Data de exclusão (soft delete)

**Relacionamentos:**
- Pertence a uma Account
- Possui muitas ProductVariants (tamanhos e/ou cores)
- Possui muitas imagens (Active Storage)
- Foi vendido em muitos SaleItems

### 2.6 Entidade: ProductVariant (Variação)

Cada variação representa uma combinação específica de tamanho e/ou cor do produto com seu próprio estoque.

**Campos principais:**
- Tamanho (ex: "P", "M", "G", "2", "4", "6-8") - opcional se usar apenas cor
- Cor (ex: "Vermelho", "Azul", "Verde") - opcional se usar apenas tamanho
- SKU específico da variação (opcional)
- Ajuste de preço (positivo ou negativo sobre o preço base)

**Controle de Estoque:**
- Quantidade em estoque (atual)
- Quantidade reservada (vendas pendentes)
- Quantidade disponível = estoque - reservado (calculado)

**Outros:**
- Ativo/Inativo
- Posição para ordenação
- Data de exclusão

**Relacionamentos:**
- Pertence a um Product
- Possui muitos SaleItems
- Possui muitos StockMovements

**Métodos Importantes:**
- Calcular quantidade disponível
- Verificar se está com estoque baixo
- Verificar se está sem estoque

### 2.7 Entidade: StockMovement (Movimentação)

Registra todo histórico de entrada e saída de estoque para auditoria.

**Campos:**
- Tipo de movimentação: "sale" (venda), "adjustment" (ajuste manual), "return" (devolução), "initial" (estoque inicial)
- Quantidade movimentada (positivo = entrada, negativo = saída)
- Quantidade antes da movimentação
- Quantidade após a movimentação
- Observações/notas
- Dados adicionais (JSON)

**Relacionamentos:**
- Pertence a uma Account
- Pertence a uma ProductVariant
- Foi feita por um User (opcional)
- Relacionada a um SaleItem (se for venda)

### 2.8 Entidade: Sale (Venda)

Representa uma transação de venda completa.

**Identificação:**
- Número da venda (gerado automaticamente, ex: "20250119-0001")
- Status: "draft", "pending_payment", "paid", "cancelled"

**Valores:**
- Subtotal (soma dos itens)
- Valor do desconto (em reais)
- Percentual de desconto (alternativo)
- Total final (subtotal - desconto)
- Quantidade total de itens

**Dados Adicionais:**
- Observações da venda
- Token único para link de pagamento
- Data/hora do envio do link
- Data/hora da conclusão
- Data/hora do cancelamento
- Motivo do cancelamento

**Relacionamentos:**
- Pertence a uma Account
- Registrada por um User (vendedor)
- Feita para um Customer (opcional)
- Possui muitos SaleItems
- Possui um Payment

**Métodos Importantes:**
- Gerar número da venda
- Gerar token do link de pagamento
- Enviar link via WhatsApp
- Marcar como paga
- Cancelar venda

### 2.9 Entidade: SaleItem (Item da Venda)

Cada linha/produto dentro de uma venda.

**Snapshot do Produto:**
- Nome do produto (snapshot histórico)
- Tamanho (snapshot histórico) - se aplicável
- Cor (snapshot histórico) - se aplicável
- SKU (snapshot histórico)

**Valores:**
- Quantidade vendida
- Preço unitário (no momento da venda)
- Subtotal (quantidade × preço)
- Desconto aplicado neste item
- Total final do item

**Relacionamentos:**
- Pertence a uma Sale
- Pertence a uma ProductVariant
- Gerou um StockMovement

**Por que Snapshot?**
Os dados do produto são copiados no momento da venda para preservar o histórico. Se o produto for editado ou excluído depois, a venda continua mostrando os dados originais (nome, tamanho, cor, SKU).

### 2.10 Entidade: Payment (Pagamento)

Armazena informações sobre o pagamento da venda.

**Campos Principais:**
- Método de pagamento: "pix", "credit_card", "debit_card", "cash", "fiado"
- Status: "pending", "processing", "paid", "failed", "refunded"
- Valor do pagamento

**Específico PIX:**
- QR Code gerado
- Código copia-e-cola
- ID da transação PIX

**Específico Cartão:**
- Bandeira (Visa, Mastercard, etc)
- Últimos 4 dígitos
- Número de parcelas

**Dados da Transação:**
- ID da transação no gateway
- Resposta completa do gateway (JSON)
- Data/hora do pagamento
- Data/hora de expiração

**Relacionamentos:**
- Pertence a uma Sale (1:1)

### 2.11 Entidade: Customer (Cliente)

Cadastro opcional de clientes da loja.

**Dados Pessoais:**
- Nome completo (obrigatório)
- Telefone
- Email
- CPF

**Endereço:**
- Rua
- Número
- Complemento
- Bairro
- Cidade
- Estado
- CEP

**Estatísticas (Cache):**
- Total de compras realizadas
- Valor total gasto
- Data da última compra

**Outros:**
- Observações
- Ativo/Inativo
- Data de exclusão (soft delete)

**Relacionamentos:**
- Pertence a uma Account
- Realizou muitas Sales

### 2.12 Entidade: Notification (Notificação)

Sistema de notificações internas da aplicação.

**Campos:**
- Tipo: "low_stock", "sale_completed", "daily_goal_reached", etc
- Título
- Mensagem
- URL de ação (para onde a notificação leva)
- Dados adicionais (JSON)
- Lida ou não
- Data/hora de leitura

**Relacionamentos:**
- Pertence a uma Account
- Pode ser direcionada a um User específico

---

## 3. Estrutura de Rotas e Controllers

### 3.1 Organização de Controllers

O sistema é organizado em controllers RESTful com algumas ações customizadas:

**Controllers Principais:**
- OnboardingController - Setup inicial
- DashboardController - Tela principal
- ProductsController - Gestão de produtos
- Products::StockAdjustmentsController - Ajuste de estoque
- SalesController - Gestão de vendas
- Sales::PaymentsController - Pagamentos
- ReportsController - Relatórios
- CustomersController - Clientes
- SettingsController - Configurações
- NotificationsController - Notificações

**Controllers Públicos:**
- Public::PaymentLinksController - Links de pagamento (sem autenticação)

### 3.2 Rotas Principais

**Autenticação:**
- GET /login - Tela de login
- POST /login - Fazer login
- DELETE /logout - Sair
- GET /signup - Criar conta
- POST /signup - Registrar

**Dashboard:**
- GET / (root) - Dashboard principal
- GET /dashboard - Mesma coisa

**Onboarding:**
- GET /onboarding - Tela de boas-vindas ou passo atual
- POST /onboarding/complete_step_1 - Completar passo 1
- POST /onboarding/complete_step_2 - Completar passo 2

**Produtos:**
- GET /products - Listar produtos
- GET /products/new - Formulário novo produto
- POST /products - Criar produto
- GET /products/:id - Detalhe do produto
- GET /products/:id/edit - Editar produto
- PATCH /products/:id - Atualizar produto
- DELETE /products/:id - Deletar (soft delete)
- GET /products/low_stock - Produtos com estoque baixo
- PATCH /products/:id/toggle_active - Ativar/desativar

**Ajuste de Estoque:**
- GET /products/:id/stock_adjustment - Tela de ajuste
- POST /products/:id/stock_adjustment - Processar ajuste

**Vendas:**
- GET /sales - Listar vendas
- GET /sales/new - Nova venda (multi-step)
- POST /sales - Criar venda
- GET /sales/:id - Detalhe da venda
- POST /sales/:id/send_payment_link - Enviar link WhatsApp
- PATCH /sales/:id/complete - Marcar como paga
- PATCH /sales/:id/cancel - Cancelar venda

**Link de Pagamento Público:**
- GET /p/:token - Visualizar link de pagamento
- POST /p/:token/pay - Processar pagamento

**Relatórios:**
- GET /reports - Relatório principal
- GET /reports/sales - Relatório detalhado de vendas
- GET /reports/products - Relatório de produtos
- GET /reports/customers - Relatório de clientes

**Configurações:**
- GET /settings - Configurações gerais
- PATCH /settings - Atualizar configurações

**Clientes:**
- GET /customers - Listar clientes
- GET /customers/new - Novo cliente
- POST /customers - Criar cliente
- GET /customers/:id - Detalhe
- PATCH /customers/:id - Atualizar
- DELETE /customers/:id - Deletar

**Notificações:**
- GET /notifications - Listar notificações
- PATCH /notifications/:id/mark_as_read - Marcar como lida
- PATCH /notifications/mark_all_as_read - Marcar todas

### 3.3 Padrões de URL

**Filtros e Parâmetros Comuns:**
- ?query=texto - Busca por texto
- ?filter=low_stock - Filtros pré-definidos
- ?period=today|7_days|month - Período de tempo
- ?page=2 - Paginação
- ?step=1 - Passo em fluxos multi-step

**Exemplos:**
- /products?query=vestido&filter=low_stock
- /sales?period=7_days&page=2
- /sales/new?step=2
- /reports?period=month

---

## 4. Fluxos de Telas

### 4.1 Fluxo de Primeiro Acesso (Onboarding)

**Passo 0: Tela de Boas-Vindas**

Quando o usuário acessa pela primeira vez após criar a conta, ele vê uma tela de boas-vindas com três opções:

1. **Registrar primeira venda** - Vai direto para o fluxo de nova venda
2. **Cadastrar produtos** - Vai para o cadastro de produto
3. **Importar produtos do XML** - Importar de nota fiscal (recurso futuro)

Também tem o botão principal "Começar" que leva ao setup.

**Passo 1: Configurar a Loja**

Formulário simples pedindo:
- Nome da loja (ex: "Universo Kids")
- WhatsApp (com máscara brasileira)
- Tipo de loja (dropdown: Roupa Infantil, Roupa Adulta, etc)
- Toggle para ativar alertas de estoque baixo

Tem uma dica amigável: "você pode cadastrar produtos durante a venda. Não precisa preparar tudo antes."

Ao clicar "Continuar", salva os dados e vai para o passo 2.

**Passo 2: Personalizar**

Aqui o lojista define suas preferências:

1. **Meta diária de vendas**: Um slider interativo que vai de R$ 0 até R$ 5.000+, valor sugerido R$ 1.500
2. **Estoque baixo**: Stepper para escolher quando alertar (padrão: 3 unidades)
3. **Formas de pagamento**: Grid com 4 cards selecionáveis (Pix, Cartão, Dinheiro, Fiado)

Ao clicar "Finalizar Configuração":
- Marca o onboarding como completo
- Redireciona para o Dashboard
- Mostra mensagem motivadora: "Pronto! Vamos registrar sua primeira venda."

### 4.2 Fluxo de Cadastro de Produto

**Início:**
- Pode começar de qualquer lugar clicando no botão "+" ou "Novo produto"
- Se não tiver produtos ainda, o empty state tem um botão grande "Cadastrar meu primeiro produto"

**Tela de Cadastro:**

Dividida em 3 seções:

1. **Foto do Produto** (opcional)
   - Placeholder com ícone de câmera
   - Botão "Adicionar foto"
   - Aceita múltiplas imagens (até 5)
   - Mostra preview das fotos selecionadas

2. **Informações Básicas**
   - Nome do produto (obrigatório, mostra erro se vazio: "Digite um nome para o produto")
   - Preço (opcional, formatado como R$ XX,XX)

3. **Variações**
   - Variações podem ser por tamanho e/ou cor
   - Chips pré-selecionados: Tamanhos (M, G) e/ou Cores
   - Botão "+ Adicionar tamanho" ou "+ Adicionar cor" para criar outras variações
   - Toggle "Informar estoque agora"
     - Se OFF: cria as variações com estoque zerado
     - Se ON: mostra campo de quantidade para cada variação

Botão verde no rodapé: "Salvar produto"

**Após salvar:**
- Redireciona para a tela de detalhe do produto
- Mostra mensagem de sucesso
- Oferece opção de ajustar estoque imediatamente

### 4.3 Fluxo de Ajuste de Estoque

**Entrada:**
Pode chegar aqui de várias formas:
- Do detalhe do produto → botão "Ajustar estoque"
- Da lista de alertas de estoque baixo → botão "Ajustar estoque"
- Do dashboard → clicando no card de "Estoque baixo"

**Tela de Ajuste:**

Mostra instrução: "Use + e - para corrigir o estoque rapidamente."

Lista todas as variações do produto, cada uma com:
- Ícone colorido (verde = ok, laranja = baixo, vermelho = zero)
- Nome da variação (ex: "Tam P", "Cor Vermelha", "Tam M - Cor Azul")
- Quantidade atual (ex: "12 unidades")
- Badge de status se aplicável ("BAIXO", "SEM ESTOQUE")
- Stepper +/- para ajustar

Campo opcional de observação: "Ex: contagem do estoque"

Botão verde: "Confirmar ajuste"

**Processamento:**
- Atualiza a quantidade de cada variação modificada
- Cria registro de StockMovement para auditoria
- Tipo = "adjustment"
- Guarda a observação

**Após confirmar:**
- Volta para a tela de detalhe do produto
- Mostra "Estoque ajustado com sucesso!"
- As quantidades estão atualizadas

### 4.4 Fluxo de Alertas de Estoque

**Gatilhos:**
- Badge de notificação no ícone do sino
- Card no dashboard: "Estoque baixo - X itens precisam de atenção"
- Notificação push (se habilitado)

**Tela de Alertas:**

Header: "Estoque baixo - Evite perder vendas por falta de produto."

Lista organizada por severidade:
1. Primeiro: Produtos CRÍTICOS (sem estoque, vermelho)
2. Depois: Produtos em ALERTA (estoque baixo, laranja)

Cada card mostra:
- Número do alerta (círculo colorido)
- Badge de status ("CRÍTICO" ou "EM ESTOQUE")
- Foto do produto
- Nome do produto
- Tamanho específico
- Última venda (ex: "há 2 horas")
- Botão "Ajustar estoque"

Rodapé: "Exibindo X itens com alerta"

**Ação:**
Clicar em "Ajustar estoque" leva diretamente para o ajuste daquele produto específico.

### 4.5 Fluxo Completo de Nova Venda

Este é o fluxo mais importante do sistema, dividido em 3 passos.

**Passo 1: Selecionar Produtos**

Indicador de progresso: "1/3"

Componentes principais:

1. **Barra de Busca**
   - Campo de texto para buscar produtos
   - Busca em tempo real enquanto digita
   - Placeholder: "Buscar produto..."

2. **Recentes**
   - Chips com os 5 produtos mais vendidos recentemente
   - Ex: "Vestido floral", "Conjunto Moletom", "Body RN"
   - Ao clicar, adiciona o produto à lista

3. **Lista de Produtos**
   Cada produto mostra:
   - Miniatura (80x80px)
   - Nome
   - Referência/SKU
   - Preço
   - **Seleção de tamanho** - Chips clicáveis (P, M, G, etc)
   - Alerta se estoque baixo: "⚠️ Baixo estoque (2 un)"
   - **Stepper de quantidade** - Aparece após selecionar tamanho
   - Botão "+ Adicionar" ou contador se já adicionou

**Comportamento:**
- Usuário clica em um tamanho (ex: M)
- Aparecem os botões +/- de quantidade
- Ao incrementar, o item é adicionado ao carrinho
- O card ganha borda verde mostrando que está selecionado
- O botão muda para mostrar a quantidade

4. **Resumo (Sticky no Bottom)**
   - Ícone de carrinho
   - "1 item selecionado" ou "X itens selecionados"
   - Total parcial: "Total: R$ 89,90"
   - Botão verde: "Continuar"

Os dados são salvos temporariamente na sessão do navegador.

**Validação:**
- Precisa ter pelo menos 1 item selecionado
- Não pode exceder a quantidade disponível em estoque

Ao clicar "Continuar" → vai para Passo 2

---

**Passo 2: Forma de Pagamento**

Indicador: "Passo 2/3"

1. **Resumo do Pedido** (Card azul no topo)
   - Ícone de sacola de compras
   - "RESUMO DO PEDIDO"
   - Quantidade de itens: "Itens: 3"
   - Subtotal: "Subtotal: R$ 139,90"

2. **Forma de Pagamento** (Grid 2x2)
   
   Quatro cards grandes e clicáveis:
   - **Pix** - Ícone de QR Code
   - **Cartão** - Ícone de cartão de crédito
   - **Dinheiro** - Ícone de nota
   - **Fiado** - Ícone de caderneta
   
   Apenas as formas habilitadas na configuração aparecem ativas.
   
   Ao selecionar:
   - Card ganha borda verde e checkmark
   - Se for **Cartão**: aparece campo de parcelas (1x até 12x)
   - Se for **Fiado**: exige selecionar ou cadastrar cliente

3. **Opções Adicionais** (Toggles)
   
   a) **Aplicar desconto**
   - Se ativado, expande campos:
     - Radio: "Valor fixo" ou "Porcentagem"
     - Input: R$ 10,00 ou 10%
     - Atualiza o total em tempo real
   
   b) **Adicionar cliente**
   - Se ativado, expande:
     - Autocomplete de clientes cadastrados
     - Ou botão "Cadastrar novo cliente" (abre modal)

4. **Valor Total** (Card destacado)
   - "Valor Total a Pagar"
   - Valor em verde, grande: "R$ 139,90"
   - Atualizado automaticamente se aplicar desconto

Botão verde: "Continuar"

**Validações:**
- Forma de pagamento obrigatória
- Se desconto > subtotal, mostra erro
- Se "Fiado", cliente é obrigatório

Ao clicar "Continuar" → vai para Passo 3

---

**Passo 3: Confirmação e Finalização**

Indicador: "Passo 3/3"

Mostra um resumo completo:
- Lista de todos os produtos selecionados
- Quantidades
- Valores individuais
- Desconto aplicado (se houver)
- Forma de pagamento escolhida
- Cliente (se informado)
- **Valor Total Final**

**Opções de Finalização:**

O que aparece aqui depende da forma de pagamento escolhida:

**Se PIX ou Cartão:**
- Radio option 1: "Enviar link de pagamento via WhatsApp"
  - Mostra preview do link
  - Campo de telefone (pré-preenchido se tiver cliente)
  - Ao enviar, cria a venda como "pending_payment"
  
- Radio option 2: "Pagamento confirmado em mãos"
  - Finaliza a venda imediatamente como "paid"
  - Pula a etapa de pagamento online

**Se Dinheiro:**
- Checkbox marcado: "Pagamento recebido"
- Finaliza direto como "paid"

**Se Fiado:**
- Campo opcional: "Data de vencimento"
- Finaliza como "pending_payment"
- Cliente é obrigatório

Botões:
- Primário (verde): "Finalizar venda"
- Secundário: Link "Voltar e editar"

**Processamento (ao clicar Finalizar):**

1. Cria o registro da Sale com status apropriado
2. Cria todos os SaleItems
3. Cria o Payment
4. Atualiza o estoque (decrementa as quantidades)
5. Cria os StockMovements para auditoria
6. Se solicitou link WhatsApp:
   - Gera token único
   - Envia mensagem via WhatsApp API
7. Limpa a sessão temporária
8. Verifica se algum produto ficou com estoque baixo (cria notificação)
9. Verifica se atingiu a meta diária (notificação de comemoração)

**Após finalizar:**
- Redireciona para a tela de detalhe da venda
- Mostra mensagem: "Venda registrada com sucesso! 🎉"
- Se enviou WhatsApp: "Link de pagamento enviado!"

### 4.6 Fluxo de Visualização de Vendas

**Lista de Vendas:**

Header:
- Título: "Vendas"
- Subtítulo: "Acompanhe rapidamente o que foi vendido"
- Ícone de filtro (abre filtros avançados)

Filtros rápidos (Pills):
- "Hoje" (ativo por padrão)
- "7 dias"
- "Mês"

Lista de cards, cada venda mostra:
- Horário (ex: "14:32")
- Valor total em verde: "R$ 79,90"
- Descrição: "2 itens • Vestido + Conjunto"
- Badge de pagamento colorido: "PIX" (verde), "CARTÃO" (azul), "DINHEIRO" (cinza)
- Seta para ver detalhes

FAB flutuante: "Registrar venda"

**Ao clicar em uma venda:**

Abre a tela de detalhe mostrando:

**Header:**
- Número da venda: "#20250119-0001"
- Status com cor: "PAGA" (verde), "PENDENTE" (laranja), "CANCELADA" (vermelho)
- Data e hora completa

**Itens da Venda:**
- Lista de todos os produtos
- Foto + Nome + Tamanho
- Quantidade × Preço unitário
- Subtotal de cada item

**Resumo Financeiro:**
- Subtotal
- Desconto (se aplicado)
- **Total** (destacado)

**Pagamento:**
- Método utilizado
- Status do pagamento
- Se PIX: QR Code e código copia-e-cola
- Se Cartão: Bandeira, últimos 4 dígitos, parcelas
- Data/hora do pagamento

**Cliente:** (se informado)
- Nome
- Telefone
- Link para "Ver histórico do cliente"

**Ações Disponíveis:**

Se venda está pendente:
- Botão: "Confirmar pagamento"
- Botão: "Reenviar link WhatsApp"
- Botão: "Cancelar venda"

Se venda está paga:
- Botão: "Compartilhar comprovante"
- Botão: "Cancelar venda" (com confirmação)

Se venda está cancelada:
- Mostra motivo do cancelamento
- Mostra quem cancelou e quando

### 4.7 Fluxo de Relatórios

**Acesso:**
- Desktop: Sidebar → "Relatórios"
- Mobile: Bottom navigation → "Menu" → "Relatórios"
- Ou diretamente pela URL /reports

**Tela Principal:**

Header:
- "Relatórios"
- "O essencial para acompanhar sua loja"
- Ícone de calendário (seletor de datas customizado)

Filtros de período (Pills):
- "Hoje"
- "7 dias"
- "Mês"

**Card Principal - Total Vendido:**
- Valor enorme em verde: "R$ 1.240,50"
- Ícone de gráfico ascendente
- Label: "Total vendido"

**Métricas em Grid:**

Card 1: Vendas
- Número grande: "8"
- Label: "Vendas"

Card 2: Ticket Médio
- Valor: "R$ 155,06"
- Label: "Ticket médio"

**Mais Vendidos:**

Lista ranqueada:
1. "Conjunto Dinossauro"
   - Miniatura
   - "12 unidades"
   - "R$ 828,00"

2. "Vestido Margarida"
   - Miniatura
   - "8 unidades"
   - "R$ 312,50"

3. "Body Básico RN"
   - Miniatura
   - "5 unidades"
   - "R$ 100,00"

Link no final: "Ver todos" → leva para relatório detalhado

**Cálculos:**

Todas as queries consideram o período selecionado:

- Total vendido = soma do total_amount de todas as vendas pagas
- Vendas = contagem de vendas com status "paid"
- Ticket médio = total vendido ÷ quantidade de vendas
- Mais vendidos = agrupa por produto, soma quantidades vendidas, ordena decrescente

### 4.8 Fluxo de Configurações

**Acesso:**
- Desktop: Sidebar → "Configurações"
- Mobile: Bottom navigation → "Menu" → "Configurações"

**Tela de Configurações:**

Organizada em seções:

**1. Dados da Loja**
- Nome da loja (editável)
- WhatsApp (editável)
- Logo (upload de imagem)

**2. Metas**
- Meta diária (slider)
- Meta semanal (opcional)
- Meta mensal (opcional)

**3. Alertas**
- Toggle: Alertas de estoque baixo
- Stepper: Quantidade mínima para alertar
- Toggle: Notificações push

**4. Formas de Pagamento**
- Toggles para cada forma:
  - PIX
  - Cartão (Crédito/Débito)
  - Dinheiro
  - Fiado

**5. Preferências**
- Toggle: Exigir cliente em toda venda
- Toggle: Enviar link de pagamento automaticamente

Botão verde no final: "Salvar alterações"

**Validações:**
- Pelo menos 1 forma de pagamento deve estar ativa
- Nome e WhatsApp obrigatórios
- Meta não pode ser negativa

Ao salvar:
- Atualiza o registro de AccountConfig
- Mostra mensagem: "Configurações atualizadas!"
- Mantém na mesma tela

---

## 5. Especificação Detalhada das Telas

### 5.1 Dashboard (Tela Principal)

**Propósito:** Visão geral do dia atual de vendas e alertas importantes.

**URL:** `/` ou `/dashboard`

**Parâmetros opcionais:**
- `date` - para visualizar outro dia específico

**Layout:**

**Header Personalizado:**
- Avatar circular da loja (logo ou ícone padrão)
- Saudação contextual baseada na hora:
  - 5h-12h: "Bom dia, [Nome da Loja] 👋"
  - 12h-18h: "Boa tarde, [Nome da Loja] ☀️"
  - 18h-5h: "Boa noite, [Nome da Loja] 🌙"
- Data por extenso: "Hoje, 15 Jan" ou nome do dia se for outro
- Badge com meta: "META DIÁRIA: R$ 500"
- Ícone de lupa (abre busca global)

**Card: Vendas de Hoje**

Mostra o desempenho do dia:

- Valor total enorme em verde: "R$ 0,00"
- Texto explicativo: "0 vendas • Ticket médio: —"

Se não tem vendas ainda, mostra traço no ticket médio.
Se tem vendas, calcula: total ÷ quantidade = ticket médio

Cores da meta:
- Vermelho se < 30% da meta
- Laranja se 30-70% da meta
- Verde se > 70% da meta

**Card: Estoque Baixo** (condicional)

Só aparece se existirem produtos com estoque abaixo do threshold.

- Ícone de caixa laranja
- Título: "Estoque baixo"
- Descrição: "3 itens precisam de atenção"
- Seta para navegar

Ao clicar → redireciona para /products/low_stock

**Empty State** (quando não tem vendas)

Se for o primeiro dia ou não tiver nenhuma venda ainda:

- Ilustração: Sacola verde grande e amigável
- Título motivador: "Pronto para começar?"
- Texto: "Registre sua primeira venda e acompanhe seu dia aqui."
- Botão CTA: "Registrar venda agora"

**FAB (Floating Action Button)**

Botão verde flutuante fixo no canto inferior direito:
- Ícone de carrinho de compras
- Ao clicar → /sales/new

Pressionar e segurar ou clicar em expansão:
- Mostra opção secundária: "Novo produto"
- Com ícone de voz: "Registrar por voz ou texto"

**Navegação Responsiva:**

**Desktop/Laptop:**
- Layout otimizado com sidebar lateral e topbar
- Navegação através do menu lateral

**Mobile/Tablet:**
- Bottom Navigation (fixa no rodapé)
- 4 tabs sempre visíveis:
  1. **Hoje** (casa) - /dashboard - ATIVO
  2. **Vendas** (recibo) - /sales
  3. **Produtos** (caixa) - /products
  4. **Menu** (três linhas) - abre sidebar lateral

**Lógica de Dados:**

Query para vendas de hoje:
- Filtra Sales onde `created_at >= Date.current.beginning_of_day`
- Filtra apenas status "paid"
- Soma o `total_amount`
- Conta registros para quantidade
- Calcula ticket médio

Query para estoque baixo:
- Busca ProductVariants onde `stock_quantity > 0 AND stock_quantity <= threshold`
- Conta produtos distintos
- Ordena por quantidade (menor primeiro)

Atualização em tempo real:
- Usa Turbo Streams para atualizar a cada 30 segundos
- Quando uma venda nova é criada, faz broadcast para atualizar

### 5.2 Lista de Produtos

**Propósito:** Catálogo completo dos produtos da loja com busca e filtros.

**URL:** `/products`

**Parâmetros:**
- `query` - texto de busca
- `filter` - filtro predefinido (all, low_stock, best_sellers)
- `page` - número da página

**Header:**
- Título: "Produtos"
- Ícone de sino (notificações) com badge se tiver alertas
- Botão "+" no canto direito

**Search Bar:**
- Input com ícone de lupa
- Placeholder: "Buscar por nome..."
- Busca while typing (Stimulus controller)
- Submete via GET mantendo outros params

**Filter Pills:**

Três opções mutuamente exclusivas:
- "Todos" - ?filter=all (padrão)
- "Estoque baixo" - ?filter=low_stock
- "Mais vendidos" - ?filter=best_sellers

O pill ativo fica verde com fundo sólido.

**Lista de Produtos:**

Cada card é um link para /products/:id e contém:

- **Thumbnail** (80×80px)
  - Se tem foto: primeira imagem do produto
  - Se não: placeholder com gradiente verde e ícone
  - Border-radius: 12px

- **Conteúdo Textual:**
  - Nome do produto (bold, 18px, truncado em 2 linhas)
  - "Variações: X" (cinza, 14px)

- **Badge de Status:**
  
  Lógica completa:
  
  1. Se TODAS variações têm estoque = 0:
     - Badge vermelho: "SEM ESTOQUE"
  
  2. Se ALGUMA variação tem 0 < estoque ≤ threshold:
     - Badge laranja: "BAIXO (N)"
     - Onde N = quantidade de variações nessa situação
  
  3. Se todas as variações têm estoque > threshold:
     - Badge verde: "EM ESTOQUE"

- **Ação:**
  - Seta para a direita (ícone chevron_right)
  - Cor cinza clara

**Hover/Press Effect:**
- Card eleva ligeiramente (shadow maior)
- Background fica levemente mais escuro

**Empty State:**

Se não existir nenhum produto:

- Ilustração: Sacola azul com carinha feliz
- Título: "Sua vitrine está vazia"
- Texto: "Cadastre seu primeiro produto para começar a vender agora mesmo."
- Botão azul: "Cadastrar meu primeiro produto"

**Paginação:**
- 20 produtos por página
- Infinite scroll (Turbo Frames)
- Ou botão "Carregar mais" no final

**Lógica de Busca:**

Para a query de texto:
- Busca no campo `name` usando ILIKE
- Pode usar pg_trgm para busca mais avançada
- Case-insensitive
- Remove acentos (unaccent extension)

Para filtro "low_stock":
- JOIN com product_variants
- WHERE stock_quantity > 0 AND stock_quantity <= threshold
- DISTINCT para não duplicar produtos

Para filtro "best_sellers":
- JOIN com sale_items → sales
- WHERE sales.created_at >= 30.days.ago
- GROUP BY product
- ORDER BY SUM(sale_items.quantity) DESC

### 5.3 Cadastro de Produto

**Propósito:** Formulário para adicionar novo produto ao catálogo.

**URL:** `/products/new`

**Método:** GET (visualizar) / POST (criar)

**Layout em Seções:**

**Seção 1: Foto do Produto**

- Area de upload grande com placeholder
- Ícone de câmera no centro
- Texto: "Adicionar foto"
- Border tracejado quando vazio
- Aceita arrastar e soltar (drag & drop)

Comportamento ao adicionar foto:
- Mostra preview da imagem
- Permite adicionar até 5 fotos
- Cada foto tem botão "X" para remover
- Primeira foto é a principal (thumbnail)

Formatos aceitos: JPG, PNG, WEBP
Tamanho máximo: 5MB por foto

**Seção 2: Informações Básicas**

Campo 1: **Nome do Produto**
- Label: "Nome do produto"
- Input de texto normal
- Placeholder: "Ex: Vestido floral"
- Obrigatório (asterisco vermelho)
- Validação em tempo real
- Erro se vazio: "Digite um nome para o produto."

Campo 2: **Preço** (Opcional)
- Label: "Preço (Opcional)"
- Input com máscara de moeda: "R$ 79,90"
- Não obrigatório
- Se vazio, pode definir preço depois ou por variação

**Seção 3: Variações**

Título: "Variações"

Variações podem ser por tamanho e/ou cor:

**Tamanhos (opcional):**
- Chips pré-selecionados: M, G (já marcados)
- Botão verde: "+ Adicionar tamanho"
- Ao clicar: abre modal com input de texto livre
- Exemplos: P, GG, 2, 4, 6-8

**Cores (opcional):**
- Botão verde: "+ Adicionar cor"
- Ao clicar: abre modal com input de texto ou seleção de cor
- Exemplos: Vermelho, Azul, Verde

**Combinações:**
- Sistema cria variações para cada combinação selecionada
- Ex: Se selecionar tamanhos M, G e cor Vermelho → cria: M-Vermelho, G-Vermelho

Cada variação adicionada vira um chip:
- Mostra tamanho e/ou cor
- Pode ser removido (X no canto)
- Pode ser reordenado (drag & drop)

**Toggle: "Informar estoque agora"**

Estado OFF (padrão):
- Cria variações com stock_quantity = 0
- Pode ajustar depois

Estado ON:
- Para cada variação, mostra input numérico
- Label: "Quantidade em estoque"
- Placeholder: 0
- Stepper +/- ou input direto

**Botão de Ação:**

Fixo no bottom (sticky):
- "Salvar produto" (verde, full width)
- Fica desabilitado se nome estiver vazio

**Validações Client-Side:**

- Nome: obrigatório, mínimo 2 caracteres
- Preço: se preenchido, deve ser número >= 0
- Variações: pelo menos 1 variação (tamanho, cor ou combinação)
- Estoque: se toggle ON, não pode ser negativo

**Processamento:**

Ao submeter o formulário:

1. Valida todos os campos
2. Se inválido, mostra erros inline
3. Se válido:
   - Cria o Product
   - Upload das imagens (Active Storage)
   - Para cada tamanho, cria ProductVariant
   - Se informou estoque, cria StockMovement inicial
   - Redireciona para /products/:id
   - Flash message: "Produto cadastrado com sucesso!"

**Campos Futuros** (não mostrados nas imagens):
- Descrição detalhada
- SKU
- Código de referência
- Categoria
- Marca
- Cor
- Material
- Preço de custo

### 5.4 Detalhe do Produto

**Propósito:** Visualizar todas as informações de um produto específico.

**URL:** `/products/:id`

**Layout:**

**Hero Section:**

- **Imagem Principal:** 
  - Full width, aspect ratio 1:1
  - Se múltiplas fotos, galeria com dots
  - Swipe horizontal para trocar
  - Zoom ao tocar (modal fullscreen)

- **Informações Primárias:**
  - Nome do produto (H1, 24px, bold)
  - Preço base (R$ 89,90, verde, 32px)
  - Última venda:
    - "Última venda: hoje" (se foi hoje)
    - "Última venda: ontem" (se foi ontem)
    - "Última venda: há 3 dias" (relativo)
    - Nada, se nunca vendeu

- **Badge de Status:**
  - Se SEM ESTOQUE: vermelho
  - Se ESTOQUE BAIXO: laranja com ícone ⚠️
  - Se OK: verde (ou não mostra)

**Seção: Variações e Estoque**

Título da seção: "Variações e Estoque"

Para cada variação, um card:

- **Ícone de camiseta colorido:**
  - Verde se quantidade > threshold
  - Laranja se 0 < quantidade ≤ threshold
  - Vermelho se quantidade = 0

- **Nome da variação:**
  - "Tamanho P" ou "Cor Vermelha" ou "Tam M - Cor Azul"
  - Bold, 16px

- **Quantidade:**
  - "12 unidades" (se > 1)
  - "1 unidade" (se = 1)
  - "Sem estoque" (se = 0)
  - Cinza, 14px

- **Badge "Atenção":**
  - Só aparece se quantidade ≤ threshold
  - Laranja, pill pequeno

**Botões de Ação:**

Dois botões largos empilhados:

1. **Primário (verde):**
   - "Ajustar estoque"
   - Ícone de edit/adjust
   - Link para /products/:id/stock_adjustment

2. **Outline (borda verde):**
   - "Editar produto"
   - Ícone de lápis
   - Link para /products/:id/edit

**Menu de Três Pontos:**

No header, ícone ⋮ abre menu dropdown:

- "Desativar produto" (se ativo)
  - Marca como inactive
  - Ainda aparece em vendas antigas
  
- "Ativar produto" (se inativo)
  - Marca como active novamente

- "Excluir produto" (vermelho)
  - Modal de confirmação:
    - "Tem certeza? Esta ação não pode ser desfeita."
    - "Cancelar" / "Excluir"
  - Faz soft delete (preenche deleted_at)
  - Redireciona para /products

**Seções Futuras:**

- Histórico de vendas (últimas 10)
- Histórico de movimentações de estoque
- Estatísticas (total vendido, unidades, margem)

### 5.5 Ajustar Estoque

**Propósito:** Interface rápida para corrigir quantidades em estoque.

**URL:** `/products/:id/stock_adjustment`

**Método:** GET (visualizar) / POST (processar)

**Header:**
- Título: "Ajustar estoque"
- Botão voltar (<) para /products/:id

**Instrução:**
- Texto amigável: "Use + e - para corrigir o estoque rapidamente."
- Cinza, 16px

**Lista de Variações:**

Para cada ProductVariant do produto:

Card horizontal contendo:

- **Ícone:**
  - Camiseta estilizada
  - Cor do fundo baseada em estoque:
    - Verde claro: tudo ok
    - Laranja claro: baixo
    - Vermelho claro: zero

- **Informações:**
  - Nome: "Tam P" ou "Cor Vermelha" ou "Tam M - Cor Azul" (bold)
  - Quantidade atual: "12 unidades" (cinza)
  - Badge se aplicável: "BAIXO" ou "SEM ESTOQUE"

- **Stepper:**
  - Botão "-" (cinza, circular)
  - Valor atual (número grande, editável)
  - Botão "+" (cinza, circular)
  - Min: 0, Max: 9999

Comportamento:
- Ao clicar +/-: incrementa/decrementa
- Pode digitar diretamente
- Valida em tempo real
- Não deixa ficar negativo

**Campo de Observação:**

Label: "Observação (opcional)"
- Textarea de múltiplas linhas
- Placeholder: "Ex: contagem do estoque"
- Máximo: 500 caracteres
- Contador de caracteres

**Botão de Ação:**

Sticky no bottom:
- "Confirmar ajuste" (verde, full width)
- Fica desabilitado se nenhuma quantidade mudou

**Processamento:**

Ao submeter:

1. Para cada variação que teve alteração:
   - Guarda quantidade antiga
   - Atualiza para quantidade nova
   - Calcula diferença (positiva ou negativa)
   - Cria StockMovement do tipo "adjustment"
   - Registra user que fez
   - Inclui observação

2. Se alguma variação ficou abaixo do threshold:
   - Cria notificação de estoque baixo

3. Redireciona para /products/:id
   - Flash: "Estoque ajustado com sucesso!"

### 5.6 Alertas de Estoque Baixo

**Propósito:** Centralizar todos os produtos que precisam de atenção.

**URL:** `/products/low_stock`

**Header:**
- Título: "Estoque baixo"
- Subtítulo: "Evite perder vendas por falta de produto."

**Organização:**

A lista é ordenada por severidade:
1. Produtos CRÍTICOS (alguma variação sem estoque)
2. Produtos EM ALERTA (variações com estoque baixo)

**Cada Alerta Mostra:**

Card expandido com várias informações:

- **Número do Alerta:**
  - Círculo com número (1, 2, 3...)
  - Cor baseada em severidade:
    - Vermelho: crítico
    - Laranja: alerta

- **Badge de Severidade:**
  - "CRÍTICO" (vermelho) se qty = 0
  - "EM ESTOQUE" (laranja) se qty > 0 mas baixo

- **Foto do Produto:**
  - Thumbnail 80×80px
  - Border-radius 12px

- **Informações:**
  - Nome do produto (bold)
  - Variação específica: "Tamanho: 4 Anos" ou "Cor: Vermelha" ou "Tam M - Cor Azul"
  - Última venda: "há 2 horas" (relativo)

- **Botão de Ação:**
  - "Ajustar estoque" (verde, outline)
  - Link direto para ajuste daquele produto

**Rodapé:**
- "Exibindo X itens com alerta"
- Cinza claro, pequeno

**Empty State:**

Se não houver alertas:

- Ícone: Check verde grande ✓
- Título: "Tudo certo por aqui!"
- Texto: "Nenhum produto com estoque baixo no momento."
- Botão: "Ver todos os produtos"

**Lógica de Query:**

```
Buscar produtos onde:
  - Produto está ativo (active = true)
  - Produto não está deletado (deleted_at IS NULL)
  - Pelo menos uma variação tem:
    - stock_quantity > 0 E
    - stock_quantity <= threshold
  OU
  - Pelo menos uma variação tem stock_quantity = 0

Ordenar por:
  1. Severidade (crítico primeiro)
  2. Quantidade (menor primeiro)
  3. Última venda (mais recente primeiro)
```

### 5.7 Lista de Vendas

**Propósito:** Histórico completo de todas as transações.

**URL:** `/sales`

**Parâmetros:**
- `period` - filtro de tempo (today, 7_days, month)
- `status` - filtro de status (opcional)
- `page` - paginação

**Header:**
- Título: "Vendas"
- Subtítulo: "Acompanhe rapidamente o que foi vendido."
- Ícone de filtro (abre modal de filtros avançados)

**Filter Pills:**

Três períodos comuns:
- "Hoje" (padrão)
- "7 dias"
- "Mês"

**Lista de Vendas:**

Cards ordenados do mais recente para o mais antigo.

Cada card mostra:

- **Horário:**
  - "14:32" (se foi hoje)
  - "Ontem 14:32" (se foi ontem)
  - "15/01 14:32" (se foi em outro dia)
  - Cinza, 14px

- **Valor Total:**
  - "R$ 79,90"
  - Verde se paga, laranja se pendente, vermelho se cancelada
  - Bold, 20px

- **Descrição dos Itens:**
  Gerada dinamicamente:
  - Se 1 item: "1 item • [Nome do produto]"
  - Se 2 itens: "2 itens • [Produto1] + [Produto2]"
  - Se 3+ itens: "X itens • [Produto1] + outros"
  - Cinza, 16px

- **Badge de Pagamento:**
  - "PIX" (verde)
  - "CARTÃO" (azul)
  - "DINHEIRO" (cinza)
  - "FIADO" (roxo)
  - Pill pequeno, bold

- **Seta:**
  - Chevron right >
  - Cinza claro

**FAB:**
- Botão verde flutuante
- Ícone: carrinho
- "Registrar venda"

**Paginação:**
- 25 vendas por página
- Scroll infinito ou "Carregar mais"

**Empty State:**

Se não houver vendas no período:

- Ícone: Recibo vazio
- Título: "Nenhuma venda ainda"
- Texto: "Suas vendas aparecerão aqui."
- Botão: "Registrar primeira venda"

**Lógica de Filtro:**

Para "Hoje":
- created_at >= Date.current.beginning_of_day

Para "7 dias":
- created_at >= 7.days.ago

Para "Mês":
- created_at >= Date.current.beginning_of_month

### 5.8 Detalhe da Venda

**Propósito:** Ver todos os dados de uma venda específica.

**URL:** `/sales/:id`

**Header:**

- Número da venda: "#20250119-0001"
- Status com badge colorido:
  - "PAGA" (verde)
  - "PENDENTE" (laranja)
  - "CANCELADA" (vermelho)
- Data e hora completa: "19/01/2025 às 14:32"

**Seção: Itens da Venda**

Título: "Itens"

Lista de todos os SaleItems:

Para cada item:
- Foto em miniatura (60×60px)
- Nome do produto + variação
  - "Vestido Floral - Tam M" ou "Vestido Floral - Cor Vermelha" ou "Vestido Floral - Tam M - Cor Azul"
- Quantidade × Preço unitário
  - "2 × R$ 44,95"
- Subtotal do item
  - "R$ 89,90"
  - Alinhado à direita

Separador visual entre itens.

**Resumo Financeiro:**

Box destacado com:

- **Subtotal:** R$ 139,90
- **Desconto:** -R$ 10,00 (se aplicado)
  - Mostra também a porcentagem: "(-7,2%)"
- Linha divisória
- **Total:** R$ 129,90
  - Verde, bold, 24px

**Seção: Pagamento**

Título: "Pagamento"

Card com informações do Payment:

- **Método:**
  - Ícone + nome
  - "Pix", "Cartão de Crédito", etc

- **Status:**
  - Badge colorido
  - "Pago", "Pendente", "Falhou"

**Se PIX:**
- QR Code para escannear
- Código copia-e-cola
- Botão: "Copiar código"
- Validade: "Expira em: 23:59"

**Se Cartão:**
- Bandeira (Visa, Mastercard, etc)
- Final: •••• 1234
- Parcelas: "3× de R$ 43,30"
- ID da transação (se disponível)

**Se Dinheiro:**
- Ícone de nota
- "Pagamento recebido em dinheiro"
- Data/hora do recebimento

**Seção: Cliente** (se informado)

- Nome do cliente
- Telefone (formatado)
- Link: "Ver histórico do cliente"
  - Abre /customers/:id

**Ações Disponíveis:**

Botões no final, dependendo do status:

**Se PENDENTE:**
- Primário: "Confirmar pagamento"
  - PATCH /sales/:id/complete
  - Marca como "paid"
  
- Secundário: "Reenviar link WhatsApp"
  - POST /sales/:id/send_payment_link
  
- Terciário (vermelho): "Cancelar venda"
  - Abre modal de confirmação
  - Pede motivo do cancelamento
  - PATCH /sales/:id/cancel

**Se PAGA:**
- "Compartilhar comprovante"
  - Gera PDF ou imagem
  - Share API do dispositivo
  
- "Cancelar venda" (com aviso)
  - Exige confirmação dupla
  - Explica que vai reverter estoque

**Se CANCELADA:**
- Mostra info box:
  - "Venda cancelada"
  - Motivo: "[texto do motivo]"
  - Por: [nome do usuário]
  - Quando: [data/hora]

### 5.9 Nova Venda - Detalhamento Completo

Este é o fluxo mais crítico e complexo.

**PASSO 1/3: Selecionar Produtos**

URL: `/sales/new?step=1`

**Componentes principais:**

1. **Barra de Busca:**
   - Input grande no topo
   - Placeholder: "Buscar produto..."
   - Ícone de lupa
   - Busca enquanto digita (debounce 300ms)
   - Se vazio, mostra recentes + todos

2. **Chips de Recentes:**
   - Abaixo da busca
   - Label: "RECENTES"
   - 5 produtos mais vendidos nos últimos 7 dias
   - Ex: "Vestido floral", "Conjunto Moletom"
   - Ao clicar: adiciona à seleção

3. **Lista de Produtos:**
   
   Seção: "PRODUTOS"
   
   Cada produto é um card com:
   
   - Foto (80×80px)
   - Nome (bold)
   - Referência: "Ref: 44029"
   - Preço: "R$ 89,90"
   
   - **Seleção de Variação:**
     - Chips horizontais mostrando variações disponíveis
     - Ex: "M", "G", "Vermelho", "M - Vermelho"
     - Radio buttons estilizados
     - Um por vez
     - Ao selecionar, chip fica verde
   
   - **Alerta de Estoque:**
     - Se stock <= threshold:
       - "⚠️ Baixo estoque (2 un)"
       - Laranja, pequeno
   
   - **Stepper de Quantidade:**
     - Só aparece após selecionar variação
     - Botões - e +
     - Valor no meio
     - Min: 1 (não deixa zerar)
     - Max: quantidade disponível
   
   - **Botão de Adicionar:**
     - Antes de selecionar: "+ Adicionar"
     - Depois de adicionar: mostra quantidade
     - Verde se adicionado

**Estado do Card:**
- Normal: fundo branco
- Hover: fundo cinza claro
- Selecionado: borda verde 2px

4. **Carrinho (Resumo Sticky):**
   
   Fixo no bottom, sempre visível:
   
   - Ícone de carrinho
   - Texto: "1 item selecionado" ou "X itens"
   - Total parcial: "Total: R$ 89,90"
   - Botão verde: "Continuar"
   
   Se carrinho vazio:
   - Botão fica cinza e desabilitado
   - Texto: "Selecione produtos"

**Validações:**
- Mínimo 1 item
- Não exceder estoque disponível
- Não permitir quantidade <= 0

**Persistência:**
Os dados ficam na sessão do navegador:
- session[:draft_sale][:items]
- Cada item: { variant_id, quantity, unit_price }

Ao clicar "Continuar":
- Valida se tem itens
- Salva na sessão
- Redireciona para step=2

---

**PASSO 2/3: Pagamento**

URL: `/sales/new?step=2`

**1. Resumo do Pedido:**

Card azul no topo com:
- Ícone de sacola
- Label: "RESUMO DO PEDIDO"
- Itens: "Itens: 3"
- Subtotal: "Subtotal: R$ 139,90"

**2. Forma de Pagamento:**

Grid 2×2 de cards grandes:

Card PIX:
- Ícone de QR code grande
- Label: "Pix"
- Selecionável

Card Cartão:
- Ícone de cartão
- Label: "Cartão"
- Selecionável

Card Dinheiro:
- Ícone de nota
- Label: "Dinheiro"
- Selecionável

Card Fiado:
- Ícone de caderneta
- Label: "Fiado"
- Selecionável (se habilitado)

**Comportamento:**
- Apenas os métodos habilitados ficam ativos
- Ao clicar: borda verde + checkmark
- Apenas um por vez (radio behavior)

**Se selecionar Cartão:**
Expande campo adicional:
- "Parcelas"
- Dropdown: 1× até 12×
- Mostra valor de cada parcela

**Se selecionar Fiado:**
Toggle "Adicionar cliente" fica obrigatório.

**3. Opções Adicionais:**

a) **Toggle: Aplicar desconto**

Estado OFF:
- Apenas o toggle

Estado ON:
- Expande campos abaixo
- Radio buttons:
  - "Valor fixo" (selecionado)
  - "Porcentagem"
- Input numérico:
  - "R$ 10,00" ou "10%"
  - Máscara apropriada
- Total atualiza em tempo real

b) **Toggle: Adicionar cliente**

Estado OFF:
- Apenas o toggle

Estado ON:
- Expande campo de busca/seleção
- Autocomplete de clientes cadastrados
- Busca por nome ou telefone
- Botão: "Cadastrar novo cliente"
  - Abre modal de cadastro rápido
  - Campos: nome, telefone
  - Salva e seleciona automaticamente

**4. Valor Total:**

Card grande e destacado:
- "Valor Total a Pagar"
- Valor em verde gigante: "R$ 139,90"
- Atualiza automaticamente se mudar desconto

**Botão de Ação:**
- "Continuar" (verde, full width)

**Validações:**
- Forma de pagamento obrigatória
- Se desconto % > 100, erro
- Se desconto R$ > subtotal, erro
- Se Fiado, cliente obrigatório

Ao clicar "Continuar":
- Salva escolhas na sessão
- Redireciona para step=3

---

**PASSO 3/3: Confirmação**

URL: `/sales/new?step=3`

**Resumo Completo:**

Mostra TUDO que foi escolhido:

1. **Itens:**
   - Lista todos os produtos
   - Nome + variação (tamanho e/ou cor)
   - Quantidade × preço
   - Subtotal de cada

2. **Resumo Financeiro:**
   - Subtotal
   - Desconto (se houver)
   - **Total Final**

3. **Forma de Pagamento:**
   - Método escolhido
   - Parcelas (se cartão)

4. **Cliente:**
   - Nome e telefone (se informado)

**Opções de Finalização:**

Dependendo do método de pagamento:

**PIX ou Cartão:**

Radio option 1: "Enviar link de pagamento"
- Mostra ícone do WhatsApp
- Campo de telefone (preenchido se tiver cliente)
- Preview: "O cliente receberá: [mensagem]"

Radio option 2: "Pagamento confirmado em mãos"
- Cliente já pagou pessoalmente
- Marca direto como "paid"

**Dinheiro:**

Checkbox marcado por padrão:
- "Pagamento recebido"
- Texto: "Recebido em dinheiro"

**Fiado:**

Campo opcional:
- "Data de vencimento"
- Date picker
- Se vazio, sem vencimento

**Botões:**

- Link: "← Voltar e editar"
  - Volta para step=2
  
- Botão primário: "Finalizar venda" (verde)

**Processamento:**

Ao clicar "Finalizar venda":

POST /sales com todos os dados

Backend executa Sales::CreateService:

1. Valida todos os dados
2. Cria registro de Sale
3. Gera sale_number único
4. Para cada item:
   - Cria SaleItem
   - Snapshot do produto
   - Calcula totais
5. Cria Payment
6. Para cada item:
   - Decrementa stock_quantity
   - Cria StockMovement (tipo: sale)
7. Se enviou WhatsApp:
   - Gera payment_link_token
   - Envia mensagem
   - Marca payment_link_sent_at
8. Se dinheiro:
   - Marca payment como paid
   - Marca sale como paid
   - Preenche completed_at
9. Verifica metas e alertas:
   - Se atingiu meta diária → notificação
   - Se produto ficou baixo → notificação
10. Limpa session[:draft_sale]
11. Redireciona para /sales/:id
12. Flash: "Venda registrada com sucesso! 🎉"

### 5.10 Relatórios

**Propósito:** Métricas e análises do negócio.

**URL:** `/reports`

**Parâmetros:**
- `period` - hoje, 7_days, month, custom
- `start_date` - para período customizado
- `end_date` - para período customizado

**Header:**
- Título: "Relatórios"
- Subtítulo: "O essencial para acompanhar sua loja."
- Ícone de calendário
  - Abre seletor de período customizado
  - Date range picker

**Filter Pills:**
- "Hoje"
- "7 dias"
- "Mês"

**Card Principal:**

Destaque visual:
- Label: "Total vendido"
- Valor gigante em verde: "R$ 1.240,50"
- Ícone de gráfico ascendente
- Comparação com período anterior:
  - "↗ +12,5% vs período anterior" (verde)
  - "↘ -5,2% vs período anterior" (vermelho)

**Grid de Métricas:**

Card 1: **Vendas**
- Número grande: "8"
- Label: "Vendas"
- Comparação: "+2 vs anterior"

Card 2: **Ticket Médio**
- Valor: "R$ 155,06"
- Label: "Ticket médio"
- Comparação: "+R$ 8,20"

**Seção: Mais Vendidos**

Título: "Mais Vendidos"

Lista ranqueada (top 10):

Para cada produto:
- Posição: "1.", "2.", "3."...
- Foto pequena (60×60px)
- Nome do produto
- Unidades vendidas: "12 unidades"
- Receita total: "R$ 828,00"
- Barra de progresso visual (proporcional ao #1)

Link no final:
- "Ver todos" → página com ranking completo

**Gráfico de Vendas:** (futuro)

Chart.js ou ApexCharts:
- Linha do tempo
- Eixo X: dias do período
- Eixo Y: valor em reais
- Tooltip ao passar o mouse
- Pontos clicáveis para ver detalhes

**Cálculos dos Dados:**

Query base:
```
Sales onde:
  - status = 'paid'
  - created_at no período selecionado
```

Total vendido:
- SUM(total_amount)

Quantidade de vendas:
- COUNT(*)

Ticket médio:
- total_vendido ÷ quantidade_vendas

Mais vendidos:
- JOIN sales → sale_items → product_variants → products
- GROUP BY product_id
- SUM(sale_items.quantity) as units_sold
- SUM(sale_items.total_amount) as revenue
- ORDER BY units_sold DESC
- LIMIT 10

Comparação com período anterior:
- Calcula mesmos valores para período equivalente anterior
- Ex: se filtrar "7 dias", compara com 7 dias anteriores
- Mostra diferença percentual

---

## 6. Regras de Negócio

### 6.1 Gestão de Estoque

**Regra 1: Atualização Automática**

Quando uma venda é finalizada com sucesso:
- O estoque de cada variação vendida é decrementado automaticamente
- Quantidade = Quantidade Atual - Quantidade Vendida
- Cria um registro em StockMovement para auditoria
- Se a nova quantidade ficar abaixo do threshold, gera alerta

**Regra 2: Validação de Disponibilidade**

Ao adicionar item no carrinho:
- Sistema verifica se há estoque suficiente
- available_quantity = stock_quantity - reserved_quantity
- Se não houver, mostra erro: "Estoque insuficiente. Disponível: X unidades"
- Não permite prosseguir com quantidade maior que disponível

**Regra 3: Cancelamento de Venda**

Quando uma venda é cancelada:
- Estoque é revertido para todas as variações
- Quantidade volta ao valor antes da venda
- Cria StockMovement do tipo "return" com quantidade positiva
- Observação registra o motivo do cancelamento

**Regra 4: Ajuste Manual**

No ajuste manual de estoque:
- Registra quantidade antes e depois
- Calcula diferença (positiva = entrada, negativa = saída)
- Cria StockMovement do tipo "adjustment"
- Permite adicionar observação explicativa
- Verifica threshold e cria alerta se necessário

**Regra 5: Alertas de Estoque Baixo**

Dispara notificação quando:
- Após venda, se qty <= threshold
- Após ajuste manual, se qty <= threshold
- Não dispara duplicado (verifica se já existe alerta ativo)
- Marca alerta como resolvido quando qty > threshold novamente

### 6.2 Vendas e Pagamentos

**Regra 1: Numeração de Vendas**

Formato: YYYYMMDD-NNNN
- YYYYMMDD = data da venda
- NNNN = sequencial do dia (0001, 0002, etc)
- Exemplo: 20250119-0001

Geração:
- Ao criar sale, antes de salvar
- Busca último número do mesmo dia
- Incrementa sequencial
- Se for primeira do dia, começa em 0001

**Regra 2: Cálculo de Totais**

Para cada SaleItem:
- subtotal = quantity × unit_price
- total_amount = subtotal - discount_amount

Para Sale:
- subtotal = SUM de todos sale_items.subtotal
- se discount_percentage:
  - discount_amount = subtotal × (percentage / 100)
- total_amount = subtotal - discount_amount

Arredondamento:
- Sempre 2 casas decimais
- Arredonda para cima no último centavo

**Regra 3: Status da Venda**

Estados possíveis:
- **draft**: Em criação (não finalizada)
- **pending_payment**: Aguardando pagamento
- **paid**: Paga e concluída
- **cancelled**: Cancelada

Transições permitidas:
- draft → pending_payment (ao finalizar com PIX/Cartão/Fiado)
- draft → paid (ao finalizar com Dinheiro)
- pending_payment → paid (ao confirmar pagamento)
- pending_payment → cancelled (cancelamento)
- paid → cancelled (cancelamento com reversão de estoque)

**Regra 4: Link de Pagamento**

Geração:
- Token: 32 bytes aleatórios, URL-safe
- URL: dominio.com/p/TOKEN
- Validade: 24 horas (configurable)

Mensagem WhatsApp padrão:
```
Olá! 👋

Sua compra no *[Nome da Loja]* está pronta!

📦 X item(s)
💰 Total: R$ XXX,XX

Para pagar, acesse: [LINK]
```

Comportamento:
- Cliente acessa link
- Vê resumo da compra
- Escolhe método (PIX ou Cartão)
- Completa pagamento
- Sistema atualiza status automaticamente via webhook

**Regra 5: Cancelamento**

Permite cancelar se:
- Status = pending_payment → sempre permite
- Status = paid → só até 24h depois
- Status = cancelled → não permite

Ao cancelar:
- Exige motivo (texto)
- Reverte estoque
- Marca sale.cancelled_at
- Marca sale.cancellation_reason
- Se tinha payment, marca como refunded (futuro)
- Notifica cliente (se tiver email/phone)

### 6.3 Meta e Estatísticas

**Regra 1: Meta Diária**

Configurável por conta em AccountConfig.

Cálculo de progresso:
- total_hoje = SUM de sales pagas do dia
- percentual = (total_hoje / meta_diária) × 100
- arredonda para 1 casa decimal

Notificações:
- 50% atingido: "Você está na metade! 🎯"
- 100% atingido: "Meta do dia alcançada! 🎉"
- 150% atingido: "Dia espetacular! Você superou a meta! 🚀"

**Regra 2: Ticket Médio**

Fórmula:
- ticket_médio = total_vendido ÷ quantidade_vendas
- apenas vendas com status = paid
- arredonda para 2 casas decimais
- se quantidade = 0, retorna null (mostra "—")

**Regra 3: Estatísticas de Cliente**

Atualiza após cada venda:
- total_purchases++
- total_spent += sale.total_amount
- last_purchase_at = sale.completed_at

Usa counter cache para performance.

**Regra 4: Estatísticas de Produto**

Calcula sob demanda (não cached):
- Total vendido = SUM(sale_items.quantity) onde sale.status = paid
- Receita = SUM(sale_items.total_amount)
- Última venda = MAX(sale.created_at)

### 6.4 Variações de Produto

**Regra 1: Preço Final**

Lógica:
- Se variant.price_adjustment existe:
  - final_price = product.base_price + variant.price_adjustment
- Senão:
  - final_price = product.base_price

Exemplo:
- Produto: R$ 100,00
- Variação P: sem ajuste → R$ 100,00
- Variação GG: +R$ 10,00 → R$ 110,00

**Regra 2: Exclusão de Variação**

Permite deletar se:
- Nunca foi vendida (não tem sale_items)

Se já foi vendida:
- Faz soft delete (preenche deleted_at)
- Mantém para histórico
- Não aparece mais em novos cadastros
- Ainda aparece em vendas antigas

**Regra 3: Ordenação**

Campo position permite ordenação manual:
- Null = ordem alfabética
- Valor definido = ordem customizada
- Permite drag & drop na interface

Ordem padrão sugerida:
- P, M, G, GG
- 0, 2, 4, 6, 8, 10, 12, 14, 16
- Alfabética para outros

### 6.5 Notificações

**Regra 1: Tipos de Notificação**

- **low_stock**: Produto abaixo do threshold
- **out_of_stock**: Produto zerou
- **daily_goal_50**: Atingiu 50% da meta
- **daily_goal_100**: Atingiu 100% da meta
- **daily_goal_150**: Superou 150% da meta
- **sale_completed**: Venda concluída (para multi-usuário)
- **payment_received**: Pagamento confirmado

**Regra 2: Deduplicação**

Evita spam:
- Verifica se já existe notificação não lida do mesmo tipo
- Para mesmo produto/venda nos últimos 30 minutos
- Se existir, não cria nova

**Regra 3: Limpeza**

Notificações lidas:
- Auto-arquiva após 30 dias
- Mantém histórico em tabela separada (futuro)

Notificações não lidas:
- Mantém indefinidamente
- Badge no sino mostra contagem

---

## 7. Integrações Externas

### 7.1 Storage de Imagens

**Propósito:** Armazenar fotos de produtos.

**Provider:** AWS S3 ou similar

**Active Storage:**
- Upload direto do browser (Direct Upload)
- Variants para diferentes tamanhos
- CDN para performance

**Variants:**
- thumbnail: 80×80
- medium: 400×400
- large: 800×800
- original: tamanho real

**Processamento:**
- ImageMagick ou libvips
- Compressão automática
- Conversão para WebP (quando possível)

---

## 8. Instruções para Cursor Rules

Ao implementar este projeto, adicione as seguintes instruções no arquivo `.cursorrules` ou nas configurações do Cursor:

```markdown
# Cursor Rules - Vendi Gestão

## 📋 Contexto do Projeto

Este é o projeto **Vendi Gestão**, uma plataforma web mobile-first para gestão de vendas e estoque de lojas físicas.

## 🎯 Princípios Fundamentais

1. **Responsividade First** - Layout otimizado para desktop (laptop) e mobile
   - Desktop: sidebar lateral e topbar
   - Mobile/Tablet: navegação inferior (bottom navigation) com último item abrindo sidebar
2. **Seguir padrões Rails 8** - Usar recursos modernos do Rails
3. **Multi-Account First** - Tudo deve considerar isolamento por account (não "store")
4. **Service Objects** - Lógica de negócio em services, não em controllers
5. **Mobile-First Design** - Interface pensada primeiro para mobile, depois adaptada para desktop

## 📁 Estrutura de Arquivos

### Models
- `Account` (não "Store") - Representa a conta/loja do usuário
- `AccountConfig` (não "StoreConfig") - Configurações da conta
- `Product` - Produtos do catálogo
- `ProductVariant` - Variações por tamanho E/OU cor
- `User` - Usuários/vendedores
- `Sale`, `SaleItem`, `Payment` - Vendas e pagamentos
- `Customer` - Clientes
- `Notification` - Notificações
- `StockMovement` - Movimentações de estoque

### Controllers
- Sempre usar namespaces apropriados
- Services para lógica complexa
- Controllers enxutos

### Views
- Layout responsivo:
  - Desktop: `layouts/application.html.erb` com sidebar
  - Mobile: `layouts/mobile.html.erb` com bottom navigation
- Componentes reutilizáveis em `shared/`
- Stimulus controllers para interatividade

## 🔧 Padrões de Código

### Models

```ruby
class Product < ApplicationRecord
  belongs_to :account
  has_many :product_variants, dependent: :destroy
  
  validates :account_id, presence: true
  validates :name, presence: true
end

class ProductVariant < ApplicationRecord
  belongs_to :product
  
  # Variação pode ser por tamanho E/OU cor
  # size e color são ambos opcionais, mas pelo menos um deve existir
  validates :size, presence: true, if: -> { color.blank? }
  validates :color, presence: true, if: -> { size.blank? }
end
```

### Controllers

```ruby
class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  
  def index
    @products = @account.products.includes(:product_variants)
  end
  
  private
  
  def set_account
    @account = current_user.account
  end
end
```

### Services

```ruby
module Sales
  class CreateService
    def initialize(account:, user:, items:, payment_method:)
      @account = account
      @user = user
      @items = items
      @payment_method = payment_method
    end
    
    def call
      return false unless valid?
      
      ActiveRecord::Base.transaction do
        create_sale
        create_sale_items
        update_stock
        create_payment
      end
    end
    
    private
    
    def valid?
      # Validações
    end
  end
end
```

## 🎨 UI e Layout

### Responsividade

- **Desktop (≥1024px):**
  - Sidebar lateral sempre visível
  - Topbar com ações principais
  - Conteúdo centralizado com max-width

- **Mobile/Tablet (<1024px):**
  - Bottom navigation fixa no rodapé
  - 4 tabs principais + último item abre sidebar
  - Layout adaptado para touch

### Componentes UI

- Cards para produtos e vendas
- Badges para status
- Steppers para quantidades
- Modais para ações secundárias
- Toast notifications para feedback

## 🚫 O Que NÃO Fazer

1. **NÃO usar "Store"** - Sempre usar "Account"
2. **NÃO criar lógica complexa em controllers** - Use services
3. **NÃO esquecer responsividade** - Sempre testar desktop e mobile
4. **NÃO usar Device/PWA específico** - Apenas responsividade web
5. **NÃO limitar variações a apenas tamanho** - Suportar tamanho E/OU cor

## ✅ O Que Sempre Fazer

1. **SEMPRE incluir account em queries** - `Product.where(account: @account)`
2. **SEMPRE validar responsividade** - Testar em desktop e mobile
3. **SEMPRE usar services para operações complexas** - Criar, atualizar, deletar
4. **SEMPRE considerar multi-account** - Isolamento por account_id
5. **SEMPRE testar variações** - Produtos podem ter tamanho e/ou cor

## 🔐 Segurança

1. **Sempre validar account_id** - Não confiar apenas em params
2. **Sempre autenticar** - before_action :authenticate_user!
3. **Sempre autorizar** - Verificar se resource pertence ao account do usuário
4. **Sempre sanitizar inputs** - Strong parameters

## 📱 Responsividade

### Breakpoints
- Mobile: < 768px
- Tablet: 768px - 1023px
- Desktop: ≥ 1024px

### Navegação
- Desktop: Sidebar lateral
- Mobile: Bottom navigation + último item abre sidebar
- Transições suaves entre layouts
```

---

**FIM DA ESPECIFICAÇÃO COMPLETA**

Este documento serve como referência única para implementação do sistema Vendi Gestão, contendo todas as informações necessárias sobre modelagem de dados, fluxos de telas, regras de negócio e integrações.
