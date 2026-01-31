# Vendi Gestão - Design System e Especificações de UI

## Sumário Executivo

Este documento contém todas as especificações de design, componentes, cores, tipografia e padrões de interface do aplicativo **Vendi Gestão** - um sistema de gestão para pequenos negócios de roupa infantil.

**Importante**: Este design system segue os mesmos princípios e padrões de desenvolvimento do projeto **nucleo_api**, utilizando:
- **Componentes reutilizáveis**: Partials ERB em `app/views/shared/ui/`
- **Tailwind CSS**: Classes utilitárias e variáveis CSS customizadas
- **Alpine.js**: Para interatividade frontend
- **Stimulus**: Para controllers JavaScript
- **Hotwire Turbo**: Para navegação SPA-like
- **Toasts**: Sistema de notificações toast ao invés de flash messages
- **Responsividade total**: Navegação mobile exclusiva com sidebar responsivo
- **Tipografia reutilizável**: Sempre usar componentes para hierarquia tipográfica
- **Padrões Rails**: Seguindo as diretrizes do projeto

---

## 1. Identidade Visual e Cores

### 1.1 Cores Primárias do Vendi Gestão

As cores específicas do Vendi Gestão devem ser adicionadas ao sistema de cores existente (`app/javascript/stylesheets/colors.css`):

```css
/* Adicionar em colors.css dentro de :root ou @theme */

/* === VENDI GESTÃO - CORES PRIMÁRIAS === */
--color-primary: #10b981;  /* Primary - emerald-500 */
--color-primary-dark: #059669;  /* Primary Dark - emerald-600 */

/* Variantes para uso em backgrounds e badges (derivadas de primary) */
--color-primary-light: #D1FAE5;  /* Para badges - mais elegante */
--color-primary-soft: #ECFDF5;   /* Backgrounds de alertas */

/* === VENDI GESTÃO - CORES DE ALERTA === */
--color-vendi-warning-orange: #FF8C42;
--color-vendi-warning-light: #FFF4EC; /* Background de alertas laranja */

/* === BACKGROUNDS === */
--color-background-light: #f8fafc; /* Background Light - slate-50 */
--color-sidebar-bg: #ffffff; /* Sidebar Background */

/* Integração com sistema existente */
--color-brand-500: var(--color-primary);
--color-brand-600: var(--color-primary-dark);
--color-brand-700: #047857;
```

### 1.2 Cores de Status

O sistema já possui cores de status (`success`, `warning`, `error`). Para o Vendi Gestão, mapeamos:

```css
/* Badges de Estoque - usar classes existentes */
/* EM ESTOQUE: badge-success (verde) */
/* BAIXO: badge-warning (laranja) */
/* SEM ESTOQUE: badge-error (vermelho) */
```

**Uso em ERB:**
```erb
<%= render 'shared/ui/badge', text: "EM ESTOQUE", variant: :success %>
<%= render 'shared/ui/badge', text: "BAIXO (2)", variant: :warning %>
<%= render 'shared/ui/badge', text: "SEM ESTOQUE", variant: :error %>
```

### 1.3 Integração com Tailwind

As cores devem estar disponíveis como classes Tailwind. Adicionar em `@theme` do `colors.css`:

```css
@theme {
  /* Variáveis principais */
  --color-primary: var(--color-primary);
  --color-primary-dark: var(--color-primary-dark);
  --color-primary-light: var(--color-primary-light);
  --color-primary-soft: var(--color-primary-soft);

  /* Backgrounds */
  --color-background-light: var(--color-bg-layout);
  --color-sidebar-bg: var(--color-sidebar-bg);

  /* Alertas */
  --color-vendi-warning-orange: var(--color-vendi-warning-orange);
  --color-vendi-warning-light: var(--color-vendi-warning-light);
}
```

**Uso:**
```erb
<div class="bg-primary text-white">Verde primário</div>
<div class="bg-primary-dark text-white">Verde escuro (hover)</div>
<div class="bg-primary-light text-primary-dark">Badge verde</div>
<div class="bg-sidebar-bg">Background da sidebar</div>
<div class="bg-background-light">Background do layout</div>
```

---

## 2. Tipografia

### 2.1 Sistema de Tipografia Existente

O projeto já possui um sistema de tipografia robusto (`app/javascript/stylesheets/typography.css`). **SEMPRE usar o componente `_heading.html.erb` para títulos** - nunca escrever tags HTML diretamente.

### 2.2 Componente de Heading (Obrigatório)

**SEMPRE usar o componente `shared/ui/heading` para títulos:**

```erb
<!-- Títulos de Página (H1) -->
<%= render 'shared/ui/heading', text: "Dashboard", size: :xl %>

<!-- Títulos de Seção (H2) -->
<%= render 'shared/ui/heading', text: "Vendas de Hoje", size: :lg %>

<!-- Subtítulos de Seção (H3) -->
<%= render 'shared/ui/heading', text: "Produtos em Destaque", size: :md %>

<!-- Com descrição -->
<%= render 'shared/ui/heading',
    text: "Dashboard",
    size: :xl,
    description: "Acompanhe suas vendas e estoque em tempo real" %>
```

**Tamanhos disponíveis:**
- `:xl` → H1, `text-2xl`, `font-bold` (Títulos de página)
- `:lg` → H2, `text-lg`, `font-semibold` (Títulos de seção)
- `:md` → H3, `text-md`, `font-semibold` (Subtítulos)

**⚠️ NUNCA escrever `<h1>`, `<h2>`, `<h3>` diretamente. Sempre usar o componente.**

### 2.3 Texto do Corpo

**Para texto do corpo, usar classes Tailwind diretamente:**

