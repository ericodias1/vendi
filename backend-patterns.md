# Padrões de Implementação de Backend - Núcleo App

## Sumário Executivo

Este documento define todos os padrões de implementação de backend para o projeto **Núcleo App**. Os padrões seguem princípios de simplicidade, manutenibilidade e uso de convenções Rails sempre que possível.

**Princípios Fundamentais:**
1. **CRUD primeiro**: Preferir ações CRUD padrão ao invés de actions customizadas
2. **Services apenas quando necessário**: Usar services apenas quando a lógica ficar complexa
3. **Validações no model**: Sempre validar no model, nunca nos services
4. **Form Objects para formulários complexos**: Usar Form Objects quando precisar validar múltiplos models ou campos que não pertencem a um único model
5. **Resources com only/except**: Usar `resources` com `only:` ou `except:` para limitar ações
6. **Multi-Account First**: Tudo deve considerar isolamento por account
7. **Pundit para autorização**: Todas as ações devem ser autorizadas
8. **Busca abstraída**: Usar concern `Searchable` para lógica de busca nos models
9. **Service base robusto**: Classe `Service` com métodos auxiliares para validações e tratamento de erros

---

## 1. Estrutura de Arquivos

### 1.1 Controllers

```
app/controllers/
  backoffice/
    base_controller.rb           # Base para controllers backoffice
    *_controller.rb              # Controllers específicos
  concerns/
    authentication.rb            # Concern para autenticação
```

### 1.2 Services

```
app/services/
  service.rb                     # Classe base para services (com métodos auxiliares)
  backoffice/
    */                           # Namespace do recurso
      *_service.rb               # Services específicos
```

### 1.3 Models

```
app/models/
  application_record.rb          # Base para todos os models
  *.rb                          # Models específicos
  concerns/
    searchable.rb                # Concern para busca
    *.rb                        # Outros concerns dos models
```

### 1.4 Policies

```
app/policies/
  application_policy.rb          # Base para todas as policies
  backoffice_policy.rb          # Policy única para backoffice
```

### 1.5 Form Objects

```
app/forms/
  *_form.rb                      # Form objects para validações complexas
```

---

## 2. Controllers

### 2.1 Estrutura Básica

**Controllers devem herdar de `Backoffice::BaseController`:**

```ruby
# frozen_string_literal: true

module Backoffice
  class ResourceNameController < BaseController
    before_action :set_resource, only: [:show, :edit, :update, :destroy]

    def index
      @resources = current_account.resources.order(created_at: :desc)
    end

    def show
    end

    def new
      @resource = current_account.resources.build
    end

    def create
      @resource = current_account.resources.build(resource_params)

      if @resource.save
        redirect_to backoffice_resources_path, notice: "Recurso criado com sucesso"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @resource.update(resource_params)
        redirect_to backoffice_resources_path, notice: "Recurso atualizado com sucesso"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @resource.destroy
      redirect_to backoffice_resources_path, notice: "Recurso excluído com sucesso"
    end

    private

    def set_resource
      @resource = ResourceName.find(params[:id])
    end

    def resource_params
      params.require(:resource_name).permit(:field1, :field2, :field3)
    end
  end
end
```

### 2.2 Padrões Importantes

**1. Sempre usar `current_account` (método) para filtrar recursos:**

```ruby
# ✅ Correto
@resources = current_account.resources.order(created_at: :desc)

# ❌ Errado
@resources = Resource.all
@resources = @current_account.resources  # Não usar variável de instância
```

**2. Sempre criar recursos associados ao account:**

```ruby
# ✅ Correto
@resource = current_account.resources.build(resource_params)

# ❌ Errado
@resource = Resource.new(resource_params)
@resource.account = current_account
```

**3. Sempre usar `before_action` para setar recursos:**

```ruby
before_action :set_resource, only: [:show, :edit, :update, :destroy]

private

def set_resource
  @resource = ResourceName.find(params[:id])
end
```

**4. Sempre usar strong parameters:**

```ruby
def resource_params
  params.require(:resource_name).permit(:field1, :field2, :field3)
end
```

### 2.3 Busca e Filtros

**Para adicionar busca, usar o concern `Searchable` no model:**

```ruby
# No model
class Resource < ApplicationRecord
  include Searchable
  
  searchable_columns :name, :description, :email
end

# No controller
def index
  @resources = current_account.resources
                              .search(params[:search])
                              .order(created_at: :desc)
end
```

