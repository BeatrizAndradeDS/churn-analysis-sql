# 📊 Análise de Churn — SaaS B2C com PostgreSQL

Projeto de análise de churn construído do zero em PostgreSQL, simulando o ambiente de dados de uma empresa SaaS com assinaturas mensais e anuais.

O objetivo é demonstrar capacidade técnica end-to-end: desde a modelagem do banco até queries analíticas avançadas, passando por boas práticas de engenharia de dados.

---

## Problema de Negócio

Churn é a taxa de cancelamento de clientes em um período. Em empresas SaaS, reduzir o churn em 5% pode aumentar a receita em até 25%.

Este projeto responde perguntas reais de negócio:

- Qual é a taxa de churn mensal?
- Quais planos têm maior índice de cancelamento?
- Qual o LTV médio dos clientes antes do churn?
- Clientes com mais tickets de suporte churnam mais?
- Quais clientes estão em risco nos próximos 30 dias?

---

## Estrutura do Projeto

```
churn-analysis-sql/
│
├── scripts/
│   ├── 01_schema.sql        # Criação do schema
│   ├── 02_ddl.sql           # Criação das tabelas com constraints
│   ├── 03_dml.sql           # Inserção de dados fictícios realistas
│   ├── 04_analytics.sql     # Queries analíticas (Níveis 1 ao 5)
│   ├── 05_views.sql         # Views para consultas recorrentes
│   └── 06_indexes.sql       # Índices e otimização com EXPLAIN
│
├── docs/                    # Diagramas e documentação visual
├── data/                    # Dados exportados em CSV
├── .gitignore
└── README.md
```

---

## Modelagem de Dados

O modelo foi projetado para suportar análise histórica de churn — cada assinatura é registrada como um evento independente, preservando o histórico completo do cliente.

### Entidades

| Tabela | Descrição |
|---|---|
| `customers` | Dados cadastrais e canal de aquisição |
| `plans` | Planos disponíveis e preços |
| `subscriptions` | Histórico de contratos por cliente (tabela central) |
| `invoices` | Faturas geradas por assinatura |
| `support_tickets` | Chamados abertos pelo cliente |
| `events` | Log comportamental no produto |

### Decisões técnicas

- `NUMERIC(10,2)` para valores monetários — evita imprecisão de FLOAT
- `CHECK constraints` para garantir integridade nos campos de status
- Modelagem orientada a histórico — assinaturas nunca são sobrescritas
- Constraint de dependência entre campos: `status = 'paid'` exige `payment_date`

---

## Tecnologias

- **PostgreSQL 18**
- **pgAdmin 4**
- **VS Code**
- **Git / GitHub**

---

## Como Executar

### Pré-requisitos
- PostgreSQL instalado (versão 15+)
- pgAdmin ou qualquer client SQL

### Passo a passo

```sql
-- 1. Crie o database
CREATE DATABASE churn_analysis;

-- 2. Execute os scripts na ordem:
-- 01_schema.sql → 02_ddl.sql → 03_dml.sql
-- → 04_analytics.sql → 05_views.sql → 06_indexes.sql
```

---

## Análises Implementadas

### Nível 1 — SELECT + filtros
Perguntas diretas sobre uma tabela: planos disponíveis, clientes por estado, assinaturas ativas, faturas em atraso.

### Nível 2 — GROUP BY + agregações
Distribuição de clientes por canal de aquisição, receita por status de pagamento, ticket médio por status.

### Nível 3 — JOINs
Relacionamento entre tabelas para responder perguntas cruzadas:
- Clientes ativos com nome do plano
- Clientes que cancelaram e o motivo
- Clientes com faturas em atraso (JOIN em cadeia: invoices → subscriptions → customers)
- Clientes que nunca abriram ticket (LEFT JOIN + IS NULL)

### Nível 4 — CTEs (Common Table Expressions)
Queries em etapas para responder perguntas mais complexas:
- Clientes que cancelaram e também abriram tickets
- Clientes com mais de um ticket de suporte
- Clientes que gastaram mais de R$100 em faturas pagas
- Clientes que cancelaram mas nunca abriram ticket (CTE + LEFT JOIN + IS NULL)

### Nível 5 — Window Functions
Cálculos analíticos sem perder o detalhe das linhas:
- Ranking de clientes por valor total pago (`RANK`)
- Total acumulado de faturas pagas ao longo do tempo (`SUM OVER`)
- Ordem de cadastro dos clientes (`ROW_NUMBER`)
- Ranking por valor pago dentro de cada plano (`RANK + PARTITION BY`)

---

## Views Criadas

Views são queries salvas com nome no banco — consultadas como tabelas, mas calculadas em tempo real.

| View | Descrição |
|------|-----------|
| `v_eventos_sp` | Eventos de clientes de São Paulo |
| `v_cancelamentos_preco` | Cancelamentos por motivo "too_expensive" |
| `v_ativa_com_suporte` | Clientes com assinatura ativa e ticket em aberto |
| `v_logins_ativos` | Logins de clientes com assinatura ativa |

---

## Otimização

Índices criados para acelerar as queries mais frequentes do projeto:

| Índice | Tabela | Coluna | Justificativa |
|--------|--------|--------|---------------|
| `idx_subscriptions_status` | subscriptions | status | Filtro em toda query de churn |
| `idx_subscriptions_customer` | subscriptions | id_customer | JOIN frequente com customers |
| `idx_invoices_status` | invoices | status | Filtro de inadimplência |
| `idx_invoices_subscription` | invoices | id_subscription | JOIN com subscriptions |
| `idx_tickets_customer` | support_tickets | id_customer | JOIN com customers |
| `idx_events_customer` | events | id_customer | Tabela de alto volume |

---

## Autora

**Beatriz Andrade**

Analista de Dados com experiência em preparação, análise e visualização de dados para apoio à tomada de decisão estratégica. Atuação como elo entre áreas de negócio, liderança e dados, com histórico em indicadores, dashboards executivos e geração de insights acionáveis.

Pós-graduada em Ciência de Dados (Data Science Academy, 2026). Experiência prática com Power BI, Python (pandas) e SQL.

[LinkedIn](https://www.linkedin.com/in/andrade-beatriz/) | [GitHub](https://github.com/BeatrizAndradeDS)

---

> Projeto desenvolvido para portfólio em Data Analytics. Todos os dados são fictícios.
> Desenvolvido com orientação técnica incremental, priorizando compreensão sobre cada decisão de modelagem e SQL.