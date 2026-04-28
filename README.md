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
│   ├── 01_schema.sql       # Criação do schema
│   ├── 02_ddl.sql          # Criação das tabelas
│   ├── 03_dml.sql          # Inserção de dados fictícios
│   └── 04_analytics.sql    # Queries analíticas
│
├── docs/                   # Diagramas e documentação visual
├── data/                   # Dados exportados em CSV
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
| `subscriptions` | Histórico de contratos por cliente |
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
-- 01_schema.sql → 02_ddl.sql → 03_dml.sql → 04_analytics.sql
```

Execute cada arquivo dentro do database `churn_analysis` no pgAdmin ou via terminal.

---

## Análises Implementadas

### Nível 1 — Filtros e seleções
- Planos disponíveis por preço
- Clientes por estado
- Assinaturas ativas
- Faturas em atraso

### Nível 2 — Agregações
- Distribuição de clientes por canal de aquisição
- Volume de assinaturas por status
- Receita total por status de pagamento

### Em construção 🚧
- JOINs entre tabelas para visão consolidada do cliente
- CTEs para cálculo de churn mensal
- Window Functions para ranking e análise temporal
- Views para KPIs de retenção e LTV
- Otimização com índices e EXPLAIN

---

## Autora

**Beatriz Andrade**
[GitHub](https://github.com/BeatrizAndradeDS)

---

> Projeto desenvolvido para portfólio em Data Analytics.
> Todos os dados são fictícios, gerados para fins educacionais.