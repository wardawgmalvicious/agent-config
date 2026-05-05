# MS Learn link bundle — Fabric Variable Library

Curated set of Microsoft Learn pages relevant to Fabric Variable Library — config-as-code item type for parameterizing notebooks, pipelines, lakehouse shortcuts, dataflows, copy jobs, and user data functions across environments.

The 3 highest-leverage entry points (overview, NotebookUtils API reference, pipeline integration) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The Variable Library product is documented under `learn.microsoft.com/fabric/cicd/variable-library/` (concept + types + value sets + REST). Per-consumer integration docs live with the consumer (notebooks under data-engineering, pipelines under data-factory, etc.). Both branches are linked below.

## Concept and overview

- [What is a variable library?](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview) — concept, the supported-items list (Pipeline, lakehouse shortcut, Notebook via NotebookUtils, Dataflow Gen 2, Copy job, User data functions), naming conventions. Read first.
- [Get started with variable libraries](https://learn.microsoft.com/fabric/cicd/variable-library/get-started-variable-libraries) — UI walkthrough: add/delete/edit variables, add value sets, set active, the 1000-variable / 1000-value-set / 10000-cell / 1 MB limits.
- [Variable library CI/CD](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-cicd) — Git integration + deployment pipeline patterns; how value-set selection is workspace state (not item definition).

## Variable types and value sets

- [Variable types in variable libraries](https://learn.microsoft.com/fabric/cicd/variable-library/variable-types) — full type reference (String, Boolean, Integer, Number, DateTime, Guid, Item reference, Connection reference) and naming conventions.
- [Item reference variable type](https://learn.microsoft.com/fabric/cicd/variable-library/item-reference-variable-type) — `{itemId, workspaceId}` schema and runtime-vs-logicalId implications. Pair with `fabric-rest-api` skill.
- [Connection reference variable type](https://learn.microsoft.com/fabric/cicd/variable-library/connection-reference-variable-type) — connection-id binding shape.
- [Value-sets in variable libraries](https://learn.microsoft.com/fabric/cicd/variable-library/value-sets) — only-deltas-from-default storage model, per-environment file structure (`MyVars_Default.json`, `MyVars_Prod.json`), naming rules, the no-reorder-in-UI limitation (edit JSON to reorder).

## Notebook consumption (Python / Scala / R)

- [NotebookUtils variable library utilities for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-variable-library) — full API: `getLibrary("name").variableName`, `getVariable('name')`, bracket syntax, the alternative `get("$(/**/lib/var)")` reference-path form. Considerations: same-workspace only, no SPN auth (yet), read-only from notebooks, case-sensitive names.
- [Spark best practices: Development and Monitoring](https://learn.microsoft.com/fabric/data-engineering/spark-best-practices-development-monitoring) — CI/CD section with the canonical "dynamically interacting Lakehouses" worked example (`abfss://...` path constructed from VL values).
- [Spark session configuration via `%%configure`](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#spark-session-configuration-magic-command) — magic command syntax for binding default lakehouse / spark conf via VL values.

## Pipeline consumption (Data Factory)

- [Variable library integration with pipelines](https://learn.microsoft.com/fabric/data-factory/variable-library-integration-with-data-pipelines) — UI walkthrough, the "Library variables" tab, the `@pipeline.libraryVariables.<name>` expression syntax, expression-builder integration. Documents the **type-name mapping the parent skill calls out**: Boolean→Bool, Integer→Int, Datetime→String, Guid→String. Number is currently unsupported in pipelines.
- [Convert Azure Data Factory global parameters to Fabric variable libraries](https://learn.microsoft.com/fabric/data-factory/convert-global-parameters-to-variable-libraries) — migration mapping `@globalParameters('X')` → `@pipeline.libraryVariables.X`; current limitations (no auto-conversion in upgrade tool, connections don't support expression parameterization the same way).
- [Migration planning: ADF → Fabric Data Factory](https://learn.microsoft.com/fabric/data-factory/migrate-planning-azure-data-factory) — broader architectural-difference table including Variable Library vs ADF Global Parameters.

## Other consumers

- [Assign variables to lakehouse shortcuts](https://learn.microsoft.com/fabric/onelake/assign-variables-to-shortcuts) — parameterizing OneLake shortcuts with VL values.
- [Dataflow Gen 2 variable library integration](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-variable-library-integration) — Power Query / Dataflow consumption.
- [Copy Job CI/CD with variable libraries](https://learn.microsoft.com/fabric/data-factory/cicd-copy-job) — Copy Job parameter binding.
- [User Data Functions: Get variables from Fabric variable libraries](https://learn.microsoft.com/fabric/data-engineering/user-data-functions/python-programming-model#get-variables-from-fabric-variable-libraries) — Python UDF runtime API.

## REST API (programmatic management)

- [VariableLibrary item REST overview](https://learn.microsoft.com/rest/api/fabric/variablelibrary/items) — list / create / get / update / delete entry points.
- [Update VariableLibrary (set active value set, etc.)](https://learn.microsoft.com/rest/api/fabric/variablelibrary/items/update-variable-library) — the canonical PATCH for switching active value set programmatically.
- [Get VariableLibrary definition](https://learn.microsoft.com/rest/api/fabric/variablelibrary/items/get-variable-library-definition) — fetch the definition envelope (variables.json, settings.json, valueSets/*).
- [Update item definition (cross-item)](https://learn.microsoft.com/rest/api/fabric/core/items/update-item-definition) — used to reorder value sets (UI-blocked path).
- [VariableLibrary item definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/variable-library-definition) — definition-envelope schema. **Confirms the `format` field is NOT supported** for VariableLibrary parts (the parent skill's gotcha).
