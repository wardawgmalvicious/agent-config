# Identity, versions, package formats and the Store

Read on Microsoft Learn on 2026-10-01; the pages show no date.

Sources:

- [Identity (Windows 10 schema)](https://learn.microsoft.com/uwp/schemas/appxpackage/uapmanifestschema/element-f-identity) and [Identity (Windows 8 schema)](https://learn.microsoft.com/uwp/schemas/appxpackage/appxmanifestschema/element-identity)
- [An overview of package identity](https://learn.microsoft.com/windows/apps/desktop/modernize/package-identity-overview)
- [App package updates](https://learn.microsoft.com/windows/msix/app-package-updates) and [Add-AppxPackage](https://learn.microsoft.com/powershell/module/appx/add-appxpackage)
- [Plan for your deployment](https://learn.microsoft.com/windows/msix/desktop/managing-your-msix-deployment-targetdevices)
- [How Visual Studio generates an app package manifest](https://learn.microsoft.com/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest)
- [App package requirements for MSIX app](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/app-package-requirements), [Upload MSIX app packages](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/upload-app-packages), [Resolve submission errors](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/resolve-submission-errors) and [View product identity details](https://learn.microsoft.com/windows/apps/publish/view-app-identity-details)
- [Package a desktop or UWP app in Visual Studio](https://learn.microsoft.com/windows/msix/package/packaging-uwp-apps) and [MakeAppx](https://learn.microsoft.com/windows/msix/package/create-app-package-with-makeappx-tool)
- [App capability declarations](https://learn.microsoft.com/windows/apps/package-and-deploy/app-capability-declarations)
- [Troubleshooting packaging, deployment, and query of Windows apps](https://learn.microsoft.com/windows/win32/appxpkg/troubleshooting), [MSIX deployment troubleshooting](https://learn.microsoft.com/windows/msix/desktop/managing-your-msix-deployment-troubleshooting) and the [MSIX troubleshooting guide](https://learn.microsoft.com/windows/msix/msix-troubleshooting-guide)

## The Identity element

- **Name**: "A string between 3 and 50 characters in length that
  consists of alpha-numeric, period, and dash characters", ASCII only,
  never equal to a reserved device name such as `con` or `nul`, never
  starting `xn--`, never ending with a period. Whether it is
  case-sensitive is disputed: the Windows 10 schema page says it is,
  the Windows 8 page and the identity overview say it compares
  case-insensitively.
- **Publisher**: 1 to 8192 characters in distinguished-name form. "If
  the **Publisher** attribute doesn't exactly match the subject name,
  the package is invalid." Several RDNs are separated by a comma and a
  space (`CN=JohnSmith, O=Contoso`); a multivalued RDN
  (`CN=JohnSmith + O=Contoso`) is not allowed. The identity overview
  calls Publisher case-sensitive.
- **Version**: "Major.Minor.Build.Revision", each part 0 to 65535.
  "The app developer can choose arbitrary version numbers but must
  ensure version numbers increase with updates."
- **ProcessorArchitecture**: `x86`, `x64`, `arm`, `arm64`, `x86a64` or
  `neutral`; "A package that includes executable code must include this
  attribute." `x64` means the package "works on systems supporting x64
  code", and `neutral` that it works on all architectures, not that it
  holds no code. Visual Studio sets it from the build configuration.
- **The package family name** is "an opaque string derived from only two
  parts of a package identity - *name* and *publisher*", the publisher
  part a 13-character hash. "Data and security are typically scoped to a
  package family."
- **The package full name** comes from all five parts; "It is an error
  to have two packages or bundles with different contents but with the
  same Package Full Name."
- **`Package.appxmanifest` is the source**; the build generates
  `AppxManifest.xml` from it, and that generated file is what ships.

## Versions and updates

- **Same family only**: "To update an already installed package, the
  new package must have the same package family name." A changed Name
  or Publisher therefore makes a package no installed copy updates to.
  Learn states the family rule, not that consequence.
- **Higher versions only, by default**: "The app update process will
  not allow packages with lower versions to be installed by default."
  `ForceUpdateFromAnyVersion` overrides it, as an `Add-AppxPackage`
  parameter, through the PackageManager API and the
  EnterpriseModernAppManagement CSP, and as an `.appinstaller` element.
  The same page's prose calls it `ForceUpdateToAnyVersion`.
- **Same version, different bits** is `0x80073CFB`: "if a package is
  rebuilt or resigned, it is no longer bitwise identical to the
  previously installed package". The fixes Learn gives: raise the
  version, or remove the old package for every user first.
- **MSIX to bundle, never back**: "An update package can go from MSIX
  package to an MSIXbundle package but not vice-versa. When an
  MSIXbundle is installed, the package update will need to remain a
  bundle."
- **Architecture may change** on update where the OS supports the new
  one, but "you cannot reinstall the same version of different
  architectures": x86 1.0 over x64 1.0 is not supported.
- **Uninstalling or downgrading keeps app data**: "When uninstalling or
  downgrading MSIX, MSIX preserves the user's appdata."
- **`TargetDeviceFamily`**: `MinVersion` gates installation ("If the
  device family version of the system is lower than *MinVersion*, then
  the app is not considered applicable"); `MaxVersionTested` caps the
  OS behaviour the package gets. In a Visual Studio project both come
  from the project's target platform properties, and one page says
  values typed into `Package.appxmanifest` "are ignored", while the
  element's own page says non-`10.0.0.0` values there win.

## Package formats

- **`.msix` or `.appx`**: one package, one architecture.
- **`.msixbundle` or `.appxbundle`**: several packages, one per
  architecture. "App bundles should be generated whenever possible".
  Every package in a bundle must have the same manifest elements and
  attributes except `ProcessorArchitecture`.
- **`.msixupload` or `.appxupload`**: "for Store Submission only", a
  file holding the packages or the bundle, plus an optional `.appxsym`
  symbol file for crash analytics. "MakeAppx.exe does not create an app
  package upload file".
- **MakeAppx's bundle version** (`/bv`) defaults to the current date and
  time when omitted or `0.0.0.0`; whether that satisfies the Store's
  revision rule is not documented.

## The Microsoft Store

- **Reserve the name first**: "All apps on the Microsoft Store must have
  a unique name", reservable up to three months before publishing.
- **The manifest must carry Partner Center's identity**:
  `Package/Identity/Name`, `Package/Identity/Publisher` and
  `Package/Properties/PublisherDisplayName`. Visual Studio's *Associate
  App with the Store* writes them; built by hand, "Values in the
  manifest are case-sensitive. Spaces and other punctuation must also
  match." Without them, "you may encounter package upload failures".
  Learn does not spell out the Publisher's format.
- **Formats**: the Store accepts `.msix`, `.msixbundle`, `.msixupload`,
  `.appx`, `.appxbundle` and `.appxupload`, and recommends the upload
  file. "If you are submitting a UWP app, you may see an error during
  preprocessing if your package file is not a .msixupload or
  .appxupload file generated by Visual Studio for the Store." No page
  says a packaged desktop app must use the upload file.
- **Signing**: "Your MSIX and AppX packages don't have to be signed with
  a certificate rooted in a trusted certificate authority when
  submitting to the Microsoft Store. The Microsoft Store will
  automatically re-sign your MSIX/AppX packages with a Microsoft
  certificate during the publishing process after your app passes
  certification." An MSI or EXE installer is not re-signed.
- **Version numbers**: "For Windows 10 or Windows 11 (UWP) packages, the
  last (fourth) section of the version number is reserved for Store use
  and must be left as 0 when you build your package (although the Store
  may change the value in this section). The other sections must be set
  to an integer between 0 and 65535 (except for the first section,
  which cannot be 0)." The rules are the Store's: the page opens them
  with "The Microsoft Store enforces certain rules related to version
  numbers", and the Identity element page reserves nothing. The Store
  serves "the highest-versioned package that is applicable", accepts
  packages in any order, and allows equal versions only across
  architectures.
- **Package requirements**: SHA2-256 block map hashes, 25 GB per package
  or bundle, ANSI file names.
- **Restricted capabilities**, `runFullTrust` among them: "you must
  provide info during the app submission process in order to be
  approved", on the Submission options page. "Note that you can
  sideload apps that declare restricted capabilities without needing to
  receive any approval." Declare them with the `rescap` namespace,
  listed in `IgnorableNamespaces`, before any `CustomCapability` or
  `DeviceCapability`:

  ```xml
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  ```

  A medium-integrity app "*needs* to declare the **runFullTrust**
  restricted capability", and MakeAppx's schema check reports when it is
  missing.
- **Framework dependencies**: "When distributing through the **Microsoft
  Store**, framework dependencies are automatically downloaded and
  installed."
- **Minimum OS**: MSIX installs through the Store require Windows 10
  1809 or later.
- **The Windows App Certification Kit** is "deprecated and no longer
  maintained" on one page and recommended before submission on others;
  the Store certifies every submission itself. Its command:
  `appcert.exe test -appxpackagepath [package path] -reportoutputpath [report file name]`,
  release builds only.
- **Whether a Store install can update from an `.appinstaller`**, or the
  reverse, is not stated on any page fetched.

## Install and update errors

Read the code and its text in the AppXDeployment-Server event log (event
404; a 465 before it means the package would not open). Where Learn
maps a code two ways, both are given.

| Code | Name | Meaning per the Win32 table | Other mapping |
| --- | --- | --- | --- |
| `0x8007000B` | ERROR_BAD_FORMAT | Needs rebuilding or re-signing; often Publisher ≠ certificate subject | |
| `0x8007000D` | ERROR_INVALID_DATA | | Publisher mismatch, per MSIX deployment troubleshooting |
| `0x800B0100` | TRUST_E_NOSIGNATURE | Unsigned, or an invalid signature | |
| `0x800B0109` | CERT_E_UNTRUSTEDROOT | Chain ends in an untrusted root | |
| `0x800B010A` | CERT_E_CHAINING | No chain to a trusted root | |
| `0x80073CF0` | ERROR_INSTALL_OPEN_PACKAGE_FAILED | Unsigned, Publisher ≠ subject, or not found; see AppxPackagingOM | A UNC path given to `Add-AppxPackage` |
| `0x80073CF3` | ERROR_INSTALL_RESOLVE_DEPENDENCY_FAILED | Conflict, missing dependency, or wrong architecture | Downgrade, per MSIX deployment troubleshooting; prerequisite failed, per the Deployment API table |
| `0x80073CF9` | ERROR_INSTALL_FAILED | Install failed; see the event log | Package or dependency not found, per MSIX deployment troubleshooting |
| `0x80073CFB` | ERROR_PACKAGE_ALREADY_EXISTS | Installed, and this one is not bitwise identical | "Informational", per the Deployment API table |
| `0x80073CFF` | ERROR_INSTALL_POLICY_FAILURE | Needs a developer license or a sideloading-enabled system | |
| `0x80073D02` | ERROR_PACKAGES_IN_USE | Resources it modifies are in use | |
| `0x80073D06` | ERROR_INSTALL_PACKAGE_DOWNGRADE | A higher version is installed | Packages in use, per the Deployment API table |
| `0x80073D10` | ERROR_INSTALL_WRONG_PROCESSOR_ARCHITECTURE | Wrong architecture for the machine | |
| `0x80073D1E` | ERROR_APPINSTALLER_ACTIVATION_BLOCKED | Blocked by the `.appinstaller`'s update settings | |
| `0x8008020C` | APPX_E_INVALID_APPINSTALLER | The `.appinstaller` is invalid | |
| `0x80070057` | E_INVALIDARG | Often `\|` or similar in `DisplayName` or `Description`, which the firewall profile rejects | |
| `0x80072F76` | | | Missing `Content-Length` or a wrong MIME type, per the App Installer pages |

A message rather than a code:

- *The package could not be installed because it is not compatible with
  this version of Windows*: `MinVersion` above the OS, or the wrong
  architecture.
- *The name found in the package is not one of your reserved app names*
  (Store upload): the manifest Name is not a name reserved in Partner
  Center.
- *App installation failed with error message: The parameter is
  incorrect*: an `ms-appinstaller:` source not ending in `.appinstaller`.
- An install that "succeeds" but replaces another version silently: a
  package of the same family was already installed.
