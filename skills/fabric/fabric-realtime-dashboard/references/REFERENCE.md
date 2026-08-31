# fabric-realtime-dashboard — reference

## `money()` display formatter

Validated Aug 2026 (incl. rounding carry `$999.995 → $1,000.00`, negatives
`-$14,751.36`, millions). Needed because KQL has no `format_number()` and RE2
has no lookahead for regex comma insertion. Duplicate into each query that
needs it — base queries are tabular only and cannot host a scalar lambda.

```kusto
let money = (v: real) {
    let r = round(v, 2);
    let a = abs(r);
    let w = tolong(a);
    let c = tolong(round((a - todouble(w)) * 100, 0));
    let cw = iff(c >= 100, w + 1, w);
    let cc = iff(c >= 100, long(0), c);
    let m = cw / 1000000;
    let t = (cw % 1000000) / 1000;
    let u = cw % 1000;
    let t3 = substring(strcat("00", tostring(t)), strlen(strcat("00", tostring(t))) - 3);
    let u3 = substring(strcat("00", tostring(u)), strlen(strcat("00", tostring(u))) - 3);
    let whole = case(m > 0, strcat(tostring(m), ",", t3, ",", u3), t > 0, strcat(tostring(t), ",", u3), tostring(u));
    let c2 = substring(strcat("0", tostring(cc)), strlen(strcat("0", tostring(cc))) - 2);
    strcat(iff(r < 0, "-", ""), "$", whole, ".", c2)
};
```

Usage: `| summarize Total = sum(NetPrice) | project Total = money(Total)`.
Caveat: string values lose the stat visual's automatic k/M abbreviation
(usually the point), and numeric color rules no longer apply.

Percent variant inline: `strcat(tostring(round(100.0 * a / b, 1)), "%")`,
guarding division with `iff(b == 0, "n/a", ...)`.

## Timezone-anchored "today"

A dashboard has no date table; anchor business dates explicitly:

```kusto
let _today = startofday(datetime_utc_to_local(now(), "US/Eastern"));
```

`TODAY()`-style UTC rollover bugs reproduce here too — `now()` is UTC and
rolls the date at 8 PM Eastern without the conversion.

## Business days month-to-date (as a base query)

Single tabular expression (base-query compatible); holiday table optional:

```kusto
range Day from startofmonth(startofday(datetime_utc_to_local(now(), "US/Eastern"))) to startofday(datetime_utc_to_local(now(), "US/Eastern")) step 1d
| where dayofweek(Day) between (1d .. 5d)
| join kind=leftanti (
    HolidayTable
    | project Day = startofday(todatetime(Date))
    | distinct Day
) on Day
```

`dayofweek()` returns a timespan: `0d` = Sunday … `6d` = Saturday.

## Multistat with ordered rows

`union` does not guarantee order — carry an ordinal and sort:

```kusto
union
    (print Ord = 1, Metric = "Today", Value = money(todouble(_todayTotal))),
    (print Ord = 2, Metric = "MTD Avg / Business Day", Value = money(todouble(_avgBizDay))),
    (print Ord = 3, Metric = "% of Daily Avg", Value = iff(_avgBizDay == 0, "n/a", strcat(tostring(round(100.0 * todouble(_todayTotal) / todouble(_avgBizDay), 1)), "%")))
| order by Ord asc
| project Metric, Value
```

visualOptions: `{"multiStat__labelColumn": "Metric", "multiStat__valueColumn":
"Value", "multiStat__displayOrientation": "horizontal", "multiStat__slot":
{"width": 3, "height": 1}}`.

## Deterministic ids for scripted authoring

`uuid.uuid5(FIXED_NAMESPACE, "query:tile-orders-today")` — reruns of a
generator script produce identical ids, so regenerating the file never
triggers the delete+recreate identity break.
