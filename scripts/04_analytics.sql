-- ============================================================
-- 04_ANALYTICS.SQL
-- Projeto: Análise de Churn — SaaS B2C
-- Descrição: Queries analíticas progressivas
-- Executar APÓS 03_dml.sql
-- ============================================================
-- PROGRESSÃO:
--   Nível 1 → SELECT simples + filtros
--   Nível 2 → GROUP BY + agregações
--   Nível 3 → JOINs (em construção)
--   Nível 4 → CTEs (em construção)
--   Nível 5 → Window Functions (em construção)
-- ============================================================


-- ============================================================
-- NÍVEL 1 — SELECT simples + filtros
-- ============================================================


-- Pergunta 1: Quais planos existem e quanto custam?

SELECT
    name,
    monthly_price,
    billing_cycle,
    max_users
FROM churn.plans
ORDER BY monthly_price;


-- Pergunta 2: Quais clientes vieram de São Paulo?

SELECT
    name,
    email,
    acquisition_channel,
    created_at
FROM churn.customers
WHERE state = 'SP'
ORDER BY created_at;


-- Pergunta 3: Quais assinaturas estão ativas hoje?
-- end_date NULL = contrato ainda em vigor

SELECT
    id_subscription,
    id_customer,
    id_plan,
    start_date,
    status
FROM churn.subscriptions
WHERE status = 'active'
ORDER BY start_date;


-- Pergunta 4: Quais faturas estão em atraso?
-- Inadimplência é um dos principais preditores de churn

SELECT
    id_invoice,
    id_subscription,
    amount,
    due_date,
    status
FROM churn.invoices
WHERE status = 'overdue'
ORDER BY due_date;


-- ============================================================
-- NÍVEL 2 — GROUP BY + agregações
-- GROUP BY agrupa linhas com o mesmo valor.
-- Funções de agregação (COUNT, SUM, AVG, MIN, MAX)
-- calculam um valor para cada grupo.
-- ============================================================


-- Pergunta 5: Quantos clientes temos por canal de aquisição?

SELECT
    acquisition_channel,
    COUNT(*)                                             AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)  AS pct
FROM churn.customers
GROUP BY acquisition_channel
ORDER BY total_customers DESC;


-- Pergunta 6: Quantas assinaturas existem por status?
-- Responde: quantos clientes deram churn vs estão ativos?

SELECT
    status,
    COUNT(*)          AS total,
    MIN(start_date)   AS primeira_assinatura,
    MAX(start_date)   AS ultima_assinatura
FROM churn.subscriptions
GROUP BY status
ORDER BY total DESC;


-- Pergunta 7: Qual o valor total faturado por status de pagamento?
-- Permite identificar quanto está em risco (overdue + pending)

SELECT
    status,
    COUNT(*)               AS qtd_faturas,
    SUM(amount)            AS valor_total,
    ROUND(AVG(amount), 2)  AS ticket_medio
FROM churn.invoices
GROUP BY status
ORDER BY valor_total DESC;
