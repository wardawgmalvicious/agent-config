---
name: msix-packaging
description: "Use when releasing a packaged Windows desktop app as MSIX: WinUI 3 (Windows App SDK), or WPF and WinForms through a Windows Application Packaging Project (.wapproj), shipped by App Installer (.appinstaller), the Microsoft Store (.msixupload) or a plain .msix or .msixbundle. Reads the project first, since WindowsPackageType None means no MSIX and WindowsAppSDKSelfContained decides who delivers the runtime, then walks the release in order: raise the Identity Version in Package.appxmanifest, build with msbuild /p:GenerateAppxPackageOnBuild=true, sign with SignTool (/fd matching the block map, a timestamp, Publisher equal to the certificate subject), publish the package before the .appinstaller that names it, and check the update lands. Covers .appinstaller schemas and UpdateSettings, MIME types, the ms-appinstaller protocol disabled since December 2023, Trusted People trust, Azure Artifact Signing, the Store re-sign, and errors 0x80073CFB, 0x8007000B, 0x800B0109 and 0x80072F76."
when_to_use: "Use when asked to publish, release or ship a new version of a Windows app, bump or sign an MSIX (SignTool, Azure Artifact or Trusted Signing), edit the Identity in Package.appxmanifest or an .appinstaller file, set up App Installer auto-update, prepare a Microsoft Store submission, or explain why an MSIX will not install or update. Not for publishing a git branch or pull request: that is land."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# MSIX packaging: from a version bump to an update that lands

An MSIX release is a short chain (version, build, sign, publish,
verify) where each link fails in its own way, often with nothing but a
hex code. This skill walks the chain for a packaged Windows desktop
app: WinUI 3 on the Windows App SDK, or WPF and WinForms through a
Windows Application Packaging Project.

**Dated, and drilled from Microsoft Learn on 2026-10-01.** Learn
contradicts itself on this subject in about a dozen places, error codes
and schema OS floors among them. §7 lists each conflict; quote neither
side as the rule.

**Not here.** Unpackaged distribution (MSI, EXE, xcopy, the Windows App
SDK runtime installer), packaging with external location, enterprise
deployment through Intune or Configuration Manager, and repackaging an
existing installer with the MSIX Packaging Tool. C# and XAML
conventions belong to the `coding-csharp` and `coding-xaml` rules,
which load with those files.

Detail lives in `references/`: `app-installer.md` (the `.appinstaller`
file, hosting, the protocol), `signing.md` (certificates, SignTool,
trust, Artifact Signing), `build.md` (the Windows App SDK forks and
msbuild) and `identity-and-store.md` (identity, versions, the Store,
the full error table). Each cites the Learn page behind every claim.

## 1. The three rules everything else serves

- **Name plus Publisher is the app.** The package family name is formed
  from the two, and an update installs only within its family: "To be
  able to update, the new package metadata will need to be the same as
  the previously installed package" (Learn, *App package updates*).
  Learn never says outright what changing either does to a shipped
  app; it follows from that rule that installed copies stop receiving
  updates, so treat both as fixed once anything has shipped.
- **Every release raises the Version.** "App updates require the
  version of the new package to be higher than the current one", and a
  lower one is refused unless a force option allows it. Same version,
  different bits fails as `0x80073CFB`, and a rebuild or a re-sign
  counts as different bits: "the digital signature is also part of the
  package".
- **The manifest's Publisher equals the signing certificate's
  subject**, "including all distinguished name fields in the same
  order", case and whitespace included. A mismatch fails signing with
  `SignerSign() failed` (`0x8007000B`), Event ID 150 in the
  AppxPackagingOM log.

## 2. Read the project before anything else

The procedure forks on what the project file says. Read the app's
`.csproj` (or `.vcxproj`) and any `.wapproj` in the solution first:

