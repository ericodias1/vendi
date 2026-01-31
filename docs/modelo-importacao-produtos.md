# Modelo de Importação de Produtos - CSV

Este documento descreve o formato do arquivo CSV para importação de produtos no sistema Vendi Gestão.

## 📋 Formato do Arquivo

O arquivo deve ser um CSV (valores separados por vírgula) com encoding UTF-8. A primeira linha deve conter os cabeçalhos das colunas.

## 📊 Colunas Disponíveis

### Colunas Obrigatórias

| Coluna | Tipo | Descrição | Exemplo |
|--------|------|-----------|---------|
| `nome` | String | Nome do produto (obrigatório) | "Vestido Floral Infantil" |
| `quantidade_estoque` | Integer | Quantidade inicial em estoque (obrigatório) | `10` |

### Colunas Opcionais

| Coluna | Tipo | Descrição | Exemplo | Valor Padrão |
|--------|------|-----------|---------|--------------|
| `id` | Integer | ID interno do produto (não editável). Quando preenchido e o produto existir na conta, a linha **atualiza** o produto em vez de criar um novo. Usado na conciliação (exportar CSV da base e reimportar). | `42` | `null` (cria novo produto) |
| `descricao` | Text | Descrição detalhada do produto | "Confortável vestido com estampa floral" | `null` |
| `sku` | String | Código SKU interno do produto | "VD-FLOR-001" | `null` |
| `codigo_fornecedor` | String | Código de referência do fornecedor | "FORN-1234" | `null` |
| `preco_base` | Decimal | Preço de venda do produto | `89.90` | `null` |
| `preco_custo` | Decimal | Preço de compra do produto | `45.00` | `null` |
| `categoria` | String | Categoria do produto | "Vestidos" | `null` |
| `marca` | String | Marca do produto | "Marca Kids" | `null` |
| `cor` | String | Cor do produto | "Rosa" | `null` |
| `tamanho` | String | Tamanho do produto | "P", "M", "G", "2", "4" | `null` |
| `ativo` | Boolean | Se o produto está ativo | `sim`, `não`, `nao`, `true`, `false`, `1` ou `0` | `true` |

## 📝 Observações Importantes

### Conciliação (atualização por ID)

Na tela **Importações**, você pode **Baixar CSV da base**: o arquivo exportado contém a coluna `id` (ID interno de cada produto). Ao editar esse CSV e reimportar, as linhas que tiverem `id` preenchido com um produto existente na sua conta terão esse produto **atualizado** (nome, preços, estoque, etc.) em vez de criar um novo. Linhas sem `id` ou com `id` inexistente continuam criando novos produtos. Não altere a coluna `id` ao editar o CSV de conciliação.

### Campos Opcionais (cor, tamanho, SKU)

Conforme especificado, os campos `cor`, `tamanho` e `sku` são **opcionais**. Você pode deixá-los em branco no CSV se não se aplicarem ao produto.

### Preço de Compra (Opcional)

O campo `preco_custo` (preço de compra) é **opcional**. Se não for informado no CSV (deixado em branco), o valor será salvo como `nil` no banco de dados. Isso permite que você tenha produtos com ou sem informação de preço de compra, facilitando o controle de margem de lucro apenas quando necessário.

### Valores Booleanos

Para o campo `ativo`, use:
- `sim`, `true` ou `1` para ativo
- `não`, `nao`, `false` ou `0` para inativo
- Se deixado em branco, o padrão será `true`

**Tratamento automático**: O sistema aplicará `parameterize` no valor antes de converter para boolean. 

**Valores que resultam em `true`** (independente de maiúsculas/minúsculas):
- `sim`, `SIM`, `Sim`, `SiM`, etc.

**Valores que resultam em `false`** (independente de maiúsculas/minúsculas):
- `não`, `NÃO`, `Não`, `Nao`, `nao`, `NAO`, `NaO`, etc. (com ou sem acento)
- `false`, `False`, `FALSE`
- `0`

### Valores Numéricos

- **Preços**: Use ponto (`.`) como separador decimal (ex: `89.90`)
- **Quantidade**: Apenas números inteiros (ex: `10`)
- **Valores vazios**: Deixe o campo completamente vazio (sem espaços) ou use `null`

### Campos Vazios

Para campos opcionais que você não deseja preencher:

1. **Deixe completamente vazio**: Apenas coloque nada entre as vírgulas
   ```csv
   nome,sku,cor
   Produto Teste,,Rosa
   ```

2. **Ou use aspas vazias**: `""`
   ```csv
   nome,sku,cor
   Produto Teste,"",Rosa
   ```

**Importante**: Não use espaços em branco, pois serão considerados como valores válidos.

### Tratamento Automático de Dados

O sistema aplicará automaticamente os seguintes tratamentos em todos os campos:

1. **`strip` bilateral**: Remove espaços em branco no início e fim de todos os campos
2. **`parameterize` em campos booleanos**: Converte valores de texto para boolean

**Exemplos de tratamento:**
- `"  Rosa  "` → `"Rosa"` (strip)
- `"Sim"` → `true` (parameterize + conversão booleana)
- `"SIM"` → `true` (parameterize + conversão booleana)
- `"Não"` → `false` (parameterize + conversão booleana)
- `"NÃO"` → `false` (parameterize + conversão booleana)
- `"nao"` → `false` (parameterize + conversão booleana - sem acento também funciona)
- `"NAO"` → `false` (parameterize + conversão booleana - sem acento também funciona)

