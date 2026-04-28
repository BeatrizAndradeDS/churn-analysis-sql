-- ============================================================
-- 02_DDL.SQL
-- Projeto: Análise de Churn — SaaS B2C
-- Descrição: Criação das tabelas do projeto
-- Executar APÓS 01_schema.sql
-- ============================================================
-- ORDEM DE CRIAÇÃO (respeita dependências de FK):
--   1. plans
--   2. customers
--   3. subscriptions
--   4. invoices
--   5. support_tickets
--   6. events
-- ============================================================


-- ------------------------------------------------------------
-- TABELA: plans
-- Tabela de referência — contém os planos disponíveis.
-- Criada primeiro porque subscriptions depende dela via FK.
-- NUMERIC(10,2) para preço: nunca use FLOAT para dinheiro.
-- CHECK em billing_cycle: só aceita 'monthly' ou 'annual'.
-- ------------------------------------------------------------

CREATE TABLE churn.plans (
    id_plan       SERIAL PRIMARY KEY,
    name          VARCHAR(50)    NOT NULL,
    monthly_price NUMERIC(10,2)  NOT NULL CHECK (monthly_price > 0),
    billing_cycle VARCHAR(10)    NOT NULL CHECK (billing_cycle IN ('monthly', 'annual')),
    max_users     INTEGER        NOT NULL DEFAULT 1,
    is_active     BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP      NOT NULL DEFAULT NOW()
);


-- ------------------------------------------------------------
-- TABELA: customers
-- Dados cadastrais do cliente.
-- UNIQUE no email: dois clientes não podem ter o mesmo email.
-- CHECK em acquisition_channel: lista fixa de canais permitidos.
-- created_at é crítico: permite calcular tempo de vida do cliente.
-- ------------------------------------------------------------

CREATE TABLE churn.customers (
    id_customer         SERIAL PRIMARY KEY,
    name                VARCHAR(100)  NOT NULL,
    email               VARCHAR(150)  NOT NULL UNIQUE,
    city                VARCHAR(100),
    state               CHAR(2),
    birth_date          DATE,
    acquisition_channel VARCHAR(50)   CHECK (acquisition_channel IN (
                            'organic', 'paid_ads', 'referral', 'social_media', 'email_campaign'
                        )),
    created_at          TIMESTAMP     NOT NULL DEFAULT NOW()
);


-- ------------------------------------------------------------
-- TABELA: subscriptions
-- Entidade central do modelo de churn.
-- Um cliente pode ter múltiplas linhas (histórico de contratos).
-- Nunca sobrescreve — sempre registra novo contrato.
-- end_date NULL = assinatura ainda ativa.
-- status define se o cliente deu churn ou não.
-- CONSTRAINT chk_dates: end_date nunca antes de start_date.
-- ------------------------------------------------------------

CREATE TABLE churn.subscriptions (
    id_subscription SERIAL PRIMARY KEY,
    id_customer     INTEGER       NOT NULL REFERENCES churn.customers(id_customer),
    id_plan         INTEGER       NOT NULL REFERENCES churn.plans(id_plan),
    start_date      DATE          NOT NULL,
    end_date        DATE,
    status          VARCHAR(20)   NOT NULL DEFAULT 'active'
                                  CHECK (status IN ('active','cancelled','expired','paused')),
    cancel_reason   TEXT,
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_dates CHECK (end_date IS NULL OR end_date >= start_date)
);


-- ------------------------------------------------------------
-- TABELA: invoices
-- Cada cobrança gerada por uma assinatura.
-- Vinculada à subscription, não diretamente ao customer.
-- CONSTRAINT chk_payment: se status = 'paid', payment_date
-- é obrigatório. Exemplo de dependência entre campos.
-- ------------------------------------------------------------

CREATE TABLE churn.invoices (
    id_invoice      SERIAL PRIMARY KEY,
    id_subscription INTEGER       NOT NULL REFERENCES churn.subscriptions(id_subscription),
    amount          NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    due_date        DATE          NOT NULL,
    payment_date    DATE,
    status          VARCHAR(20)   NOT NULL DEFAULT 'pending'
                                  CHECK (status IN ('paid', 'pending', 'overdue', 'refunded')),
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_payment CHECK (
        (status = 'paid' AND payment_date IS NOT NULL) OR
        (status != 'paid')
    )
);


-- ------------------------------------------------------------
-- TABELA: support_tickets
-- Chamados abertos pelo cliente.
-- Alto volume de tickets é sinal comportamental de risco de churn.
-- category é padronizada (para análise agregada).
-- description é texto livre (para contexto qualitativo).
-- ------------------------------------------------------------

CREATE TABLE churn.support_tickets (
    id_ticket   SERIAL PRIMARY KEY,
    id_customer INTEGER       NOT NULL REFERENCES churn.customers(id_customer),
    category    VARCHAR(50)   NOT NULL CHECK (category IN (
                    'financial', 'technical', 'cancellation', 'billing', 'other'
                )),
    priority    VARCHAR(20)   NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status      VARCHAR(20)   NOT NULL DEFAULT 'open'
                              CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    open_date   TIMESTAMP     NOT NULL DEFAULT NOW(),
    close_date  TIMESTAMP,
    description TEXT,

    CONSTRAINT chk_close_date CHECK (
        close_date IS NULL OR close_date >= open_date
    )
);


-- ------------------------------------------------------------
-- TABELA: events
-- Log comportamental do cliente no produto.
-- Clientes que param de fazer login são sinal de risco de churn.
-- ------------------------------------------------------------

CREATE TABLE churn.events (
    id_event         SERIAL PRIMARY KEY,
    id_customer      INTEGER       NOT NULL REFERENCES churn.customers(id_customer),
    event_type       VARCHAR(50)   NOT NULL CHECK (event_type IN (
                         'login', 'feature_use', 'export', 'settings_change', 'api_call'
                     )),
    event_date       TIMESTAMP     NOT NULL DEFAULT NOW(),
    duration_seconds INTEGER       CHECK (duration_seconds >= 0)
);


-- ------------------------------------------------------------
-- VERIFICAÇÃO: lista todas as colunas criadas
-- Resultado esperado: 43 linhas
-- ------------------------------------------------------------

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'churn'
ORDER BY table_name, ordinal_position;
