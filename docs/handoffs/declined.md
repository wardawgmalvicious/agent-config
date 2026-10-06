# Declined

Learnings that reached this repo's inbox and were refused. `/triage`
reads this before it gives a verdict, and is its only writer. Entries
are dated and never corrected in place: a learning that comes back with
new evidence gets a verdict, or a new entry.

## 2026-10-06 — An `HTTPS_PROXY` for Claude Code on the corporate network

- **From**: a note of 2026-10-02, updated 2026-10-05, by a VS Code
  Local-agent session in a client Fabric repo.
- **Why not**: that network has no proxy. WinHTTP goes direct, WinINET
  has neither a proxy nor a PAC URL, `wpad` does not resolve and the
  .NET system proxy is direct, measured there on 2026-10-05 by the
  note's session. It resets Anthropic's hosts by name as the TLS
  handshake begins, which no proxy setting changes. Before that run, on
  2026-10-02, the user had chosen a machine-local overlay: the address
  in a User-scope variable that machine-config sets, copied into the
  live `env` as `HTTPS_PROXY` by `link-claude.ps1` only on that network.
  A committed `HTTPS_PROXY` breaks every other network, `-Force` replaces
  the live `env` whole, settings `env` values are literal strings, and
  the docs say the `processWrapper` launcher is ignored on Windows.
- **Would change it**: a network Claude Code has to work on that does
  route through a proxy.
