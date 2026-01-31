--- ANALISE INICIAL LOG ---
SELECT COUNT(*) as "Total Linhas(Log)"
FROM table_log;

SELECT order_last_status as "Status", 
COUNT(*) as total
FROM table_log
GROUP BY order_last_status;

SELECT delivery_method as Modo_de_entrega,
COUNT (*) as Total
FROM table_log
GROUP BY delivery_method
ORDER BY COUNT(*) DESC;

SELECT TOP 1
merchant_frn_id as ID_comercial,
Count (*) as "mais pedido"
from table_log
WHERE merchant_frn_id IS NOT NULL
GROUP BY  merchant_frn_id
ORDER BY COUNT(*) DESC;

SELECT merchant_commercial_group as Grupo_Comercial,
COUNT (*) as Total
FROM table_log
GROUP BY merchant_commercial_group;

SELECT driver_modal_cluster as Veiculos,
COUNT(*) as "mais utilizado"
FROM table_log
WHERE driver_modal_cluster IS NOT NULL
GROUP BY driver_modal_cluster
ORDER BY COUNT(*) DESC;

--- ANALISE INICIAL OPS/ DADOS PERDIDOS --- 
SELECT COUNT(*) as "Total linhas(Ops)"
FROM table_ops;

select picking_sla as Separacao,
COUNT(*) as Total
FROM table_ops
GROUP BY picking_sla
ORDER BY COUNT(*) DESC;

SELECT
    COUNT(*) AS total_registros,
    COUNT(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp')) AS registros_com_valor,
    COUNT(*) - COUNT(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp')) AS registros_null
FROM table_ops;

-- desfragmentando estrutura JSON OPS -- 
SELECT

	JSON_VALUE(picking_app_timestamps, '$.picking_started_timestamp') as Inicio_Separacao,
	JSON_VALUE(picking_app_timestamps, '$.picking_completed_timestamp') as Fim_Separacao,
	JSON_VALUE(picking_app_timestamps, '$.picking_expected_start_timestamp') as Inicio_esperado,
	JSON_VALUE(picking_app_timestamps, '$.picking_expected_end_timestamp') as Fim_esperado,
	JSON_VALUE(picking_app_timestamps, '$.last_pause_timestamp') as ultima_pausa,
	JSON_VALUE(picking_app_timestamps, '$.handshake_timestamp') as Momento_da_Confirmacao,
	JSON_VALUE(picking_app_timestamps, '$.received_timestamp') as momento_do_recebimento,
	JSON_VALUE(picking_app_timestamps, '$.packing_sent_timestamp') as envio_para_empacotamento,
	JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp') as empacotamento_confirmado

FROM table_ops;

-- tabela virtual(CTE) com os dados ja extraidos do JSON ---
WITH CTEOPS AS (
SELECT 
	order_uuid,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_started_timestamp')AS DATETIME) as Inicio_Separacao,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_completed_timestamp')AS DATETIME) as Fim_Separacao,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_expected_start_timestamp')AS DATETIME) as Inicio_esperado,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_expected_end_timestamp')AS DATETIME) as Fim_esperado,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.last_pause_timestamp')AS DATETIME) as ultima_pausa,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.handshake_timestamp')AS DATETIME) as Momento_da_Confirmacao,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.received_timestamp')AS DATETIME) as momento_do_recebimento,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.packing_sent_timestamp')AS DATETIME) as envio_para_empacotamento,
	TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp')AS DATETIME) as empacotamento_confirmado
FROM table_ops

-- Conteudo do CTE --
)

SELECT
	order_uuid,
	DATEDIFF(MINUTE, Inicio_Separacao, Fim_Separacao) AS "Tempo de separacao (min)",
	DATEDIFF(MINUTE, Inicio_esperado, Fim_esperado) AS "sla de separacao (min)",
	DATEDIFF(MINUTE, envio_para_empacotamento, Fim_Separacao) AS "Espera Empacotamento (min)",
	DATEDIFF(MINUTE, momento_do_recebimento, empacotamento_confirmado) AS "Tempo Total de Processamento"
FROM CTEOPS;

---- QUALIDADE DE DADOS LOG ---
SELECT
    order_uuid,
    route_uuid,
    timestamp_local_order_created,
    timestamp_local_assign,
    timestamp_local_collect,
    timestamp_local_complete,
    timestamp_local_expected,

    -- Tempo
    DATEDIFF(MINUTE,
        timestamp_local_assign,
        timestamp_local_collect
    ) AS espera_do_motorista,

    DATEDIFF(MINUTE,
        timestamp_local_collect,
        timestamp_local_complete
    ) AS tempo_de_entrega,

    DATEDIFF(MINUTE,
        timestamp_local_order_created,
        timestamp_local_complete
    ) AS tempo_total_do_pedido,

    CASE 
    WHEN timestamp_local_complete <= timestamp_local_expected THEN 'sim'
    ELSE 'nao'
END AS sla_cumprido


FROM table_log
WHERE timestamp_local_assign IS NOT NULL
   AND timestamp_local_collect IS NOT NULL
   AND timestamp_local_complete IS NOT NULL;

