DO $$
DECLARE
    v_batch_id INT;
BEGIN
    RAISE NOTICE '--- СТАРТ ETL ПРОЦЕССА ---';
    
    -- Запускаем оркестратор. 
    -- Он сам очистит стейджинг, зальет новые данные и разложит их по Raw Vault
    CALL raw_vault.run_etl_orchestrator(
        p_source_name        := 'OLIST_MARKETPLACE',
        p_generated_batch_id := v_batch_id
    );
    
    RAISE NOTICE '--- УСПЕХ ---';
    RAISE NOTICE 'Данные обработаны в рамках Батча №: %', v_batch_id;
END $$;