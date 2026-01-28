/*
===============================================================================
Procedure: silver.load_silver()
===============================================================================
Purpose:
    Loads and transforms data from the bronze layer into the silver layer.

Actions:
    - Truncates all Silver tables.
    - Cleans, normalizes, and deduplicates Bronze data.
    - Inserts transformed records into Silver tables.
    - Logs execution duration for each step.

Notes (PostgreSQL):
    - Implemented using PL/pgSQL.
    - RAISE NOTICE is used instead of PRINT.
    - NOW() replaces GETDATE().
    - COALESCE replaces ISNULL().
    - LENGTH replaces LEN().
    - EXTRACT(EPOCH FROM interval) is used for duration in seconds.

Usage:
    CALL silver.load_silver();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
BEGIN
    batch_start_time := NOW();

    RAISE NOTICE '=============================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '=============================================';

    ---------------------------------------------------------------------------
    -- CRM CUSTOMER INFO
    ---------------------------------------------------------------------------
    start_time := NOW();

    RAISE NOTICE 'Truncating silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE rn = 1;   -- keep latest customer record

    end_time := NOW();
    RAISE NOTICE 'crm_cust_info load time: % seconds',
        EXTRACT(EPOCH FROM end_time - start_time);

    ---------------------------------------------------------------------------
    -- PRODUCT INFO
    ---------------------------------------------------------------------------
    start_time := NOW();

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_'),
        SUBSTRING(prd_key FROM 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        prd_start_dt::date,
        (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day')::date
    FROM bronze.crm_prd_info;

    end_time := NOW();
    RAISE NOTICE 'crm_prd_info load time: % seconds',
        EXTRACT(EPOCH FROM end_time - start_time);

    ---------------------------------------------------------------------------
    -- SALES DETAILS
    ---------------------------------------------------------------------------
    start_time := NOW();

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) <> 8 THEN NULL
             ELSE sls_order_dt::text::date END,
        CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::text) <> 8 THEN NULL
             ELSE sls_ship_dt::text::date END,
        CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::text) <> 8 THEN NULL
             ELSE sls_due_dt::text::date END,
        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0
                 OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;

    end_time := NOW();
    RAISE NOTICE 'crm_sales_details load time: % seconds',
        EXTRACT(EPOCH FROM end_time - start_time);

    ---------------------------------------------------------------------------
    -- ERP TABLES (direct loads with light cleansing)
    ---------------------------------------------------------------------------

    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4) ELSE cid END,
        CASE WHEN bdate > NOW() THEN NULL ELSE bdate END,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
            ELSE 'n/a'
        END
    FROM bronze.erp_cust_az12;

    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101
    SELECT
        REPLACE(cid,'-',''),
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2
    SELECT * FROM bronze.erp_px_cat_g1v2;

    batch_end_time := NOW();

    RAISE NOTICE '=============================================';
    RAISE NOTICE 'Silver Layer Load Completed';
    RAISE NOTICE 'Total duration: % seconds',
        EXTRACT(EPOCH FROM batch_end_time - batch_start_time);
    RAISE NOTICE '=============================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '=============================================';
        RAISE NOTICE 'ERROR DURING SILVER LOAD';
        RAISE NOTICE 'Message: %', SQLERRM;
        RAISE NOTICE '=============================================';
END;
$$;