**O concern `Searchable` é implementado assim:**

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(term) {
      return all if term.blank?
      
      search_term = "%#{term}%"
      where(
        searchable_columns.map { |col| "#{table_name}.#{col} ILIKE ?" }.join(" OR "),
        *([search_term] * searchable_columns.count)
      )
    }
  end

  class_methods do
    attr_accessor :searchable_columns

    def searchable_columns(*columns)
      @searchable_columns = columns
    end
  end
end
```

### 2.4 Valores Padrão

**Sempre definir valores padrão no model usando `after_initialize`:**

```ruby
# ✅ Correto - No model
class Resource < ApplicationRecord
  after_initialize :set_defaults

  private

  def set_defaults
    if new_record?
      self.active ||= true
      self.status ||= 'pending'
    end
  end
end

# No controller
@resource = current_account.resources.build # active já será true

# ❌ Errado - No controller
@resource = current_account.resources.build(active: true)
```

### 2.5 Quando Usar Services

**Use services apenas quando:**
1. **Múltiplos models** precisam ser criados/atualizados em uma transação
2. **Lógica complexa** que não cabe no model (ex: envio de emails, integrações externas)
3. **Operações que precisam de múltiplos passos** em sequência

**Exemplo de quando usar service:**

```ruby
# Controller simples (sem service)
def create
  @announcement = current_account.announcements.build(announcement_params)
  
  if @announcement.save
    redirect_to backoffice_announcements_path, notice: "Comunicado criado com sucesso"
  else
    render :new, status: :unprocessable_entity
  end
end

# Controller complexo (com service)
def create
  service = Backoffice::Accounts::CreateService.new(
    account: current_account,
    current_user: current_backoffice_user,
    **account_params.to_h
  )
  
  if service.call
    redirect_to backoffice_accounts_path, notice: "Conta criada com sucesso"
  else
    @account = service.account
    @errors = service.errors
    render :new, status: :unprocessable_entity
  end
end
```

### 2.6 Autorização

**O `Backoffice::BaseController` já autoriza automaticamente:**

```ruby
# O BaseController faz isso automaticamente:
before_action :authorize_resource, if: -> { action_name != "index" }

# Para index, use policy_scope se necessário:
def index
  @resources = policy_scope(current_account.resources)
end
```

---

## 3. Services

### 3.1 Quando Criar um Service

**Crie um service quando:**
- Precisa criar/atualizar múltiplos models em uma transação
- Precisa executar lógica complexa (emails, integrações, cálculos)
- Precisa de múltiplos passos em sequência
- A lógica não faz sentido estar no model ou controller

**Não crie um service quando:**
- É apenas um CRUD simples
- A lógica cabe em um callback do model
- É apenas validação (vai no model)

### 3.2 Service Base - Métodos Auxiliares

**A classe `Service` base fornece métodos auxiliares para validações e tratamento de erros:**

```ruby
# frozen_string_literal: true

