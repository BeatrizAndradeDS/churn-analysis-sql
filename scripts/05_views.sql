-- ============================================================
-- 05_VIEWS.SQL
-- Projeto: Análise de Churn — SaaS B2C
-- Descrição: Views para consultas recorrentes
-- Executar APÓS 03_dml.sql
-- ============================================================
-- O QUE É UMA VIEW?
-- View é uma query salva com nome dentro do banco.
-- Funciona como uma tabela virtual — você consulta com SELECT,
-- mas os dados vêm da query original em tempo real.
-- Não armazena dados: toda vez que você consulta uma view,
-- o banco executa a query por baixo.
--
-- QUANDO USAR VIEW?
-- → Queries complexas usadas com frequência (evita repetição)
-- → Simplificar acesso para analistas (expõe só o necessário)
-- → Padronizar colunas com nomes em português para relatórios
-- → Criar uma "camada semântica" sobre o banco técnico
--
-- CONVENÇÃO: prefixo "v_" identifica que é uma view.
-- PARA CONSULTAR: SELECT * FROM churn.nome_da_view;
-- ============================================================


-- ------------------------------------------------------------
-- VIEW: v_eventos_sp
-- Eventos realizados por clientes do estado de SP.
-- Uso: monitorar engajamento de clientes paulistas.
-- ------------------------------------------------------------

CREATE VIEW churn.v_eventos_sp AS
SELECT
    e.event_type AS tipo_evento,
    e.event_date AS data_evento,
    c.name       AS nome_cliente,
    c.state      AS estado
FROM churn.events AS e
JOIN churn.customers AS c ON e.id_customer = c.id_customer
WHERE c.state = 'SP';


-- ------------------------------------------------------------
-- VIEW: v_cancelamentos_preco
-- Cancelamentos com motivo "too_expensive" — nome do plano incluso.
-- Uso: entender quais planos perdem clientes por preço.
-- ------------------------------------------------------------

CREATE VIEW churn.v_cancelamentos_preco AS
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


-- ------------------------------------------------------------
-- VIEW: v_ativa_com_suporte
-- Clientes com assinatura ativa E ticket em aberto.
-- Uso: identificar clientes ativos em risco — precisam de atenção.
-- ------------------------------------------------------------

CREATE VIEW churn.v_ativa_com_suporte AS
SELECT
    s.status  AS status_plano,
    st.status AS status_suporte,
    c.name    AS nome_cliente
FROM churn.subscriptions AS s
JOIN churn.customers       AS c  ON s.id_customer = c.id_customer
JOIN churn.support_tickets AS st ON s.id_customer = st.id_customer
WHERE st.status IN ('open', 'in_progress')
  AND s.status = 'active';


-- ------------------------------------------------------------
-- VIEW: v_logins_ativos
-- Logins de clientes com assinatura ativa — com nome do plano.
-- Uso: monitorar engajamento dos clientes ativos no produto.
-- ------------------------------------------------------------

CREATE VIEW churn.v_logins_ativos AS
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
-- COMO CONSULTAR AS VIEWS
-- ============================================================

-- Lista todas as views do schema churn
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'churn';

-- Consultas diretas — simples como qualquer tabela
SELECT * FROM churn.v_eventos_sp;
SELECT * FROM churn.v_cancelamentos_preco;
SELECT * FROM churn.v_ativa_com_suporte;
SELECT * FROM churn.v_logins_ativos;