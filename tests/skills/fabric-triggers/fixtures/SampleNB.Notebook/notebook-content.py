# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # SampleNB
# Trigger fixture. Exists so `**/*.Notebook/**` has something to match.

# CELL ********************

df = spark.read.format("delta").load("Tables/sample")
df.write.mode("overwrite").saveAsTable("sample_copy")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
