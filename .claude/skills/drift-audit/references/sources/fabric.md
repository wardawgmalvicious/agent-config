# `fabric` — Microsoft Fabric (incl. RTI)

- `repo`: `MicrosoftDocs/fabric-docs`
- `branch`: `main`
- `path`: `docs/fundamentals/whats-new.md`
- `shape`: `table`
- `columns`: feature = the bold text in `Feature`, description =
  `Learn more`, status = table membership plus the suffix inside the
  bold name (`(Preview)`, `(Generally Available)`; the spelling varies),
  and the GA table adds `Month`
- `sections`: `Features currently in preview`,
  `Generally available features` — the only headings carrying entries
  since the page's 2026-10-02 restructure (`9eda27f8`), checked
  2026-10-06
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `drill.strip`: `#post-NNNN-_TocNNNN`, any `#post-...`, and `#toc-hId-<signed-int>`
  — the community-blog table-of-contents form. **The integer is signed**, so the
  hyphen doubles on negatives (`#toc-hId-1329740083` *and* `#toc-hId--1208717068`);
  a pattern anchored on one hyphen misses roughly half. At 2026-08-29 the page
  carried 37 of these against 14 `#post-...`, so both forms are live — the
  `#post-...` patterns are incomplete, not superseded.
  Strip a third form too, `#community-<postid>-mcetoc_<id>_<n>`, with
  `#community-\d+-mcetoc_[A-Za-z0-9_]+`. **It arrived in the 2026-10-06
  audit's window**: 0 at base `8375c89d` (2026-08-31), 108 at head
  `7ff5f2b3` (2026-10-02), where `#post-...` was down to 10 and
  `#toc-hId-...` to 13. Its id takes two shapes at head,
  `mcetoc_1k3kj91s5_<n>` (98 links) and `mcetoc_1k3t…_<n>` (10), and the
  regex matches both.
- `artifacts`: skills, rules, `CLAUDE.md`, MCP templates

Real-Time Intelligence has no separate What's New page — RTI updates fold
into this source. Don't search for one.

**Size, measured 2026-10-06.** `whats-new.md` was 207,309 bytes and 609
lines at the window's diff base `8375c89d` (2026-08-31), and 147,892
bytes and 388 lines at head `7ff5f2b3` (2026-10-02), after the
restructure. Two full versions are about 355 KB, more than twice
SKILL.md § 4a's 150 KB per-source budget, and even a unified diff of
that window measured 267,382 bytes.