| Found | Means | So |
| --- | --- | --- |
| `<WindowsPackageType>None</WindowsPackageType>` | Unpackaged: no MSIX and no package identity | **Stop**: none of this applies; say so |
| `<EnableMsixTooling>true</EnableMsixTooling>` and a `Package.appxmanifest` in the app project | Single-project MSIX: WinUI only, one executable | Build the app project (§3, step 2) |
| A `.wapproj` in the solution | Windows Application Packaging Project: WPF, WinForms, or several executables | Build the `.wapproj` |
| `<WindowsAppSDKSelfContained>true</WindowsAppSDKSelfContained>` | Self-contained: the runtime ships inside the package | No runtime to deliver |
| No `WindowsAppSDKSelfContained` | Framework-dependent, per the deployment guide, but see §7 | The Store installs the framework package; a sideload must deliver it |

Two architecture checks go with it:

- **Pick x86, x64 or ARM64, never Any CPU.** Learn's WPF and WinForms
  packaging guide says to pick x64 "instead of Any Cpu"; the reason,
  that the Windows App SDK is native code, is in its 2021 release
  notes.
- **Portable runtime identifiers on .NET 8 and later.** A `win10-x64`
  fails with `NETSDK1083: The specified RuntimeIdentifier 'win10-x64'
  is not recognized`. Spell `win-x86`, `win-x64` and `win-arm64`
  everywhere a RID appears: the project file, a `--runtime` argument,
  and any publish profile that names one. `<UseRidGraph>true</UseRidGraph>`
  restores the old graph, which .NET will not update again.

Then the channel:

- **An `.appinstaller` in the repo** means App Installer sideloading
  (§3).
- **Store association**, Visual Studio's *Publish > Associate App with
  the Store*, writes the Partner Center app's Name, Publisher and
  PublisherDisplayName into the manifest (§5).
- **Neither**: a plain `.msix` or `.msixbundle`, handed out and
  installed by double-click or `Add-AppxPackage`. Follow §3 and skip
  the `.appinstaller` in step 4; such a copy is outside the update
  channel (step 5).

## 3. Release through App Installer, in order

Each step names what goes wrong at it.

### Step 1: raise the version

- **The package version** is `Identity/@Version` in
  `Package.appxmanifest`: four parts, Major.Minor.Build.Revision, each
  0 to 65535, and all four are yours in a sideload; only the Store
  reserves the fourth (§5). Raise it every release, a rebuild that
  changes nothing you meant to change included.
- **The `.appinstaller`'s `MainPackage` or `MainBundle` must carry the
  same identity**: "The Name, Publisher, Version, ProcessorArchitecture,
  and ResourceId **must** match the values in the AppxManifest.xml file
  specified in the app package Uri", or the install fails.
- **The `.appinstaller` root `Version` is the file's own.** Learn states
  no rule tying it to the package's; its CI sample raises both
  together, and that is the safe habit.
- **A committed `Package.appinstaller` holding `{Version}`,
  `{AppInstallerUri}` and `{MainPackageUri}` placeholders is a
  template, not the file that ships** (observed in a reference repo;
  no Learn page documents the placeholders or when they are filled, as
  of 2026-10-01). Read the generated `.appinstaller` in the output
  folder before publishing.

### Step 2: build

Build with msbuild: "WinUI 3 XAML projects currently require MSBuild"
(`dotnet build` invokes it), and the package comes only from one
property: "Without that option, the project will build, but you won't
get an MSIX package." Restore first, as Learn's CI workflow does:

```powershell
msbuild <App>.sln /t:Restore /p:Configuration=Release
msbuild <App>.sln `
    /p:Configuration=Release `
    /p:Platform=x64 `
    /p:AppxBundlePlatforms="x86|x64|arm64" `
    /p:AppxBundle=Always `
    /p:UapAppxPackageBuildMode=SideloadOnly `
    /p:AppxPackageDir="Packages\" `
    /p:GenerateAppxPackageOnBuild=true