```erb
<!-- Body Text Regular -->
<p class="text-md text-slate-700">Texto do corpo</p>

<!-- Body Text Small -->
<p class="text-sm text-slate-600">Texto menor</p>

<!-- Body Text Large -->
<p class="text-lg text-slate-900">Texto maior</p>
```

### 2.4 Labels

**Labels são incluídos automaticamente nos componentes de formulário:**

```erb
<%= render 'shared/ui/form_input', form: f, field: :name, label: "Nome do Produto" %>
```

### 2.5 Helper para Preços

**Criar helper (`app/helpers/vendi_helper.rb`):**

```ruby
module VendiHelper
  def price_display(amount, size: :regular)
    return "—" if amount.nil?

    size_classes = {
      large: "text-3xl font-bold",
      regular: "text-lg font-bold",
      small: "text-sm font-semibold"
    }

    content_tag :span,
      number_to_currency(amount, unit: "R$ ", separator: ",", delimiter: "."),
      class: size_classes[size],
      style: "color: var(--color-primary);"
  end
end
```

**Uso:**
```erb
<%= price_display(89.90, size: :large) %>
```

---

## 3. Sistema de Notificações - Toasts

### 3.1 Uso de Toasts (Obrigatório)

**⚠️ IMPORTANTE**: O projeto **nucleo_api** usa **toasts ao invés de flash messages**. Sempre usar toasts para feedback ao usuário.

**O layout admin já inclui o container de toasts:**

```erb
<!-- Em app/views/layouts/admin.html.erb (já existe) -->
<div class="toast-container" id="toast-container">
  <%= render 'shared/flash_toasts' if notice.present? || alert.present? || flash.any? %>
</div>
```

### 3.2 Renderizar Toasts Manualmente

**Para renderizar toasts em controllers ou views:**

```erb
<%= render 'shared/ui/toast', type: :success, message: "Produto criado com sucesso!" %>
<%= render 'shared/ui/toast', type: :error, message: "Erro ao salvar produto" %>
<%= render 'shared/ui/toast', type: :warning, message: "Estoque baixo" %>
<%= render 'shared/ui/toast', type: :info, message: "Informação importante" %>
```

### 3.3 Toasts em Controllers

**Em controllers, usar `flash` normalmente - o layout converte automaticamente para toasts:**

```ruby
# app/controllers/vendi/products_controller.rb
def create
  @product = Vendi::Product.new(product_params)

  if @product.save
    redirect_to vendi_products_path, notice: "Produto criado com sucesso!"
  else
    flash.now[:error] = "Erro ao criar produto"
    render :new, status: :unprocessable_entity
  end
end
```

**O partial `shared/flash_toasts` converte automaticamente:**
- `notice` → `toast-success`
- `alert` → `toast-error`
- `flash[:success]` → `toast-success`
- `flash[:warning]` → `toast-warning`
- `flash[:info]` → `toast-info`

### 3.4 Toasts com Turbo Streams

**Para atualizar toasts via Turbo Streams:**

```erb
<!-- create.turbo_stream.erb -->
<%= turbo_stream.append "toast-container" do %>
  <%= render 'shared/ui/toast', type: :success, message: "Produto criado com sucesso!" %>
<% end %>
```

### 3.5 Componente Toast

**O componente toast já existe em `app/views/shared/ui/_toast.html.erb`:**

```erb
<%= render 'shared/ui/toast',
    type: :success,
    message: "Operação realizada com sucesso!",
    duration: 5000 %>
```

**Parâmetros:**
- `type`: `:success`, `:error`, `:warning`, `:info`
- `message`: Texto da mensagem
- `duration`: Duração em milissegundos (padrão: 5000)

---

## 4. Layout e Navegação Responsiva

### 4.1 Layout Admin Responsivo

**O layout admin do nucleo_api já possui navegação mobile responsiva:**

```erb
<!-- app/views/layouts/admin.html.erb -->
<div class="flex h-screen overflow-hidden" data-controller="sidebar">
  <!-- Sidebar Overlay (mobile only) -->
  <div class="hidden fixed inset-0 bg-black bg-opacity-50 z-40 md:hidden"
       data-sidebar-target="overlay"
       data-action="click->sidebar#close"></div>

  <!-- Sidebar -->
  <%= render "admin/shared/sidebar" %>

  <!-- Main Content -->
  <div class="flex-1 flex flex-col overflow-hidden">
    <!-- Topbar -->
    <%= render "admin/shared/topbar" %>

    <!-- Page Content -->
    <main class="flex-1 overflow-y-auto p-6">
      <%= yield %>
    </main>
  </div>
</div>
```

### 4.2 Sidebar Responsivo

**A sidebar usa o Stimulus controller `sidebar` para controle mobile:**

```erb
<!-- app/views/admin/shared/_sidebar.html.erb -->
<aside class="fixed md:static inset-y-0 left-0 z-50 w-64 bg-white border-r border-slate-200 flex flex-col transform -translate-x-full md:translate-x-0 transition-transform duration-300 ease-in-out"
       data-sidebar-target="sidebar">
  <!-- Conteúdo da sidebar -->
</aside>
```

**Comportamento:**
- **Mobile**: Sidebar oculta por padrão, abre com overlay escuro
- **Desktop**: Sidebar sempre visível
- **Toggle**: Botão hamburger no topbar (mobile only)

### 4.3 Topbar com Menu Mobile

**O topbar inclui botão de menu mobile:**