# Classe base para todos os services
# Fornece funcionalidades comuns:
# - ActiveModel::Model para integração com errors
# - Métodos auxiliares para validações comuns
# - Métodos auxiliares para tratamento de erros de models
# - Método helper para executar em transação com tratamento de erros
class Service
  include ActiveModel::Model
  attr_reader :errors

  def initialize(**kwargs)
    super(**kwargs) if defined?(super)
    @errors ||= ActiveModel::Errors.new(self)
  end

  private

  # Helper para executar código dentro de uma transação com tratamento de erros
  def execute_with_transaction
    ActiveRecord::Base.transaction do
      yield
    end
    true
  rescue StandardError => e
    errors.add(:base, e.message)
    false
  end

  # Validação: Verifica se um atributo está presente
  def validate_presence(attribute, value, message: nil)
    return true if value.present?
    
    error_message = message || "#{attribute} não pode ficar em branco"
    errors.add(attribute, error_message)
    false
  end

  # Validação: Verifica se um atributo está presente em uma lista de valores
  def validate_inclusion(attribute, value, in: [], message: nil)
    return true if value.in?(binding.local_variable_get(:in))
    
    error_message = message || "#{attribute} deve estar em #{binding.local_variable_get(:in).join(', ')}"
    errors.add(attribute, error_message)
    false
  end

  # Validação: Verifica se um objeto (model) é válido e adiciona seus erros
  def validate_model(model, context: nil)
    return true if model.valid?(context)

    model.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
    false
  end

  # Validação: Verifica se uma condição é verdadeira
  def validate_condition(condition, attribute: :base, message:)
    return true if condition

    errors.add(attribute, message)
    false
  end

  # Validação: Verifica se um objeto existe e está ativo (se tiver método active?)
  def validate_active(object, attribute: :base, message: nil)
    return true if object.blank? # Permite nil
    return true if object.respond_to?(:active?) && object.active?
    return true unless object.respond_to?(:active?)

    error_message = message || "#{object.class.name} não está ativo"
    errors.add(attribute, error_message)
    false
  end

  # Validação: Verifica se um usuário tem permissão para uma ação
  def validate_permission(user, action, resource, message: nil)
    return true if user.blank? # Deixa Pundit lidar com nil
    return true if BackofficePolicy.new(user, resource).public_send("#{action}?")

    error_message = message || "Você não tem permissão para #{action} este recurso"
    errors.add(:base, error_message)
    false
  end

  # Helper: Salva um model e adiciona erros ao service se falhar
  def save_model!(model, raise_on_error: false)
    if model.save
      true
    else
      model.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::Rollback if raise_on_error
      false
    end
  end

  # Helper: Atualiza um model e adiciona erros ao service se falhar
  def update_model!(model, attributes, raise_on_error: false)
    if model.update(attributes)
      true
    else
      model.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::Rollback if raise_on_error
      false
    end
  end

  # Helper: Cria um model e adiciona erros ao service se falhar
  def create_model!(association, attributes, raise_on_error: false)
    model = association.build(attributes)
    
    if model.save
      model
    else
      model.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::Rollback if raise_on_error
      nil
    end
  end

  # Helper: Destrói um model e adiciona erros ao service se falhar
  def destroy_model!(model, raise_on_error: false)
    if model.destroy
      true
    else
      errors.add(:base, "Não foi possível excluir o recurso")
      raise ActiveRecord::Rollback if raise_on_error
      false
    end
  end
end
```

### 3.3 Estrutura de um Service

**Todos os services devem herdar de `Service` e usar os métodos auxiliares:**

```ruby
# frozen_string_literal: true

module Backoffice
  module ResourceName
    class CreateService < Service
      attr_reader :resource, :account, :current_user

      def initialize(account:, current_user:, **params)
        super()
        @account = account
        @current_user = current_user
        @params = params
      end

      def call
        return false unless valid?

        execute_with_transaction do
          create_resource
          send_notification
          log_audit
        end
      end

      private

      def valid?
        validate_account
        validate_params
        validate_permissions
        errors.empty?
      end

      def validate_account
        validate_presence(:account, @account) &&
        validate_active(@account, attribute: :account, message: "Conta não está ativa")
      end

      def validate_params
        # Validações de negócio (não de dados - dados vão no model)
        validate_condition(
          !@account.archived?,
          attribute: :base,
          message: "Não é possível criar recursos em contas arquivadas"
        )
      end

      def validate_permissions
        # Exemplo de validação de permissão
        return true # Pundit já faz isso no controller
        
        # Se precisar validar aqui:
        # validate_permission(@current_user, :create, @account)
      end

      def create_resource
        @resource = create_model!(
          @account.resources,
          @params,
          raise_on_error: true
        )
        
        # Validações do model são tratadas automaticamente por create_model!
      end

      def send_notification
        # Lógica complexa (emails, etc)
      end

      def log_audit
        # Log de auditoria
      end
    end
  end
end
```

### 3.4 Validações em Services

**⚠️ IMPORTANTE: Validações de dados SEMPRE no model:**

```ruby
# ✅ Correto - Validações no model
class Resource < ApplicationRecord
  validates :name, presence: true
  validates :email, uniqueness: { scope: :account_id }
end

# No service, apenas validações de negócio/regras usando métodos auxiliares
def validate_params
  validate_condition(
    !@account.archived?,
    attribute: :base,
    message: "Não é possível criar recursos em contas arquivadas"
  )
end

# ❌ Errado - Validações de dados no service
def validate_params
  validate_presence(:name, @params[:name])  # Isso deve estar no model!
end
```

**Services devem apenas:**
- Validar condições de negócio usando `validate_condition`
- Validar permissões usando `validate_permission`
- Validar regras complexas que envolvem múltiplos models
- Validar objetos relacionados usando `validate_model` ou `validate_active`
- **NUNCA** validar dados simples (presence, format, etc) - isso vai no model

### 3.5 Tratamento de Erros de Models

**Use os métodos auxiliares para salvar/atualizar/criar models:**

```ruby
# ✅ Correto - Usar métodos auxiliares
def create_resource
  @resource = create_model!(
    @account.resources,
    @params,
    raise_on_error: true  # Levanta ActiveRecord::Rollback se falhar
  )
