-- ============================================================
-- 04_ANALYTICS.SQL
-- Projeto: Análise de Churn — SaaS B2C
-- Descrição: Queries analíticas progressivas
-- Executar APÓS 03_dml.sql
-- ============================================================
-- PROGRESSÃO:
--   Nível 1 → SELECT simples + filtros
--   Nível 2 → GROUP BY + agregações
--   Nível 3 → JOINs entre tabelas
--   Nível 4 → CTEs (Common Table Expressions)
--   Nível 5 → Window Functions
-- ============================================================


-- ============================================================
-- NÍVEL 1 — SELECT simples + filtros
-- ============================================================

-- Quais planos existem e quanto custam?
SELECT
    name,
    monthly_price,
    billing_cycle,
    max_users
FROM churn.plans
ORDER BY monthly_price;

-- Quais clientes vieram de São Paulo?
SELECT
    name,
    email,
    acquisition_channel,
    created_at
FROM churn.customers
WHERE state = 'SP'
ORDER BY created_at;

-- Quais assinaturas estão ativas hoje?
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

-- Quais faturas estão em atraso?
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
-- ============================================================
-- GROUP BY agrupa linhas com o mesmo valor em uma coluna.
-- Funções de agregação (COUNT, SUM, AVG, MIN, MAX)
-- calculam um valor para cada grupo.
-- ============================================================

-- Quantos clientes temos por canal de aquisição?
SELECT
    acquisition_channel,
    COUNT(*)                                            AS total_clientes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM churn.customers
GROUP BY acquisition_channel
ORDER BY total_clientes DESC;

-- Quantas assinaturas existem por status?
SELECT
    status,
    COUNT(*)        AS total,
    MIN(start_date) AS primeira_assinatura,
    MAX(start_date) AS ultima_assinatura
FROM churn.subscriptions
GROUP BY status
ORDER BY total DESC;

-- Qual o valor total faturado por status de pagamento?
SELECT
    status,
    COUNT(*)              AS qtd_faturas,
    SUM(amount)           AS valor_total,
    ROUND(AVG(amount), 2) AS ticket_medio
FROM churn.invoices
GROUP BY status
ORDER BY valor_total DESC;


-- ============================================================
-- NÍVEL 3 — JOINs
-- ============================================================
-- JOIN relaciona tabelas pela chave em comum.
-- Regra prática: comece pelo FROM (tabela base),
-- depois adicione JOINs pensando em qual coluna liga as tabelas.
-- INNER JOIN → só linhas que existem nos dois lados
-- LEFT JOIN  → todas do lado esquerdo + match do direito (NULL se não achar)
-- ============================================================

-- Clientes com assinatura ativa — nome do cliente + nome do plano
SELECT
    s.id_subscription,
    s.start_date,
    s.status,
    c.name AS nome_cliente,
    p.name AS nome_plano
FROM churn.subscriptions AS s
JOIN churn.customers AS c ON s.id_customer = c.id_customer
JOIN churn.plans     AS p ON s.id_plan     = p.id_plan
WHERE s.status = 'active';

-- Clientes que cancelaram e qual foi o motivo?
SELECT
    s.status,
    s.end_date      AS data_cancelamento,
    s.cancel_reason AS motivo,
    c.name          AS nome_cliente
FROM churn.subscriptions AS s
JOIN churn.customers AS c ON s.id_customer = c.id_customer
WHERE s.status = 'cancelled';

-- Clientes que abriram tickets de suporte
SELECT
    st.category  AS categoria,
    st.priority  AS prioridade,
    st.open_date AS data_abertura,
    c.name       AS nome_cliente
FROM churn.support_tickets AS st
JOIN churn.customers AS c ON st.id_customer = c.id_customer;

-- Clientes com faturas em atraso
-- caminho obrigatório: invoices → subscriptions → customers
SELECT
    i.amount   AS valor,
    i.due_date AS vencimento,
    c.name     AS nome_cliente
