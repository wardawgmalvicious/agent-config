# Custom CA / mTLS for Kafka connectors

GA July 2026 for the Kafka-protocol sources (Kafka, Amazon MSK, Confluent Cloud
Kafka). The **MQTT** source has its own **TLS/mTLS settings** with the same Key
Vault PEM rules (Learn, 2026-10-06); the Azure Event Hubs source has no TLS/mTLS
block.

**GA July 2026.** For Kafka, Amazon MSK, and Confluent Cloud Kafka sources, you can specify a **custom CA certificate** and a **client certificate** sourced from **Azure Key Vault** to enforce TLS / mTLS. Configured in the source connection step under **TLS/mTLS settings**. Use when the broker is behind a private CA or requires client-cert auth.

The What's New row phrases this as "Eventstream **connectors**". As of 2026-10-06 Learn documents the block on the Kafka-protocol connectors and on MQTT, and not on Event Hubs, whose connection UI has no TLS/mTLS block at all. Check a connector's own page before assuming it has one.

Which **Security protocol** you pick decides what you must supply:

| Protocol | When | Certificates |
|---|---|---|
| `SASL_SSL` | SASL-based auth. The broker cert must be signed by a CA on Fabric's [trusted CA list](https://github.com/microsoft/fabric-event-streams/blob/main/References/certificate-authority-list/trusted-ca-list.txt) | Only if the cluster uses a **custom CA** — then set **Trust CA certificate** |
| `SSL (mTLS)` | The cluster requires mTLS | **Both** a custom server CA certificate and a client certificate + key |

If you only use mTLS for authentication, the connection wizard still demands an **API Key** — put any string in the Key field.

**Certificate gotchas** (all cause silent-ish failures, and the first blocks data preview rather than the stream):

- The user configuring the source **and previewing data** needs Key Vault access to the certs — *Key Vault Certificate User* or *Key Vault Administrator*. Without it, preview fails from this source.
- Upload as **PEM**, not PKCS#12/PFX, with `contentType: application/x-pem-file`. The bundle is certificate **and** private key concatenated in one file — a cert without its key won't work.
- `keySize` in the import policy must match the **actual** key size (4096 for the CA, 2048 for server/client certs). Declaring 2048 for a 4096-bit key fails.
- `issuerParameters.name` is `"Unknown"` for externally signed certs, not `"Self"`.
- PEM files need **LF** line endings. CRLF breaks them — relevant on Windows, and this repo's `.gitattributes` won't save you outside it.
- The server certificate's **SAN** must carry the broker's FQDN *and* IP, or hostname verification (`ssl.endpoint.identification.algorithm=https`) rejects it.
- Private-network sources: the Key Vault must be reachable from the streaming VNet data gateway's virtual network (private endpoint).
