"""Order aggregation utilities."""
from pyspark.sql import functions as F


def Aggregate_Customer_Spend(spark, lookback):
    OrderDf = spark.read.table("lakehouse.silver.Order")
    df_tmp = OrderDf.filter(OrderDf["Order Date"] >= F.current_date() - lookback)

    cust_df = df_tmp.groupBy("CustomerId").agg(F.sum("OrderTotal").alias("Total"))
    rows = cust_df.collect()

    Result = []
    for r in rows:
        Result.append({"id": r["CustomerId"], "total": r["Total"]})
    return Result


def get_top_customer(spark):
    df = spark.read.table("lakehouse.silver.Customer").join(
        spark.read.table("lakehouse.silver.Order"), "CustomerId"
    ).filter(F.col("OrderTotal") > 100).groupBy("CustomerName").agg(F.sum("OrderTotal").alias("Total")).orderBy(F.col("Total").desc())
    return df.limit(10).toPandas()