# Melhorias na Importação de Produtos

**Data**: 31 de Janeiro de 2026  
**Status**: Planejado para futuro  
**Prioridade**: Alta

---

## 📋 Contexto

O sistema de importação de produtos (`ProductImport`) funciona corretamente, mas o código atual apresenta problemas de manutenibilidade que dificultam futuras alterações e aumentam o risco de bugs.

### Arquivos Principais Afetados

- `app/controllers/backoffice/product_imports_controller.rb`
- `app/services/backoffice/product_imports/process_service.rb`
- `app/services/backoffice/product_imports/row_processor.rb`
- Demais services em `app/services/backoffice/product_imports/`

---

## 🔴 Problemas Identificados

### 1. Controller com Muitas Responsabilidades

**Arquivo**: `app/controllers/backoffice/product_imports_controller.rb`

**Problemas**:
- **Linhas 184-218**: Método `recalculate_duplicate_errors_for` com 35 linhas de lógica de negócio complexa no controller
- **Linhas 221-228**: Salvando configurações do `AccountConfig` diretamente no controller
- **Linhas 172-182**: Lógica de normalização de arrays que deveria estar em um helper

**Por que é um problema**:
- Controllers devem ser magros e focar apenas em HTTP (request/response)
- Lógica de negócio no controller dificulta testes unitários
- Viola o princípio de Single Responsibility

---

### 2. Duplicação de Lógica de Erros

**Arquivos**:
- `ProductImportsController#recalculate_duplicate_errors_for` (linhas 184-218)
- `ProcessService#calculate_duplicate_name_errors` (linhas 110-141)

**Problema**:
A lógica de calcular erros de duplicata está **duplicada** em dois lugares. Ambos fazem praticamente a mesma coisa:
1. Iteram sobre `parsed_data`
2. Agrupam por nome normalizado
3. Detectam duplicatas
4. Geram mensagens de erro

**Por que é um problema**:
- Se precisar mudar a lógica, precisa alterar em 2 lugares
- Alto risco de inconsistência entre as duas implementações
- Dificulta manutenção e aumenta chance de bugs

**Impacto**: 🔴 **CRÍTICO** - Este é o problema mais grave

---

### 3. ProcessService Muito Complexo

**Arquivo**: `app/services/backoffice/product_imports/process_service.rb`

**Problema**:
O `ProcessService` tem múltiplas responsabilidades:
- Validar dados de entrada
- Calcular erros de duplicata
- Limpar erros antigos
- Processar linhas do CSV
- Gerenciar status da importação
- Gerenciar transações do banco
- Inicializar múltiplos componentes (8 objetos diferentes)

**Por que é um problema**:
- Service com mais de 200 linhas é difícil de entender
- Dificulta testes unitários (precisa mockar muitas coisas)
- Viola Single Responsibility Principle
- Mudanças em uma parte podem afetar outras partes

---

### 4. Muitas Dependências Injetadas

**Arquivo**: `app/services/backoffice/product_imports/row_processor.rb`

**Problema**:
O `RowProcessor` recebe **8 parâmetros** no construtor (linhas 6-24):
```ruby
def initialize(
  account:,
  current_user:,
  product_import:,
  import_result:,
  sku_generator:,
  sku_validator:,
  name_validator:,
  product_builder:
)
```

**Por que é um problema**:
- Code smell chamado "Long Parameter List"
- Difícil de instanciar e testar
- Alto acoplamento entre componentes
- Dificulta refatoração

---

### 5. Lógica de Status Espalhada

**Arquivos múltiplos**:
- `ProcessService#should_fail_due_to_parsing_errors?`
- `ProcessService#fail_import`
- `ProcessService#finalize_import`
- `ProductImportsController#process_import`

**Problema**:
A lógica de quando usar `failed` vs `completed` vs `processing` está espalhada em vários lugares sem uma centralização clara.

**Por que é um problema**:
- Dificulta entender o fluxo de estados
- Aumenta risco de estados inconsistentes
- Dificulta adicionar novos estados no futuro

---

## ✅ Melhorias Propostas

### 🔴 Prioridade ALTA

#### 1. Criar Service para Cálculo de Erros de Duplicata

**Objetivo**: Eliminar duplicação entre controller e service.

