CREATE OR ALTER VIEW vw_logistica_pedidos AS

WITH CTE_OPS AS (
    SELECT 
        order_uuid,
        TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_started_timestamp') AS DATETIME) AS picking_start,
        TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_completed_timestamp') AS DATETIME) AS picking_end,
        TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.packing_sent_timestamp') AS DATETIME) AS packing_start,
        TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp') AS DATETIME) AS packing_end,
        TRY_CAST(JSON_VALUE(picking_app_timestamps, '$.picking_expected_end_timestamp') AS DATETIME) AS picking_expected_end
    FROM table_ops
),

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

SELECT 
    L.order_uuid,
    L.merchant_commercial_group AS grupo_comercial,
    L.driver_modal_cluster AS modal_entrega,


    -- KPI empacotamento
    DATEDIFF(MINUTE, O.packing_start, O.packing_end) AS tempo_empacotamento_min,

    -- KPIs Loja
    DATEDIFF(MINUTE, O.picking_start, O.picking_end) AS tempo_separacao_min,

    -- KPIs Driver
    DATEDIFF(MINUTE, L.timestamp_local_at_origin, L.timestamp_local_collect) AS tempo_espera_driver_min,

    -- KPIs Entrega
    DATEDIFF(MINUTE, L.timestamp_local_order_created, L.timestamp_local_complete) AS tempo_total_entrega_min,

    -- SLA Separação
     CASE 
        WHEN O.picking_end IS NOT NULL
             AND O.picking_expected_end IS NOT NULL
             AND O.picking_end <= O.picking_expected_end
        THEN 'No Prazo'
        ELSE 'Atrasado'
    END AS status_sla_separacao,

    -- SLA Entrega
    CASE 
        WHEN L.timestamp_local_complete <= L.timestamp_local_expected 
        THEN 'No Prazo'
        ELSE 'Atrasado'
    END AS status_sla_entrega,

       -- SLA Geral (ponta a ponta)
    CASE
        WHEN 
            O.picking_end IS NOT NULL
            AND O.picking_expected_end IS NOT NULL
            AND O.picking_end <= O.picking_expected_end
            AND L.timestamp_local_complete <= L.timestamp_local_expected
        THEN 'No Prazo'
        ELSE 'Atrasado'
    END AS status_sla_geral




FROM CTE_LOG L
LEFT JOIN CTE_OPS O 
    ON L.order_uuid = O.order_uuid
WHERE L.timestamp_local_complete IS NOT NULL;