end

def update_resource
  update_model!(
    @resource,
    @params,
    raise_on_error: true
  )
end

def save_resource
  save_model!(@resource, raise_on_error: true)
end

# ❌ Evitar - Fazer manualmente
def create_resource
  @resource = @account.resources.build(@params)
  unless @resource.save
    @resource.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
    raise ActiveRecord::Rollback
  end
end
```

### 3.6 Uso do Service no Controller

```ruby
def create
  service = Backoffice::ResourceName::CreateService.new(
    account: current_account,
    current_user: current_backoffice_user,
    **resource_params.to_h
  )

  if service.call
    redirect_to backoffice_resources_path, notice: "Recurso criado com sucesso"
  else
    @resource = service.resource || current_account.resources.build(resource_params)
    @errors = service.errors
    render :new, status: :unprocessable_entity
  end
end
```

---

## 3.5 Form Objects

### 3.5.1 Quando Usar Form Objects

**Use Form Objects quando:**
- Precisa validar múltiplos models simultaneamente (ex: criar Account + User + AccountConfig)
- Campos do formulário não pertencem a um único model
- Precisa de validações customizadas que não fazem sentido nos models individuais
- Quer simplificar a lógica de validação no controller e service

**Não use Form Objects quando:**
- É apenas um CRUD simples de um único model
- As validações já estão bem definidas no model
- Não há necessidade de validar múltiplos models juntos

### 3.5.2 Estrutura de um Form Object

```ruby
# frozen_string_literal: true

class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Attributes
  attribute :account_name, :string
  attribute :whatsapp, :string
  attribute :name, :string
  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  # Validations
  validates :account_name, presence: true
  validates :whatsapp, presence: true
  validates :email, presence: true
  validates :password, presence: true, length: { minimum: 6 }
  validates :password_confirmation, presence: true
  validate :password_confirmation_matches

  # Accessors for models
  def account_attributes
    {
      name: account_name,
      whatsapp: whatsapp,
      active: true
    }
  end

  def user_attributes
    {
      name: name,
      email: email&.downcase&.strip,
      password: password,
      password_confirmation: password_confirmation,
      role: "owner"
    }
  end

  private

  def password_confirmation_matches
    return if password.blank? || password_confirmation.blank?

    unless password == password_confirmation
      errors.add(:password_confirmation, "não confere")
    end
  end
end
```

**Padrões Importantes:**
- ✅ Sempre usar `ActiveModel::Model` e `ActiveModel::Attributes`
- ✅ Validações no form object, não no service
- ✅ Métodos `*_attributes` para facilitar criação dos models
- ✅ Validações customizadas usando `validate :method_name`

### 3.5.3 Uso do Form Object no Controller

```ruby
# frozen_string_literal: true

class RegistrationsController < ApplicationController
  layout "auth"
  skip_before_action :authenticate_user!

  def new
    redirect_to backoffice_root_path if current_user
    @form = RegistrationForm.new
  end

  def create
    @form = RegistrationForm.new(registration_params)
    service = Backoffice::Accounts::CreateService.new(form: @form)
    
    if service.call
      session[:user_id] = service.user.id
      redirect_to backoffice_root_path, notice: "Conta criada com sucesso!"
    else
      # Adiciona erros do service ao form
      service.errors.each do |error|
        @form.errors.add(error.attribute, error.message) unless @form.errors[error.attribute].include?(error.message)
      end
      
      flash.now[:alert] = "Erro ao criar conta. Verifique os campos abaixo."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.permit(
      :account_name,
      :whatsapp,
      :name,
      :email,
      :password,
      :password_confirmation
    )
  end