```erb
<!-- app/views/admin/shared/_topbar.html.erb -->
<div class="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-6">
  <div class="flex items-center gap-4">
    <!-- Mobile Menu Toggle -->
    <button type="button"
            class="md:hidden p-2 rounded-md text-slate-700 hover:bg-slate-100"
            data-action="click->sidebar#toggle"
            aria-label="Toggle menu">
      <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
      </svg>
    </button>
    <!-- Resto do conteúdo -->
  </div>
</div>
```

### 4.4 Stimulus Controller Sidebar

**O controller já existe em `app/javascript/controllers/sidebar_controller.js`:**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]
  static values = { open: Boolean }

  connect() {
    this.openValue = false
    this.openValueChanged()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  openValueChanged() {
    if (this.hasSidebarTarget) {
      if (this.openValue) {
        this.sidebarTarget.classList.remove('-translate-x-full')
        document.body.style.overflow = 'hidden'
      } else {
        this.sidebarTarget.classList.add('-translate-x-full')
        document.body.style.overflow = ''
      }
    }

    if (this.hasOverlayTarget) {
      if (this.openValue) {
        this.overlayTarget.classList.remove('hidden')
      } else {
        this.overlayTarget.classList.add('hidden')
      }
    }
  }
}
```

### 4.5 Padrões de Responsividade

**Sempre usar classes Tailwind responsivas:**

```erb
<!-- Grid responsivo -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- Itens -->
</div>

<!-- Espaçamento responsivo -->
<div class="p-4 md:p-6 lg:p-8">
  <!-- Conteúdo -->
</div>

<!-- Texto responsivo -->
<h1 class="text-xl md:text-2xl lg:text-3xl">Título</h1>
```

---

## 5. Componentes de UI

### 5.1 Botões

**Usar o componente existente `_button.html.erb`:**

#### Primary Button (Verde)
```erb
<%= render 'shared/ui/button',
    text: "Salvar produto",
    variant: :primary,
    size: :lg,
    type: :submit,
    form: f %>
```

**Para customizar a cor verde do Vendi**, adicionar CSS específico:

```css
/* Em components.css ou arquivo específico do Vendi */
.vendi .btn-primary {
  background-color: var(--color-primary) !important;
  border-color: var(--color-primary) !important;
}

.vendi .btn-primary:hover:not(:disabled) {
  background-color: var(--color-primary-dark) !important;
  border-color: var(--color-primary-dark) !important;
}
```

#### Outline Button (Verde)
```erb
<%= render 'shared/ui/button',
    text: "Editar produto",
    variant: :secondary,
    size: :md %>
```

#### Icon Button / FAB
```erb
<%= render 'shared/ui/button',
    text: "",
    variant: :primary,
    size: :lg,
    href: new_vendi_sale_path,
    class: "fixed bottom-6 right-6 w-16 h-16 rounded-full shadow-xl" do %>
  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
  </svg>
<% end %>
```

### 5.2 Cards

**Usar o componente existente `_card.html.erb`:**

```erb
<%= render 'shared/ui/card', class: "mb-4" do %>
  <div class="flex items-center gap-4">
    <div class="w-20 h-20 rounded-xl bg-slate-100 shrink-0"></div>
    <div class="flex-1">
      <%= render 'shared/ui/heading', text: "Nome do Produto", size: :md %>
      <p class="text-sm text-slate-500">Variações: 4</p>
      <%= render 'shared/ui/badge', text: "EM ESTOQUE", variant: :success %>
    </div>
  </div>
<% end %>
```

**Card de Produto específico:**

Criar partial `app/views/vendi/shared/_product_card.html.erb`:

```erb
<% if false %>
  Product Card component for Vendi Gestão
  Usage:
    <%= render 'vendi/shared/product_card', product: @product %>
<% end %>

<%= render 'shared/ui/card', class: "mb-3 hover:shadow-md transition-shadow cursor-pointer" do %>
  <div class="flex items-center gap-4">
    <div class="w-20 h-20 rounded-xl bg-slate-100 shrink-0 overflow-hidden">
      <% if product.image.present? %>
        <%= image_tag product.image, alt: product.name, class: "w-full h-full object-cover" %>
      <% else %>
        <div class="w-full h-full flex items-center justify-center">
          <svg class="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
          </svg>
        </div>
      <% end %>
    </div>

    <div class="flex-1 min-w-0">
      <%= render 'shared/ui/heading', text: product.name, size: :md, class: "truncate" %>
      <p class="text-sm text-slate-500 mb-2">Variações: <%= product.variants.count %></p>
      <%= render 'shared/ui/badge', text: stock_status_label(product), variant: stock_status_variant(product) %>
    </div>

    <%= link_to vendi_product_path(product), class: "shrink-0 text-slate-400 hover:text-slate-600" do %>
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
      </svg>
    <% end %>
  </div>
<% end %>
```

**Helper para status de estoque:**
```ruby
# app/helpers/vendi_helper.rb
module VendiHelper
  def stock_status_variant(product)
    total_stock = product.total_stock
    return :error if total_stock <= 0
    return :warning if total_stock <= 3
    :success
  end

  def stock_status_label(product)
    total_stock = product.total_stock
    return "SEM ESTOQUE" if total_stock <= 0
    return "BAIXO (#{total_stock})" if total_stock <= 3
    "EM ESTOQUE"
  end
end
```

### 5.3 Inputs

**Usar componentes existentes:**

#### Text Input (com form)
```erb
<%= render 'shared/ui/form_input',
    form: f,
    field: :name,
    label: "Nome do Produto",
    type: :text,
    required: true,
    placeholder: "Ex: Vestido Floral" %>
```

#### Search Input
```erb
<div class="relative mb-5">
  <div class="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400">
    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
    </svg>
  </div>
  <%= render 'shared/ui/form_input',
      form: f,
      field: :search,
      type: :text,
      placeholder: "Buscar por nome...",
      class: "pl-12 bg-slate-100 border-0" %>
