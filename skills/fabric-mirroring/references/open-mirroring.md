# Open mirroring landing zone — full protocol

Source: `learn.microsoft.com/fabric/mirroring/open-mirroring-landing-zone-format`,
fetched 2026-08-30. The essentials are in `SKILL.md` §9; this is the rest.

## Landing zone layout

Every mirrored database has a unique OneLake location. The landing zone URL
appears on the mirrored database item's **Home** page.

```
https://onelake.dfs.fabric.microsoft.com/<workspace id>/<mirrored db id>/Files/LandingZone/TableA
https://onelake.dfs.fabric.microsoft.com/<workspace id>/<mirrored db id>/Files/LandingZone/TableB
```

With schemas — folder name is `<schemaname>.schema`, and there can be many
schemas each holding many tables:

```
.../Files/LandingZone/Schema1.schema/TableA
.../Files/LandingZone/Schema1.schema/TableB
.../Files/LandingZone/Schema2.schema/TableC
```

Write to it with the ADLS Gen2 API after authorizing against OneLake, or
upload through the portal (**Upload files** on the mirrored database home
page, which also prompts for table name and primary key columns and shows a
data preview). Microsoft publishes an
[Open Mirroring Python SDK](https://github.com/microsoft/fabric-toolbox/tree/main/tools/OpenMirroringPythonSDK)
in the `fabric-toolbox` repo. *(SDK not drilled beyond its existence.)*

## `_metadata.json` — per table folder

Required for updates and deletes. Minimum form:

```json
{ "keyColumns": ["C1", "C2"] }
```

`keyColumns` may be compound. It can be added at any time, but **once added
it cannot be changed**. If `_metadata.json` or `keyColumns` is absent,
updates and deletes are not possible.

### Nonsequential files and default-upsert

```json
{
  "keyColumns": ["id"],
  "fileDetectionStrategy": "LastUpdateTimeFileDetection",
  "isUpsertDefaultRowMarker": true
}
```

Files are then read by timestamp instead of sequence. The two settings are
independent — either alone, both, or neither are all supported.

## `_partnerEvents.json` — per mirrored database

Optional, strongly recommended for partner implementations. Placed at the
**mirrored database level**, not per table.

```json
{
  "partnerName": "testPartner",
  "sourceInfo": {
    "sourceType": "SQL",
    "sourceVersion": "2019",
    "additionalInformation": { "testKey": "testValue" }
  }
}
```

`sourceType` is a free string ("SQL", "Oracle", "Salesforce"). Keep
`partnerName` consistent across all mirrored databases.

## Data files

Parquet or delimited text (including CSV). Uncompressed, or Snappy, GZIP, or
ZSTD.

**Parquet** must use a valid logical/physical type combination per the
Parquet spec — e.g. `DATE` is days since epoch and must be `INT32`;
`logical=DATE, physical=INT64` is invalid.

**Delimited text** requires a header row and extra `_metadata.json`
properties. `FileExtension` is required whenever `FileFormat` is
`DelimitedText`.

| Property | Description | Notes |
| --- | --- | --- |
| `FirstRowAsHeader` | First row is a header | Must be `true` |
| `RowSeparator` | Row delimiter | Default `\r\n`; also `\n`, `\r` |
| `ColumnSeparator` | Column delimiter | Default `,`; also `;`, `\|`, `\t` |
| `QuoteCharacter` | Quotes values containing delimiters | Default `"`; also `'` or empty |
| `EscapeCharacter` | Escapes quotes inside quoted values | Default `\`; also `/`, `"`, or empty |
| `NullValue` | String representing null | e.g. `""`, `"N/A"`, `"null"` |
| `Encoding` | Character encoding | Default `UTF-8`; `ascii`, `utf-16`, `windows-1252`, … |
| `SchemaDefinition` | Column names, types, nullability | **Schema evolution is not supported** |
| `FileFormat` | Data file format | Defaults to `CSV`; must be `"DelimitedText"` for anything else |
| `FileExtension` | e.g. `.tsv`, `.psv` | Required with `DelimitedText` |

Only delimited text declares column types. Supported: `Double`, `Single`,
`Int16`, `Int32`, `Int64`, `DateTime`, `IDate`, `ITime`, `String`,
`Boolean`, `ByteArray`.

## `__rowMarker__`

Column name is exactly `__rowMarker__` (two underscores each side) and it
**must be the final column**.

| Value | Key not present in destination | Key present in destination |
| --- | --- | --- |
| `0` Insert | Insert | Insert — no duplicate-key validation |
| `1` Update | Insert — no existence check | Update the matching row |
| `2` Delete | No change — no existence check | Delete the matching row |
| `4` Upsert | Insert — no existence check | Update the matching row |

- **Row order** within a file must be the natural transaction order — it
  matters when the same row changes more than once.
- **File order**: monotonically increasing 20-digit names,
  `00000000000000000001.parquet`, continuous. Fabric deletes processed files
  but leaves the last one so the publisher can resume the sequence.
- **Initial load**: omit `__rowMarker__`. The whole file is treated as INSERT.
  Including it is allowed but not recommended.
- **Incremental**: a file becomes incremental as soon as `__rowMarker__`
  appears in any row. Updated rows must carry **all** columns.

Changing `EmployeeLocation` for `EmployeeID` E0001:

```
EmployeeID,EmployeeLocation,__rowMarker__
E0001,Redmond,0
E0002,Redmond,0
E0003,Redmond,0
E0001,Bellevue,1
```

Changing a **key** column is a DELETE of the old key plus an INSERT of the
new one. A DELETE row needs only the key columns:

```
EmployeeID,EmployeeLocation,__rowMarker__
E0001,Bellevue,0
E0001,NULL,2
E0002,Bellevue,0
```

## Table operations

| Operation | How |
| --- | --- |
| **Add** | Create the folder. Open mirroring scans for new tables every iteration. |
| **Drop** | Delete the folder. Tracked by ETag — a recreated folder drops and recreates the table. Deletion can fail if mirroring is mid-read; retry. |
| **Rename** | No rename. Drop the folder, recreate under the new name, repopulate all data. |

## Column operations

| Operation | Behaviour |
| --- | --- |
| **Add** | New columns in the Parquet/CSV are added to the Delta table automatically. |
| **Delete** | Dropping a column from new files stores `NULL` for it in new rows; old rows keep it. Open mirroring **unions all columns from every previous version**. To actually remove it, recreate the table folder. |
| **Change type** | Drop and recreate the folder with all data. Supplying a new type without recreating **errors and stops replication for that table**; recreating the folder resumes it. |
| **Rename** | Delete the folder and recreate it with all data under the new column name. |

Column types: simple Parquet types are supported. Complex types must be
written as JSON strings. Binary complex types (geography, images) can be
stored as binary.

## Cleanup

Processed files move to `_ProcessedFiles` or `_FilesReadyToDelete` and are
removed **after seven days**.
