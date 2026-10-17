# Credentials: types, lifetimes and expiry

Read 2026-10-17 from Learn.

## Learn's ranking

Security best practices for app registration, in order:

1. "Use a managed identity as a credential whenever possible. This is
   strongly recommended, as managed identities are both the most secure
   option and don't require any ongoing credential management."
2. "If the service the app is used in doesn't run on Azure, but does
   run on another platform that offers automated credential management,
   consider using an identity from that platform as a credential": a
   federated credential.
3. "If using a managed identity or other secure external identity
   provider isn't possible, use certificate credentials. **Don't use
   password credentials, also known as *secrets***." Even
   "self-signed certificates are still preferred over passwords."

Workload identity federation's own case against stored credentials:
they "pose a security risk and have to be stored securely and rotated
regularly. You also run the risk of service downtime if the credentials
expire."

## Lifetimes

- **Managed identity**: Azure holds the credential, a certificate that
  "has an expiration of 90 days and it's rolled after 45 days", an
  implementation detail "subject to change without notice". Nobody
  rotates it.
- **Client secret**: "limited to two years (24 months) or less", and
  "Microsoft recommends that you set an expiration value of less than 12
  months."
- **Certificate**: app management policies recommend a 180-day maximum.
  The same policies can limit secret lifetimes or block secrets
  outright, so a refused secret can be policy, not RBAC.
- **Federated credential**: no expiry. Graph's
  `federatedIdentityCredential` resource lists audiences, description,
  id, issuer, name and subject, and nothing that ends.

## The reset trap

`az ad app credential reset`: "By default, this command clears all
passwords and keys, and let graph service generate a password
credential." `--append`, default `False`: "Append the new credential
instead of overwriting." `--years` defaults to 1. `az ad sp credential
reset` behaves the same, and Learn's service principal tutorial says so:
"By default, this command clears all passwords and keys so use
carefully." Learn's own AKS rotation example runs the bare form, which
suits an app with one consumer and no other.

## Key Vault's expiry semantics

- `exp`: "IntDate, optional, default is **forever**", and "This field
  is for **informational** purposes only". `nbf` is the same at the
  other end; `enabled` set to `false` blocks retrieval.
- "A secret's **get** operation works for not-yet-valid and expired
  secrets, outside the *nbf* / *exp* window", and "Retrieving
  (**get**ting) an expired secret can be used for recovery operations."
- Certificates: "If a Key Vault certificate expires it can still be
  retrieved, but certificate may become inoperable in scenarios like TLS
  protection where expiration of certificate is validated."
- Event Grid: `Microsoft.KeyVault.SecretNearExpiry` is "triggered 30
  days before the expiration date", and `Microsoft.KeyVault.SecretExpired`
  at expiry; a key's near-expiry timing follows its rotation policy.

So a vault holding an app secret fails when the secret expires in
Entra, whatever its `exp` says: audit the credential at its issuer, and
treat the vault's dates as a reminder.

## Pages

- App registration security practices:
  https://learn.microsoft.com/entra/identity-platform/security-best-practices-for-app-registration
- Adding credentials:
  https://learn.microsoft.com/entra/identity-platform/how-to-add-credentials
- App management policies:
  https://learn.microsoft.com/entra/identity/enterprise-apps/tutorial-enforce-secret-standards
- Managed identities FAQ:
  https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/managed-identities-faq
- `az ad app credential`:
  https://learn.microsoft.com/cli/azure/ad/app/credential
- Key Vault secrets:
  https://learn.microsoft.com/azure/key-vault/secrets/about-secrets
- Key Vault events:
  https://learn.microsoft.com/azure/event-grid/event-schema-key-vault
