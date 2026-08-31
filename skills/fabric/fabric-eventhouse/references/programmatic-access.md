# Programmatic access and item definitions

Driving Eventhouse from `az rest` / Fabric REST: the query endpoint call, and
the item-definition envelope for create/update. `SKILL.md` carries the cluster
URI shape and token audience you need for any of it.

## Connection

- **Cluster URI**: each KQL Database has a unique `queryServiceUri` of the form `https://<cluster>.kusto.fabric.microsoft.com`. Discover via Fabric REST: `GET /v1/workspaces/{wsId}/kqlDatabases` (returns `queryServiceUri` and `databaseName` per item).
- **Token audience**: `https://kusto.kusto.windows.net/.default` for all direct access.
- **Query endpoint**: `POST {clusterUri}/v1/rest/query` with body `{"db":"<dbName>", "csl":"<KQL>"}`.
- **KQL `|` breaks shell escaping** — write the JSON body to a temp file and use `--body @<file>` (bash) or `@$env:TEMP\kql_body.json` (PowerShell).

```bash
cat > /tmp/kql_body.json << 'EOF'
{"db":"MyDB","csl":"MyTable | take 10"}
EOF
az rest --method POST \
  --url "${CLUSTER_URI}/v1/rest/query" \
  --resource "https://kusto.kusto.windows.net" \
  --body @/tmp/kql_body.json \
  | jq '.Tables[0].Rows'
```

## Item definition envelope (REST)

For programmatic create/update via Fabric REST (see fabric-rest-api skill for the envelope):

| Item | Format | Required parts |
|---|---|---|
| **Eventhouse** | `JSON` | `EventhouseProperties.json` (currently empty: `{}`) |
| **KQLDatabase** | `JSON` | `DatabaseProperties.json` (+ optional `DatabaseSchema.kql`) |

`DatabaseProperties.json` schema:

```json
{
  "databaseType": "ReadWrite",
  "parentEventhouseItemId": "<eventhouse-item-id>",
  "oneLakeCachingPeriod": "P36500D",
  "oneLakeStandardStoragePeriod": "P365000D"
}
```

`DatabaseSchema.kql` is an optional KQLDatabase part — KQL management commands run at deploy time. Use to seed tables, materialized views, functions, and ingestion mappings as part of the definition (e.g. `.create-merge table MyLogs (...)` blocks).
