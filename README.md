# Query Hub - Teknisa BI

Bem-vindo ao **Query Hub**, o repositório central para armazenamento, organização e versionamento das consultas (queries) SQL utilizadas no [Teknisa BI](https://bi.teknisa.com/).

## 🎯 Objetivo

Este repositório foi criado para centralizar o conhecimento e garantir a padronização das extrações de dados do sistema Teknisa. Ter um repositório estruturado de queries é fundamental para:

- **Garantir a Consistência dos Dados:** Assegurar que diferentes painéis, dashboards e relatórios utilizem as mesmas regras de negócio e fontes da verdade.
- **Facilitar a Manutenção:** Centralizar as regras de extração permite que, em caso de mudanças estruturais no banco de dados (ERP Teknisa), os impactos sejam facilmente mapeados e os ajustes realizados em um só lugar.
- **Agilizar o Desenvolvimento:** Evitar o retrabalho ao permitir que analistas reaproveitem queries complexas que já foram validadas e homologadas.
- **Histórico e Versionamento:** Manter um registro das alterações nas consultas ao longo do tempo, auxiliando na compreensão de como e por que determinadas regras de negócio evoluíram.

## 📂 Organização do Repositório

Para facilitar a localização e manutenção, os dados estão organizados de forma lógica, divididos pelos principais domínios de negócio e módulos do sistema Teknisa:

- 📊 **`Controladoria/`**: Consultas relacionadas a custos, contabilidade, rateios e análises gerenciais (ex: Rateio por Nota Fiscal).
- 💰 **`Faturamento/`**: Consultas sobre vendas, notas fiscais emitidas, apuração de impostos e análises de receita.
- 👥 **`RH/`**: Consultas focadas em recursos humanos, departamento pessoal, folha de pagamento, ponto e benefícios (relacionadas ao HCM).
- 📦 **`Suprimentos/`**: Consultas abrangendo a cadeia de suprimentos, pedidos de compras, gestão de estoque e relacionamento com fornecedores.

*(Dentro de cada diretório principal, as consultas são agrupadas em subpastas por assunto específico, contendo o arquivo `.sql` correspondente.)*

## 🚀 Boas Práticas de Contribuição e Uso

Ao utilizar ou contribuir com novas queries para este repositório, por favor, siga estas diretrizes:

1. **Documentação Interna:** Toda query deve possuir comentários (`--` ou `/* */`) no cabeçalho explicando de forma resumida o objetivo da extração, filtros principais aplicados e particularidades importantes das regras de negócio.
2. **Nomenclatura Clara:** Os arquivos `.sql` e as pastas devem possuir nomes descritivos, facilitando a busca. Prefira nomes no formato `kebab-case` (ex: `rateio-por-nf.sql`).
3. **Formatação do Código SQL:** Utilize indentação e quebra de linhas adequadas para facilitar a leitura. Recomenda-se manter as palavras reservadas do SQL (SELECT, FROM, WHERE, JOIN, etc.) em letras maiúsculas.
4. **Parâmetros:** Caso a query exija filtros dinâmicos preenchidos pelo usuário no BI (como datas, filiais ou empresas), sinalize de forma clara no código onde esses filtros devem ser aplicados.

## 🔗 Links Úteis

- [Acesso ao portal Teknisa BI](https://bi.teknisa.com/)

---
*Repositório mantido pela equipe de Dados / BI.*