</div>
```

#### Number Input
```erb
<%= render 'shared/ui/form_input',
    form: f,
    field: :price,
    label: "Preço",
    type: :number,
    step: 0.01,
    placeholder: "79,90" %>
```

### 5.4 Stepper (Quantidade) - Stimulus Controller

**Criar Stimulus Controller: `app/javascript/controllers/vendi/stepper_controller.js`:**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["value", "input"]
  static values = {
    min: { type: Number, default: 0 },
    max: { type: Number, default: 999 },
    step: { type: Number, default: 1 }
  }

  connect() {
    if (this.hasInputTarget) {
      const currentValue = parseInt(this.inputTarget.value) || this.minValue
      this.update(currentValue)
    }
  }

  increment() {
    const current = this.currentValue()
    const next = Math.min(current + this.stepValue, this.maxValue)
    this.update(next)
  }

  decrement() {
    const current = this.currentValue()
    const next = Math.max(current - this.stepValue, this.minValue)
    this.update(next)
  }

  currentValue() {
    if (this.hasInputTarget) {
      return parseInt(this.inputTarget.value) || this.minValue
    }
    return parseInt(this.valueTarget.textContent) || this.minValue
  }

  update(value) {
    if (this.hasValueTarget) {
      this.valueTarget.textContent = value
    }
    if (this.hasInputTarget) {
      this.inputTarget.value = value
      this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }
  }
}
```

**Partial para Stepper: `app/views/vendi/shared/_stepper.html.erb`:**

```erb
<% if false %>
  Stepper component for quantity selection
  Usage:
    <%= render 'vendi/shared/stepper',
        form: f,
        field: :quantity,
        value: 1,
        min: 0,
        max: 999 %>
<% end %>

<%
  form = local_assigns[:form]
  field = local_assigns[:field]
  initial_value = local_assigns[:value] || 1
  min = local_assigns[:min] || 0
  max = local_assigns[:max] || 999
  step = local_assigns[:step] || 1

  input_id = form ? "#{form.object_name}_#{field}" : "stepper_#{field}"
%>

<div data-controller="vendi--stepper"
     data-vendi--stepper-min-value="<%= min %>"
     data-vendi--stepper-max-value="<%= max %>"
     data-vendi--stepper-step-value="<%= step %>"
     class="inline-flex items-center gap-4 bg-slate-50 px-4 py-2 rounded-full">
  <button type="button"
          data-action="click->vendi--stepper#decrement"
          class="w-8 h-8 rounded-full border-0 bg-transparent text-primary text-xl font-semibold flex items-center justify-center hover:bg-primary-soft transition-colors">
    −
  </button>

  <% if form %>
    <%= form.hidden_field field,
        value: initial_value,
        data: { "vendi--stepper-target": "input" } %>
  <% else %>
    <%= hidden_field_tag field, initial_value,
        id: input_id,
        data: { "vendi--stepper-target": "input" } %>
  <% end %>

  <span data-vendi--stepper-target="value"
        class="text-lg font-semibold text-slate-900 min-w-[40px] text-center">
    <%= initial_value %>
  </span>

  <button type="button"
          data-action="click->vendi--stepper#increment"
          class="w-8 h-8 rounded-full border-0 bg-transparent text-primary text-xl font-semibold flex items-center justify-center hover:bg-primary-soft transition-colors">
    +
  </button>
</div>
```

### 5.5 Badges e Status

**Usar componente existente `_badge.html.erb`:**

```erb
<!-- EM ESTOQUE -->
<%= render 'shared/ui/badge', text: "EM ESTOQUE", variant: :success %>

<!-- BAIXO -->
<%= render 'shared/ui/badge', text: "BAIXO (2)", variant: :warning %>

<!-- SEM ESTOQUE -->
<%= render 'shared/ui/badge', text: "SEM ESTOQUE", variant: :error %>

<!-- Badge de Pagamento (customizado) -->
<span class="inline-flex items-center px-3 py-1 rounded-md text-xs font-semibold uppercase bg-primary-light text-primary-dark">
  PIX
</span>
```

### 5.6 Alertas e Notificações

**Criar partial: `app/views/vendi/shared/_alert.html.erb`:**

```erb
<% if false %>
  Alert component for Vendi Gestão
  Usage:
    <%= render 'vendi/shared/alert',
        variant: :warning,
        title: "Estoque baixo",
        description: "3 itens precisam de atenção" %>
<% end %>

<%
  variant = local_assigns[:variant] || :info
  title = local_assigns[:title]
  description = local_assigns[:description]
  dismissible = local_assigns[:dismissible] || false

  variant_classes = {
    warning: {
      bg: "bg-orange-50",
      border: "border-orange-200",
      icon_bg: "bg-orange-500",
      title_color: "text-slate-900",
      desc_color: "text-slate-600"
    },
    info: {
      bg: "bg-blue-50",
      border: "border-blue-200",
      icon_bg: "bg-blue-500",
      title_color: "text-slate-900",
      desc_color: "text-slate-600"
    },
    success: {
      bg: "bg-primary-soft",
      border: "border-primary-light",
      icon_bg: "bg-primary",
      title_color: "text-slate-900",
      desc_color: "text-slate-600"
    }
  }

  styles = variant_classes[variant] || variant_classes[:info]
%>

<div class="<%= styles[:bg] %> <%= styles[:border] %> border rounded-2xl p-5 flex items-center gap-3 mb-5">
  <div class="<%= styles[:icon_bg] %> w-12 h-12 rounded-xl flex items-center justify-center shrink-0">
    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
    </svg>
  </div>

  <div class="flex-1">
    <% if title.present? %>
      <%= render 'shared/ui/heading', text: title, size: :md, class: "mb-1" %>
    <% end %>
    <% if description.present? %>
      <p class="<%= styles[:desc_color] %> text-sm"><%= description %></p>
    <% end %>
  </div>

  <% if dismissible %>
    <button type="button"
            data-action="click->vendi--alert#dismiss"
            class="shrink-0 w-8 h-8 rounded-lg border-0 bg-transparent text-slate-400 hover:text-slate-600">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>
  <% end %>
</div>
```

