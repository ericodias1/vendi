Perfeito. Esse relatório é estratégico demais para ficar só como ideia — então aqui vai o **PRD completo** no padrão de produto.

---

# 📄 PRD — Relatório “Ranking de Vendas por Critério”

**Produto:** Vendi Gestão
**Módulo:** Relatórios
**Versão:** MVP 1.1 (logo após MVP base)

---

# 1. 🎯 Objetivo do Relatório

Permitir que o lojista descubra **o que mais vende e mais gera lucro** com base em diferentes **critérios comerciais**, como:

* Marca
* Categoria
* Tamanho
* Cor
* (futuros: fornecedor, faixa de preço, grupo)

Este relatório transforma a pergunta:

> **“O que está funcionando na minha loja?”**

em uma resposta clara e acionável.

---

# 2. 👤 Público-alvo

Donos de lojas de varejo (roupas, calçados, acessórios), especialmente lojas com:

* Peças únicas
* Grande variedade
* Dificuldade em entender padrão de venda

---

# 3. 🧠 Problema que resolve

Sem esse relatório, o lojista:

* Compra no achismo
* Repete erros de mix
* Não entende qual marca/cor/tamanho realmente gira
* Foca em faturamento, não em lucro

---

# 4. 💡 Conceito do Relatório

Um **relatório dinâmico**, onde o usuário escolhe um critério e o sistema mostra o ranking de vendas e lucro com base nesse critério.

É um **relatório único com múltiplas visões**.

---

# 5. 🎛 Comportamento Principal

## Seletor de Critério (obrigatório)

No topo do relatório:

**“Analisar por:”** (dropdown)

Opções MVP:

* Marca
* Categoria
* Tamanho
* Cor
* Fornecedor
* Faixa de preço

Ao mudar o critério:

* A tabela se reorganiza
* Os insights mudam
* Os gráficos (se houver) se atualizam
* Podemos usar reload

---

# 6. ⏳ Filtros do Relatório

Filtros simples, sempre visíveis:

* Período (hoje / 7 dias / 30 dias / personalizado)
* Categoria
* Marca
* Mostrar apenas itens com estoque
* Faixa de preço (opcional)

---

# 7. 📊 Estrutura da Tabela

Independente do critério escolhido, a tabela sempre terá:

| Critério | Qtd vendida | Receita (R$) | Custo (R$) | Lucro (R$) | Margem (%) | Estoque atual |

Exemplo se critério = Marca:

| Marca | Qtd vendida | Receita | Custo | Lucro | Margem | Estoque |

---

# 8. 🔥 Widgets no topo (cards)

Sempre mostrar:

1. **Total vendido** (R$)
2. **Lucro total** (R$)
3. **Margem média (%)**
4. **Critério campeão** (ex: “Marca X”)

---

# 9. 💡 Sistema de Insights Automáticos

Os insights mudam conforme o critério:

### Se critério = Marca

* “Marca X gera mais lucro que todas as outras”
* “Marca Y vende muito mas tem margem baixa”

### Se critério = Tamanho

* “Tamanho M representa X% das vendas”
* “Tamanho G está com estoque baixo”

### Se critério = Cor

* “Cores neutras giram mais rápido”
* “Cor rosa tem margem alta mas pouco giro”

### Se critério = Categoria

* “Categoria X é responsável por Y% do lucro”

---

# 10. 🎯 Decisões que o relatório permite

| Critério  | Decisão do lojista                    |
| --------- | ------------------------------------- |
| Marca     | Comprar mais de X, reduzir Y          |
| Categoria | Ajustar investimento por tipo de peça |
| Tamanho   | Corrigir mix de tamanhos              |
| Cor       | Ajustar vitrine e reposição           |

---

# 11. 🧭 Ações sugeridas na tela

No rodapé ou painel lateral:

* “Ver produtos desse critério”
* “Gerar lista de reposição”
* “Ver itens com margem baixa”
* “Comparar com período anterior”

---

# 12. 🧩 Integração com Sistema de Agrupamento

Se a loja trabalha com peças únicas:

* O relatório deve funcionar também por **Grupo Comercial**
* Agrupamentos influenciam os resultados por categoria/marca/tamanho

---

# 13. 🎨 Experiência de uso

O relatório deve:

* Ser visualmente limpo
* Permitir ordenação por qualquer coluna
* Usar cores para margem:

  * Verde: alta
  * Amarelo: média
  * Vermelho: baixa

---

# 14. 📈 Métricas de sucesso

* % de usuários que usam o relatório semanalmente
* Tempo médio de permanência na tela
* Frequência de troca de critério

---

# 15. ❌ Fora do escopo

* BI customizável
* Exportações complexas
* Cruzamentos avançados (multi-critério simultâneo)

---

# 16. 🏁 Resultado esperado

Após usar este relatório, o lojista deve saber:

* Qual marca realmente vale a pena
* Qual tamanho gira mais
* Qual categoria sustenta o lucro
* Onde ajustar seu mix de compra

Se isso acontece, o relatório cumpriu sua função.
