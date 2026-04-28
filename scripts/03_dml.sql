-- ============================================================
-- 03_DML.SQL
-- Projeto: Análise de Churn — SaaS B2C
-- Descrição: Inserção de dados fictícios realistas
-- Executar APÓS 02_ddl.sql
-- ============================================================
-- ORDEM DE INSERÇÃO (respeita dependências de FK):
--   1. plans → 2. customers → 3. subscriptions
--   → 4. invoices → 5. support_tickets → 6. events
-- ============================================================


-- ------------------------------------------------------------
-- INSERT: plans
-- 4 planos mensais + 2 anuais.
-- ------------------------------------------------------------

INSERT INTO churn.plans
    (name, monthly_price, billing_cycle, max_users, is_active)
VALUES
    ('Basic',        29.90,  'monthly', 1,  true),
    ('Standard',     59.90,  'monthly', 3,  true),
    ('Pro',          99.90,  'monthly', 10, true),
    ('Super Pro',   199.90,  'monthly', 30, true),
    ('Basic Annual', 299.90, 'annual',  1,  true),
    ('Pro Annual',   999.90, 'annual',  10, true);


-- ------------------------------------------------------------
-- INSERT: customers
-- 20 clientes de diferentes estados e canais de aquisição.
-- Datas distribuídas ao longo de 2023 para análises temporais.
-- ------------------------------------------------------------

INSERT INTO churn.customers
    (name, email, city, state, birth_date, acquisition_channel, created_at)
VALUES
    ('Ana Lima',        'ana.lima@email.com',       'São Paulo',      'SP', '1990-03-15', 'organic',        '2023-01-10'),
    ('Bruno Souza',     'bruno.souza@email.com',    'Rio de Janeiro', 'RJ', '1985-07-22', 'paid_ads',       '2023-01-15'),
    ('Carla Mendes',    'carla.mendes@email.com',   'Curitiba',       'PR', '1992-11-30', 'referral',       '2023-02-01'),
    ('Diego Castro',    'diego.castro@email.com',   'Belo Horizonte', 'MG', '1988-05-10', 'social_media',   '2023-02-14'),
    ('Eva Rodrigues',   'eva.rodrigues@email.com',  'Porto Alegre',   'RS', '1995-09-08', 'email_campaign', '2023-03-05'),
    ('Felipe Nunes',    'felipe.nunes@email.com',   'Salvador',       'BA', '1991-01-25', 'organic',        '2023-03-20'),
    ('Gabriela Alves',  'gabi.alves@email.com',     'Fortaleza',      'CE', '1993-06-17', 'paid_ads',       '2023-04-02'),
    ('Henrique Costa',  'h.costa@email.com',        'Recife',         'PE', '1987-12-03', 'referral',       '2023-04-18'),
    ('Isabela Martins', 'isa.martins@email.com',    'Manaus',         'AM', '1996-04-22', 'social_media',   '2023-05-07'),
    ('João Ferreira',   'joao.ferreira@email.com',  'Brasília',       'DF', '1983-08-14', 'organic',        '2023-05-19'),
    ('Karen Oliveira',  'karen.oli@email.com',      'São Paulo',      'SP', '1994-02-28', 'paid_ads',       '2023-06-03'),
    ('Lucas Pereira',   'lucas.p@email.com',        'Campinas',       'SP', '1990-10-11', 'email_campaign', '2023-06-15'),
    ('Mariana Torres',  'mari.torres@email.com',    'Florianópolis',  'SC', '1989-07-30', 'referral',       '2023-07-01'),
    ('Nicolas Araújo',  'nic.araujo@email.com',     'Goiânia',        'GO', '1997-03-19', 'organic',        '2023-07-22'),
    ('Olivia Santos',   'oli.santos@email.com',     'São Paulo',      'SP', '1992-11-05', 'social_media',   '2023-08-08'),
    ('Paulo Ribeiro',   'paulo.rib@email.com',      'Rio de Janeiro', 'RJ', '1986-06-23', 'paid_ads',       '2023-08-25'),
    ('Quintina Rocha',  'quin.rocha@email.com',     'Natal',          'RN', '1995-01-14', 'email_campaign', '2023-09-10'),
    ('Rafael Lima',     'rafa.lima@email.com',      'São Paulo',      'SP', '1991-09-27', 'organic',        '2023-09-28'),
    ('Sandra Vieira',   'san.vieira@email.com',     'Curitiba',       'PR', '1988-04-06', 'referral',       '2023-10-15'),
    ('Thiago Campos',   'thi.campos@email.com',     'Belém',          'PA', '1993-12-20', 'paid_ads',       '2023-10-30');