**Tip Box (Dica):**

```erb
<div class="bg-vendi-mint-green rounded-2xl p-5 flex items-start gap-3 mb-5">
  <svg class="w-6 h-6 text-primary shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
  </svg>
  <div class="flex-1">
    <p class="text-sm font-semibold text-slate-700 mb-1">Dica</p>
    <p class="text-sm text-slate-600">Ative os alertas para ser notificado quando o estoque estiver baixo.</p>
  </div>
</div>
```

### 5.7 Filtros e Tabs (Alpine.js)

**Filter Pills com Alpine.js:**

```erb
<div x-data="{ activeFilter: 'all' }"
     class="flex gap-3 overflow-x-auto pb-2 mb-5">
  <button type="button"
          @click="activeFilter = 'all'"
          :class="activeFilter === 'all' ? 'bg-primary text-white shadow-md' : 'bg-white text-slate-600'"
          class="px-5 py-2.5 rounded-full border-0 text-sm font-medium whitespace-nowrap transition-all">
    Todos
  </button>
  <button type="button"
          @click="activeFilter = 'low'"
          :class="activeFilter === 'low' ? 'bg-primary text-white shadow-md' : 'bg-white text-slate-600'"
          class="px-5 py-2.5 rounded-full border-0 text-sm font-medium whitespace-nowrap transition-all">
    Estoque baixo
  </button>
  <button type="button"
          @click="activeFilter = 'popular'"
          :class="activeFilter === 'popular' ? 'bg-primary text-white shadow-md' : 'bg-white text-slate-600'"
          class="px-5 py-2.5 rounded-full border-0 text-sm font-medium whitespace-nowrap transition-all">
    Mais vendidos
  </button>
</div>
```

**Period Tabs:**

```erb
<div x-data="{ activePeriod: 'today' }"
     class="flex gap-2 mb-5">
  <button type="button"
          @click="activePeriod = 'today'"
          :class="activePeriod === 'today' ? 'bg-primary text-white' : 'bg-white text-slate-600'"
          class="px-5 py-2 rounded-full border-0 text-sm font-medium transition-all">
    Hoje
  </button>
  <button type="button"
          @click="activePeriod = 'week'"
          :class="activePeriod === 'week' ? 'bg-primary text-white' : 'bg-white text-slate-600'"
          class="px-5 py-2 rounded-full border-0 text-sm font-medium transition-all">
    7 dias
  </button>
  <button type="button"
          @click="activePeriod = 'month'"
          :class="activePeriod === 'month' ? 'bg-primary text-white' : 'bg-white text-slate-600'"
          class="px-5 py-2 rounded-full border-0 text-sm font-medium transition-all">
    Mês
  </button>
</div>
```

### 5.8 Size Selector (Alpine.js)

**Criar partial: `app/views/vendi/shared/_size_selector.html.erb`:**

```erb
<% if false %>
  Size Selector component
  Usage:
    <%= render 'vendi/shared/size_selector',
        form: f,
        field: :size,
        sizes: ["P", "M", "G", "2", "4", "6"],
        selected: @selected_size,
        disabled_sizes: @disabled_sizes %>
<% end %>

<%
  form = local_assigns[:form]
  field = local_assigns[:field]
  sizes = local_assigns[:sizes] || []
  selected = local_assigns[:selected]
  disabled_sizes = local_assigns[:disabled_sizes] || []
  model_name = form ? "#{form.object_name}.#{field}" : "selectedSize"
%>

<div x-data="{ selected: '<%= selected %>', disabled: <%= disabled_sizes.to_json %> }"
     class="flex gap-2 flex-wrap mt-3">
  <% sizes.each do |size| %>
    <% size_id = "#{field}_#{size}" %>
    <% is_disabled = disabled_sizes.include?(size) %>

    <% if form %>
      <%= form.radio_button field, size,
          checked: selected == size,
          disabled: is_disabled,
          id: size_id,
          class: "hidden",
          data: { "x-model": model_name } %>
    <% else %>
      <%= radio_button_tag field, size, selected == size,
          disabled: is_disabled,
          id: size_id,
          class: "hidden",
          data: { "x-model": model_name } %>
    <% end %>

    <label for="<%= size_id %>"
           :class="selected === '<%= size %>' ? 'border-primary bg-primary text-white' : 'border-slate-200 bg-white text-slate-700 hover:border-primary hover:bg-primary-soft'"
           :class="{ 'opacity-30 cursor-not-allowed': <%= is_disabled %> }"
           class="w-12 h-12 rounded-xl border-2 flex items-center justify-center text-base font-semibold cursor-pointer transition-all">
      <%= size %>
    </label>
  <% end %>
</div>
```

### 5.9 Toggle Switch (Alpine.js)

**Criar partial: `app/views/vendi/shared/_toggle.html.erb`:**

