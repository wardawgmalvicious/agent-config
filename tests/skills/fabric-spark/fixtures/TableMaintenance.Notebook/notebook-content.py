# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # TableMaintenance
# Nightly OPTIMIZE and VACUUM over every table in the target schema.

# CELL ********************

target_schema = "silver"
retain_hours = 168

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

tables = [t.name for t in spark.catalog.listTables(target_schema)]
print(f"{len(tables)} tables in {target_schema}")

for table in tables:
    full_name = f"{target_schema}.{table}"
    spark.sql(f"OPTIMIZE {full_name}")
    spark.sql(f"VACUUM {full_name} RETAIN {retain_hours} HOURS")
    print(f"done: {full_name}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
