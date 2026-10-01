# Signing an MSIX package

Read on Microsoft Learn on 2026-10-01; the pages show no date.

Sources:

- [Sign an MSIX package](https://learn.microsoft.com/windows/msix/package/signing-package-overview)
- [Sign an app package using SignTool](https://learn.microsoft.com/windows/msix/package/sign-app-package-using-signtool)
- [Sign your MSIX package: end-to-end guide](https://learn.microsoft.com/windows/msix/package/sign-msix-package-guide)
- [Create a certificate for package signing](https://learn.microsoft.com/windows/msix/package/create-certificate-package-signing)
- [Known issues and troubleshooting for SignTool](https://learn.microsoft.com/windows/msix/package/signing-known-issues)
- [SignTool reference](https://learn.microsoft.com/windows/win32/seccrypto/signtool)
- [How to troubleshoot app package signature errors](https://learn.microsoft.com/windows/win32/appxpkg/how-to-troubleshoot-app-package-signature-errors)
- [MSIX troubleshooting guide](https://learn.microsoft.com/windows/msix/msix-troubleshooting-guide)
- [Artifact Signing integrations](https://learn.microsoft.com/azure/trusted-signing/how-to-signing-integrations) and [FAQ](https://learn.microsoft.com/azure/artifact-signing/faq)
- [Set up automated builds for your UWP app](https://learn.microsoft.com/windows/uwp/packaging/auto-build-package-uwp-apps)
- [MSIX persistent identity](https://learn.microsoft.com/windows/msix/package/persistent-identity) and [Create an unsigned MSIX package](https://learn.microsoft.com/windows/msix/package/unsigned-package)

## The subject rule

"To use a certificate to sign your app package, the 'Subject' in the
certificate **must** match the 'Publisher' section in your app's
manifest." The match is exact: "including all distinguished name
fields in the same order", and both strings "are both case and
whitespace sensitive".

Read a certificate's subject before writing the manifest, or the
reverse:

```powershell
(Get-PfxCertificate <cert_file>).Subject      # a .cer or a .pfx
(Get-Item Cert:\CurrentUser\My\<THUMBPRINT>).Subject
```

```cmd
certutil -dump <cert_file.pfx>
```

Visual Studio "only supports the common name (CN) form for the
publisher and will add the prefix 'CN=' to publisher field in the
manifest".

## Certificates

- **For testing**, a self-signed certificate, exactly as Learn writes
  it, from an elevated prompt:

  ```powershell
  New-SelfSignedCertificate -Type Custom -KeyUsage DigitalSignature -CertStoreLocation "Cert:\CurrentUser\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}") -Subject "CN=Contoso Software, O=Contoso Corporation, C=US" -FriendlyName "Your friendly name goes here"
  ```

  `DigitalSignature` key usage, the Code Signing EKU
  (`1.3.6.1.5.5.7.3.3`), and basic constraints marking an end entity
  rather than a CA. "Self-signed certificates should only be used for
  testing. Remove them from tester machines when no longer needed."
- **Exporting a `.pfx`** needs `-Password` or `-ProtectTo`, or
  `Export-PfxCertificate` errors:

  ```powershell
  $password = ConvertTo-SecureString -String <Your Password> -Force -AsPlainText
  Export-PfxCertificate -cert "Cert:\CurrentUser\My\<Certificate Thumbprint>" -FilePath <FilePath>.pfx -Password $password
  ```

- **For distribution**, a certificate from a public CA, or Azure
  Artifact Signing (below). SignTool requires the Code Signing EKU by
  default (`/u`). Learn states no further requirement for a CA-issued
  certificate, such as key size, for MSIX (2026-10-01).
- **For the Store**, none: the Store re-signs (`identity-and-store.md`).

## SignTool

SignTool ships in the Windows SDK's `bin` folder, for example
`C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe`.
It is not on standard CI runner images, so a pipeline installs the SDK
first; Learn's troubleshooting guide uses
`winget install --id Microsoft.WindowsSDK.10.0.22621 --accept-source-agreements --accept-package-agreements`.

```syntax
SignTool sign /fd <Hash Algorithm> /a /f <Path to Certificate>.pfx /p <Your Password> <File path>.msix
SignTool sign /fd <Hash Algorithm> /n <Name of Certificate> <File Path>.msix
SignTool sign /fd <Hash Algorithm> /sha1 <SHA1 hash> <File Path>.msix
```

- **`/fd` must match the package's block map.** "The hash algorithm
  used in SignTool must be the same algorithm you used to package your
  app." Read it from `AppxBlockMap.xml`'s `HashMethod`:
  `http://www.w3.org/2001/04/xmlenc#sha256` is SHA256 (MakeAppx's
  default), `http://www.w3.org/2001/04/xmldsig-more#sha384` SHA384,
  `http://www.w3.org/2001/04/xmlenc#sha512` SHA512. "Since SignTool's
  default algorithm is SHA1 (not available in MakeAppx.exe), you must
  always specify a hash algorithm."
- **`/a`** picks the valid certificate that lasts longest; without it,
  SignTool expects exactly one. **`/n`** matches a substring of the
  subject; **`/sha1`** picks by thumbprint; **`/sm`** searches the
  machine store instead of the user's.
- **Bundles**: "Only the bundle needs to be signed; the signature covers
  the packages inside the bundle." Packages need no signature before
  bundling.
- **`/debug`**, placed right after `sign`, shows the certificate
  filtering.

### Timestamping

```powershell
SignTool sign /fd SHA256 /a /f .\cert.pfx /p "YourPassword" `
  /tr http://timestamp.digicert.com /td SHA256 `
  MyApp.msix
```

| | Signed without timestamping | Signed with timestamping |
| --- | --- | --- |
| Certificate valid | App will install | App will install |
| Certificate expired | App will fail to install | App will install |

"If the app is successfully installed on a device, it will continue to
run even after the certificate expiry regardless of it being
timestamped or not." `/tr` takes an RFC 3161 server; `/td` must
accompany it. The SignTool page calls a missing `/td` an error in one
table and a warning in another, so pass both, as every MSIX example
does.

## Azure Artifact Signing

"Azure Artifact Signing is the new name for what was previously called
Trusted Signing." The GitHub Action keeps the old name,
`azure/trusted-signing-action`.

- **SignTool needs the Client Tools**: "The Artifact Signing Client
  Tools include the required dlib plugin, a compatible version of
  SignTool, and the .NET 8 runtime. Standard SignTool syntax does
  **not** work with Artifact Signing without this package."

  ```powershell
  winget install -e --id Microsoft.Azure.ArtifactSigningClientTools
  ```

- **A `metadata.json`** names the account; the endpoint must be the
  account's region:

  ```json
  {
    "Endpoint": "https://<region>.codesigning.azure.net/",
    "CodeSigningAccountName": "<your-account-name>",
    "CertificateProfileName": "<your-certificate-profile-name>"
  }
  ```

- **The command**:

  ```powershell
  signtool sign /v /fd SHA256 `
    /tr "https://timestamp.acs.microsoft.com" /td SHA256 `
    /dlib "C:\Program Files (x86)\Microsoft\ArtifactSigningClientTools\bin\Azure.CodeSigning.Dlib.dll" `
    /dmdf .\metadata.json `
    MyApp.msix
  ```

  The Azure page writes the timestamp URL with `http://`; the MSIX guide
  with `https://`.
- **The Publisher must be the profile's subject**: "the publisher value
  in your manifest must match your verified identity — found in the
  Azure portal under your certificate profile's **Subject name**
  field." Custom CN or O values are not supported.
- **Certificates last about three days**, so "time stamping is critical
  for continued successful validation of a signature beyond that
  three-day validity period".
- **Integrations** Learn lists: SignTool, GitHub Actions, Azure DevOps
  tasks, PowerShell, Azure PowerShell and the SDK. Visual Studio is not
  among them. AzureSignTool is a different tool, for Azure Key Vault,
  and "does *not* support Artifact Signing".
- **Eligibility** changes, so check the quickstart: as of the drill,
  organizations in the USA, Canada, the EU and the UK with three or
  more years of tax history, individuals in the USA and Canada, and a
  paid Azure subscription only.
- **No instant SmartScreen trust**: signed packages still build
  reputation over time.

## Signing during the build

| Property | Meaning |
| --- | --- |
| `AppxPackageSigningEnabled` | `true` signs the package during the build |
| `PackageCertificateThumbprint` | "This value **must** match the thumbprint in the signing certificate, or be an empty string." |
| `PackageCertificateKeyFile` | Path to the `.pfx` |
| `PackageCertificatePassword` | The private key's password, passed from a secret variable |

- **Keep the certificate out of the repo**: "You should avoid submitting
  certificates to your repo if at all possible, and git ignores them by
  default." Azure Pipelines keeps it in Secure files
  (`DownloadSecureFile@1`); Learn's GitHub Actions workflow stores it
  base64-encoded in a `BASE64_ENCODED_PFX` secret and deletes the
  decoded file after the build.
- **Set `/p:PackageCertificateThumbprint=""` beside a key file**: "If
  the thumbprint is set in the project but does not match the signing
  certificate, the build will fail with the error: `Certificate does
  not match supplied signing thumbprint`."
- **A password-protected certificate file is not supported** in that
  pipeline: "a password is only supported for the private key".
- **Store builds turn signing off**:
  `/p:AppxPackageSigningEnabled=false`.

## Trust on the target machine

```powershell
Import-PfxCertificate -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" -Password $password -FilePath <FilePath>.pfx
Import-Certificate -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" -FilePath .\devcert.cer
```

Both run from an administrator prompt. A package's own certificate can
be pulled out first:
`(Get-AuthenticodeSignature -FilePath .\app.msix).SignerCertificate`,
then `Export-Certificate`. "The App Installer does not search User
Certificates when verifying package identity."

Trusted People versus Trusted Root is a conflict in Learn: the
certificate-creation page, the App Installer troubleshooting page and
the MSIX troubleshooting guide say Trusted People, the latter two
warning against Trusted Root for a self-signed certificate; the
line-of-business sideloading page and the MSIX Core page say Trusted
Root.

**Sideloading** is "turned on by default" from Windows 10 2004 per the
signing overview; the sideloading policy can still be set through
`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\AllowAllTrustedApps`
(`DWORD` `1`). In Windows 11 25H2 the developer settings moved to the
*For developers* section of *Advanced settings*.

## Unsigned test packages

"As of Windows 11, you can install your app via PowerShell without
needing to sign your package. ... Don't use this feature to distribute
your app widely." The Publisher must end with the unsigned marker:

```xml
<Identity Name="NumberGuesserManifest"
  Publisher="CN=AppModelSamples, OID.2.25.311729368913984317654407730594956997722=1"
  Version="1.0.0.0" />
```

```powershell
Add-AppxPackage -Path ".\MyEmployees.appx" -AllowUnsigned
```

"An unsigned package will never have the same identity as a package
that's signed."

## Changing the certificate's subject

MSIX persistent identity signs with a new certificate "while still
maintaining the app's update experience", from Windows 11 21H2 (build
22000). It needs an artifact relating the old certificate to the new,
the old certificate still installed on the machine, and it must be set
up "before the old certificate has expired". Changing the manifest
Publisher instead moves the package to a new family.

## Signing errors

| Error | Meaning |
| --- | --- |
| `SignerSign() failed` `0x8007000B`, Event ID 150 | "The app manifest publisher name (CN=Contoso) must match the subject name of the signing certificate (CN=Contoso, C=US)." |
| `0x8007000B`, Event ID 151 | "The signature hash method specified (SHA512) must match the hash method used in the app package block map (SHA256)." |
| `0x8007000B`, Event ID 152 | "The app package contents must validate against its block map." Rebuild. |
| `0x8008xxxx` | The package being signed is invalid; rebuild and sign again |
| `0x800700C1` Bad PE certificate | A binary inside has a corrupt certificate; `set APPXSIP_LOG=1` names it |
| `0x800B0100` | Unsigned |
| `0x800B0109` | The chain ends in an untrusted root |
| `0x800B010A` | No chain to a trusted root |
| `0x800B0004` | Tampered with after signing; sign again |
| `0x80080205` | Invalid block map; rebuild |
| `Certificate does not match supplied signing thumbprint` | `PackageCertificateThumbprint` names another certificate |
| `'signtool' is not recognized` in CI | The Windows SDK is not on the runner |
| `No certificates were found that met all the given criteria.` (Artifact Signing) | SignTool fell back to local certificates: check the dlib path, version and name |
| A 403 and a `SignerSign()` failure (Artifact Signing) | `metadata.json`'s endpoint is the wrong region |
| SignTool fails silently (Artifact Signing) | The .NET runtime the dlib needs is missing |