end
```

**Padrões Importantes:**
- ✅ Controller cria o form object em `new` e `create`
- ✅ Usa `form_with model: @form` na view para integração automática
- ✅ Passa form object para o service ao invés de params brutos
- ✅ Adiciona erros do service ao form object para exibição

### 3.5.4 Uso do Form Object no Service

```ruby
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
```

**Padrões Importantes:**
- ✅ Service recebe o form object ao invés de params brutos
- ✅ Valida apenas se form é válido: `return false unless @form.valid?`
- ✅ Usa métodos `*_attributes` do form object para criar models
- ✅ Não faz validações de dados (isso é responsabilidade do form object)
- ✅ Foca apenas na criação dos models em transação

### 3.5.5 Uso do Form Object na View

```erb
<%= form_with model: @form, url: registration_path, method: :post, local: true, class: "space-y-4" do |f| %>
  <!-- Account Name Field -->
  <%= render 'shared/auth/label', text: "Nome da loja" %>
  <%= render 'shared/auth/input', 
      form: f, 
      field: :account_name, 
      type: :text, 
      placeholder: "Ex: Loja de Roupas Infantis" %>

  <!-- Email Field -->
  <%= render 'shared/auth/label', text: "E-mail" %>
  <%= render 'shared/auth/input', 
      form: f, 
      field: :email, 
      type: :email, 
      placeholder: "seu@email.com" %>

  <!-- Password Field -->
  <%= render 'shared/auth/label', text: "Senha" %>
  <%= render 'shared/auth/input', 
      form: f, 
      field: :password, 
      type: :password, 
      show_toggle: true,
      minlength: 6 %>

  <!-- Error Messages -->
  <%= render 'shared/auth/error_message', errors: @form.errors %>
  
  <!-- Submit Button -->
  <%= render 'shared/auth/button', text: "Criar conta", icon: "person_add" %>
<% end %>
```

**Padrões Importantes:**
- ✅ Usa `form_with model: @form` para integração automática
- ✅ Componentes de input detectam erros automaticamente via `form.object.errors`
- ✅ Erros são exibidos individualmente por campo e também em bloco
- ✅ Form object funciona como um model normal para o Rails

### 3.5.6 Benefícios dos Form Objects

1. **Separação de Responsabilidades**: Validações de formulário separadas dos models
2. **Simplificação do Service**: Service não precisa validar dados, apenas criar models
3. **Reutilização**: Form object pode ser usado em diferentes contextos
4. **Testabilidade**: Fácil testar validações isoladamente
5. **Manutenibilidade**: Lógica de validação centralizada em um único lugar

---

## 4. Models

### 4.1 Estrutura Básica

**Todos os models devem herdar de `ApplicationRecord`:**

```ruby
# frozen_string_literal: true

class ResourceName < ApplicationRecord
  belongs_to :account

  include Searchable
  searchable_columns :name, :description, :email

  # ⚠️ IMPORTANTE: Validações SEMPRE no model
  validates :name, presence: true
  validates :email, uniqueness: { scope: :account_id }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Valores padrão
  after_initialize :set_defaults

  private

  def set_defaults
    if new_record?
      self.active ||= true
      self.status ||= 'pending'
    end
  end
end
```

### 4.2 Concern Searchable

**O concern `Searchable` abstrai a lógica de busca:**

```ruby
# app/models/concerns/searchable.rb
# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(term) {
      return all if term.blank?
      return all if searchable_columns.blank?

      search_term = "%#{term.strip}%"
      conditions = searchable_columns.map { |col| 
        "#{table_name}.#{col} ILIKE ?" 
      }.join(" OR ")
      
      where(conditions, *([search_term] * searchable_columns.count))
    }
  end

  class_methods do
    attr_accessor :searchable_columns

    def searchable_columns(*columns)
      @searchable_columns = columns.map(&:to_s)
    end
  end
end
```

**Uso no model:**

```ruby
class Resource < ApplicationRecord
  include Searchable
  
  # Define quais colunas devem ser pesquisadas
  searchable_columns :name, :description, :email, :phone
end
```

**Uso no controller:**

```ruby
def index
  @resources = current_account.resources
                              .search(params[:search])
                              .order(created_at: :desc)
end
```

### 4.3 Validações

**⚠️ SEMPRE validar no model, nunca no service:**

```ruby
class Resource < ApplicationRecord
  belongs_to :account

  # Validações básicas
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  
  # Validações com scope (multi-account)
  validates :email, uniqueness: { scope: :account_id }, allow_nil: true
  validates :code, uniqueness: { scope: :account_id }
  
  # Validações customizadas
  validates :status, inclusion: { in: %w[active inactive] }
  
  # Validações condicionais
  validates :phone, presence: true, if: :requires_phone?
  
  private

  def requires_phone?
    category == 'contact'
  end
end
```

### 4.4 Associações Multi-Account

**Sempre incluir `belongs_to :account` e validar:**

```ruby
class Resource < ApplicationRecord
  belongs_to :account
  
  validates :account_id, presence: true
  
  # Associações dentro do account
  has_many :related_resources, dependent: :destroy
