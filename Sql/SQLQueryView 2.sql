CREATE OR ALTER VIEW vw_qualidade_dados AS
SELECT
    COUNT(*) AS total_registros,
    COUNT(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp')) AS registros_com_valor,
    COUNT(*) - COUNT(JSON_VALUE(picking_app_timestamps, '$.packing_confirmed_timestamp')) AS registros_null
FROM table_ops;