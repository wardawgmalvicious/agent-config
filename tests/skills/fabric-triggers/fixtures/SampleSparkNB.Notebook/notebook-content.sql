-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "synapse_pyspark"
-- META   },
-- META   "dependencies": {
-- META     "lakehouse": {
-- META       "default_lakehouse_name": "",
-- META       "default_lakehouse_workspace_id": ""
-- META     }
-- META   }
-- META }

-- MARKDOWN ********************

-- # SampleSparkNB
-- Trigger fixture. Exists so `**/*.Notebook/notebook-content.sql` has
-- something to match. The `synapse_pyspark` kernel above is what makes
-- this Spark SQL rather than Warehouse T-SQL.

-- CELL ********************

SELECT
      cust.CustomerId
    , cust.`customer_name`
FROM lakehouse.silver.Customer AS cust;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }
