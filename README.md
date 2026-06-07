# 🛒 Olist E-Commerce Data Warehouse

<p align="center">
  <img src="https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Data_Vault-2.0-blue" alt="Data Vault 2.0">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker" alt="Docker">
</p>

Проект Data Warehouse для анализа данных бразильского e-commerce маркетплейса **Olist** с использованием методологии **Data Vault 2.0**.

## 📋 Описание проекта

Данный проект представляет собой полноценное хранилище данных (DWH) для аналитики электронной коммерции. Данные взяты из публичного датасета [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

### 🎯 Цели проекта

- Построение масштабируемого хранилища данных на основе Data Vault 2.0
- Реализация ETL-процессов для загрузки и трансформации данных
- Обеспечение историчности и аудита всех изменений данных
- Создание основы для построения аналитических витрин (Data Marts)

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA WAREHOUSE                               │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐  │
│  │   EXT       │───▶│  STAGING    │───▶│      RAW VAULT          │  │
│  │ (CSV Files) │    │ (stg_*)     │    │  (Hub/Link/Satellite)   │  │
│  └─────────────┘    └─────────────┘    └─────────────────────────┘  │
│                                                                      │
│  External Tables    Промежуточный     Data Vault 2.0                │
│  (Foreign Data)     слой очистки     (Bronze Layer)                 │
└─────────────────────────────────────────────────────────────────────┘
```

### 📊 Слои данных

| Слой | Схема | Описание |
|------|-------|----------|
| **External** | `ext` | Внешние таблицы для чтения CSV файлов |
| **Staging** | `staging` | Промежуточные таблицы для очистки и валидации |
| **Raw Vault** | `raw_vault` | Модель Data Vault 2.0 (Hubs, Links, Satellites) |

## 📁 Структура проекта

```
e_commerce_olist/
├── 📂 datasets/                    # Исходные CSV данные Olist
│   ├── olist_customers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   └── product_category_name_translation.csv
│
├── 📂 docker/                      # Docker конфигурация
│   ├── docker-compose.yml          # PostgreSQL + pgAdmin
│   └── postgresql.conf             # Оптимизированные настройки PostgreSQL
│
├── 📂 sql/                         # DDL скрипты инициализации
│   ├── ext/
│   │   └── external_tables.sql     # Внешние таблицы (file_fdw)
│   ├── staging/
│   │   └── init_staging.sql        # Схема staging
│   └── raw_vault (bronze)/
│       └── init_raw_vault.sql      # Схема Data Vault
│
├── 📂 src/                         # ETL процедуры
│   ├── staging/
│   │   └── load_staging.sql        # Процедуры загрузки в staging
│   ├── raw_vault/
│   │   ├── load_raw_vault.sql      # Процедуры загрузки в Data Vault
│   │   └── Вставка zero key и ghost records.sql
│   ├── etl_orchestrator.sql        # Главный оркестратор ETL
│   └── Запуск etl.sql              # Скрипт запуска полного ETL
│
├── .env.example                    # Шаблон переменных окружения
├── .gitignore
└── README.md
```

## 🗄️ Модель Data Vault 2.0

### Hubs (Бизнес-сущности)

| Hub | Бизнес-ключ | Описание |
|-----|-------------|----------|
| `hub_customer` | customer_unique_id | Уникальные покупатели |
| `hub_seller` | seller_id | Продавцы маркетплейса |
| `hub_order` | order_id | Заказы |
| `hub_product` | product_id | Товары |
| `hub_review` | review_id | Отзывы |
| `hub_geolocation` | zip_code_prefix | Географические точки |
| `hub_product_category` | product_category_name | Категории товаров |

### Links (Связи)

| Link | Связь | Описание |
|------|-------|----------|
| `link_order_items` | Order ↔ Product ↔ Seller | Позиции в заказе |
| `link_order_customer` | Order ↔ Customer | Заказ клиента |
| `link_order_review` | Order ↔ Review | Отзыв к заказу |
| `link_seller_geolocation` | Seller ↔ Geolocation | Локация продавца |

### Satellites (Атрибуты с историей)

| Satellite | Родитель | Описание |
|-----------|----------|----------|
| `sat_order_item_finance` | link_order_items | Цены и стоимость доставки |
| `sat_order_status` | hub_order | Статусы и даты заказа |
| `sat_order_payments` | hub_order | Платежи (multi-active) |
| `sat_customer_details` | hub_customer | Адрес клиента |
| `sat_product_details` | hub_product | Характеристики товара |
| `sat_review_details` | hub_review | Оценка и текст отзыва |

## 🚀 Быстрый старт

### Предварительные требования

- Docker & Docker Compose
- Git

### 1. Клонирование репозитория

```bash
git clone https://github.com/A95D/e_commerce_olist.git
cd e_commerce_olist
```

### 2. Настройка переменных окружения

```bash
cp .env.example .env
```

Отредактируйте файл `.env`:

```env
DB_USER=olist_admin
DB_PASSWORD=your_secure_password
DB_PORT=5432
PGADMIN_EMAIL=admin@example.com
PGADMIN_PASSWORD=your_pgadmin_password
```

### 3. Запуск контейнеров

```bash
cd docker
docker-compose up -d
```

### 4. Подключение к базе данных

**pgAdmin:** http://localhost:8080
- Email: из переменной `PGADMIN_EMAIL`
- Password: из переменной `PGADMIN_PASSWORD`

**psql:**
```bash
psql -h localhost -p 5432 -U olist_admin -d olist_dwh
```

### 5. Инициализация схем

Выполните скрипты в следующем порядке:

```sql
-- 1. Внешние таблицы
\i sql/ext/external_tables.sql

-- 2. Staging слой
\i sql/staging/init_staging.sql

-- 3. Raw Vault слой
\i sql/raw_vault (bronze)/init_raw_vault.sql

-- 4. ETL процедуры
\i src/staging/load_staging.sql
\i src/raw_vault/load_raw_vault.sql
\i src/etl_orchestrator.sql
```

### 6. Запуск ETL

```sql
DO $$
DECLARE
    v_batch_id INT;
BEGIN
    CALL raw_vault.run_etl_orchestrator('OLIST_MARKETPLACE', v_batch_id);
    RAISE NOTICE 'ETL завершён. Batch ID: %', v_batch_id;
END;
$$;
```

## 📈 Данные Olist

Датасет содержит информацию о **~100,000 заказов** с 2016 по 2018 год:

| Датасет | Записей | Описание |
|---------|---------|----------|
| Orders | ~100K | Заказы с датами и статусами |
| Order Items | ~112K | Позиции заказов |
| Customers | ~99K | Уникальные клиенты |
| Sellers | ~3K | Продавцы |
| Products | ~33K | Товары |
| Reviews | ~100K | Отзывы с оценками |
| Payments | ~104K | Платежи |
| Geolocation | ~1M | Географические координаты |

## 🔧 Технологии

- **PostgreSQL 15** — основная СУБД
- **Data Vault 2.0** — методология моделирования DWH
- **Docker Compose** — контейнеризация
- **pgAdmin 4** — веб-интерфейс администрирования
- **PL/pgSQL** — хранимые процедуры ETL

## 📝 Особенности реализации

### ETL Pipeline

1. **Batch-based загрузка** — каждый запуск создаёт уникальный `batch_id`
2. **Delta-загрузка** — использование `hash_diff` для отслеживания изменений
3. **Аудит и логирование** — таблицы `etl_batch_log` и `etl_audit_log`
4. **Обработка ошибок** — EXCEPTION блоки с логированием в audit

### Data Quality

- Очистка данных (trim, upper, nullif)
- Валидация бизнес-ключей
- Логирование проблемных записей

## 📄 Лицензия

MIT License

## 👤 Автор

**Andrey Detistov**

- GitHub: [@A95D](https://github.com/A95D)