```erb
<% if false %>
  Toggle Switch component
  Usage:
    <%= render 'vendi/shared/toggle',
        form: f,
        field: :enable_alerts,
        label: "Ativar alertas de estoque baixo" %>
<% end %>

<%
  form = local_assigns[:form]
  field = local_assigns[:field]
  label = local_assigns[:label]
  checked = local_assigns[:checked] || false
  toggle_id = form ? "#{form.object_name}_#{field}" : "toggle_#{field}"
%>

<div class="flex items-center justify-between">
  <% if label.present? %>
    <label for="<%= toggle_id %>" class="text-sm font-medium text-slate-900">
      <%= label %>
    </label>
  <% end %>

  <div x-data="{ checked: <%= checked %> }"
       class="relative inline-flex h-8 w-13 cursor-pointer rounded-full transition-colors"
       :class="checked ? 'bg-primary' : 'bg-slate-200'"
       @click="checked = !checked">
    <% if form %>
      <%= form.check_box field,
          { checked: checked, id: toggle_id, class: "hidden" },
          "1",
          "0",
          data: { "x-model": "checked" } %>
    <% else %>
      <%= check_box_tag field, "1", checked,
          id: toggle_id,
          class: "hidden",
          data: { "x-model": "checked" } %>
    <% end %>

    <span class="inline-block h-6 w-6 transform rounded-full bg-white shadow-md transition-transform translate-x-1 translate-y-1"
          :class="checked ? 'translate-x-5' : 'translate-x-1'"></span>
  </div>
</div>
```

### 5.10 Progress Bar

```erb
<div class="w-full h-2 bg-slate-200 rounded-full overflow-hidden mb-3">
  <div class="h-full bg-primary rounded-full transition-all duration-300"
       style="width: <%= percentage %>%"></div>
</div>
```

### 5.11 Slider (Meta Diária) - Stimulus Controller

**Criar Stimulus Controller: `app/javascript/controllers/vendi/slider_controller.js`:**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "thumb", "value", "input"]
  static values = {
    min: { type: Number, default: 0 },
    max: { type: Number, default: 1000 },
    step: { type: Number, default: 50 },
    current: { type: Number, default: 500 }
  }

  connect() {
    this.boundHandleMove = this.handleMove.bind(this)
    this.boundHandleUp = this.handleUp.bind(this)
    this.updatePosition()
    this.updateValue()
  }

  mousedown(event) {
    event.preventDefault()
    this.isDragging = true
    this.handleMove(event)
    document.addEventListener('mousemove', this.boundHandleMove)
    document.addEventListener('mouseup', this.boundHandleUp)
  }

  handleMove(event) {
    if (!this.isDragging) return

    const rect = this.trackTarget.getBoundingClientRect()
    const x = event.clientX - rect.left
    const percentage = Math.max(0, Math.min(100, (x / rect.width) * 100))
    const value = Math.round((percentage / 100) * (this.maxValue - this.minValue) + this.minValue)
    const steppedValue = Math.round(value / this.stepValue) * this.stepValue

    this.currentValue = Math.max(this.minValue, Math.min(this.maxValue, steppedValue))
    this.updatePosition()
    this.updateValue()
  }

  handleUp() {
    this.isDragging = false
    document.removeEventListener('mousemove', this.boundHandleMove)
    document.removeEventListener('mouseup', this.boundHandleUp)
  }

  updatePosition() {
    const percentage = ((this.currentValue - this.minValue) / (this.maxValue - this.minValue)) * 100
    this.thumbTarget.style.left = `${percentage}%`
  }

  updateValue() {
    if (this.hasValueTarget) {
      this.valueTarget.textContent = this.formatValue(this.currentValue)
    }
    if (this.hasInputTarget) {
      this.inputTarget.value = this.currentValue
      this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }
  }

  formatValue(value) {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(value)
  }
}
```

**Partial para Slider: `app/views/vendi/shared/_slider.html.erb`:**

```erb
<% if false %>
  Slider component for daily goal
  Usage:
    <%= render 'vendi/shared/slider',
        form: f,
        field: :daily_goal,
        value: 1500,
        min: 0,
        max: 5000,
        step: 50 %>
<% end %>

<%
  form = local_assigns[:form]
  field = local_assigns[:field]
  value = local_assigns[:value] || 500
  min = local_assigns[:min] || 0
  max = local_assigns[:max] || 1000
  step = local_assigns[:step] || 50
  label = local_assigns[:label] || "Meta diária"

  slider_id = form ? "#{form.object_name}_#{field}" : "slider_#{field}"
%>

<div class="bg-primary rounded-2xl p-6 mb-5">
  <div class="flex items-center gap-2 mb-1">
    <span class="text-sm font-medium text-white"><%= label %></span>
  </div>

  <div data-controller="vendi--slider"
       data-vendi--slider-min-value="<%= min %>"
       data-vendi--slider-max-value="<%= max %>"
       data-vendi--slider-step-value="<%= step %>"
       data-vendi--slider-current-value="<%= value %>"
       class="mb-2">

    <% if form %>
      <%= form.hidden_field field,
          value: value,
          data: { "vendi--slider-target": "input" } %>
    <% else %>
      <%= hidden_field_tag field, value,
          id: slider_id,
          data: { "vendi--slider-target": "input" } %>
    <% end %>

    <div class="text-3xl font-bold text-white mb-4"
         data-vendi--slider-target="value">
      R$ <%= number_with_precision(value, precision: 2, delimiter: '.', separator: ',') %>
    </div>

    <div class="relative h-2 bg-white/30 rounded-full mb-2"
         data-vendi--slider-target="track"
         data-action="mousedown->vendi--slider#mousedown">
      <div class="absolute w-5 h-5 bg-white rounded-full shadow-md -top-1.5 cursor-grab"
           style="left: <%= ((value - min) / (max - min) * 100) %>%"
           data-vendi--slider-target="thumb"></div>
    </div>

    <div class="flex justify-between text-xs font-medium text-white/80 uppercase">
      <span>R$ <%= number_with_precision(min, precision: 0) %></span>
      <span>R$ <%= number_with_precision(max, precision: 0) %></span>
    </div>
  </div>