```

That is Learn's Store bundle command with the sideload build mode;
each property is documented in `references/build.md`. `Platform`
selects the solution configuration that runs the packaging target, and
`AppxBundlePlatforms` the architectures it builds into the bundle.

- **Bundle from the first release if you will ever need one.** An
  update "can go from MSIX package to an MSIXbundle package but not
  vice-versa".
- **Single-project MSIX and bundles**: the single-project page says it
  "doesn't currently support producing MSIX bundles"; the 1.8 release
  notes say that gap was addressed, and the WinUI CI page builds a
  bundle from a single-project app. Check the output folder for the
  `.msixbundle` rather than trust either.
- **To have the build write the `.appinstaller` too**, Learn's CI
  sample adds `/p:GenerateAppInstallerFile=True`,
  `/p:AppInstallerUri=<folder URL>`,
  `/p:AppInstallerCheckForUpdateFrequency=OnApplicationRun` and
  `/p:AppInstallerUpdateFrequency=1`, for "a versioned .appinstaller
  file and an HTML page". Learn defines none of those values
  (2026-10-01), and the HTML page links through `ms-appinstaller:`,
  which is off by default (step 4).

### Step 3: sign

Skip this step when the build signed already
(`AppxPackageSigningEnabled` with `PackageCertificateKeyFile` or
`PackageCertificateThumbprint`; `references/signing.md`). Otherwise:

```powershell
SignTool sign /fd SHA256 /a /f <cert>.pfx /p <password> `
    /tr <RFC 3161 timestamp URL> /td SHA256 `
    <App>.msixbundle