**Implementação**:
```ruby
# app/services/backoffice/product_imports/duplicate_errors_calculator.rb
# frozen_string_literal: true

module Backoffice
  module ProductImports
    class DuplicateErrorsCalculator < Service
      attr_reader :product_import

      def initialize(product_import:)
        super()
        @product_import = product_import
      end

      def call
        return [] unless should_calculate?

        calculate_duplicate_errors
      end

      def clean_old_errors
        cleaned = (@product_import.import_errors || []).reject do |error|
          duplicate_error?(error)
        end

        @product_import.update_column(:import_errors, cleaned) if cleaned != @product_import.import_errors
      end

      private

      def should_calculate?
        @product_import.create_only? && @product_import.parsed_data.present?
      end

      def calculate_duplicate_errors
        name_map = build_name_map
        generate_error_messages(name_map)
      end

      def build_name_map
        name_map = {}
        @product_import.parsed_data.each_with_index do |row_data, index|
          product_name = row_data['nome'] || row_data[:nome]
          next unless product_name.present?

          parameterized_name = product_name.to_s.strip.downcase
          name_map[parameterized_name] ||= []
          name_map[parameterized_name] << { 
            row: index + 1, 
            name: product_name, 
            data: row_data 
          }
        end
        name_map
      end

      def generate_error_messages(name_map)
        duplicate_errors = []
        
        name_map.each do |_name, entries|
          next if entries.length <= 1

          entries.each do |entry|
            other_rows = entries.reject { |e| e[:row] == entry[:row] }
            other_rows_text = other_rows.map { |e| e[:row] }.join(", ")

            duplicate_errors << {
              'row' => entry[:row],
              'data' => entry[:data],
              'errors' => ["Nome duplicado: \"#{entry[:name]}\" (também na linha #{other_rows_text})"]
            }
          end
        end

        duplicate_errors
      end

      def duplicate_error?(error)
        return false unless error.is_a?(Hash)

        error_list = error['errors'] || error[:errors]
        return false unless error_list.is_a?(Array)

        error_list.all? do |err|
          err.is_a?(String) && (
            err.downcase.include?('nome duplicado') ||
            err.downcase.include?('também na linha')
          )
        end
      end
    end
  end
end
```

**Uso no Controller**:
```ruby
def recalculate_duplicate_errors_for(product_import)
  calculator = Backoffice::ProductImports::DuplicateErrorsCalculator.new(
    product_import: product_import
  )
  
  calculator.clean_old_errors
  new_errors = calculator.call
  
  if new_errors.any?
    current_errors = product_import.import_errors || []
    product_import.update_column(:import_errors, current_errors + new_errors)
  end
end
```

**Uso no ProcessService**:
```ruby
def calculate_duplicate_name_errors
  calculator = Backoffice::ProductImports::DuplicateErrorsCalculator.new(
    product_import: @product_import
  )
  calculator.call
end

def clean_duplicate_errors
  calculator = Backoffice::ProductImports::DuplicateErrorsCalculator.new(
    product_import: @product_import
  )
  calculator.clean_old_errors
end
```

**Benefícios**:
- ✅ Elimina duplicação de código
- ✅ Lógica centralizada e testável
- ✅ Fácil de manter e evoluir
- ✅ Reduz tamanho do controller e do ProcessService

---

#### 2. Extrair Lógica de Configuração para Service

**Objetivo**: Remover lógica de negócio do controller.

**Implementação**:
```ruby
# app/services/backoffice/product_imports/save_settings_service.rb
# frozen_string_literal: true

module Backoffice
  module ProductImports
    class SaveSettingsService < Service
      def initialize(account:, params:)
        super()
        @account = account
        @params = params
      end

      def call
        config = @account.account_config || @account.create_account_config!
        
        config.update(
          product_import_auto_generate_sku: auto_generate_sku?,
          product_import_ignore_errors: ignore_errors?,
          product_import_name_normalization: normalized_mode
        )
      end

      private

      def auto_generate_sku?
        @params[:auto_generate_sku] == "1"
      end

      def ignore_errors?
        @params[:ignore_errors] == "1"
      end

      def normalized_mode
        value = @params[:name_normalization]
        return nil if value.blank?
        return value if ProductImport::NAME_NORMALIZATION_MODES.include?(value.to_s)
        nil
      end
    end
  end
end
```

**Uso no Controller**:
```ruby
def create
  # ... código existente ...
  
  if @product_import.save
    Backoffice::ProductImports::SaveSettingsService.new(
      account: current_account,
      params: params
    ).call
    
    redirect_to backoffice_product_import_path(@product_import), notice: "Arquivo enviado. Processando..."
  else
    # ... código existente ...
  end
end
```

