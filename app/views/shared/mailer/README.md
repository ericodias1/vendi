# Componentes de Email - Guia de Desenvolvimento

## 📋 Visão Geral

Esta pasta (`app/views/shared/mailer/`) contém componentes reutilizáveis para construção de **emails transacionais** do Vendi Gestão. Todos os emails devem usar estes componentes para garantir consistência visual e facilitar manutenção.

## 🎯 Princípios Fundamentais

1. **Sempre use componentes**: Nunca escreva HTML inline para emails. Use os componentes de `shared/mailer/`
2. **Estilos inline obrigatórios**: Todos os componentes usam estilos inline para compatibilidade com clientes de email
3. **Consistência visual**: Todos os emails seguem o mesmo padrão visual (header, conteúdo, footer, bottom bar)
4. **Material Symbols**: Use ícones Material Symbols para ilustrações e elementos visuais
5. **Layout responsivo**: Os componentes são responsivos e funcionam bem em mobile

## 📁 Como Descobrir Componentes Disponíveis

Para ver todos os componentes disponíveis e seus parâmetros:

1. **Liste os arquivos na pasta**:
   ```bash
   ls app/views/shared/mailer/
   ```

2. **Abra o arquivo do componente**: Cada componente tem comentários no topo explicando:
   - Como usar
   - Quais parâmetros aceita
   - Exemplos de uso

3. **Veja exemplos existentes**: Consulte `app/views/password_reset_mailer/reset_password.html.erb` para ver um exemplo completo

## 🏗️ Estrutura Padrão de um Email

Todos os emails seguem esta estrutura:

```erb
<%= render 'shared/mailer/container' do %>
  <!-- Header com logo -->
  <%= render 'shared/mailer/header', icon: "nome_do_icone" %>
  
  <!-- Conteúdo principal -->
  <%= render 'shared/mailer/content_wrapper' do %>
    <!-- Ícone ilustrativo (opcional) -->
    <%= render 'shared/mailer/icon_circle', icon: "nome_do_icone" %>
    
    <!-- Título -->
    <%= render 'shared/mailer/heading', text: "Título do Email" %>
    
    <!-- Texto do corpo -->
    <%= render 'shared/mailer/body_text' do %>
      Conteúdo do email com <strong>HTML</strong> se necessário.
    <% end %>
    
    <!-- Botão de ação (CTA) -->
    <%= render 'shared/mailer/button', text: "Ação", url: @url %>
    
    <!-- Divisor (opcional) -->
    <%= render 'shared/mailer/divider' %>
    
    <!-- Rodapé com disclaimer -->
    <%= render 'shared/mailer/footer', 
        disclaimer: "Texto do disclaimer",
        support_link: "Precisa de ajuda? Fale conosco." %>
  <% end %>
  
  <!-- Barra decorativa inferior -->
  <%= render 'shared/mailer/bottom_bar' %>
<% end %>
```

## 🔍 Como Usar um Componente

1. **Abra o arquivo do componente** (ex: `_button.html.erb`)
2. **Leia os comentários no topo** - eles explicam:
   - Como usar
   - Parâmetros disponíveis
   - Exemplos
3. **Use o componente** seguindo o padrão:
   ```erb
   <%= render 'shared/mailer/nome_do_componente', param1: valor1, param2: valor2 %>
   ```

## 📝 Criando um Novo Email

### Passo 1: Criar o Mailer

```ruby
# app/mailers/example_mailer.rb
class ExampleMailer < ApplicationMailer
  def welcome(user)
    @user = user
    @url = dashboard_url
    
    mail(
      to: user.email,
      subject: "Bem-vindo ao Vendi Gestão"
    )
  end
end
```

### Passo 2: Criar a View

```erb
# app/views/example_mailer/welcome.html.erb
<%= render 'shared/mailer/container' do %>
  <%= render 'shared/mailer/header', icon: "welcome" %>
  
  <%= render 'shared/mailer/content_wrapper' do %>
    <%= render 'shared/mailer/icon_circle', icon: "celebration" %>
    <%= render 'shared/mailer/heading', text: "Bem-vindo!" %>
    
    <%= render 'shared/mailer/body_text' do %>
      Olá <%= @user.name %>! Sua conta foi criada com sucesso.
    <% end %>
    
    <%= render 'shared/mailer/button', text: "Acessar Dashboard", url: @url %>
    <%= render 'shared/mailer/divider' %>
    <%= render 'shared/mailer/footer', disclaimer: "Este é um email automático." %>
  <% end %>
  
  <%= render 'shared/mailer/bottom_bar' %>
<% end %>
```

### Passo 3: Enviar o Email

```ruby
ExampleMailer.welcome(user).deliver_now
```

## 🎨 Cores e Design System

Os componentes usam automaticamente as cores do design system definidas em `app/javascript/stylesheets/colors.css`:

- **Primary**: `#10b981` (verde)
- **Background Light**: `#f8fafc` (fundo do email)
- **Text Primary**: `#0d1c0d` (texto escuro)
- **Text Secondary**: `rgba(13, 28, 13, 0.7)` (texto secundário)

**Não é necessário** especificar cores manualmente - os componentes já usam as cores corretas.

## ⚠️ Regras Importantes

1. **Nunca use CSS externo**: Todos os estilos são inline para compatibilidade
2. **Sempre use Material Symbols**: Para ícones, use Material Symbols (já incluído no layout)
3. **Mantenha a estrutura padrão**: Container → Header → Content Wrapper → Bottom Bar
4. **Use componentes, não HTML direto**: Sempre prefira componentes ao invés de HTML customizado
5. **Teste em diferentes clientes**: Gmail, Outlook, Apple Mail, etc.

## 🔗 Componentes Relacionados

- **Layout de email**: `app/views/layouts/mailer.html.erb` - Define o layout base
- **Componentes de UI**: `app/views/shared/ui/` - Para views web (não use em emails)
- **Componentes de Auth**: `app/views/shared/auth/` - Para telas de autenticação

## 📚 Exemplo Completo de Referência

Consulte `app/views/password_reset_mailer/reset_password.html.erb` para ver um exemplo completo seguindo todos os padrões.

## 🆘 Dúvidas?

1. **Verifique o componente**: Abra o arquivo do componente e leia os comentários
2. **Veja exemplos existentes**: Consulte emails já implementados
3. **Siga o padrão**: Use a estrutura padrão mostrada acima

---

**Lembre-se**: Os componentes estão documentados em seus próprios arquivos. Sempre consulte o arquivo do componente para ver parâmetros e exemplos específicos.