FROM churn.invoices AS i
JOIN churn.subscriptions AS s ON i.id_subscription = s.id_subscription
JOIN churn.customers     AS c ON s.id_customer     = c.id_customer
WHERE i.status = 'overdue';

-- Clientes que NUNCA abriram ticket de suporte
-- LEFT JOIN + IS NULL: traz quem NÃO aparece na segunda tabela
-- Sempre que a pergunta tiver "nunca", "sem" ou "que não tem" → esse padrão
SELECT
    c.name                AS nome_cliente,
    c.acquisition_channel AS canal_aquisicao
FROM churn.customers AS c
LEFT JOIN churn.support_tickets AS st ON c.id_customer = st.id_customer
WHERE st.id_customer IS NULL;

-- Eventos realizados por clientes de São Paulo
SELECT
    e.event_type AS tipo_evento,
    e.event_date AS data_evento,
    c.name       AS nome_cliente
FROM churn.events AS e
JOIN churn.customers AS c ON e.id_customer = c.id_customer
WHERE c.state = 'SP';

-- Cancelamentos por preço alto — qual era o plano contratado?
SELECT
    s.end_date      AS data_cancelamento,
    s.cancel_reason AS motivo,
    c.name          AS nome_cliente,
    p.name          AS nome_plano,
    p.monthly_price AS preco_mensal
FROM churn.subscriptions AS s
JOIN churn.customers AS c ON s.id_customer = c.id_customer
JOIN churn.plans     AS p ON s.id_plan     = p.id_plan
WHERE s.cancel_reason = 'too_expensive';

-- Clientes com assinatura ativa E ticket em aberto (sinal de risco)
SELECT
    s.status  AS status_assinatura,
    st.status AS status_ticket,
    c.name    AS nome_cliente
FROM churn.subscriptions AS s
JOIN churn.customers       AS c  ON s.id_customer = c.id_customer
JOIN churn.support_tickets AS st ON s.id_customer = st.id_customer
WHERE st.status IN ('open', 'in_progress')
  AND s.status = 'active';

-- Clientes que fizeram login com assinatura ativa (JOIN em 4 tabelas)
SELECT
    e.event_date AS data_evento,
    c.name       AS nome_cliente,
    p.name       AS nome_plano
FROM churn.events AS e
JOIN churn.customers     AS c ON e.id_customer = c.id_customer
JOIN churn.subscriptions AS s ON e.id_customer = s.id_customer
JOIN churn.plans         AS p ON p.id_plan     = s.id_plan
WHERE e.event_type = 'login'
  AND s.status = 'active';


-- ============================================================
-- NÍVEL 4 — CTEs (Common Table Expressions)
-- ============================================================
-- CTE = query nomeada e temporária, usada como se fosse uma tabela.
-- Resolve problemas em etapas — como um rascunho antes do resultado final.
-- Sintaxe: WITH nome AS ( query ) SELECT ... FROM nome
-- Vantagem: evita subqueries aninhadas, melhora legibilidade.
-- ============================================================

-- Clientes que cancelaram E também abriram ticket
WITH cancelados AS (
    SELECT id_customer, cancel_reason
    FROM churn.subscriptions
    WHERE status = 'cancelled'
)
SELECT
    cancelados.cancel_reason AS motivo,
    st.category              AS categoria_ticket,
    c.name                   AS nome_cliente
FROM cancelados
JOIN churn.customers       AS c  ON cancelados.id_customer = c.id_customer
JOIN churn.support_tickets AS st ON cancelados.id_customer = st.id_customer;

-- Clientes com mais de 1 ticket de suporte
WITH contagem_tickets AS (
    SELECT id_customer, COUNT(*) AS total_tickets
    FROM churn.support_tickets
    GROUP BY id_customer
    HAVING COUNT(*) > 1
)
SELECT
    contagem_tickets.total_tickets AS qtd_tickets,
    c.name                         AS nome_cliente
