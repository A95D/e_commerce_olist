# Data Vault 2.0 Macros

Макросы для автоматизации создания компонентов Data Vault 2.0.

## 1. generate_hub.sql

Макрос для создания таблиц-концентраторов (Hubs). Hub содержит первичный ключ и естественный ключ сущности.

### Параметры:
- `source_model`: Имя staging модели
- `src_pk`: Имя хеш-первичного ключа
- `src_nk`: Имя натурального ключа
- `src_ldts`: Имя столбца даты загрузки
- `src_source`: Имя столбца источника
- `src_batch_id`: Имя столбца ID батча

### Пример использования:
```sql
{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_customers',
    src_pk='hub_customer_hash',
    src_nk='customer_unique_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
```

## 2. generate_link.sql

Макрос для создания связей (Links). Link соединяет несколько Hubs и содержит их внешние ключи.

### Параметры:
- `source_model`: Имя staging модели
- `src_pk`: Имя хеш-первичного ключа связи
- `src_fk`: Список внешних ключей (массив)
- `src_ldts`: Имя столбца даты загрузки
- `src_source`: Имя столбца источника
- `src_batch_id`: Имя столбца ID батча

### Пример использования:
```sql
{{ config(materialized='incremental') }}
{{ generate_link(
    source_model='stg_order_items',
    src_pk='link_order_item_hash',
    src_fk=['hub_order_hash', 'hub_product_hash', 'hub_seller_hash'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
```

## 3. generate_satellite.sql

Макрос для создания спутников (Satellites). Satellite содержит описательные атрибуты Hub или Link.

Особенности:
- Автоматически вычисляет hash_diff для отслеживания изменений
- Реализует Delta Check: вставляет только если данные изменились
- Поддерживает инкрементальную загрузку

### Параметры:
- `source_model`: Имя staging модели
- `src_pk`: Имя первичного ключа (hub_X_hash или link_X_hash)
- `src_hash_key`: Имя хеш-ключа в staging модели
- `src_attributes`: Список атрибутов (массив столбцов)
- `src_ldts`: Имя столбца даты загрузки
- `src_source`: Имя столбца источника
- `src_batch_id`: Имя столбца ID батча

### Пример использования:
```sql
{{ config(materialized='incremental') }}
{{ generate_satellite(
    source_model='stg_customers',
    src_pk='hub_customer_hash',
    src_hash_key='hub_customer_hash',
    src_attributes=['customer_city', 'customer_state', 'customer_zip_code_prefix'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
```

## 4. generate_satellite_multi_active.sql

Макрос для мультиактивных спутников. Это случай, когда может быть несколько записей на один Hub ключ (например, несколько платежей для одного заказа).

### Параметры:
- `source_model`: Имя staging модели
- `src_pk`: Имя первичного ключа hub
- `src_hash_key`: Имя хеш-ключа в staging модели
- `src_multi_key`: Столбец, который различает несколько записей (например, payment_sequential)
- `src_attributes`: Список атрибутов (массив столбцов)
- `src_ldts`: Имя столбца даты загрузки
- `src_source`: Имя столбца источника
- `src_batch_id`: Имя столбца ID батча

### Пример использования:
```sql
{{ config(materialized='incremental') }}
{{ generate_satellite_multi_active(
    source_model='stg_order_payments',
    src_pk='hub_order_hash',
    src_hash_key='hub_order_hash',
    src_multi_key='payment_sequential',
    src_attributes=['payment_type', 'payment_installments', 'payment_value'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
```

## 5. generate_pit.sql

Макрос для создания PIT таблиц (Point-in-Time). PIT содержит снимок всех спутников на конкретную дату для каждого Hub.

### Параметры:
- `hub_model`: Имя Hub модели
- `hub_pk`: Имя первичного ключа Hub
- `satellite_models`: Список имен спутников (массив)

### Пример использования:
```sql
{{ config(materialized='table') }}
{{ generate_pit(
    hub_model='hub_orders',
    hub_pk='hub_order_hash',
    satellite_models=['sat_order_status', 'sat_order_payments']
) }}
```

## 6. generate_bridge.sql

Макрос для создания Bridge таблиц. Bridge соединяет несколько сущностей через Link.

### Параметры:
- `link_model`: Имя Link модели
- `link_pk`: Имя первичного ключа Link
- `hub_pks`: Список внешних ключей Hub (массив)
- `ldts_column`: Имя столбца даты загрузки
- `source_column`: Имя столбца источника
- `batch_id_column`: Имя столбца ID батча

### Пример использования:
```sql
{{ config(materialized='incremental') }}
{{ generate_bridge(
    link_model='link_order_items',
    link_pk='link_order_item_hash',
    hub_pks=['hub_order_hash', 'hub_product_hash', 'hub_seller_hash'],
    ldts_column='load_date',
    source_column='record_source',
    batch_id_column='batch_id'
) }}
```

## Структура каталогов

```
olist_dwh/
├── macros/
│   ├── generate_hub.sql
│   ├── generate_link.sql
│   ├── generate_satellite.sql
│   ├── generate_satellite_multi_active.sql
│   ├── generate_pit.sql
│   ├── generate_bridge.sql
│   └── README.md
├── models/
│   ├── staging/
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   └── ...
│   ├── raw_vault/
│   │   ├── hubs/
│   │   │   ├── hub_customer.sql
│   │   │   ├── hub_orders.sql
│   │   │   └── ...
│   │   ├── links/
│   │   │   ├── link_order_items.sql
│   │   │   └── ...
│   │   └── satellites/
│   │       ├── sat_customer_details.sql
│   │       ├── sat_order_status.sql
│   │       ├── sat_order_payments.sql
│   │       └── ...
│   └── business_vault/
│       ├── pit_order.sql
│       └── bridge_order_product_seller.sql
└── dbt_project.yml
```

## Инкрементальная загрузка

Все макросы (кроме generate_pit) поддерживают инкрементальную загрузку. При использовании `materialized='incremental'`:
- Hub: избегает дубликатов по primary key
- Link: исключает уже существующие связи
- Satellite: вставляет только если данные изменились (Delta Check)

## Особенности

### Delta Check в Satellites
Спутники используют hash_diff для отслеживания изменений:
- hash_diff = MD5 хеш всех атрибутов
- Новая запись вставляется, если hash_diff отличается от последнего известного
- Это экономит место и отслеживает действительные изменения

### Hash Key
Используется MD5 хеш для создания суррогатных ключей:
- Hub: MD5(натуральный ключ)
- Link: MD5(бизнес-ключи + разделители)
- Satellite: наследует ключ из Hub/Link

### Multi-Active Satellites
Для случаев с несколькими записями:
- Добавляется дополнительный столбец (src_multi_key)
- Этот столбец становится частью ключа delta check
- Пример: платежи (payment_sequential)