```

- **`/fd` must name the block map's hash**: SHA256, unless MakeAppx was
  told otherwise. A mismatch is Event ID 151. Always pass it, since
  SignTool's own default is SHA1, which MakeAppx never uses.
- **Sign the bundle only**: "Only the bundle needs to be signed; the
  signature covers the packages inside the bundle."
- **Always timestamp.** "Packages that are not timestamped will be
  evaluated against the current time and if the certificate is no
  longer valid, Windows will not accept the package." An installed app
  keeps running past expiry either way; the next install and the next
  update are what fail.
- **Azure Artifact Signing**, formerly Trusted Signing, issues
  certificates valid for about three days, so the timestamp is what
  keeps a signature valid. It needs the Artifact Signing Client Tools'
  dlib and a `metadata.json`, and the manifest Publisher must equal the
  certificate profile's **Subject name**, with no custom CN or O.

### Step 4: publish the package, then the `.appinstaller`

The `.appinstaller` names the package's URI, so publish the package
first: a client that reads the new `.appinstaller` before the package
is at its URI has nothing to fetch. That ordering follows from the
file's design; Learn does not state it.

- **Serve the right MIME types**: `.msix` as `application/msix`,
  `.msixbundle` as `application/msixbundle`, `.appx` as
  `application/appx`, `.appxbundle` as `application/appxbundle`, and
  `.appinstaller` as `application/appinstaller`.
- **Send `Content-Length` on every response, `GET` and `HEAD` alike**,
  or installs fail with `0x80072F76`.
- **A UNC share works from Windows 10 1803.** For UNC, Visual Studio's
  how-to says to make the output folder and the Installation URL the
  same path.
- **The root `Uri` is where the `.appinstaller` itself is served.** A
  `Uri` that differs from the file being read redirects there, at most
  three times.
- **Link to the `.appinstaller` file itself.** The
  `ms-appinstaller:?source=` protocol has been disabled by default
  since App Installer 1.21.3421.0 (December 12, 2023), after malware
  abused it. Users download the file and open it. An administrator can
  re-enable the protocol with the `EnableMSAppInstallerProtocol` policy
  set to Enabled.

### Step 5: check the update lands

- **Start the app from the Start menu** on a machine holding the
  previous version, not from a desktop or taskbar shortcut:
  `ShowPrompt` and `UpdateBlocksActivation` act only on a launch from a
  menu item, a Start tile, an app alias or a protocol handler.
- **`HoursBetweenUpdateChecks="0"` checks on every launch**; the default
  is every 24 hours.
- **A packaged desktop app shows no update prompt**, whatever
  `ShowPrompt` says: "For desktop applications, this functionality
  provides a silent update."
- **Only a copy installed through the `.appinstaller` is in the update
  channel.** "Installing a Windows app using the App Installer file will
  create an entry in the App Installer repository", and the checks run
  off that entry. Learn never says what a bare `.msix` install gets; it
  follows that it has no entry and never checks.
  `Get-AppxPackageAutoUpdateSettings` lists the entries on a machine
  (`-AllUsers` for every user), and `-ShowUpdateAvailability` says
  whether an update is waiting. Learn documents no way to add an entry
  afterwards: `Set-AppxPackageAutoUpdateSettings` is scoped to an app
  "that was installed using an App Installer file", so point such users
  at the `.appinstaller`.
- **If nothing arrives**, install a local copy of the `.appinstaller`
  with `Add-AppxPackage -AppInstallerFile <path>` to separate the file
  from the server, then read *Application and Services Logs >
  Microsoft > Windows > AppxDeployment-Server* and
  `%LocalAppData%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir`.

## 4. Trust on the target machine

- **A self-signed or private certificate goes in Local Computer >
  Trusted People**, imported by an administrator. "The App Installer
  does not search User Certificates when verifying package identity",
  so a current-user import changes nothing.
- **Not Trusted Root for a self-signed certificate.** The MSIX
  troubleshooting guide warns that it "weakens the device's security
  posture", and the App Installer page lists it as "not recommended";
  two other pages say to use it (§7).
- **A certificate from a public CA, or from Artifact Signing, needs no
  import.** Windows trusts "certificates from most certificate
  authorities that provide code signing certificates", and Artifact
  Signing chains to a root trusted by default from Windows 10 1809.
- **Sideloading is on by default from Windows 10 2004**, per most
  pages; others disagree (§7). `0x80073CFF` means the machine's policy
  refused the install.

## 5. Releasing to the Store instead

- **Associate the app first.** Reserve the name in Partner Center, then
  use *Publish > Associate App with the Store* in Visual Studio, which
  writes Partner Center's `Identity/@Name`, `Identity/@Publisher` and
  `Properties/PublisherDisplayName` into the manifest. Typed by hand,
  "Values in the manifest are case-sensitive. Spaces and other
  punctuation must also match."
- **Build the upload file.** Learn's command is step 2's with
  `/p:UapAppxPackageBuildMode=StoreUpload` and
  `/p:AppxPackageSigningEnabled=false`, and makes a `.msixupload`, the
  recommended upload. MakeAppx cannot make one.
- **Do not sign it.** "The Microsoft Store will automatically re-sign
  your MSIX/AppX packages with a Microsoft certificate during the
  publishing process after your app passes certification."
- **For a Store package, leave the fourth version part 0 and make the
  first nonzero.** "The last (fourth) section of the version number is
  reserved for Store use and must be left as 0", one of the rules the
  page says "The Microsoft Store enforces", worded for "Windows 10 or
  Windows 11 (UWP) packages". Keeping it for a desktop app costs
  nothing; a sideload is bound by none of it, and no page fetched
  restricts its fourth part.
- **`runFullTrust` is a restricted capability**, and a packaged desktop
  app at medium integrity needs it. A Store submission must explain
  each restricted capability on the Submission options page; a
  sideloaded package needs no approval.
- **The Store installs framework dependencies itself**; managing them
  by hand is for sideloading and enterprise deployment.

## 6. When an install or update fails

Read the code from the AppXDeployment-Server log (event 404, with 465
before it when the package would not open), not from the dialog alone.

| Code | Usual cause | Revisit |
| --- | --- | --- |
| `0x8007000B` | Publisher ≠ certificate subject (event 150), `/fd` ≠ block-map hash (151), or a corrupt block map (152) | §1; §3, step 3 |
| `0x800B0100` | Unsigned | §3, step 3 |
| `0x800B0109`, `0x800B010A` | The certificate chain is not trusted on the machine | §4 |
| `0x800B0004` | The package changed after signing | Re-sign |
| `0x80073CFB` | Same version, different bits: rebuilt or re-signed | §3, step 1 |
| `0x80073D06` | A higher version is installed, per the Win32 table (§7) | §3, step 1 |
| `0x80073CF3` | Dependency, conflict or architecture validation, per the Win32 table (§7) | §2 |
| `0x80073CF0` | The package would not open: unsigned, Publisher mismatch, bad path, or a UNC path given to `Add-AppxPackage` | AppxPackagingOM log |
| `0x80072F76` | The server omits `Content-Length` or sends the wrong MIME type | §3, step 4 |
| `0x80073D02` | The app is running | Close it and retry |
| `0x80073CFF` | Policy does not allow the sideload | §4 |
| "The parameter is incorrect" | An `ms-appinstaller:` source that does not end in `.appinstaller` | §3, step 4 |
| `Certificate does not match supplied signing thumbprint` | `PackageCertificateThumbprint` names another certificate | `references/signing.md` |
| `NETSDK1083` | A `win10-*` RID on .NET 8 or later | §2 |

The full table, with every code Learn maps two ways, is in
`references/identity-and-store.md`.

## 7. Where Learn contradicts itself

Each item is two Learn pages disagreeing, as fetched on 2026-10-01.
Report the conflict; do not quote one side as the rule.

- **`0x80073CF3` and `0x80073D06`.** The Win32 error table calls
  `0x80073CF3` a failed dependency or conflict validation and
  `0x80073D06` a downgrade; the MSIX deployment troubleshooting page
  calls `0x80073CF3` the downgrade; the Windows App SDK Deployment API
  table calls `0x80073D06` packages in use. Read the event log's text.
- **A Publisher mismatch** is `0x8007000B` on two pages and
  `0x8007000D` on a third.
- **Whether the 2017/2 schema honours `HoursBetweenUpdateChecks`.** The
  auto-update overview and the schema reference say it does; the
  distribution status page, last reviewed August 2026, says it does
  not. All agree that 2017/2, which Visual Studio generates by default,
  silently ignores `ShowPrompt` and `UpdateBlocksActivation`, and the
  status page's fix is
  `xmlns="http://schemas.microsoft.com/appx/appinstaller/2021"`.
- **The 2021 schema's OS floor** is Windows 10 2004 on the how-to and
  auto-update pages, and Windows 11 21H2 (build 22000) on the element
  reference pages.
- **Trusted People or Trusted Root** (§4).
- **Sideloading's default**: on from Windows 10 2004 (the signing
  overview and guide), on from 1809 (MSIX deployment troubleshooting),
  or off until a policy turns it on (the line-of-business sideloading
  page).
- **Framework-dependent or self-contained by default.** The
  self-contained guide says framework-dependent; the 1.8 release notes
  say the NuGet default "behaves as if `WindowsAppSDKSelfContained` had
  been set as True". Read the project's properties and package
  references rather than rely on either default.
- **Single-project MSIX bundles** (§3, step 2).
- **MIME types.** Visual Studio's how-to lists `application/vns.ms-appx`
  and `application/xml`, with no `.msix` entries; every other page
  lists the five in §3, step 4.
- **Whether an MSIX must be signed.** The Visual Studio packaging page
  says "All MSIX apps must be signed with a certificate"; Windows 11
  installs an unsigned package through `Add-AppxPackage -AllowUnsigned`
  when its Publisher carries a special OID, for testing only
  (`references/signing.md`).

## 8. Constraints

- **Never change the Name or Publisher of a shipped app** to get a
  build through: the package moves to a family that installed copies
  never update to. When the certificate's subject has to change, look
  at MSIX persistent identity (Windows 11 21H2 and later, set up before
  the old certificate expires) instead.
- **Never ship two packages under one version.** Raise it, even for a
  re-sign.
- **Never commit a `.pfx` or its password.** Keep the certificate in
  the CI system's secret store and pass the password as a secret
  variable.
- **Never import a signing certificate into the user store** for App
  Installer, nor a self-signed one into Trusted Root.
- **Never offer an `ms-appinstaller:` link as the public install
  route.**
- **Stop at `WindowsPackageType` `None`.** Say the app is unpackaged
  and that an MSIX release does not apply, rather than package it
  unasked.
- **No unverified claims.** What Learn does not document, such as the
  template placeholders, the `AppInstaller*Frequency` values and the
  Store's publisher format, stays marked as undocumented.
