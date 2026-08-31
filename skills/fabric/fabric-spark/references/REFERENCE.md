# MS Learn link bundle — Fabric Spark / PySpark

Curated set of Microsoft Learn pages relevant to PySpark / Spark in Microsoft Fabric — notebooks, NotebookUtils, lakehouses, table maintenance, V-Order, autotune, Spark Job Definitions, environments, libraries, and runtime versions. Load on demand when you need authoritative reference for a specific area.

The 3 highest-leverage entry points (lakehouse overview, Spark compute / pools, NotebookUtils) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Concept and overview

- [What is a lakehouse in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview) — concept, lakehouse vs warehouse comparison, when to use each. Read first if orienting.
- [Apache Spark compute in Microsoft Fabric](https://learn.microsoft.com/fabric/data-engineering/spark-compute) — starter pools vs custom pools, capacity-unit-to-vCore mapping (1 CU = 2 vCores, 3× burst), session expiry, billing model.
- [What is an Apache Spark job definition?](https://learn.microsoft.com/fabric/data-engineering/spark-job-definition) — SJD concept, default lakehouse requirement, when to choose SJD over a notebook.

## Notebook authoring and execution

- [Develop, execute, and manage Fabric notebooks](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook) — magic commands (`%%pyspark`, `%%sql`, `%%configure`, `%pip`, `%conda`), parameters cell, reference run, session config. Authoritative notebook authoring reference.
- [NotebookUtils (formerly MSSparkUtils) for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebook-utilities) — the canonical utility module. File system, secrets, notebook chaining, runtime context. Use the `notebookutils` namespace in new code.
- [Microsoft Spark Utilities (MSSparkUtils) — legacy reference](https://learn.microsoft.com/fabric/data-engineering/microsoft-spark-utilities) — previous namespace, still backward-compatible. Linked here for porting older code.
- [Use Python for Apache Spark in Fabric](https://learn.microsoft.com/fabric/data-science/python-guide/python-overview) — PySpark basics, libraries, notebook utilities. Good entry for Python-first developers.
- [Manage and execute notebooks with REST APIs](https://learn.microsoft.com/fabric/data-engineering/notebook-public-api) — programmatic CRUD + Run on Demand. Pair with `fabric-rest-api` skill.

## Lakehouse and table operations

- [Run Delta table maintenance in Lakehouse](https://learn.microsoft.com/fabric/data-engineering/lakehouse-table-maintenance) — UI walkthrough for OPTIMIZE / V-Order / VACUUM. Pipeline orchestration via Lakehouse Maintenance activity.
- [Manage the lakehouse with the Microsoft Fabric REST API](https://learn.microsoft.com/fabric/data-engineering/lakehouse-api) — programmatic lakehouse CRUD + Run table maintenance on a Delta table.
- [Bring your data to OneLake with Lakehouse](https://learn.microsoft.com/fabric/onelake/create-lakehouse-onelake) — file upload, ABFS path discovery, OneLake file explorer integration.

## Performance and optimization

- [Optimize Delta Lake tables with V-Order](https://learn.microsoft.com/fabric/data-engineering/delta-optimization-and-v-order) — V-Order behavior, when to enable per layer, V-Order × Z-Order × OPTIMIZE × VACUUM combinations, session vs TBLPROPERTIES vs operation-level control.
- [Cross-workload table maintenance and optimization](https://learn.microsoft.com/fabric/fundamentals/table-maintenance-optimization) — engine-specific optimal file layouts (Spark vs SQL endpoint vs Direct Lake vs Mirroring), V-Order's cross-engine impact (40-60% Direct Lake, 10% SQL endpoint, none for Spark with 15-33% write overhead).
- [Tune file size](https://learn.microsoft.com/fabric/data-engineering/tune-file-size) — adaptive target file size, optimize-write semantics, partition vs file-size tradeoffs.
- [What is autotune for Spark configurations in Fabric?](https://learn.microsoft.com/fabric/data-engineering/autotune) — runtime 1.2 only; per-query-shape learning across executions. Single-session enable/disable.
- [Concurrency limits and queueing](https://learn.microsoft.com/fabric/data-engineering/spark-job-concurrency-and-queueing) — concurrent-job limits per SKU, FIFO queueing, what gets queued vs rejected.

## Spark Job Definitions

- [Schedule and run a Spark Job Definition](https://learn.microsoft.com/fabric/data-engineering/run-spark-job-definition) — UI workflow for SJD execution and snapshots; account-of-record for manual vs scheduled runs.
- [Spark Job Definition REST API tutorial](https://learn.microsoft.com/fabric/data-engineering/spark-job-definition-api) — end-to-end: create SJD shell → upload main file via OneLake → update with file URLs.

## Environments and libraries

- [Manage Apache Spark libraries in Microsoft Fabric](https://learn.microsoft.com/fabric/data-engineering/library-management) — built-in vs public (PyPI/Conda) vs custom (.whl/.jar/.tar.gz), inline `%pip` / `%conda`, environment-vs-inline tradeoffs.
- [Spark compute configuration settings in Fabric environments](https://learn.microsoft.com/fabric/data-engineering/environment-manage-compute) — workspace-level toggle for item-level compute customization, pool / runtime / driver / executor sizing per environment.
- [Environment definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/environment-definition) — `Libraries/PublicLibraries/environment.yml`, `Libraries/CustomLibraries/<name>.{jar|py|whl|tar.gz}`, `Setting/Sparkcompute.yml` definition parts. Pair with `fabric-rest-api`.

## Runtime and monitoring

- [Fabric Spark Runtime](https://learn.microsoft.com/fabric/data-engineering/runtime) — runtime version matrix, Spark / Delta / Python / Scala versions per runtime, included library list. Critical for compatibility checks.
- [Spark application monitoring](https://learn.microsoft.com/fabric/data-engineering/spark-detail-monitoring) — application / job / stage / task hierarchy, monitoring hub navigation.
- [Spark job monitoring and debugging](https://learn.microsoft.com/fabric/data-engineering/spark-monitor-debug) — Spark UI access, log inspection, OOM and skew diagnosis.

## Best practices and migration

- [Spark best practices — development and monitoring](https://learn.microsoft.com/fabric/data-engineering/spark-best-practices-development-monitoring) — `%%configure` patterns for parameterized session config, variable-library integration, CI/CD-friendly notebook authoring.
- [Compare Fabric Data Engineering and Azure Synapse Spark](https://learn.microsoft.com/fabric/data-engineering/comparison-between-fabric-and-azure-synapse-spark) — feature parity matrix, Synapse-to-Fabric migration considerations. Useful when porting Synapse Spark code.