**Benefícios**:
- ✅ Controller mais magro
- ✅ Lógica de configuração testável isoladamente
- ✅ Fácil reutilizar em outros lugares

---

### 🟡 Prioridade MÉDIA

#### 3. Usar Builder Pattern para RowProcessor

**Objetivo**: Reduzir acoplamento e facilitar instanciação.

**Implementação**:
```ruby
# app/services/backoffice/product_imports/processing_context.rb
# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ProcessingContext
      attr_reader :product_import, :account, :current_user, :import_result

      def initialize(product_import:, account:, current_user:, import_result:)
        @product_import = product_import
        @account = account
        @current_user = current_user
        @import_result = import_result
      end
    end
  end
end
```

```ruby
# app/services/backoffice/product_imports/row_processor_builder.rb
# frozen_string_literal: true

module Backoffice
  module ProductImports
    class RowProcessorBuilder
      def self.build(product_import:, account:, current_user:)
        import_result = ImportResult.new
        context = ProcessingContext.new(
          product_import: product_import,
          account: account,
          current_user: current_user,
          import_result: import_result
        )

        RowProcessor.new(
          context: context,
          validators: build_validators(account, import_result),
          generators: build_generators(account, import_result),
          product_builder: build_product_builder(account, current_user, product_import)
        )
      end

      private

      def self.build_validators(account, import_result)
        {
          sku: Validators::SkuValidator.new(account: account, import_result: import_result),
          name: Validators::NameValidator.new(account: account, import_result: import_result)
        }
      end

      def self.build_generators(account, import_result)
        {
          sku: SkuGenerator.new(account: account, import_result: import_result)
        }
      end

      def self.build_product_builder(account, current_user, product_import)
        ProductBuilder.new(
          account: account,
          current_user: current_user,
          product_import: product_import
        )
      end
    end
  end
end
```

**RowProcessor Refatorado**:
```ruby
# app/services/backoffice/product_imports/row_processor.rb
class RowProcessor
  def initialize(context:, validators:, generators:, product_builder:)
    @context = context
    @validators = validators
    @generators = generators
    @product_builder = product_builder
  end

  def process(row_data, row_number:)
    # ... lógica existente usando @context.product_import, @validators[:sku], etc
  end

  private

  def product_import
    @context.product_import
  end

  def account
    @context.account
  end

  def import_result
    @context.import_result
  end
end
```

**Uso no ProcessService**:
```ruby
def process_import
  # ... código existente ...
  
  row_processor = RowProcessorBuilder.build(
    product_import: @product_import,
    account: @account,
    current_user: @current_user
  )
  
  # ... resto do código
end
```

**Benefícios**:
- ✅ Reduz de 8 para 4 parâmetros
- ✅ Agrupa dependências relacionadas
- ✅ Facilita testes (pode mockar apenas o context)
- ✅ Mais fácil adicionar novas dependências

---

#### 4. Implementar State Machine para Status

**Objetivo**: Centralizar lógica de transição de estados.

**Implementação**:
```ruby
# app/models/product_import/state_machine.rb
# frozen_string_literal: true

class ProductImport
  class StateMachine
    attr_reader :product_import

    def initialize(product_import)
      @product_import = product_import
    end

    def can_process?
      @product_import.status.in?(['ready', 'failed'])
    end

    def start_processing!
      validate_transition!('processing')
      @product_import.update!(status: 'processing')
    end

    def complete!(import_result)
      validate_transition!('completed')
      
      final_status = determine_final_status(import_result)
      
      @product_import.update!(
        status: final_status,
        processed_rows: import_result.processed_rows,
        successful_rows: import_result.successful_rows,
        failed_rows: import_result.failed_rows,
        import_errors: merge_errors(import_result.errors)
      )
    end

    def fail!(errors, import_result: nil)
      validate_transition!('failed')
      
      attributes = { status: 'failed', import_errors: errors }
      
      if import_result
        attributes.merge!(
          processed_rows: import_result.processed_rows,
          successful_rows: import_result.successful_rows,
          failed_rows: import_result.failed_rows
        )
      end
      
      @product_import.update!(attributes)
    end

    private

    def validate_transition!(new_status)
      unless can_transition_to?(new_status)
        raise InvalidTransition, "Cannot transition from #{@product_import.status} to #{new_status}"
      end
    end

    def can_transition_to?(new_status)
      case @product_import.status
      when 'pending'
        new_status.in?(['parsing', 'failed'])
      when 'parsing'
        new_status.in?(['ready', 'failed'])
      when 'ready'
        new_status.in?(['processing', 'failed'])
      when 'processing'
        new_status.in?(['completed', 'failed'])
      when 'failed'
        new_status.in?(['processing']) # Pode reprocessar
      when 'completed'
        false # Estado final
      else
        false
      end
    end

    def determine_final_status(import_result)
      if import_result.failed_rows == import_result.processed_rows
        'failed'
      else
        'completed'
      end
    end

    def merge_errors(new_errors)
      existing = @product_import.import_errors || []
      existing + new_errors
    end

    class InvalidTransition < StandardError; end
  end
end
```

