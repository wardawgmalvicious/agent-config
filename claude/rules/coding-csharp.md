---
paths:
  - "**/*.cs"
  - "**/*.csproj"
---

# C# Coding Conventions

Applies to C# on current .NET: libraries, console tools, services and
desktop apps. XAML apps add [coding-xaml.md](coding-xaml.md), which also
covers view models and code-behind. Project files match too, because the
package choices below — SqlClient, JSON, trimming — are made there.

If a project-scope `.claude/rules/coding-csharp.md` exists, that file
supersedes this one.

## The repo's own config wins

**Anything a repo's `.editorconfig`, `Directory.Build.props` or analyzer
set already pins wins over this file, and this file says nothing about
it.** Where a file already follows a consistent style of its own, that
file wins too — `dotnet/runtime` states the same precedence. The failure
this prevents is silent and confusing: code is written to the rule, the
IDE reformats it on save, and nothing says which was right.

So this rule spends no lines on layout, spacing, brace placement or
`using` order. That is what `.editorconfig` exists to express, so a rule
stating it would be either redundant or in conflict, and never the
authority. What follows are only the forks where both branches are
defensible and an unguided model answers differently from one session to
the next.

## Declarations

- **`var` only when the type is apparent from the right-hand side** — a
  `new`, an explicit cast, or a literal. Otherwise write the type. A
  method name does not make the type apparent. Explicit in `foreach`;
  `var` where it is required (anonymous types, LINQ projections). This
  follows Learn and `dotnet/runtime`, which agree; the reasoning is that
  a diff under review has no hover tooltip. Decided 2026-09-10.
- Target-typed `new()` only where the type is named on the left of the
  same declaration: `FileStream stream = new(...)`, never
  `stream = new(...)` on a later line.
- Force initialization with `required` members, not with constructor
  parameters that exist only to be copied into properties.

## Nullable reference types

- **Annotations are compile-time only.** The compiler inserts no runtime
  check, so a public entry point still validates its arguments
  (`ArgumentNullException.ThrowIfNull`). Callers compiled without
  nullable context, and anything arriving via reflection or
  deserialization, pass `null` straight through.
- `!` asserts an invariant the compiler cannot see. Name that invariant
  in a comment on the same line, or do not use it. The one routine
  exception is EF Core navigation properties (`= null!`), which the EF
  docs themselves prescribe.
- **EF Core reads the annotations.** `string` maps to a `NOT NULL`
  column and `string?` to a nullable one. Turning `<Nullable>` on in a
  project with existing migrations makes the next migration alter column
  nullability — review that migration rather than accepting it.

## Async

- **Accept a `CancellationToken` and forward it.** Any async method whose
  callees accept a token takes `CancellationToken cancellationToken` as
  its last parameter and passes it to every callee that takes one
  (CA1068, CA2016). Give it a `= default` value only on public entry
  points, never internally, so a dropped token cannot hide behind the
  default. Decided 2026-09-10.
- **`ConfigureAwait(false)` in library code, never in app code.** A
  general-purpose library cannot know whether its caller has a
  `SynchronizationContext`, so it does not capture one. App-level code
  wants the captured context: after `ConfigureAwait(false)` in a UI event
  handler, the next line runs off the UI thread and touching a control
  throws. Source: the ConfigureAwait FAQ on the .NET blog.
- `async void` only for event handlers. An exception thrown from one
  cannot be caught by the caller and takes the process down.

## Dependencies and lifetime

- **Constructor injection.** Resolving from the container inside a class
  (`GetService<T>()`) hides that class's dependencies; Learn's DI
  guidelines name it an anti-pattern. The exception is a type the
  framework constructs itself — see coding-xaml.md for XAML pages.
- **Never dispose a service you resolved from the container.** The
  container owns it and disposes it at the end of its lifetime; a
  constructor parameter implementing `IDisposable` does not make the
  receiver its owner. You dispose only what you `new`.
- **Azure SDK clients are singletons.** They are thread-safe and
  immutable, so construct one per endpoint and credential and reuse it.
  HTTP-based clients are not `IDisposable`. The AMQP ones —
  Event Hubs and Service Bus — are, and need `DisposeAsync` at shutdown.
  Model types (`EventDataBatch`, `KeyVaultSecret`) are **not**
  thread-safe.
- `EventDataBatch.TryAdd` returns `false` when the event does not fit.
  Ignoring that return value drops the event with no error.

## Azure credentials

- **`DefaultAzureCredential` is for development.** It walks a chain and
  uses the first credential that answers, so in production an `az login`
  someone ran on the host can silently replace the managed identity.
  Deploy with a specific credential (`ManagedIdentityCredential`), or
  pin the chain with `AZURE_TOKEN_CREDENTIALS`.
- In an app that ships to end-user machines it is wrong twice over: it
  excludes interactive credentials by default, and it picks up any
  developer-tool login it finds on the machine.
- Create one credential instance and share it. Each instance keeps its
  own token cache.

## Data access

- **`Microsoft.Data.SqlClient`, not `System.Data.SqlClient`.** The
  former replaces the latter for new development. When migrating,
  remember that `Encrypt` has defaulted to `true` since 4.0, so a server
  without a trusted certificate fails with *"The certificate chain was
  issued by an authority that is not trusted."* The fix is the
  certificate; `TrustServerCertificate=True` is a bypass and should not
  be committed as a fix.
- **A `DbContext` is one unit of work.** It is short-lived and not
  thread-safe, and concurrent use surfaces as *"A second operation
  started on this context before a previous operation completed."*
  Where the DI scope does not match that lifetime — desktop apps,
  background loops — inject `IDbContextFactory<T>` and create a context
  per operation.
- `AsNoTracking()` on read-only queries.
- **Never mix `EnsureCreated` with migrations.** `EnsureCreated` builds
  the schema without a migrations history table, and the database it
  creates cannot later be updated by migrations. Use `Migrate` in any app
  whose data outlives a schema change.

## JSON

- **`System.Text.Json` by default; `Newtonsoft.Json` by exception.**
  Keep Newtonsoft only where an existing contract, or a feature STJ
  lacks, needs it — and never both on one type. Each serializer ignores
  the other's attributes, so `[JsonProperty("x")]` does nothing under
  STJ. Decided 2026-09-10.
- **STJ property matching is case-sensitive by default**, unlike
  Newtonsoft's. A casing mismatch does not throw; the property is just
  left at its default value. Use `JsonSerializerDefaults.Web` or set
  `PropertyNameCaseInsensitive` wherever the payload's casing is not
  yours to control.
- **`PublishTrimmed` turns off reflection-based serialization**, and the
  failure only appears at runtime: *"Reflection-based serialization has
  been disabled for this application."* A trimmed or AOT app serializes
  through a source-generated `JsonSerializerContext`. Newtonsoft has no
  trim-safe mode.

## Exceptions

- Catch only what you can handle. `catch (Exception)` belongs at a
  boundary (an event handler, a command, the top of a job) and only
  with an exception filter or a rethrow below it.
- Catch where you can add context or give the user something to act
  on. **Never turn a failed load or save into an empty or successful
  result**: the caller then carries on with data that is not there.

## Anti-patterns

- `.Result`, `.Wait()` or `.GetAwaiter().GetResult()` on a thread with
  a `SynchronizationContext`. That deadlocks.
- `TrustServerCertificate=True` or `Encrypt=False` in a committed
  connection string.
- A `DefaultAzureCredential` constructed per call. That builds a new
  chain and a cold token cache every time.
- Disposing an injected service.
