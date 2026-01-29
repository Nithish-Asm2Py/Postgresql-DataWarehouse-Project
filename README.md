# 📊 Modern Data Warehouse & Analytics Project

Welcome to the **Modern Data Warehouse & Analytics Project** 🚀  

This repository demonstrates an end-to-end data engineering solution built using **Medallion Architecture (Bronze, Silver, Gold)**. The project simulates a real-world production-style data warehouse — from raw data ingestion to business-ready analytical models.

It is designed as a portfolio project to showcase practical Data Engineering, Analytics Engineering, and Data Warehousing skills aligned with 3+ years industry expectations.

---

## 🏗️ Data Architecture

<p align="center">
  <img src="docs/Data Warehouse Planing.png" width="800">
</p>

This project follows the **Medallion Architecture** pattern:

### 🥉 Bronze Layer — Raw Ingestion
- Stores source data in its original format.
- Data is ingested from CSV files into the database.
- Acts as an immutable raw layer for traceability and reprocessing.

### 🥈 Silver Layer — Cleansed & Standardized
- Applies data cleansing, validation, normalization, and enrichment.
- Standardizes formats and applies business rules.
- Produces analytics-ready intermediate datasets.

### 🥇 Gold Layer — Business & Analytics
- Contains business-ready data modeled using a **Star Schema**.
- Includes fact and dimension entities.
- Optimized for analytical queries and reporting.

---

## 📖 Project Overview

This project covers the complete lifecycle of building a modern data warehouse:

- **Data Architecture**
  - Medallion Architecture (Bronze → Silver → Gold)

- **ETL / ELT Pipelines**
  - Extraction from CSV sources
  - Transformation across layers
  - Loading into analytical models

- **Data Modeling**
  - Dimensional modeling using fact and dimension structures
  - Surrogate keys and star schema design

- **Analytics & Reporting**
  - SQL-based analytical queries on Gold layer
  - Business-ready views for reporting

- **Warehouse Engineering Practices**
  - Schema separation
  - Layered transformations
  - Reusable views
  - Production-style organization

---

## 🛠️ Tech Stack

- PostgreSQL  
- SQL  
- pgAdmin  
- Git / GitHub  

*(Architecture is database-agnostic and can be adapted to cloud platforms such as AWS Redshift, Snowflake, or BigQuery.)*

---

