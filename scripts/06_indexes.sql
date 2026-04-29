-- ============================================================
-- 06_INDEXES.SQL
-- Projeto: Análise de Churn — SaaS B2C
-- Descrição: Otimização de queries com índices e EXPLAIN
-- Executar APÓS 03_dml.sql
-- ============================================================
-- O QUE É UM ÍNDICE?
-- Índice é uma estrutura auxiliar que acelera buscas no banco.
-- Analogia: índice de um livro — em vez de ler página por página,
-- você vai direto na página certa.
-- Sem índice: o banco lê TODAS as linhas (sequential scan).
-- Com índice: o banco vai direto às linhas relevantes (index scan).
--
-- QUANDO CRIAR ÍNDICE?
-- → Colunas usadas frequentemente em WHERE
-- → Colunas usadas em JOIN (FKs já têm índice automático no PK)
-- → Colunas usadas em ORDER BY com grandes volumes
--
-- CUIDADO: índice acelera leitura mas desacelera escrita.
-- Cada INSERT/UPDATE/DELETE precisa atualizar o índice também.
-- Não crie índice em toda coluna — só onde há ganho real.
-- ============================================================


-- ============================================================
-- BLOCO 1 — VER O PLANO DE EXECUÇÃO COM EXPLAIN
-- ============================================================
-- EXPLAIN mostra como o PostgreSQL vai executar uma query.
-- EXPLAIN ANALYZE executa e mostra o tempo real.
-- Termos importantes:
--   Seq Scan   → leu todas as linhas (sem índice)
--   Index Scan → usou índice (eficiente)
--   cost=X..Y  → estimativa de custo (menor = melhor)
--   rows=N     → estimativa de linhas retornadas
--   actual time → tempo real de execução (com ANALYZE)
-- ============================================================

-- Antes do índice: veja o plano de execução
EXPLAIN ANALYZE
SELECT *
FROM churn.subscriptions
WHERE status = 'cancelled';

-- Resultado esperado sem índice:
-- Seq Scan on subscriptions (lê todas as linhas)


-- ============================================================
-- BLOCO 2 — CRIAR ÍNDICES
-- ============================================================

-- Índice em subscriptions.status
-- Justificativa: quase toda query de churn filtra por status.
-- Sem índice, o banco lê todas as 22 linhas para achar 'cancelled'.
-- Com índice, vai direto nas linhas com status = 'cancelled'.
CREATE INDEX IF NOT EXISTS idx_subscriptions_status
    ON churn.subscriptions (status);


-- Índice em subscriptions.id_customer
-- Justificativa: JOIN frequente com customers.
-- PostgreSQL cria índice automático na PK (id_customer em customers),
-- mas não cria na FK (id_customer em subscriptions) — precisamos criar.
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer
    ON churn.subscriptions (id_customer);


-- Índice em invoices.status
-- Justificativa: queries de inadimplência filtram por status = 'overdue'.
CREATE INDEX IF NOT EXISTS idx_invoices_status
    ON churn.invoices (status);


-- Índice em invoices.id_subscription
-- Justificativa: JOIN frequente entre invoices e subscriptions.
CREATE INDEX IF NOT EXISTS idx_invoices_subscription
    ON churn.invoices (id_subscription);


-- Índice em support_tickets.id_customer
-- Justificativa: JOIN frequente com customers para análise de tickets.
CREATE INDEX IF NOT EXISTS idx_tickets_customer
    ON churn.support_tickets (id_customer);


-- Índice em events.id_customer
-- Justificativa: events cresce rápido — filtrar por cliente sem índice
-- seria cada vez mais lento conforme a tabela cresce.
CREATE INDEX IF NOT EXISTS idx_events_customer
    ON churn.events (id_customer);


-- ============================================================
-- BLOCO 3 — APÓS ÍNDICE: COMPARAR O PLANO DE EXECUÇÃO
-- ============================================================

-- Rode novamente após criar os índices e compare:
EXPLAIN ANALYZE
SELECT *
FROM churn.subscriptions
WHERE status = 'cancelled';

-- Resultado esperado com índice:
-- Index Scan using idx_subscriptions_status on subscriptions
-- Tempo menor, custo menor


-- Outro exemplo — query com JOIN:
EXPLAIN ANALYZE
SELECT
    c.name,
    s.status,
    s.start_date
FROM churn.subscriptions AS s
JOIN churn.customers AS c ON s.id_customer = c.id_customer
WHERE s.status = 'active';


-- ============================================================
-- BLOCO 4 — LISTAR ÍNDICES CRIADOS
-- ============================================================

-- Lista todos os índices do schema churn
SELECT
    indexname  AS nome_indice,
    tablename  AS tabela,
    indexdef   AS definicao
FROM pg_indexes
WHERE schemaname = 'churn'
ORDER BY tablename, indexname;