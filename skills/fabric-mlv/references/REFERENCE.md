# MS Learn link bundle — Materialized Lake Views

Curated set of Microsoft Learn pages relevant to Microsoft Fabric Materialized Lake Views (MLVs) — the declarative `CREATE MATERIALIZED LAKE VIEW` Spark SQL surface, the preview `@fmlv.materialized_lake_view` PySpark decorator, optimal refresh (skip / incremental / full) and the CDF prerequisite, lineage-driven scheduling, the `RefreshMaterializedLakeViews` REST API, the auto-generated data quality report, and the lakehouse-schemas + Runtime 1.3 prerequisites.

The 3 highest-leverage entry points (concept overview, Spark SQL reference, optimal refresh) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on coverage:** MLVs are documented thoroughly under `learn.microsoft.com/fabric/data-engineering/materialized-lake-views/`. The parent skill's value-add over the docs is the consolidated gotchas table (PySpark notebook organization rules, `spark.conf.set` ignored on refresh, names lowercased, the supported-construct table for incremental fallback, the Skipped-vs-Canceled status display mismatch).

## Concept and when to use

- [What are materialized lake views in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/overview-materialized-lake-view) — start here. Concept, lifecycle (create / refresh / query / monitor), authoring options, when MLVs fit vs when to use Spark notebooks or Real-Time Intelligence instead. The South Central US region exclusion lives here.
- [Get started with materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/get-started-with-materialized-lake-views) — the prerequisites: workspace on Fabric capacity, **schema-enabled lakehouse**, **Runtime 1.3**.
- [Tutorial: Implement medallion architecture with materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/tutorial) — end-to-end bronze → silver → gold walkthrough.
- [Use materialized lake views for medallion architecture (OneLake guidance)](https://learn.microsoft.com/fabric/onelake/onelake-medallion-lakehouse-architecture#use-materialized-lake-views-for-medallion-architecture) — where MLVs fit in the broader medallion / data-mesh story.

## Spark SQL reference

- [Spark SQL reference for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view) — `CREATE [OR REPLACE] [IF NOT EXISTS]`, `CONSTRAINT ... CHECK ... ON MISMATCH DROP|FAIL`, `PARTITIONED BY`, `TBLPROPERTIES`, `SHOW MATERIALIZED LAKE VIEWS`, `SHOW CREATE`, `ALTER ... RENAME` (only RENAME, no definition update), `DROP`, plus the Spark-SQL limitations (no DML, no time-travel, no UDFs, no temp views as sources, no all-uppercase schemas, session-level `spark.conf.set` ignored on refresh).

## PySpark (`fmlv` — preview)

- [PySpark reference for materialized lake views (Preview)](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view-pyspark) — `import fmlv`, the `@fmlv.materialized_lake_view` decorator, `@fmlv.check`, the SQL-vs-PySpark decision flowchart, the notebook organization rules (one decorator per cell, helpers above, hardcoded literals only, don't delete the defining notebook), and the PySpark-only limitations (always full refresh, lineage-schedule-only, no variables in decorator, periods reserved in names).

## Optimal refresh (skip / incremental / full)

- [Optimal refresh for materialized lake views in a lakehouse](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/refresh-materialized-lake-view) — the optimal-refresh decision engine, the supported-SQL-constructs table (which constructs allow incremental vs force full), the CDF (`delta.enableChangeDataFeed=true`) prerequisite for incremental, `REFRESH MATERIALIZED LAKE VIEW ... FULL`, the manage-toggle to disable optimal refresh, and the explicit "PySpark-defined MLVs always use full refresh" / "non-Delta sources always use full refresh" carveouts.
- [Use Delta Lake change data feed (Databricks docs — referenced from MS Learn)](https://learn.microsoft.com/azure/databricks/delta/delta-change-data-feed) — the underlying CDF mechanism the MLV optimal-refresh engine reads.

## Lineage and scheduling

- [Manage Fabric materialized lake views lineage](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/view-lineage) — the lineage view, dependency graph, custom Spark environment, the auto-refresh-every-2-minutes UI behavior, the deleted-environment fallback.
- [Recent runs of materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/run-history) — the **last 25 runs OR last 7 days, whichever comes first** retention rule, the run-state semantics (In progress / Success / Failed / Skipped / Canceled), the "child views auto-marked Skipped if parent fails" behavior.
- [Monitor materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/monitor-materialized-lake-views) — Monitor hub for `RefreshMaterializedLakeViews` job-type runs, sort/filter/search, view-detail and cancel actions, the `MLV_LakehouseName_JobInstanceID` activity-name pattern.

## REST API (job scheduler — `RefreshMaterializedLakeViews`)

- [Manage and refresh materialized lake views in Fabric with APIs](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/materialized-lake-views-public-api) — every endpoint (Create / Get / List / Update / Delete schedule, Run on-demand, List / Get / Cancel job instances) with `{jobType}=RefreshMaterializedLakeViews`, the schedule-limits-per-lakehouse caveat, the Skipped-vs-Canceled status mismatch between Monitoring hub and lineage view.
- [Job scheduler — Run On Demand Item Job](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/run-on-demand-item-job?tabs=HTTP) — the underlying generic on-demand endpoint the MLV API binds to.
- [Job scheduler — Create Item Schedule](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/create-item-schedule?tabs=HTTP) — the underlying generic schedule CRUD.
- [Job scheduler — Get Item Job Instance](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/get-item-job-instance?tabs=HTTP) — for polling a returned `Location` header to completion.

## Data quality report

- [Data quality report for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/data-quality-reports) — the auto-generated Power BI report (Overview + MLV Detail pages), the violations-vs-drops semantics (drops ≤ violations), the **DirectQuery 1M-row cap on non-premium**, the workspace/lakehouse-name-with-special-characters generation failure, and the `Read` / `ReadData` SQL-analytics-endpoint permission required for recipients.

## Lakehouse prerequisites

- [Lakehouse schemas (Public preview)](https://learn.microsoft.com/fabric/data-engineering/lakehouse-schemas) — the `enableSchemas` toggle that's required for MLVs and is **immutable per lakehouse** (you can't add schemas to an existing non-schema lakehouse without recreating).
- [Fabric Runtime 1.3](https://learn.microsoft.com/fabric/data-engineering/runtime-1-3) — the runtime version MLV authoring requires.
- [Spark views in lakehouses](https://learn.microsoft.com/fabric/data-engineering/lakehouse-spark-views) — the lightweight (non-persisted) alternative for cases where you don't need MLV materialization.

## Delta Lake (the storage layer MLVs persist into)

- [What is Delta Lake?](https://learn.microsoft.com/azure/databricks/delta/) — the table format MLVs persist as. CDF, partitioning, table properties.
- [Delta Lake table properties reference](https://learn.microsoft.com/azure/databricks/delta/table-properties) — for `TBLPROPERTIES` keys you can set on an MLV (`delta.enableChangeDataFeed`, `delta.minReaderVersion`, etc.).

## Comparison points

- [Materialized views in KQL (Eventhouse)](https://learn.microsoft.com/kusto/management/materialized-views/materialized-view-overview?view=microsoft-fabric) — the analogous KQL feature in Eventhouse; not the same engine, similar concept. Useful when a user is choosing between Lakehouse + MLV and Eventhouse + KQL MV.
- [Schedule refreshes in Databricks SQL (`SCHEDULE` / `TRIGGER ON UPDATE`)](https://learn.microsoft.com/azure/databricks/ldp/dbsql/schedule-refreshes) — the Databricks materialized-view counterpart. Fabric's MLVs do not currently support a SQL-clause-level `SCHEDULE` (scheduling is lakehouse-level, lineage-wide).

## See also (this repo)

- `fabric-spark` — the broader PySpark surface MLVs ride on; covers the no-external-HTTP rule and `abfss://` URI shape relevant to MLV `SELECT` sources
- `fabric-eventhouse` — KQL materialized views, the closest cross-engine analog
- `fabric-error-handling` — notebookutils / pipeline error patterns for wrapping MLV refresh in a larger flow
- `fabric-monitoring` — Workspace Monitoring + Monitor hub for the broader observability story
- `fabric-rest-api` — generic LRO / 202 Accepted polling pattern used by the MLV on-demand endpoint
- `pbip-project-structure` — `.Lakehouse/` folder placement when MLV-bearing lakehouses live in a PBIP repo
