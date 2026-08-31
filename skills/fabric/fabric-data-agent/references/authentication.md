# Fabric Data Agent: authentication modes

Split out of the parent `fabric-data-agent` SKILL.md. Read when wiring a
caller to an agent — the scope and the identity model differ per surface, and
mixing them is the usual cause of a 401.

How a caller authenticates depends on the consumption surface:

- **In-product chat (GA)** — runs under your signed-in Microsoft Entra **user** identity and your workspace/data permissions. No token or key to supply; Fabric brokers the model call on a Microsoft-managed service and handles auth for you.
- **MCP server endpoint (preview)** — every request carries an Entra bearer token in the `Authorization` header, requested for the **`https://api.fabric.microsoft.com/.default`** scope. The token may represent a **user** or a **service principal**; it needs permission on the workspace and the data agent. Note this is a *different* scope from the SPN query endpoint below — match the scope to the endpoint you are calling. The MCP server does **not** support dynamic client registration, so the client acquires the token through its own auth flow.
- **Foundry / Copilot Studio integration (preview)** — identity passthrough (On-Behalf-Of): the integration runs under the **end user's** identity. Service principal auth is **not** supported on these surfaces — each end user needs access to the agent and its underlying data sources.
- **Service principal (SPN) auth — preview** — call the *published data agent query endpoint* directly from automation, background services, custom apps, and CI/CD without a signed-in user. The SPN authenticates to Entra via the **client-credentials flow**, requests a token for the Fabric resource (`https://analysis.windows.net/powerbi/api/.default`), and passes it as a bearer token. This endpoint is for asking natural-language questions only — **not** for managing or configuring the agent.

SPN setup (high level): register an app in Entra ID → enable the tenant setting **Service principals can use Fabric APIs** (Developer settings) → grant the SPN **Member** or **Contributor** on the agent's workspace → grant it **read** on every attached data source. The agent runs queries under the calling identity, so the SPN only sees data it has been granted.

SPN limitations (preview): **managed identities are not supported** (use an SPN); the SPN needs explicit read access to *every* attached source — sharing only the agent item is not enough; and SPN auth is **not yet supported for KQL database (Kusto) sources**.
