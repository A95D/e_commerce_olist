# Olist E-Commerce Data Warehouse

<p align="center">
  <img src="https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/dbt-1.5+-FF6B35?logo=dbt" alt="dbt">
  <img src="https://img.shields.io/badge/Data_Vault-2.0-blue" alt="Data Vault 2.0">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker" alt="Docker">
</p>

Data Warehouse для анализа бразильского e-commerce маркетплейса **Olist** с использованием **dbt** и методологии **Data Vault 2.0**.

## Описание

Полноценное хранилище данных для аналитики электронной коммерции, построенное на публичном датасете [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Проект использует **dbt** для управления трансформацией данных и автоматизирует создание компонентов Data Vault 2.0 через переиспользуемые макросы.

## Архитектура

```
EXT (Raw CSV) → STAGING (stg_*) → RAW_VAULT (Hub/Link/Sat) → BUSINESS_VAULT (Витрины)
```

### Слои данных

| Слой | Схема | Тип | Описание |
|------|-------|-----|----------|
| External | `ext` | Source | Внешние таблицы CSV |
| Staging | `staging` | View | Очистка и стандартизация |
| Raw Vault | `raw_vault` | Incremental | Data Vault 2.0 (Hubs, Links, Satellites) |
| Business Vault | `business_vault` | View/Table | Аналитические витрины и PIT таблицы |

## Структура проекта

```
e_commerce_olist/
├── olist_dwh/                      # dbt проект
│   ├── macros/                     # Переиспользуемые макросы
│   │   ├── generate_hub.sql
│   │   ├── generate_link.sql
│   │   ├── generate_satellite.sql
│   │   ├── generate_satellite_multi_active.sql
│   │   ├── generate_pit.sql
│   │   ├── generate_bridge.sql
│   │   └── README.md
│   ├── models/
│   │   ├── staging/               # Staging модели
│   │   │   ├── stg_*.sql
│   │   │   └── stg_models.yml
│   │   ├── raw_vault/             # Raw Vault (Data Vault 2.0)
│   │   │   ├── hubs/
│   │   │   │   ├── hub_*.sql
│   │   │   │   └── hubs.yml
│   │   │   ├── links/
│   │   │   │   ├── link_*.sql
│   │   │   │   └── links.yml
│   │   │   └── satellites/
│   │   │       ├── sat_*.sql
│   │   │       └── satellites.yml
│   │   └── business_vault/        # Аналитические витрины
│   │       ├── pit_order.sql
│   │       ├── bridge_order_product_seller.sql
│   │       ├── v_orders_customer_detail.sql
│   │       ├── v_order_items_with_details.sql
│   │       ├── v_customer_metrics.sql
│   │       └── business_vault.yml
│   ├── tests/                      # dbt тесты
│   │   ├── generic/
│   │   ├── staging/
│   │   └── raw_vault/
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── profiles.yml
│
├── datasets/                        # Исходные CSV данные
│   └── olist_*.csv
│
├── docker/
│   ├── docker-compose.yml
│   └── postgresql.conf
│
├── sql/                            # Инициализационные скрипты
│   ├── ext/
│   ├── staging/
│   └── raw_vault/
│
└── README.md
```

## Data Vault 2.0 Модель

### Hubs (9 шт.)

| Hub | Бизнес-ключ | Тип |
|-----|-------------|-----|
| hub_customer | customer_unique_id | Покупатели |
| hub_orders | order_id | Заказы |
| hub_products | product_id | Товары |
| hub_sellers | seller_id | Продавцы |
| hub_order_items | order_item_id | Позиции заказов |
| hub_order_payments | payment_id | Платежи |
| hub_order_reviews | review_id | Отзывы |
| hub_geolocation | zip_code_prefix | География |
| hub_product_category_translation | product_category_name | Категории |

### Links (4 шт.)

| Link | Связь |
|------|-------|
| link_order_customer | Order ↔ Customer |
| link_order_items | Order ↔ Product ↔ Seller |
| link_order_review | Order ↔ Review |
| link_seller_geolocation | Seller ↔ Geolocation |

### Satellites (5 шт.)

| Satellite | Описание |
|-----------|----------|
| sat_customer_details | Адрес клиента (city, state, zip) |
| sat_order_status | Статусы и даты заказа |
| sat_order_payments | Платежи (multi-active) |
| sat_order_item_finance | Цены и доставка |
| sat_product_details | Характеристики товара |

### Business Vault

**Point-in-Time таблицы:**
- `pit_order` — снимки всех спутников заказа по датам

**Bridge таблицы:**
- `bridge_order_product_seller` — граф связей Order-Product-Seller

**Аналитические витрины:**
- `v_orders_customer_detail` — заказы с информацией о клиенте
- `v_order_items_with_details` — позиции заказов с деталями товаров
- `v_customer_metrics` — метрики клиентов (кол-во заказов, LTV)

## Быстрый старт

### Требования

- Docker & Docker Compose
- Python 3.9+
- dbt-postgres

### 1. Клонирование

```bash
git clone https://github.com/A95D/e_commerce_olist.git
cd e_commerce_olist
```

### 2. Окружение

```bash
cp .env.example .env
```

### 3. Docker

```bash
cd docker
docker-compose up -d
```

### 4. dbt установка

```bash
cd olist_dwh
pip install dbt-postgres dbt-utils dbt-audit-helper
dbt deps
```

### 5. Инициализация БД

```bash
# Создание схем и внешних таблиц
psql -h localhost -U olist_admin -d olist_dwh -f ../sql/ext/external_tables.sql
psql -h localhost -U olist_admin -d olist_dwh -f ../sql/staging/init_staging.sql
psql -h localhost -U olist_admin -d olist_dwh -f ../sql/raw_vault/init_raw_vault.sql
```

### 6. Запуск dbt

```bash
# Проверка конфигурации
dbt debug

# Запуск всех моделей
dbt run

# Запуск тестов
dbt test

# Генерация документации
dbt docs generate
dbt docs serve
```

## Датасет

Olist содержит ~100K заказов (2016-2018):

| Таблица | Записей |
|---------|---------|
| Orders | ~100K |
| Order Items | ~112K |
| Customers | ~99K |
| Sellers | ~3K |
| Products | ~33K |
| Reviews | ~100K |
| Payments | ~104K |
| Geolocation | ~1M |

## Технологии

- **PostgreSQL 15** — СУБД
- **dbt 1.5+** — трансформация данных
- **Data Vault 2.0** — методология моделирования
- **Docker Compose** — контейнеризация
- **PL/pgSQL** — процедуры и триггеры

## Особенности

### dbt макросы

Переиспользуемые макросы для автоматизации создания компонентов Data Vault:
- `generate_hub` — Hub таблицы с дедупликацией
- `generate_link` — Link таблицы
- `generate_satellite` — Satellite таблицы с delta check (hash_diff)
- `generate_satellite_multi_active` — Satellites с несколькими записями на ключ
- `generate_pit` — Point-in-Time таблицы с историческими снимками
- `generate_bridge` — Bridge таблицы для связей

### Инкрементальная загрузка

Все модели используют `materialized='incremental'` для эффективной загрузки:
- Хабы — дедупликация по primary key
- Линки — исключение уже существующих связей
- Спутники — вставка только при изменении (hash_diff)

### Качество данных

- Встроенные dbt тесты (unique, not_null, relationships)
- Валидация целостности ключей
- Очистка данных в staging слое

## Ссылки

- [dbt Documentation](https://docs.getdbtlabs.com)
- [Data Vault 2.0 Guide](https://datavault.com/)
- [Olist Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Лицензия

MIT