-- ------------------------------------------------------------
-- INSERT: subscriptions
-- 22 assinaturas simulando cenários reais:
--   - Clientes ativos (end_date NULL)
--   - Clientes que cancelaram
--   - Cliente que cancelou e voltou (Diego Castro — 2 linhas)
--   - Clientes com plano expirado
-- Modelagem orientada a histórico: nunca sobrescreve.
-- ------------------------------------------------------------

INSERT INTO churn.subscriptions
    (id_customer, id_plan, start_date, end_date, status, cancel_reason)
VALUES
-- Clientes ativos
    (1,  1, '2023-01-10', NULL,         'active',    NULL),
    (2,  3, '2023-01-15', NULL,         'active',    NULL),
    (3,  2, '2023-02-01', NULL,         'active',    NULL),
    (5,  4, '2023-03-05', NULL,         'active',    NULL),
    (10, 6, '2023-05-19', NULL,         'active',    NULL),
    (12, 3, '2023-06-15', NULL,         'active',    NULL),
    (15, 2, '2023-08-08', NULL,         'active',    NULL),
    (18, 1, '2023-09-28', NULL,         'active',    NULL),

-- Clientes que cancelaram
    (4,  1, '2023-02-14', '2023-05-14', 'cancelled', 'too_expensive'),
    (6,  2, '2023-03-20', '2023-06-20', 'cancelled', 'not_using'),
    (7,  1, '2023-04-02', '2023-07-02', 'cancelled', 'too_expensive'),
    (8,  3, '2023-04-18', '2023-08-18', 'cancelled', 'found_competitor'),
    (9,  2, '2023-05-07', '2023-08-07', 'cancelled', 'not_using'),
    (11, 1, '2023-06-03', '2023-09-03', 'cancelled', 'too_expensive'),
    (13, 2, '2023-07-01', '2023-10-01', 'cancelled', 'not_using'),
    (16, 3, '2023-08-25', '2023-11-25', 'cancelled', 'found_competitor'),
    (17, 1, '2023-09-10', '2023-12-10', 'cancelled', 'too_expensive'),
    (19, 2, '2023-10-15', '2024-01-15', 'cancelled', 'not_using'),

-- Diego Castro: cancelou em maio/2023, voltou em setembro/2023
-- Duas linhas para o mesmo cliente = histórico preservado
    (4,  2, '2023-09-01', NULL,         'active',    NULL),
    (9,  1, '2024-01-20', '2024-04-20', 'cancelled', 'too_expensive'),

-- Planos expirados
    (14, 1, '2023-07-22', '2024-01-22', 'expired',   NULL),
    (20, 2, '2023-10-30', '2024-04-30', 'expired',   NULL);


-- ------------------------------------------------------------
-- INSERT: invoices
-- Faturas vinculadas às assinaturas.
-- Inclui pagamentos em dia, atrasados e pendentes.
-- Permite calcular LTV (soma de faturas pagas por cliente).
-- ------------------------------------------------------------

INSERT INTO churn.invoices
    (id_subscription, amount, due_date, payment_date, status)
VALUES
-- Sub 1 (Ana Lima - Basic ativo)
    (1, 29.90, '2023-02-10', '2023-02-09', 'paid'),
    (1, 29.90, '2023-03-10', '2023-03-10', 'paid'),
    (1, 29.90, '2023-04-10', '2023-04-11', 'paid'),
    (1, 29.90, '2023-05-10', '2023-05-10', 'paid'),
    (1, 29.90, '2023-06-10', NULL,         'overdue'),

-- Sub 2 (Bruno Souza - Pro ativo)
    (2, 99.90, '2023-02-15', '2023-02-15', 'paid'),
    (2, 99.90, '2023-03-15', '2023-03-14', 'paid'),
    (2, 99.90, '2023-04-15', '2023-04-15', 'paid'),