-- Cruzamento de tabela
SELECT 
    [1].order_uuid AS id_pedido,
    [1].route_uuid AS id_rota,
    [1].merchant_commercial_group AS grupo_comercial,
    [1].merchant_frn_id AS id_loja,
    [1].order_last_status AS status_pedido,
    [1].driver_modal_cluster AS veiculo_utilizado,
    [1].delivery_method AS metodo_entrega,
    [1].timestamp_local_order_created AS criacao_do_pedido,
    [1].timestamp_local_assign AS alocacao_encontro_do_driver,
    [1].timestamp_local_collect AS Pedido_coletado_driver,
    [1].timestamp_local_complete AS Entrega_finalizada,
    [1].timestamp_local_expected AS prazo_final_de_entrega,

    -- transforma o valor do JSON em datetime para que o DATEDIFF consiga calcular a diferenca de tempo(se nao convertido retorna null)
    [2].picking_sla AS sla_de_separacao,
    TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_started_timestamp') AS DATETIME) AS separacao_iniciada,
    TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_completed_timestamp') AS DATETIME) AS separacao_completa,
    TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_expected_end_timestamp') AS DATETIME) AS prazo_final_de_separacao,
    DATEDIFF(MINUTE,
        TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_started_timestamp') AS DATETIME),
        TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_completed_timestamp') AS DATETIME)
    ) AS tempo_de_separacao,
    -- Condicao para verificar o sla
    CASE 
        WHEN TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_completed_timestamp') AS DATETIME) 
             <= TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_expected_end_timestamp') AS DATETIME) 
        THEN 'sim' ELSE 'nao'
    END AS sla_de_separacao,

    TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.packing_sent_timestamp') AS DATETIME) AS Envio_para_empacotamento,
    TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.packing_confirmed_timestamp') AS DATETIME) AS finalizacao_de_empacotamento,
    DATEDIFF(MINUTE,
        TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.packing_sent_timestamp') AS DATETIME),
        TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.packing_confirmed_timestamp') AS DATETIME)
    ) AS tempo_de_empacotamento,
    CASE
        WHEN TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.packing_confirmed_timestamp') AS DATETIME)
             <= TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_expected_end_timestamp') AS DATETIME)
        THEN 'sim' ELSE 'nao'
    END AS sla_de_empacotamento,

    DATEDIFF(MINUTE,
        [1].timestamp_local_assign,
        [1].timestamp_local_collect
    ) AS espera_do_motorista,
    DATEDIFF(MINUTE,
        [1].timestamp_local_collect,
        [1].timestamp_local_complete
    ) AS tempo_de_entrega,
    DATEDIFF(MINUTE,
        [1].timestamp_local_order_created,
        [1].timestamp_local_complete
    ) AS tempo_total_pedido,
    CASE 
        WHEN [1].timestamp_local_complete <= [1].timestamp_local_expected THEN 'sim' ELSE 'nao'
    END AS sla_de_entrega,
    
    CASE 
        WHEN 
            (TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_completed_timestamp') AS DATETIME) 
                <= TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_expected_end_timestamp') AS DATETIME))
            AND (TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.packing_confirmed_timestamp') AS DATETIME)
                <= TRY_CAST(JSON_VALUE([2].picking_app_timestamps, '$.picking_expected_end_timestamp') AS DATETIME))
            AND ([1].timestamp_local_complete <= [1].timestamp_local_expected)
        THEN 'sim' ELSE 'nao'
    END AS sla_geral
--- Inner join para juntar as tabelas e considera apenas os pedidos com dados completos
FROM table_log [1]
INNER JOIN table_ops [2]
    ON [1].order_uuid = [2].order_uuid
WHERE [1].timestamp_local_complete IS NOT NULL
  AND JSON_VALUE([2].picking_app_timestamps, '$.picking_completed_timestamp') IS NOT NULL
  AND JSON_VALUE([2].picking_app_timestamps, '$.packing_confirmed_timestamp') IS NOT NULL;



/*
--1. Aqui limpamos os dados da Loja (Picking/Packing)
WITH CTE_OPS AS (
    SELECT 
        order_uuid,
        CAST(JSON_VALUE(picking_app_timestamps, '$.picking_started_timestamp') AS DATETIME) AS picking_start,
        CAST(JSON_VALUE(picking_app_timestamps, '$.picking_completed_timestamp') AS DATETIME) AS picking_end,
        CAST(JSON_VALUE(picking_app_timestamps, '$.packing_sent_timestamp') AS DATETIME) AS packing_start,
        CAST(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp') AS DATETIME) AS packing_end
    FROM table_ops
),

--2. Aqui limpamos os dados da Entrega (Logistica)
CTE_LOG AS (
    SELECT 
        order_uuid,
        merchant_commercial_group,
        driver_modal_cluster,
        timestamp_local_order_created,
        timestamp_local_at_origin, 
        timestamp_local_collect,   
        timestamp_local_complete,  
        timestamp_local_expected   
    FROM table_log
)

-- 3. RESULTADO FINAL: Unimos as duas e criamos os indicadores
SELECT 
    L.order_uuid,
    L.merchant_commercial_group AS Grupo,
    L.driver_modal_cluster AS Modal,
    
    -- KPI: Tempo de Separacao (Quanto a loja demorou)
    DATEDIFF(MINUTE, O.picking_start, O.picking_end) AS tempo_separacao_min,
    
    -- KPI: Tempo de Espera do Driver (Motorista chegou, mas o pedido estava pronto?)
    DATEDIFF(MINUTE, L.timestamp_local_at_origin, L.timestamp_local_collect) AS tempo_espera_driver_loja,
    
    -- KPI: Tempo Total (Da criacao do pedido ate a casa do cliente)
    DATEDIFF(MINUTE, L.timestamp_local_order_created, L.timestamp_local_complete) AS tempo_total_entrega_min,
    
    -- Status de SLA: 'No Prazo' ou 'Atrasado'
    CASE 
        WHEN L.timestamp_local_complete <= L.timestamp_local_expected THEN 'No Prazo'
        ELSE 'Atrasado'
    END AS status_entrega

FROM CTE_LOG L
LEFT JOIN CTE_OPS O ON L.order_uuid = O.order_uuid;
*/