</div>
```

---

## 6. Ícones e Ilustrações

### 6.1 Sistema de Ícones

Usar SVG inline ou biblioteca de ícones. Exemplo com SVG Heroicons:

```erb
<!-- Ícone de busca -->
<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
</svg>

<!-- Ícone de adicionar -->
<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
</svg>
```

### 6.2 Empty States

**Usar componente existente `_empty_card.html.erb`:**

```erb
<%= render 'shared/ui/empty_card',
    title: "Sua vitrine está vazia",
    description: "Cadastre seu primeiro produto para começar a vender agora mesmo.",
    cta_text: "Cadastrar meu primeiro produto",
    cta_path: new_vendi_product_path %>
```

---

## 7. Layout e Espaçamento

### 7.1 Container e Espaçamento

**Usar classes Tailwind e componentes existentes:**

```erb
<!-- Container -->
<div class="container mx-auto px-5">
  <!-- Conteúdo -->
</div>

<!-- Espaçamento entre seções -->
<div class="mb-6">
  <!-- Seção -->
</div>
```

### 7.2 Grid System

```erb
<!-- Grid 2 colunas -->
<div class="grid grid-cols-2 gap-4">
  <!-- Itens -->
</div>

<!-- Grid responsivo -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- Itens -->
</div>
```

---

## 8. Telas do App - Exemplos de Implementação

### 8.1 Tela de Boas-Vindas

```erb
<div class="min-h-screen flex flex-col items-center justify-center px-5 bg-slate-50">
  <!-- Logo -->
  <div class="w-24 h-24 rounded-full bg-primary flex items-center justify-center mb-6">
    <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
    </svg>
  </div>

  <!-- Título -->
  <%= render 'shared/ui/heading',
      text: "Bem-vindo ao Vendi Gestão",
      size: :xl,
      description: "Registre sua primeira venda em menos de 3 minutos.",
      class: "text-center mb-8" %>

  <!-- Cards de ação -->
  <div class="w-full max-w-md space-y-4 mb-8">
    <%= render 'shared/ui/card', class: "cursor-pointer hover:shadow-md transition-shadow" do %>
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-primary-light flex items-center justify-center">
          <svg class="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
        </div>
        <div>
          <%= render 'shared/ui/heading', text: "Registrar primeira venda", size: :md %>
        </div>
      </div>
    <% end %>
  </div>

  <!-- Botão principal -->
  <%= render 'shared/ui/button',
      text: "Começar",
      variant: :primary,
      size: :lg,
      href: vendi_setup_path,
      class: "w-full max-w-md" %>

  <p class="text-xs text-slate-500 mt-6 text-center">Feito para lojas pequenas. Simples e rápido.</p>
</div>
```

### 8.2 Dashboard (Hoje)

```erb
<div class="container mx-auto px-5 py-6">
  <!-- Header -->
  <div class="mb-6">
    <div class="flex items-center justify-between mb-2">
      <div>
        <%= render 'shared/ui/heading',
            text: "Bom dia, #{@store.name} 👋",
            size: :xl,
            description: l(Date.current, format: :short) %>
      </div>
      <button class="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center">
        <svg class="w-5 h-5 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </button>
    </div>
    <%= render 'shared/ui/badge', text: "META DIÁRIA: #{price_display(@daily_goal)}", variant: :success %>
  </div>

  <!-- Vendas Hoje -->
  <%= render 'shared/ui/card', class: "mb-5" do %>
    <div class="text-center py-8">
      <p class="text-4xl font-bold" style="color: var(--color-primary);">
        <%= price_display(@today_sales, size: :large) %>
      </p>
      <p class="text-sm text-slate-500 mt-2">
        <%= @today_sales_count %> vendas • Ticket médio: <%= price_display(@avg_ticket) %>
      </p>
    </div>
  <% end %>

  <!-- Alerta de Estoque -->
  <% if @low_stock_items.any? %>
    <%= render 'vendi/shared/alert',
        variant: :warning,
        title: "Estoque baixo",
        description: "#{@low_stock_items.count} itens precisam de atenção" %>
  <% end %>

  <!-- Empty State ou Lista -->
  <% if @today_sales.empty? %>
    <%= render 'shared/ui/empty_card',
        title: "Pronto para começar?",
        description: "Registre sua primeira venda e acompanhe seu dia aqui.",
        cta_text: "Registrar venda agora",
        cta_path: new_vendi_sale_path %>
  <% end %>
</div>

<!-- FAB -->
<%= render 'shared/ui/button',
    text: "",
    variant: :primary,
    size: :lg,
    href: new_vendi_sale_path,
    class: "fixed bottom-20 right-6 w-16 h-16 rounded-full shadow-xl" do %>
  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
  </svg>
<% end %>
```

---

## 9. Fluxos e Interações - Turbo Streams

### 9.1 Formulários com Turbo Streams

**Controller:**
```ruby
def create
  @product = Vendi::Product.new(product_params)

  if @product.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to vendi_products_path, notice: "Produto criado com sucesso!" }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

**View: `create.turbo_stream.erb`:**
```erb
<%= turbo_stream.append "products_list", partial: "vendi/products/product_card", locals: { product: @product } %>
<%= turbo_stream.replace "new_product_form", partial: "vendi/products/form" %>
<%= turbo_stream.append "toast-container" do %>
  <%= render 'shared/ui/toast', type: :success, message: "Produto criado com sucesso!" %>
<% end %>
```