-- Sub 9 (Diego Castro - cancelou)
    (9, 29.90, '2023-03-14', '2023-03-14', 'paid'),
    (9, 29.90, '2023-04-14', '2023-04-15', 'paid'),
    (9, 29.90, '2023-05-14', NULL,         'overdue'),

-- Sub 19 (Diego voltou - Standard)
    (19, 59.90, '2023-10-01', '2023-10-01', 'paid'),
    (19, 59.90, '2023-11-01', '2023-11-02', 'paid'),
    (19, 59.90, '2023-12-01', NULL,          'pending');


-- ------------------------------------------------------------
-- INSERT: support_tickets
-- Clientes com múltiplos tickets de alta prioridade
-- são candidatos a churn — vira métrica de análise.
-- ------------------------------------------------------------

INSERT INTO churn.support_tickets
    (id_customer, category, priority, status, open_date, close_date, description)
VALUES
    (4,  'financial',    'high',     'closed',   '2023-04-10', '2023-04-12', 'Cobrança indevida no cartão'),
    (4,  'cancellation', 'medium',   'closed',   '2023-05-10', '2023-05-11', 'Solicitação de cancelamento'),
    (6,  'technical',    'low',      'closed',   '2023-05-15', '2023-05-20', 'Erro ao exportar relatório'),
    (7,  'financial',    'high',     'closed',   '2023-06-01', '2023-06-02', 'Contestação de cobrança'),
    (8,  'technical',    'critical', 'closed',   '2023-07-10', '2023-07-11', 'Sistema fora do ar'),
    (8,  'cancellation', 'medium',   'closed',   '2023-08-15', '2023-08-15', 'Encontrou concorrente mais barato'),
    (9,  'technical',    'low',      'closed',   '2023-06-20', '2023-06-25', 'Dúvida sobre funcionalidade'),
    (11, 'financial',    'high',     'closed',   '2023-08-01', '2023-08-03', 'Cobrança duplicada'),
    (1,  'technical',    'low',      'resolved', '2023-11-05', '2023-11-06', 'Dúvida sobre integração'),
    (2,  'billing',      'medium',   'open',     '2023-11-20', NULL,         'Nota fiscal não recebida');


-- ------------------------------------------------------------
-- INSERT: events
-- Log de comportamento no produto.
-- Clientes inativos (sem login recente) = risco de churn.
-- ------------------------------------------------------------

INSERT INTO churn.events
    (id_customer, event_type, event_date, duration_seconds)
VALUES
    (1,  'login',          '2023-11-01 08:30:00', 0),
    (1,  'feature_use',    '2023-11-01 08:35:00', 320),
    (1,  'export',         '2023-11-01 09:10:00', 45),
    (2,  'login',          '2023-11-02 14:00:00', 0),
    (2,  'feature_use',    '2023-11-02 14:05:00', 780),
    (4,  'login',          '2023-11-03 10:00:00', 0),
    (4,  'feature_use',    '2023-11-03 10:10:00', 120),
    (8,  'login',          '2023-10-01 09:00:00', 0),
    (9,  'login',          '2023-07-15 11:00:00', 0),
    (9,  'settings_change','2023-07-15 11:05:00', 60),
    (10, 'login',          '2023-11-10 07:45:00', 0),
    (10, 'api_call',       '2023-11-10 07:46:00', 15),
    (10, 'api_call',       '2023-11-10 07:47:00', 12),
    (15, 'login',          '2023-11-08 16:00:00', 0),
    (15, 'feature_use',    '2023-11-08 16:10:00', 450);


-- ------------------------------------------------------------
-- VERIFICAÇÃO FINAL
-- Resultado esperado:
--   customers       20
--   plans            6
--   subscriptions   22
--   invoices        14
--   support_tickets 10
--   events          15
-- ------------------------------------------------------------

SELECT 'customers'       AS tabela, COUNT(*) AS registros FROM churn.customers
UNION ALL
SELECT 'plans',                     COUNT(*) FROM churn.plans
UNION ALL
SELECT 'subscriptions',             COUNT(*) FROM churn.subscriptions
UNION ALL
SELECT 'invoices',                  COUNT(*) FROM churn.invoices
UNION ALL
SELECT 'support_tickets',           COUNT(*) FROM churn.support_tickets
UNION ALL
SELECT 'events',                    COUNT(*) FROM churn.events;
