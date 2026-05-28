# Documentação da Query: Fornecedores

## Objetivo
A query `fornecedores.sql` tem como objetivo extrair um cadastro detalhado de todos os fornecedores **ativos** no sistema. A extração inclui dados cadastrais, informações de endereço, e de forma destacada, a consolidação e formatação das **regras de desconto** e **condições de pagamento** negociadas com cada fornecedor.

## Tabelas Envolvidas
A consulta relaciona quatro tabelas principais:
- **`FORNECEDOR (FO)`**: Tabela principal com os dados base do fornecedor (CNPJ, Razão Social, Nome Fantasia, etc.).
- **`ENDEFORN (ED)`**: Dados de endereço associados ao fornecedor.
- **`FORMPGTO (FOPG)`**: Descrição das formas de pagamento (à vista, boleto, etc.).
- **`PRAZOPGTFORN (PRAZ)`**: Traz o detalhamento das parcelas e dias de prazo de pagamento definidos.

## Lógica Utilizada e Regras de Negócio

### 1. Filtragem de Fornecedores Ativos
A query garante que apenas fornecedores ativos sejam trazidos pelo filtro:
```sql
WHERE FO.IDSITUCADA = 'A'
```

### 2. Classificação do Tipo de Desconto (`TIPO_DESCONTO`)
A regra de negócio traduz o campo `IdTpDescForn` em texto legível usando uma estrutura `CASE WHEN`:
- `B` ➔ BONIFICAÇÃO
- `C` ➔ COMERCIAL
- `S` ➔ SEM DESCONTO
- Qualquer outro valor é tratado como "Não definido".

### 3. Consolidação da Forma de Pagamento (`FORMA_PAGTO`)
Esta é a parte mais complexa da query. Ela junta o tipo de pagamento base com a listagem de prazos em uma única string de texto.

**Lógica Principal (`CASE WHEN`)**:
Verifica o tipo de forma de pagamento (`IDTPFORPGTFO`):
- **V (Variável/À Vista)**: Retorna apenas o nome da forma de pagamento. Ex: `( BOLETO BANCARIO )`.
- **F (Fixo)**: Constrói uma frase informando o dia fixo e o número de parcelas. Ex: `Pagamento fixo no dia 15 com 3 parcela(s)`.
- Se não for nenhum desses, exibe `Sem forma de pagamento definida`.

**Listagem de Prazos (`LISTAGG`)**:
Para cada fornecedor, pode haver várias regras de prazo de pagamento (ex: 30, 60, 90 dias).
A função `LISTAGG` agrupa esses registros da tabela `PRAZOPGTFORN` em uma única linha, separando por ` | `, no formato `DIAS - PERCENTUAL%`.
O resultado é concatenado à lógica principal com um ` - `.

**Exemplo de Resultado da Coluna:**
> `( BOLETO BANCARIO ) - 30 - 50% | 60 - 50%`
*Isso significa: Pagamento em boleto, dividido em duas parcelas iguais (50%) para 30 e 60 dias.*

### 4. Data da API (`DATA_API`)
A query injeta uma data fixa (`2000-01-01`) formatada na coluna `DATA_API`, geralmente servindo como um controle de carga base ou parâmetro para rotinas de integração de ferramentas de BI.

## Dicionário de Dados Extraídos (Campos)
- `NRORG`: Número da Organização / Filial.
- `CDFORNECED`: Código interno do Fornecedor.
- `DSENDEFORN`, `NMBAIRFORN`, `NRCEPFORN`, `SGESTADO`: Dados de endereço (Logradouro, Bairro, CEP e UF).
- `IDTPIJURFORN`: Tipo de Pessoa (Física/Jurídica).
- `NRINSJURFORN`: CNPJ ou CPF.
- `NMRAZSOCFORN`, `NMFANTFORN`: Razão Social e Nome Fantasia.
- `TIPO_FORNECEDOR`, `GRUPO_FORNECEDOR`: Categorização do fornecedor.
- `TIPO_DESCONTO`: A classificação do desconto comercial negociado.
- `VRPEDESCFORN`: Percentual/Valor do desconto fornecido.
- `FORMA_PAGTO`: String consolidada detalhando como e em quantos dias o fornecedor é pago.
- `DTCADAFORN`: Data em que o cadastro do fornecedor foi criado.

## Exemplo de Resultado Esperado

| CDFORNECED | NMRAZSOCFORN | TIPO_DESCONTO | FORMA_PAGTO |
| :--- | :--- | :--- | :--- |
| 1001 | FORNECEDOR DE BEBIDAS LTDA | COMERCIAL | `( TRANSFERENCIA BANCARIA ) - 30 - 100%` |
| 1002 | PADARIA PÃO QUENTE | SEM DESCONTO | `Pagamento fixo no dia 10 com 2 parcela(s) - 15 - 50% \| 30 - 50%` |
| 1003 | DISTRIBUIDORA DE CARNES SA | BONIFICAÇÃO | `( BOLETO ) - 15 - 34% \| 30 - 33% \| 45 - 33%` |

---
**Dica de Manutenção:** Como a consulta utiliza `LEFT JOIN` com tabelas de detalhes (como `PRAZOPGTFORN` e `ENDEFORN`) e faz `GROUP BY` de muitas colunas atrelado a um `LISTAGG`, certifique-se de que essas tabelas filhas não possuam registros duplicados, o que poderia onerar a performance da extração.