**Uso no ProcessService**:
```ruby
def process_import
  state_machine = ProductImport::StateMachine.new(@product_import)
  
  state_machine.start_processing!
  
  # ... processamento ...
  
  if success
    state_machine.complete!(import_result)
  else
    state_machine.fail!(errors, import_result: import_result)
  end
end
```

**Benefícios**:
- ✅ Centraliza toda lógica de transição
- ✅ Valida transições inválidas
- ✅ Documenta estados possíveis
- ✅ Facilita adicionar novos estados

---

#### 5. Quebrar ProcessService em Services Menores

**Objetivo**: Aplicar Single Responsibility Principle.

**Implementação**:
```ruby
# app/services/backoffice/product_imports/pre_processing_validator.rb
class PreProcessingValidator < Service
  def initialize(product_import)
    @product_import = product_import
  end

  def call
    validate_parsed_data
    validate_no_parsing_errors if strict_mode?
    validate_no_duplicate_names if strict_mode?
    
    errors.empty?
  end

  private

  def strict_mode?
    !@product_import.ignore_errors
  end

  # ... métodos de validação
end
```

```ruby
# app/services/backoffice/product_imports/rows_processor.rb
class RowsProcessor < Service
  def initialize(product_import, account, current_user)
    @product_import = product_import
    @account = account
    @current_user = current_user
  end

  def call
    row_processor = RowProcessorBuilder.build(
      product_import: @product_import,
      account: @account,
      current_user: @current_user
    )

    @product_import.parsed_data.each_with_index do |row_data, index|
      process_row(row_processor, row_data, index + 1)
    end

    row_processor.import_result
  end

  private

  def process_row(processor, row_data, row_number)
    result = processor.process(row_data, row_number: row_number)
    
    unless @product_import.ignore_errors || result[:success]
      raise ProcessingError, "Row #{row_number} failed"
    end
  rescue StandardError => e
    processor.import_result.record_failure(row_number, row_data, [e.message])
    raise unless @product_import.ignore_errors
  end
end
```

```ruby
# app/services/backoffice/product_imports/process_service.rb (Simplificado)
class ProcessService < Service
  def call
    return false unless valid?

    validator = PreProcessingValidator.new(@product_import)
    return false unless validator.call

    state_machine = ProductImport::StateMachine.new(@product_import)
    state_machine.start_processing!

    import_result = RowsProcessor.new(@product_import, @account, @current_user).call
    state_machine.complete!(import_result)

    true
  rescue ProcessingError => e
    state_machine.fail!(e.errors, import_result: e.import_result)
    false
  end
end
```

**Benefícios**:
- ✅ Cada service tem uma responsabilidade clara
- ✅ Mais fácil de testar isoladamente
- ✅ Reduz complexidade do ProcessService principal
- ✅ Facilita manutenção

---

### 🟢 Prioridade BAIXA

#### 6. Usar Value Objects para Resultados

**Objetivo**: Type safety e métodos auxiliares claros.

**Implementação**:
```ruby
# app/services/backoffice/product_imports/processing_result.rb
# frozen_string_literal: true

module Backoffice
  module ProductImports
    class ProcessingResult
      attr_reader :errors, :product, :row_number

      def initialize(success:, errors: [], product: nil, row_number: nil)
        @success = success
        @errors = Array(errors)
        @product = product
        @row_number = row_number
      end

      def success?
        @success
      end

      def failure?
        !@success
      end

      def has_errors?
        @errors.any?
      end

      def error_messages
        @errors.join(", ")
      end

      # Factory methods
      def self.success(product:, row_number: nil)
        new(success: true, product: product, row_number: row_number)
      end

      def self.failure(errors:, row_number: nil)
        new(success: false, errors: errors, row_number: row_number)
      end
    end
  end
end
```