**Importante**: Tanto `"não"` quanto `"nao"` (com ou sem acento) são sempre tratados como `false`, independente de maiúsculas/minúsculas.

### Encoding e Formato

- **Encoding**: UTF-8 (para suportar acentos e caracteres especiais)
- **Separador**: Vírgula (`,`)
- **Aspas**: Use aspas duplas (`"`) para valores que contenham vírgulas ou quebras de linha
- **Quebras de linha**: Use `\n` ou `\r\n` conforme o sistema operacional

## 📄 Exemplo de Arquivo CSV

O arquivo `docs/modelo-importacao-produtos.csv` contém um exemplo completo com diferentes cenários:

1. **Produto completo** (com todos os campos): Vestido Floral Infantil
2. **Produto sem SKU**: Blusa Manga Longa
3. **Produto sem tamanho**: Blusa Manga Longa (apenas cor)
4. **Produto sem cor e sem tamanho**: Boneca de Pelúcia
5. **Produto sem tamanho mas com cor**: Kit de Acessórios
6. **Produto inativo e sem preço**: Produto Sem Preço
7. **Produto sem preço de compra**: Vestido de Festa, Conjunto Esportivo

### Exemplo Simplificado

```csv
nome,descricao,sku,codigo_fornecedor,preco_base,preco_custo,categoria,marca,cor,tamanho,quantidade_estoque,ativo
Vestido Floral Infantil,Confortável vestido com estampa floral para meninas,VD-FLOR-001,FORN-1234,89.90,45.00,Vestidos,Marca Kids,Rosa,P,10,sim
Blusa Manga Longa,Blusa confortável para o inverno,,FORN-1237,59.90,25.00,Blusas,Marca Kids,Cinza,,20,sim
Boneca de Pelúcia,Boneca macia e fofa para crianças,,FORN-1239,49.90,20.00,Brinquedos,Marca Kids,,,5,sim
```

### Cenários de Uso

#### Produto com todos os campos
```csv
nome,descricao,sku,codigo_fornecedor,preco_base,preco_custo,categoria,marca,cor,tamanho,quantidade_estoque,ativo
Vestido Floral Infantil,Confortável vestido com estampa floral para meninas,VD-FLOR-001,FORN-1234,89.90,45.00,Vestidos,Marca Kids,Rosa,P,10,sim
```

#### Produto sem SKU (deixe vazio)
```csv
nome,descricao,sku,codigo_fornecedor,preco_base,preco_custo,categoria,marca,cor,tamanho,quantidade_estoque,ativo
Blusa Manga Longa,Blusa confortável para o inverno,,FORN-1237,59.90,25.00,Blusas,Marca Kids,Cinza,,20,sim
```

#### Produto sem cor e sem tamanho (deixe ambos vazios)
```csv
nome,descricao,sku,codigo_fornecedor,preco_base,preco_custo,categoria,marca,cor,tamanho,quantidade_estoque,ativo
Boneca de Pelúcia,Boneca macia e fofa para crianças,,FORN-1239,49.90,20.00,Brinquedos,Marca Kids,,,5,sim
```

#### Produto sem preço de venda (deixe vazio)
```csv
nome,descricao,sku,codigo_fornecedor,preco_base,preco_custo,categoria,marca,cor,tamanho,quantidade_estoque,ativo
Produto Sem Preço,Produto para teste sem preço definido,TEST-001,FORN-1241,,,Teste,Marca Kids,Verde,M,0,não
```

#### Produto sem preço de compra (deixe vazio - será salvo como nil)
```csv
nome,descricao,sku,codigo_fornecedor,preco_base,preco_custo,categoria,marca,cor,tamanho,quantidade_estoque,ativo
Vestido de Festa,Vestido elegante para ocasiões especiais,VD-FEST-008,FORN-1242,129.90,,Vestidos,Marca Kids,Rosa,G,8,sim
```

## 🔍 Validações

### Validações que serão aplicadas na importação:

1. **Nome**: Obrigatório e não pode estar vazio
2. **Quantidade de Estoque**: Obrigatório, deve ser um número inteiro ≥ 0
3. **SKU**: Se informado, deve ser único dentro da conta (account)
4. **Preços**: Se informados, devem ser números decimais positivos. O preço de compra (`preco_custo`) é opcional e será salvo como `nil` se não for informado.
5. **Ativo**: Se informado, deve ser `sim`, `não`, `nao`, `true`, `false`, `1` ou `0` (será aplicado `parameterize` e `strip` antes da validação). Tanto `não` quanto `nao` (com ou sem acento) são sempre tratados como `false`, independente de maiúsculas/minúsculas.

## 📦 Campos que NÃO serão importados (por enquanto)

- **Imagens**: As fotos dos produtos não serão importadas nesta primeira versão
- **Campos customizados**: O campo `custom_fields` (JSON) não será importado
- **Posição**: O campo `position` não será importado (será definido automaticamente)

## 🎯 Próximos Passos

Após a definição deste modelo, será desenvolvida a funcionalidade de importação que:

1. Validará o formato do arquivo CSV
2. Validará os dados de cada linha
3. Criará os produtos no sistema
4. Registrará as movimentações de estoque inicial
5. Retornará um relatório de importação com sucessos e erros

## 📚 Referências

- Ver `docs/vendi-especificacao-completa.md` para mais detalhes sobre a estrutura de produtos
- Ver `app/models/product.rb` para validações e comportamentos do modelo
