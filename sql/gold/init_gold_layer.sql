-- создаем схему
create schema if not exists gold;

-- создаем виртуальную витрину с измерением customer
create or replace view gold.dim_customer as (
    select
        customer_unique_id,
        customer_city, 
        customer_state,
        zip_code_prefix
    from raw_vault.hub_customer as hub
    join raw_vault.sat_customer_details as sat 
        on hub.hub_customer_hash = sat.hub_customer_hash
    where sat.load_date = (
                            select 
                                    max(load_date) 
                            from raw_vault.sat_customer_details
                            where hub_customer_hash = hub.hub_customer_hash
                            )
);

-- создаем виртуальную таблицу фактов order_items
create or replace view gold.fact_order_item as (

    with actual_order_item_finance as (
        select 
            link_order_item_hash,
            order_item_id,
            price,
            freight_value,
            row_number() over (partition by link_order_item_hash
                                order by load_date desc) rn
        from raw_vault.sat_order_item_finance 
    )
    select 
        h_ord.order_id,
        fin.order_item_id,
        h_prod.product_id,
        h_slr.seller_id,
        fin.price,
        fin.freight_value
    from raw_vault.link_order_items lnk
    join actual_order_item_finance fin
        on lnk.link_order_item_hash = fin.link_order_item_hash
        and fin.rn = 1
    join raw_vault.hub_order h_ord
        on lnk.hub_order_hash = h_ord.hub_order_hash
    join raw_vault.hub_product h_prod
        on lnk.hub_product_hash = h_prod.hub_product_hash
    join raw_vault.hub_seller h_slr
        on lnk.hub_seller_hash = h_slr.hub_seller_hash
);