end
```

### 4.5 Scopes

**Criar scopes para queries comuns:**

```ruby
class Resource < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
end
```

### 4.6 Valores Padrão

**Sempre usar `after_initialize` para valores padrão:**

```ruby
class Resource < ApplicationRecord
  after_initialize :set_defaults

  private

  def set_defaults
    # Apenas para novos registros
    if new_record?
      self.active ||= true
      self.status ||= 'pending'
    end
  end
end
```

### 4.7 Enums

**Usar `str_enum` para enums (Rails 8):**

```ruby
class Resource < ApplicationRecord
  str_enum :status, {
    pending: 'pending',
    active: 'active',
    inactive: 'inactive'
  }
end
```

---

## 5. Rotas

### 5.1 Padrão de Rotas

**Sempre usar `resources` com `only:` ou `except:` para limitar ações:**

```ruby
# ✅ Correto - Todas as ações CRUD
resources :announcements

# ✅ Correto - Apenas algumas ações
resources :messages, only: [:index, :show]

# ✅ Correto - Todas exceto algumas
resources :push_notifications, only: [:new, :create]

# ❌ Evitar - Actions customizadas
resources :announcements do
  member do
    post :publish  # Se possível, usar update com status
    post :archive  # Se possível, usar update com status
  end
end
```

### 5.2 Quando Usar Actions Customizadas

**Evite actions customizadas. Prefira:**

1. **Status como atributo** ao invés de actions:
   ```ruby
   # ✅ Correto
   PATCH /backoffice/announcements/:id
   # params: { announcement: { status: 'published' } }
   
   # ❌ Evitar
   POST /backoffice/announcements/:id/publish
   ```

2. **Nested resources** ao invés de actions:
   ```ruby
   # ✅ Correto
   resources :groups do
     resources :members, only: [:create, :destroy]
   end
   
   # ❌ Evitar
   resources :groups do
     member do
       post :add_member
       delete :remove_member
     end
   end
   ```

3. **Se realmente necessário**, use `member` ou `collection`:
   ```ruby
   resources :accounts do
     member do
       post :switch  # Apenas quando não há alternativa
     end
   end
   ```

### 5.3 Exemplo de Rotas Completas

```ruby
namespace :backoffice do
  root "dashboard#index"
  
  # CRUD completo
  resources :announcements
  resources :events
  resources :contents
  resources :members
  resources :groups
  
  # CRUD limitado
  resources :messages, only: [:index, :show]
  resources :push_notifications, only: [:new, :create]
  
  # Resource singular
  resource :app_config, only: [:edit, :update]
end
```

---

## 6. Policies

### 6.1 BackofficePolicy

**Usar `BackofficePolicy` única para todos os recursos:**

```ruby
# app/policies/backoffice_policy.rb
# frozen_string_literal: true

class BackofficePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      return scope.all if user.super_admin?
      scope.where(account: user.account)
    end
  end

  def show?
    return true if user&.super_admin?
    user.present?
  end

  def create?
    return true if user&.super_admin?
    user.present?
  end

  def update?
    return true if user&.super_admin?
    user.present?
  end

  def destroy?
    return true if user&.super_admin?
    user.present?
  end
end
```

**O `Backoffice::BaseController` já configura isso:**

```ruby
def policy(record)
  BackofficePolicy.new(pundit_user, record)
end
```

### 6.2 Policy Scope

**Use `policy_scope` quando necessário:**

```ruby
def index
  @resources = policy_scope(current_account.resources)
end
```

---

## 7. Multi-Account

### 7.1 Isolamento por Account

**Sempre usar o método `current_account` (não variável de instância):**

```ruby
# ✅ Correto
@resources = current_account.resources

# ❌ Errado
@resources = Resource.all
@resources = @current_account.resources  # Não usar variável de instância
```

**Sempre criar recursos associados ao account:**

```ruby
# ✅ Correto
@resource = current_account.resources.build(params)

# ❌ Errado
@resource = Resource.new(params)
@resource.account = current_account
```

### 7.2 Validações Multi-Account

**Validar uniqueness com scope:**

```ruby
class Resource < ApplicationRecord
  belongs_to :account
  
  validates :code, uniqueness: { scope: :account_id }
  validates :email, uniqueness: { scope: :account_id }, allow_nil: true
end
```

---

## 8. Flash Messages (Toasts)

### 8.1 Uso em Controllers

**Sempre usar `notice` para sucesso e `alert` para erros:**

```ruby
# Sucesso
redirect_to backoffice_resources_path, notice: "Recurso criado com sucesso"

