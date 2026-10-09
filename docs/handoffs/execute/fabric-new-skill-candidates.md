---
status: deferred
priority: 3
needs: []
blocked-by: []
reopen-when: client work outside the Git-sync sandbox uses Business Events, a dbt job or a Fabric Maps item
written: 2026-10-09
---

# Handoff: three Fabric skill candidates wait for client work

- **Written**: 2026-10-09, to carry what
  [platform-skill-portfolio.md](platform-skill-portfolio.md) held: three
  new skills the user accepted for `/author-skill` on 2026-10-06, before
  deciding on 2026-10-08 to slim the platform skills. On 2026-10-09 they
  ruled out new platform skills while the portfolio shrinks, unless
  client work uses the item.
- **Kind**: for each candidate whose trigger fires, a decision first,
  then `/author-skill` or an edit. Nothing is drafted.

## The candidates

The evidence is the 2026-10-06 `fabric` audit's
[brief 19](../../audits/2026-10-06/fabric/completed/19-decide-new-skill-candidates.md),
whose own rationale for each was the same: a skill is worth writing if
the item is in use.

| Candidate | What's New, by 2026-10-02 | Covered now by |
| --- | --- | --- |
| Business Events | GA, September 2026; Activator as publisher still preview; schemas live in the Schema Registry | passing mentions in `fabric-activator` and `fabric-event-schema-set` |
| dbt job | GA in Data Factory, September 2026 | a "dbt Job *(preview)*" row in `fabric-deployment-pipelines`' reference |
| Fabric Maps | data-driven styling GA, August 2026; three preview rows, among them Maps in Real-Time Dashboards | an item-type name in the same reference |

## On reopening

Re-read brief 19's evidence against What's New and Learn, since it was
measured in the week of 2026-10-02. Then weigh a reference under the
skill that owns the item's neighbourhood before a skill of its own:
`fabric-event-schema-set` or `fabric-activator` for Business Events,
`fabric-data-pipeline` for a dbt job, `fabric-realtime-dashboard` for
Maps. The slimmed portfolio prefers fewer, larger skills, and the user
decides the shape.

## Re-measure before acting

```bash
grep -rniE 'business event|dbt|fabric maps' skills/   # the passing mentions above, on 2026-10-06
```

## Scrubbing

Client repos are named by kind.