FROM contagem_tickets
JOIN churn.customers AS c ON contagem_tickets.id_customer = c.id_customer;

-- Clientes que gastaram mais de R$100 em faturas pagas
WITH total_pago AS (
    SELECT id_subscription, SUM(amount) AS total
    FROM churn.invoices
    WHERE status = 'paid'
    GROUP BY id_subscription
)
SELECT
    total_pago.total AS total_pago,
    c.name           AS nome_cliente
FROM total_pago
JOIN churn.subscriptions AS s ON s.id_subscription = total_pago.id_subscription
JOIN churn.customers     AS c ON c.id_customer     = s.id_customer
WHERE total_pago.total > 100;

-- Clientes que cancelaram MAS NUNCA abriram ticket
WITH cancelados AS (
    SELECT id_customer, cancel_reason
    FROM churn.subscriptions
    WHERE status = 'cancelled'
)
SELECT
    cancelados.cancel_reason AS motivo,
    c.name                   AS nome_cliente
FROM cancelados
JOIN churn.customers            AS c  ON cancelados.id_customer = c.id_customer
LEFT JOIN churn.support_tickets AS st ON c.id_customer          = st.id_customer
WHERE st.id_customer IS NULL;


-- ============================================================
-- NÍVEL 5 — Window Functions
-- ============================================================
-- Calculam sobre um conjunto de linhas SEM agrupá-las.
-- Diferença fundamental do GROUP BY:
--   GROUP BY  → colapsa linhas em um resultado por grupo
--   WINDOW FN → mantém todas as linhas e adiciona o cálculo ao lado
-- O OVER() define a "janela" de cálculo:
--   OVER (ORDER BY x)                 → calcula em ordem
--   OVER (PARTITION BY x)             → reinicia o cálculo por grupo
--   OVER (PARTITION BY x ORDER BY y)  → ordena dentro de cada grupo
-- ============================================================

-- Ranking de clientes por valor total pago
-- RANK(): classifica com empate — dois 1ºs lugares pula o 2º
SELECT
    c.name        AS nome_cliente,
    SUM(i.amount) AS total_pago,
    RANK() OVER (ORDER BY SUM(i.amount) DESC) AS ranking
FROM churn.invoices AS i
JOIN churn.subscriptions AS s ON i.id_subscription = s.id_subscription
JOIN churn.customers     AS c ON s.id_customer     = c.id_customer
GROUP BY c.name;

-- Total acumulado de faturas pagas ao longo do tempo
-- SUM() OVER(): acumula linha a linha — impossível de fazer com GROUP BY
SELECT
    due_date                             AS vencimento,
    amount                               AS valor,
    SUM(amount) OVER (ORDER BY due_date) AS total_acumulado
FROM churn.invoices
WHERE status = 'paid';

-- Ordem de cadastro dos clientes na plataforma
-- ROW_NUMBER(): numeração sequencial sem empate
SELECT
    ROW_NUMBER() OVER (ORDER BY created_at) AS ordem_cadastro,
    name                                     AS nome_cliente,
    created_at                               AS data_cadastro
FROM churn.customers;

-- Ranking de clientes por valor pago DENTRO DE CADA PLANO
-- PARTITION BY: reinicia o ranking para cada grupo (plano)
SELECT
    c.name        AS nome_cliente,
    p.name        AS nome_plano,
    SUM(i.amount) AS total_pago,
    RANK() OVER (PARTITION BY p.name ORDER BY SUM(i.amount) DESC) AS ranking_no_plano
FROM churn.invoices AS i
JOIN churn.subscriptions AS s ON i.id_subscription = s.id_subscription
JOIN churn.customers     AS c ON s.id_customer     = c.id_customer
JOIN churn.plans         AS p ON p.id_plan         = s.id_plan
WHERE i.status = 'paid'
GROUP BY c.name, p.name;