# Erro (raro, geralmente render)
flash.now[:alert] = "Erro ao processar"
render :new, status: :unprocessable_entity
```

**⚠️ IMPORTANTE**: O layout backoffice já converte flash messages para toasts automaticamente via `shared/flash_toasts`.

---

## 9. Strong Parameters

### 9.1 Padrão

**Sempre usar strong parameters:**

```ruby
private

def resource_params
  params.require(:resource_name).permit(:field1, :field2, :field3)
end
```

### 9.2 Parâmetros Aninhados

```ruby
def resource_params
  params.require(:resource_name).permit(
    :field1,
    :field2,
    nested_attributes: [:id, :field1, :field2, :_destroy]
  )
end
```

---

## 10. Exemplos Completos

### 10.1 Controller Simples (CRUD)

```ruby
# frozen_string_literal: true

module Backoffice
  class AnnouncementsController < BaseController
    before_action :set_announcement, only: [:show, :edit, :update, :destroy]

    def index
      @announcements = current_account.announcements
                                      .search(params[:search])
                                      .order(created_at: :desc)
    end

    def show
    end

    def new
      @announcement = current_account.announcements.build
    end

    def create
      @announcement = current_account.announcements.build(announcement_params)

      if @announcement.save
        redirect_to backoffice_announcements_path, notice: "Comunicado criado com sucesso"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @announcement.update(announcement_params)
        redirect_to backoffice_announcements_path, notice: "Comunicado atualizado com sucesso"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @announcement.destroy
      redirect_to backoffice_announcements_path, notice: "Comunicado excluído com sucesso"
    end

    private

    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(:title, :description, :active)
    end
  end
end
```

### 10.2 Model Simples

```ruby
# frozen_string_literal: true

class Announcement < ApplicationRecord
  belongs_to :account

  include Searchable
  searchable_columns :title, :description

  validates :title, presence: true
  validates :description, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }

  after_initialize :set_defaults

  private

  def set_defaults
    if new_record?
      self.active ||= true
    end
  end
end
```

### 10.3 Service (Quando Necessário)

```ruby
# frozen_string_literal: true

module Backoffice
  module Accounts
    class CreateService < Service
      attr_reader :account, :admin_user, :app_config

      def initialize(**params)
        super()
        @params = params
        @account = nil
        @admin_user = nil
        @app_config = nil
      end

      def call
        return false unless valid?

        execute_with_transaction do
          create_account
          create_admin_user
          create_app_config
          send_notification_email
        end
      end

      private

      def valid?
        validate_params
        validate_account
        validate_admin_user
        errors.empty?
      end

      def validate_params
        validate_presence(:church_name, @params[:church_name])
        validate_presence(:email, @params[:email])
        validate_presence(:password, @params[:password])
        
        validate_condition(
          @params[:password] == @params[:password_confirmation],
          attribute: :password_confirmation,
          message: "não confere"
        )
      end

      def validate_account
        return unless validate_presence(:church_name, @params[:church_name])

        @account = Account.new(
          name: @params[:church_name],
          subdomain: generate_subdomain(@params[:church_name]),
          active: true
        )
        
        validate_model(@account)
      end

      def validate_admin_user
        return unless @account&.valid?

        @admin_user = AdminUser.new(
          email: @params[:email],
          password: @params[:password],
          account: @account
        )
        
        validate_model(@admin_user)
      end

      def create_account
        save_model!(@account, raise_on_error: true)
      end

      def create_admin_user
        save_model!(@admin_user, raise_on_error: true)
      end

      def create_app_config
        @app_config = @account.build_app_config(
          title: @params[:church_name]
        )
        save_model!(@app_config, raise_on_error: true)
      end

      def send_notification_email
        # Lógica de envio de email
      end

      def generate_subdomain(name)
        # Lógica de geração de subdomain
      end
    end
  end
