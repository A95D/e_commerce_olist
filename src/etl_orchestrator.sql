
CREATE OR REPLACE PROCEDURE raw_vault.run_etl_orchestrator(
    p_source_name VARCHAR, 
    OUT p_generated_batch_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_id     INT;
    v_load_date    TIMESTAMP := CURRENT_TIMESTAMP;
    v_step         VARCHAR(100);
BEGIN
    -------------------------------------------------------------------------------
    -- 1. ИНИЦИАЛИЗАЦИЯ СЕССИИ (БАТЧА)
    -------------------------------------------------------------------------------
    v_step := 'Инициализация батча в etl_batch_log';
    
    INSERT INTO raw_vault.etl_batch_log (status, source_system, run_timestamp)
    VALUES ('STARTED', p_source_name, v_load_date)
    RETURNING batch_id INTO v_batch_id;

    p_generated_batch_id := v_batch_id;

    -------------------------------------------------------------------------------
    -- 2. ПОСЛЕДОВАТЕЛЬНЫЙ ЗАПУСК СЛОЯ STAGING (Все типы параметров - INT)
    -------------------------------------------------------------------------------
    v_step := 'Вызов staging.load_customers';
    CALL staging.load_customers(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_geolocation';
    CALL staging.load_geolocation(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_order_items';
    CALL staging.load_order_items(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_order_payments';
    CALL staging.load_order_payments(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_order_reviews';
    CALL staging.load_order_reviews(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_orders';
    CALL staging.load_orders(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_products';
    CALL staging.load_products(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_sellers';
    CALL staging.load_sellers(v_batch_id, p_source_name);

    v_step := 'Вызов staging.load_product_category_name_translation';
    CALL staging.load_product_category_name_translation(v_batch_id, p_source_name);

    -------------------------------------------------------------------------------
    -- 3. ЗАПУСК ДЕКОМПОЗИЦИИ В СЛОЙ RAW VAULT
    -------------------------------------------------------------------------------
    v_step := 'Вызов raw_vault.load_olist_order_items';
    CALL raw_vault.load_olist_order_items(v_batch_id, v_load_date, p_source_name);

    -------------------------------------------------------------------------------
    -- 4. ФИКСАЦИЯ УСПЕШНОГО ЗАВЕРШЕНИЯ КОНВЕЙЕРА
    -------------------------------------------------------------------------------
    UPDATE raw_vault.etl_batch_log
    SET status = 'COMPLETED', end_timestamp = CURRENT_TIMESTAMP
    WHERE batch_id = v_batch_id;

EXCEPTION
    WHEN OTHERS THEN
        UPDATE raw_vault.etl_batch_log
        SET status = 'FAILED', end_timestamp = CURRENT_TIMESTAMP
        WHERE batch_id = v_batch_id;

        INSERT INTO raw_vault.etl_audit_log (batch_id, error_msg, failed_payload)
        VALUES (
            v_batch_id, 
            'Критический сбой конвейера на шаге: [' || v_step || ']. Ошибка: ' || SQLERRM, 
            'CRITICAL_ORCHESTRATOR_CRASH'
        );

        RAISE EXCEPTION 'ETL конвейер аварийно остановлен на шаге "%": %', v_step, SQLERRM;
END;
$$;