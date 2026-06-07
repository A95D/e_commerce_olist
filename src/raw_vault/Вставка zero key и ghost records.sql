do $$
begin
    insert into raw_vault.sat_customer_details (
        hub_customer_hash,
        customer_city,
        customer_state,
        zip_code_prefix,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    values (
        lpad('0',32,'0'),
        'N/A',
        'N/A',
        0,
        lpad('0',32,'0'),
        '1900-01-01 00:00:00'::timestamp,
        'SYSTEM',
        0
    );

    insert into raw_vault.sat_order_item_finance (
        link_order_item_hash,
        order_item_id,
        shipping_limit_date,
        price,
        freight_value,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    values (
        lpad('0',32,'0'),
        0,
        '1900-01-01 00:00:00'::timestamp,
        0.00,
        0.00,
        lpad('0',32,'0'),
        '1900-01-01 00:00:00'::timestamp,
        'SYSTEM',
        0
    );

    insert into raw_vault.sat_order_status (
        hub_order_hash,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    values (
        lpad('0',32,'0'),
        'N/A',
        '1900-01-01 00:00:00'::timestamp,
        '1900-01-01 00:00:00'::timestamp,
        '1900-01-01 00:00:00'::timestamp,
        '1900-01-01 00:00:00'::timestamp,
        '1900-01-01 00:00:00'::timestamp,
        lpad('0',32,'0'),
        '1900-01-01 00:00:00'::timestamp,
        'SYSTEM',
        0
    );

    insert into raw_vault.sat_order_payments (
        hub_order_hash,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    values (
        lpad('0',32,'0'),
        0,
        'N/A',
        0,
        0.00,
        lpad('0',32,'0'),
        '1900-01-01 00:00:00'::timestamp,
        'SYSTEM',
        0
    );

    insert into raw_vault.sat_product_details (
        hub_product_hash,
        category_name,
        name_length,
        description_length,
        photos_qty,
        weight_g,
        length_cm,
        height_cm,
        width_cm,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    values (
        lpad('0',32,'0'),
        'N/A',
        0,
        0,
        0,
        0.00,
        0.00,
        0.00,
        0.00,
        lpad('0',32,'0'),
        '1900-01-01 00:00:00'::timestamp,
        'SYSTEM',
        0
    );

    insert into raw_vault.sat_review_details (
        hub_review_hash,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    values (
        lpad('0',32,'0'),
        0,
        'N/A',
        'N/A',
        '1900-01-01 00:00:00'::timestamp,
        '1900-01-01 00:00:00'::timestamp,
        lpad('0',32,'0'),
        '1900-01-01 00:00:00'::timestamp,
        'SYSTEM',
        0
    );

end $$;