end
```

---

## 11. Checklist de Implementação

### 11.1 Novo Recurso CRUD

- [ ] Criar migration com `account_id`
- [ ] Criar model com `belongs_to :account`
- [ ] Incluir concern `Searchable` e definir `searchable_columns` se necessário
- [ ] Adicionar validações no model
- [ ] Adicionar scopes se necessário
- [ ] Adicionar valores padrão com `after_initialize`
- [ ] Criar controller herdando de `Backoffice::BaseController`
- [ ] Implementar actions CRUD padrão
- [ ] Usar `current_account` (método) ao invés de `@current_account`
- [ ] Usar `.search(params[:search])` se o model incluir `Searchable`
- [ ] Adicionar `before_action :set_resource`
- [ ] Criar `resource_params` com strong parameters
- [ ] Adicionar rotas com `resources :resource_name` no namespace `backoffice`
- [ ] Testar isolamento por account

### 11.2 Novo Service (Quando Necessário)

- [ ] Criar service herdando de `Service`
- [ ] Implementar `initialize` com parâmetros
- [ ] Implementar `call` que retorna true/false
- [ ] Implementar `valid?` usando métodos auxiliares da classe `Service`
- [ ] Usar métodos auxiliares: `validate_presence`, `validate_model`, `save_model!`, etc.
- [ ] Implementar métodos privados para cada passo
- [ ] Usar `execute_with_transaction` para operações atômicas
- [ ] **NÃO** adicionar validações de dados (vão no model)
- [ ] Usar métodos auxiliares para tratamento de erros de models

---

## 12. Regras Obrigatórias

### 12.1 ⚠️ Regras que NUNCA Devem Ser Violadas

1. **Validações SEMPRE no model**, nunca no service
2. **Sempre usar método `current_account`** (não variável `@current_account`) em queries
3. **Sempre criar recursos associados ao account** via `current_account.resources.build`
4. **Sempre usar strong parameters** nos controllers
5. **Sempre herdar de `Backoffice::BaseController`** para controllers backoffice
6. **Sempre usar `resources` com `only:` ou `except:`** nas rotas
7. **Preferir CRUD actions** ao invés de actions customizadas
8. **Usar services apenas quando necessário** (lógica complexa, múltiplos models)
9. **Sempre usar `before_action :set_resource`** para actions que precisam
10. **Valores padrão sempre no model** com `after_initialize`
11. **Usar concern `Searchable`** para busca nos models
12. **Usar métodos auxiliares da classe `Service`** para validações e tratamento de erros

### 12.2 Padrões de Nomenclatura

- **Controllers**: `ResourceNamesController` (plural, PascalCase, namespace `Backoffice`)
- **Models**: `ResourceName` (singular, PascalCase)
- **Services**: `Backoffice::ResourceNames::CreateService` (namespace, ação)
- **Form Objects**: `RegistrationForm` (singular, PascalCase, sufixo `Form`)
- **Policies**: `BackofficePolicy` (única para todos os recursos)
- **Routes**: `resources :resource_names` (plural, snake_case, namespace `backoffice`)
- **Concerns**: `Searchable` (PascalCase)

---

## 13. Decisões de Arquitetura

### 13.1 Por Que Services Apenas Quando Necessário?

- **Simplicidade**: CRUD simples não precisa de service
- **Manutenibilidade**: Menos código = menos bugs
- **Convenções Rails**: Rails já fornece padrões para CRUD
- **Performance**: Menos camadas = mais rápido

### 13.2 Por Que Validações no Model?

- **Single Source of Truth**: Validações em um único lugar
- **Reutilização**: Models podem ser usados em diferentes contextos
- **Testabilidade**: Mais fácil testar validações isoladamente
- **Rails Way**: Convenção do Rails

### 13.3 Por Que CRUD Actions?

- **Convenções REST**: Padrão da web
- **Simplicidade**: Menos rotas = menos complexidade
- **Manutenibilidade**: Código mais previsível
- **Status como atributo**: Mais flexível que actions separadas

### 13.4 Por Que Concern Searchable?

- **DRY**: Evita duplicação de código de busca
- **Manutenibilidade**: Lógica de busca centralizada
- **Simplicidade**: Controllers mais limpos
- **Consistência**: Busca funciona da mesma forma em todos os models

### 13.5 Por Que Métodos Auxiliares na Classe Service?

- **DRY**: Evita duplicação de código de validação e tratamento de erros
- **Consistência**: Todos os services usam os mesmos padrões
- **Manutenibilidade**: Fácil adicionar novos métodos auxiliares
- **Testabilidade**: Métodos auxiliares podem ser testados isoladamente

### 13.6 Por Que Form Objects?

- **Separação de Responsabilidades**: Validações de formulário separadas dos models
- **Simplificação do Service**: Service não precisa validar dados, apenas criar models
- **Reutilização**: Form object pode ser usado em diferentes contextos
- **Testabilidade**: Fácil testar validações isoladamente
- **Manutenibilidade**: Lógica de validação centralizada em um único lugar
- **Múltiplos Models**: Facilita validação e criação de múltiplos models simultaneamente

---

**FIM DO DOCUMENTO**

Este documento define os padrões de backend para o projeto Núcleo App. Seguir estes padrões garante consistência, manutenibilidade e simplicidade do código.
