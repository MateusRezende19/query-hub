# Consulta: Rateio por Nota Fiscal

Esta documentação explica detalhadamente o propósito, a lógica de negócio e as particularidades da query `rateio-por-nf.sql`. 

## 🎯 Propósito da Query

A query **Rateio por Nota Fiscal** tem como objetivo extrair todos os dados de Notas Fiscais de Entrada (compras/despesas) detalhadas ao nível máximo: **por item do produto e por centro de custo (rateio)**. 

No sistema Teknisa, uma única Nota Fiscal pode ter vários itens, e cada item pode ser rateado (dividido) para vários centros de custo diferentes. Essa query "desdobra" a nota fiscal para exibir exatamente quanto de cada item foi para cada centro de custo, sendo ideal para análises detalhadas de Controladoria e Custos.

## 🧠 Lógica e Estrutura (Como funciona?)

O maior desafio ao extrair dados de Nota Fiscal + Itens + Rateio é a **duplicação de valores** (produto cartesiano). Se uma nota de R$ 100,00 tem 5 rateios, um simples `JOIN` faria o valor total da nota aparecer 5 vezes (totalizando R$ 500,00 erroneamente).

Para resolver isso de forma inteligente e facilitar a modelagem no Power BI, a query utiliza funções de janela (`Window Functions` como `ROW_NUMBER()` e `SUM() OVER`) criando campos específicos:

### 1. Prevenção de Duplicação em Contagens (`QTDNOTAS`)
- **Como funciona:** A query avalia as quebras de linha e atribui o valor `1` apenas para a **primeira linha** de cada nota fiscal, e `0` para as demais linhas de itens/rateios dessa mesma nota.
- **Uso prático:** No Power BI, basta fazer uma soma `SUM(QTDNOTAS)` e você terá a contagem exata e real de notas fiscais, sem duplicações.

### 2. Prevenção de Duplicação Financeira (`VRLIQTOTAL`)
- **Como funciona:** Semelhante ao campo acima, a query calcula o valor líquido total da nota, mas só exibe esse valor na **primeira linha** da nota. Nas linhas subsequentes de itens e rateios, o valor fica `0`.
- **Uso prático:** Fazer um `SUM(VRLIQTOTAL)` no painel de BI trará o valor financeiro correto das notas, ignorando a explosão de linhas causadas pelos itens e centros de custo.

### 3. Cálculo Proporcional do Item (`VRTOT_LIQUIDO`)
- **Como funciona:** Se um item custa R$ 100 e foi rateado 60% para o Setor A e 40% para o Setor B, a query faz o cálculo exato:
  `Valor do Item * (Valor do Rateio / Soma dos Rateios do Item)`
- **Uso prático:** Mostra exatamente o custo fracionado de cada item por departamento/centro de custo.

## 🔗 Principais Tabelas Relacionadas

A extração cruza as seguintes informações essenciais:
- `NOTAFISCAL (N)`: Cabeçalho da nota (Data, número, série, fornecedor).
- `ITEMPRODUTO (I)`: Os produtos ou serviços comprados na nota.
- `RATEIONF (R)`: As regras de divisão (rateio) de cada item por centro de custo.
- `CENTCUST (C)`: Cadastro e nome dos centros de custos (departamentos).
- `FORNECEDOR (F)` / `EMPRESA (E)` / `PRODUTO (P)`: Tabelas dimensão para trazer as descrições (nomes).

## ⚙️ Filtros Aplicados (Regras de Negócio)

Para garantir que apenas dados relevantes de Controladoria sejam trazidos, a query possui regras fixas na cláusula `WHERE`:

1. **Apenas Entradas:** Filtra `N.IDENTRSAIDOP = 'E'` e `TP.IDENTRSAIDOP = 'E'`.
2. **Tipos de Operação (CFOP/Operação):** Restringe apenas aos códigos financeiros/fiscais de interesse: `01, 15, 19, 20, 22, 23, 24, 26, 28, 29, 40, 43, 45, 46, 58`.
3. **Filtro de Data Dinâmico:** A query utiliza os parâmetros `:START_DATE` e `:END_DATE` na data de emissão (`DTEMISSAO`). Ao configurar esta query no BI ou em uma automação Python, **estes parâmetros devem ser fornecidos dinamicamente**.

## 📊 Como usar no Power BI

- Para saber o **Custo Total por Centro de Custo**: Some a coluna `VRTOT_LIQUIDO` cruzando com a coluna `NMCENTCUST`.
- Para saber o **Valor Total Comprado (Geral)**: Some a coluna `VRLIQTOTAL` (não use a coluna de valor do rateio para evitar divergências de arredondamento no total).
- Para saber o **Volume de Notas Fiscais Emitidas**: Some a coluna `QTDNOTAS`.