**Uso**:
```ruby
# Em vez de:
{ success: true, product: product }
{ success: false, errors: ["Erro"] }

# Usar:
ProcessingResult.success(product: product)
ProcessingResult.failure(errors: ["Erro"])

# Checagem:
if result.success?
  # ...
end
```

**Benefícios**:
- ✅ Type safety (não pode esquecer chaves)
- ✅ Métodos auxiliares claros
- ✅ Facilita refatoração
- ✅ Melhor autocompletar na IDE

---

#### 7. Extrair Concerns do Controller

**Objetivo**: Organizar código relacionado.

**Implementação**:
```ruby
# app/controllers/concerns/product_import_params_handler.rb
# frozen_string_literal: true

module ProductImportParamsHandler
  extend ActiveSupport::Concern

  private

  def normalize_costs_array(costs)
    case costs
    when Array
      costs
    when Hash, ActionController::Parameters
      n = costs.size
      (0...n).map { |i| costs[i] || costs[i.to_s] }
    else
      []
    end
  end

  def permitted_import_mode(value)
    return "create_only" if value.blank?
    return value if ProductImport::IMPORT_MODES.include?(value.to_s)
    "create_only"
  end

  def permitted_name_normalization(value)
    return nil if value.blank?
    return value if ProductImport::NAME_NORMALIZATION_MODES.include?(value.to_s)
    nil
  end
end
```

**Uso no Controller**:
```ruby
class ProductImportsController < BaseController
  include ProductImportParamsHandler

  # ... resto do código
end
```

**Benefícios**:
- ✅ Controller mais organizado
- ✅ Concerns reutilizáveis
- ✅ Facilita testes

---

## 📊 Resumo de Prioridades

| Prioridade | Melhoria | Impacto | Esforço |
|------------|----------|---------|---------|
| 🔴 Alta | `DuplicateErrorsCalculator` service | Elimina duplicação crítica | Médio |
| 🔴 Alta | `SaveSettingsService` | Controller mais limpo | Baixo |
| 🟡 Média | Builder Pattern para `RowProcessor` | Reduz acoplamento | Médio |
| 🟡 Média | State Machine para status | Centraliza transições | Alto |
| 🟡 Média | Quebrar `ProcessService` | Reduz complexidade | Alto |
| 🟢 Baixa | Value Objects para resultados | Type safety | Baixo |
| 🟢 Baixa | Concerns no controller | Organização | Baixo |

---

## 🎯 Plano de Implementação Recomendado

### Fase 1 - Quick Wins (1-2 dias)
1. ✅ Criar `DuplicateErrorsCalculator` service
2. ✅ Refatorar controller e `ProcessService` para usar o novo service
3. ✅ Criar `SaveSettingsService`
4. ✅ Extrair concerns do controller

**Resultado esperado**: Elimina duplicação crítica e reduz controller em ~50 linhas.

---

### Fase 2 - Melhorias Estruturais (3-5 dias)
1. ✅ Implementar Builder Pattern para `RowProcessor`
2. ✅ Criar Value Objects para resultados
3. ✅ Atualizar testes

**Resultado esperado**: Código mais desacoplado e testável.

---

### Fase 3 - Refatoração Profunda (1-2 semanas)
1. ✅ Implementar State Machine
2. ✅ Quebrar `ProcessService` em services menores
3. ✅ Atualizar toda suite de testes
4. ✅ Documentar novos padrões

**Resultado esperado**: Arquitetura mais robusta e manutenível.

---

## 📝 Notas Importantes

### Quando Implementar

- **NÃO implementar agora**: O sistema está funcionando corretamente. Essas melhorias são para **manutenibilidade futura**.
- **Implementar quando**: 
  - For adicionar novas features relacionadas à importação
  - Começar a ter bugs recorrentes
  - Precisar fazer mudanças significativas no fluxo

### Testes

- ⚠️ **CRÍTICO**: Antes de qualquer refatoração, garantir que há testes cobrindo o comportamento atual
- Cada service novo deve ter testes unitários
- Manter testes de integração para garantir que o fluxo completo funciona

### Compatibilidade

- Todas as refatorações devem manter compatibilidade com o comportamento atual
- Não mudar a interface pública (rotas, params, responses) sem necessidade

---

## 🔗 Referências

- **Padrões de Design**: Builder Pattern, State Machine, Service Objects
- **Princípios SOLID**: Single Responsibility, Dependency Inversion
- **Code Smells**: Long Method, Long Parameter List, Duplicated Code

---

**Última atualização**: 31 de Janeiro de 2026  
**Responsável**: Time de Desenvolvimento Vendi