**Form com Turbo:**
```erb
<%= form_with model: @product,
    url: vendi_products_path,
    local: false,
    data: { turbo_frame: "_top" } do |f| %>
  <!-- Campos do formulário -->
  <%= render 'shared/ui/form_input', form: f, field: :name, label: "Nome" %>

  <%= render 'shared/ui/button', text: "Salvar", type: :submit, variant: :primary, form: f %>
<% end %>
```

---

## 10. Stimulus Controllers Adicionais

### 10.1 Alert Dismiss Controller

**`app/javascript/controllers/vendi/alert_controller.js`:**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    this.element.style.transition = "opacity 0.3s ease"
    this.element.style.opacity = "0"
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
```

---

## 11. Helpers Úteis

### 11.1 Helper para Formatação

**`app/helpers/vendi_helper.rb`:**

```ruby
module VendiHelper
  def price_display(amount, size: :regular)
    return "—" if amount.nil?

    size_classes = {
      large: "text-3xl font-bold",
      regular: "text-lg font-bold",
      small: "text-sm font-semibold"
    }

    content_tag :span,
      number_to_currency(amount, unit: "R$ ", separator: ",", delimiter: "."),
      class: size_classes[size],
      style: "color: var(--color-primary);"
  end

  def stock_status_variant(product)
    total_stock = product.total_stock
    return :error if total_stock <= 0
    return :warning if total_stock <= 3
    :success
  end

  def stock_status_label(product)
    total_stock = product.total_stock
    return "SEM ESTOQUE" if total_stock <= 0
    return "BAIXO (#{total_stock})" if total_stock <= 3
    "EM ESTOQUE"
  end
end
```

---

## 12. Checklist de Implementação

### Fase 1 - Fundação
- [ ] Adicionar cores do Vendi Gestão em `colors.css`
- [ ] Criar namespace `Vendi::` para models/controllers
- [ ] Configurar rotas do Vendi Gestão
- [ ] Criar layout específico baseado em `admin.html.erb` (se necessário)
- [ ] Configurar sistema de toasts (já existe no layout)

### Fase 2 - Componentes Básicos
- [ ] Criar partials específicos do Vendi:
  - [ ] `_product_card.html.erb`
  - [ ] `_stepper.html.erb`
  - [ ] `_alert.html.erb`
  - [ ] `_size_selector.html.erb`
  - [ ] `_toggle.html.erb`
  - [ ] `_slider.html.erb`
- [ ] Criar Stimulus controllers:
  - [ ] `vendi/stepper_controller.js`
  - [ ] `vendi/slider_controller.js`
  - [ ] `vendi/alert_controller.js`

### Fase 3 - Helpers
- [ ] Criar `VendiHelper` com helpers específicos
- [ ] Implementar `price_display`
- [ ] Implementar helpers de status de estoque

### Fase 4 - Telas
- [ ] Tela de Boas-vindas
- [ ] Setup (2 passos)
- [ ] Dashboard (Hoje)
- [ ] Lista de Produtos
- [ ] Cadastro de Produto
- [ ] Detalhe do Produto
- [ ] Lista de Vendas
- [ ] Nova Venda (3 passos)
- [ ] Relatórios

### Fase 5 - Interações
- [ ] Configurar Turbo Streams para todas as ações
- [ ] Implementar validações de formulário
- [ ] Adicionar toasts em todas as ações (substituir flash messages)
- [ ] Loading states

### Fase 6 - Polimento
- [ ] Responsividade mobile (sidebar já implementada)
- [ ] Acessibilidade (ARIA labels)
- [ ] Performance (lazy loading de imagens)
- [ ] Testes

---

## 13. Notas Importantes

### 13.1 Princípios do Projeto

- **Sempre usar componentes reutilizáveis**: Partials em `app/views/shared/ui/`
- **Nunca escrever HTML/CSS direto**: Sempre usar componentes ou classes Tailwind
- **Sempre usar componente heading**: Nunca escrever `<h1>`, `<h2>`, `<h3>` diretamente
- **Sempre usar toasts**: Nunca usar flash messages - sempre toasts
- **Responsividade total**: Sidebar mobile já implementada - seguir padrão
- **Turbo Streams**: Sempre preferir Turbo Streams para atualizações de UI
- **Alpine.js**: Usar para interatividade simples (tabs, filters, toggles)
- **Stimulus**: Usar para lógica mais complexa (steppers, sliders)
- **Seguir padrões Rails**: Services, Presenters, Policies conforme `.cursorrules`

### 13.2 Convenções de Nomenclatura

- Partials do Vendi: `app/views/vendi/shared/_*.html.erb`
- Stimulus controllers: `app/javascript/controllers/vendi/*_controller.js`
- Helpers: `app/helpers/vendi_helper.rb`
- Models: `app/models/vendi/*.rb`
- Controllers: `app/controllers/vendi/*.rb`

### 13.3 Regras Obrigatórias

1. **⚠️ NUNCA escrever tags de título diretamente** - Sempre usar `render 'shared/ui/heading'`
2. **⚠️ NUNCA usar flash messages** - Sempre usar toasts via `render 'shared/ui/toast'` ou `flash` (que é convertido automaticamente)
3. **⚠️ SEMPRE considerar responsividade mobile** - Sidebar já implementada, seguir padrão
4. **⚠️ SEMPRE usar componentes reutilizáveis** - Nunca duplicar código de UI

---

**FIM DO DOCUMENTO**

Este Design System foi adaptado para seguir os padrões do projeto **nucleo_api**, utilizando os mesmos componentes reutilizáveis, Tailwind CSS, Alpine.js, Stimulus, Hotwire Turbo, sistema de toasts e navegação mobile responsiva.
