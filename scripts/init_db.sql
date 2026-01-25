/*
=============================================================
Create Database and Schemas (PostgreSQL)
=============================================================
Script Purpose:
    This script drops and recreates a database named 'datawarehouse'
    and creates bronze, silver, and gold schemas.

WARNING:
    This will DELETE the entire database if it exists.
=============================================================
*/

-- ============================
-- STEP 1: Drop database if exists
-- (run while connected to postgres db)
-- ============================

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'datawarehouse'
AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS datawarehouse;

-- ============================
-- STEP 2: Create database
-- ============================

CREATE DATABASE datawarehouse;

-- ============================
-- STEP 3: Connect to database
-- ============================
-- In pgAdmin: open Query Tool on datawarehouse
-- In psql: \c datawarehouse


-- ============================
-- STEP 4: Create schemas
-- ============================

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

