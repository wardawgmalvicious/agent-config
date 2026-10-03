# The App Installer file

Everything below was read on Microsoft Learn on 2026-10-01. Pages show
no date unless one is given. A claim marked **excerpt only** comes from
a search excerpt of a page that was not fetched in full.

Sources:

- [App Installer file overview](https://learn.microsoft.com/windows/msix/app-installer/app-installer-file-overview)
- [Schema reference](https://learn.microsoft.com/uwp/schemas/appinstallerschema/schema-root) and the element pages under `uwp/schemas/appinstallerschema/`
- [Create an App Installer file manually](https://learn.microsoft.com/windows/msix/app-installer/how-to-create-appinstaller-file)
- [Create an App Installer file with Visual Studio](https://learn.microsoft.com/windows/msix/app-installer/create-appinstallerfile-vs)
- [Configure update settings](https://learn.microsoft.com/windows/msix/app-installer/update-settings)
- [Auto-update and repair apps](https://learn.microsoft.com/windows/msix/app-installer/auto-update-and-repair--overview)
- [Current status of Windows app distribution features](https://learn.microsoft.com/windows/apps/package-and-deploy/distribution-feature-status) (last reviewed August 2026)
- [Installing Windows apps from a web page](https://learn.microsoft.com/windows/msix/app-installer/installing-windows10-apps-web)
- [Distribute from an IIS server](https://learn.microsoft.com/windows/msix/app-installer/web-install-iis) and [from an Azure web app](https://learn.microsoft.com/windows/msix/app-installer/web-install-azure)
- [Troubleshoot App Installer issues](https://learn.microsoft.com/windows/msix/app-installer/troubleshoot-appinstaller-issues)
- [App Installer security features](https://learn.microsoft.com/windows/msix/app-installer/app-installer-security-features)
- [Configure CI/CD pipeline with YAML file](https://learn.microsoft.com/windows/msix/desktop/azure-dev-ops)
- [Get-AppxPackageAutoUpdateSettings](https://learn.microsoft.com/powershell/module/appx/get-appxpackageautoupdatesettings) and [Set-AppxPackageAutoUpdateSettings](https://learn.microsoft.com/powershell/module/appx/set-appxpackageautoupdatesettings)

## Anatomy

```xml
<?xml version="1.0" encoding="utf-8"?>
<AppInstaller
    xmlns="http://schemas.microsoft.com/appx/appinstaller/2021"
    Version="1.0.0.0"
    Uri="http://mywebservice.azurewebsites.net/appset.appinstaller" >

    <MainBundle
        Name="Contoso.MainApp"
        Publisher="CN=Contoso"
        Version="2.23.12.43"
        Uri="http://mywebservice.azurewebsites.net/mainapp.msixbundle" />

    <UpdateSettings>
        <OnLaunch
            HoursBetweenUpdateChecks="12"
            UpdateBlocksActivation="true"
            ShowPrompt="true" />
        <AutomaticBackgroundTask />
        <ForceUpdateFromAnyVersion>true</ForceUpdateFromAnyVersion>
    </UpdateSettings>

</AppInstaller>
```

That is Learn's own sample, from the manual how-to.

- **The root element** requires `xmlns`, `Version` in quad notation, and
  `Uri`. "When the Uri specified in the field differs from the current
  file, the deployment operation will redirect to the Uri instead of the
  current file. The appinstaller file can only be redirected a max of
  three times." Query strings with several key/value pairs are not
  supported.
- **Exactly one main element.** "`<AppInstaller>` can have either a
  `<MainPackage>` or `<MainBundle>` element. The deployment operation
  will fail if more than one of either are included." `MainPackage` is
  for an `.msix` or `.appx`, `MainBundle` for a bundle.
- **Encoding**: "Only `encoding="UTF-8"` with no escape characters, and
  no non-ascii characters is accepted."
- **The main element's identity must match the package's.** "The Name,
  Publisher, Version, ProcessorArchitecture, and ResourceId **must**
  match the values in the AppxManifest.xml file specified in the app
  package Uri." The how-to adds that the installation fails otherwise.
- **`ProcessorArchitecture`** is "mandatory for non-bundle packages"
  per the how-to, and not required for bundles. The schema root's table
  calls it optional; the `MainPackage` page lists `x86`, `x64`, `arm`
  and `neutral` only, with no `arm64`.
- **`Dependencies`** is optional: "These packages will only be
  installed if they are not already available on the target device."
- **The root `Version`** is the file's own version. No page states a
  rule tying it to the package version; the CI page's script raises
  the root's and `MainPackage`'s together.
- **Child element order**: the root's reference page says "Child
  elements must appear in the specified order", while its own syntax
  key says the interleave connector allows any order. Keep Learn's
  sample order.

## Schema namespaces

Features arrive by adding namespaces; earlier schemas can reference a
later one's elements through its namespace.

| Namespace | Introduced in, per the overview page |
| --- | --- |
| `http://schemas.microsoft.com/appx/appinstaller/2017` | Windows 10 1709 |
| `http://schemas.microsoft.com/appx/appinstaller/2017/2` | Windows 10 1803 |
| `http://schemas.microsoft.com/appx/appinstaller/2018` (`s3`) | Windows 10 1809 |
| `http://schemas.microsoft.com/appx/appinstaller/2021` (`s4`) | Windows 21H2, build 22000 |

The floors conflict across pages. The how-to and the auto-update page
put the 2021 settings at Windows 10 2004 (build 19041); the element
pages put `s4` at Windows 11 21H2. One reference page maps the `s4`
prefix to the 2018 namespace. The MSIX troubleshooting guide has a
"schema version" table keyed to the root `Uri` and values like
`1.3.0.0`, which contradicts every schema page: do not use it.

**Visual Studio generates the 2017/2 schema by default.** The status
page says that developers who then set `ShowPrompt` or
`UpdateBlocksActivation` "will find those settings are silently ignored
at runtime", and its fix is to change `xmlns` to the 2021 namespace.
Its table also marks `HoursBetweenUpdateChecks` unsupported in 2017/2,
which the auto-update page and the schema reference contradict ("The
2017/2 schema supports `HoursBetweenUpdateChecks`").

## Update settings

| Setting | What it does | Minimum Windows 10, per the update-settings page |
| --- | --- | --- |
| `OnLaunch` | Check for an update when the app launches | 1709 |
| `HoursBetweenUpdateChecks` | `0` to `255`; default 24; `0` checks on every launch | 1803 |
| `AutomaticBackgroundTask` | Check every 8 hours whether or not the app runs; cannot show UI | 1803 |
| `ShowPrompt` | Show the user a prompt about the update | 1903 |
| `UpdateBlocksActivation` | `true` only with `ShowPrompt="true"`; the user must update or close | 1903 |
| `ForceUpdateFromAnyVersion` | Allow a downgrade as well as an upgrade | 1903 |
| `UpdateUris` | Up to 10 fallback `.appinstaller` URIs when the main one is unreachable | 2021 schema |
| `RepairUris` | Up to 10 repair sources, packages or `.appinstaller` files | 2021 schema |

Other pages give other floors for the same settings: `ForceUpdateFromAnyVersion`
at 1809 on the reference page and in *App package updates*,
`AutomaticBackgroundTask` at 1803 in one cell of its page and 21H2 in
another.

- **`ShowPrompt` does not prompt a packaged desktop app.** "Setting the
  `ShowPrompt="true"` attribute currently shows a prompt for UWP
  applications but not for desktop applications that have been
  packaged in a Windows app package ... For desktop applications, this
  functionality provides a silent update".
- **Both prompt attributes act only on some launches**: "from a menu
  item, a tile in the Start menu, an app alias, or a protocol handler.
  These attributes have no effect if the user starts the app from a
  desktop shortcut or from the Taskbar."
- **`UpdateBlocksActivation="false"`** lets the user start the app
  without updating; "the update will be applied silently at an
  opportune time".
- **Attribute spelling differs by page.** The `OnLaunch` reference
  writes `s4:HoursBetweenUpdateChecks`, `s4:ShowPrompt` and
  `s4:UpdateBlocksActivation`; the how-to writes them unprefixed under
  a 2021 default namespace, as in the sample above. Keep the prefix
  consistent with the namespace declarations.
- **Precedence**: settings set through a CSP override PowerShell and
  the file, and the file overrides one embedded in the package; the
  page's sentence on the rest is garbled ("the develop"), so the full
  order is not stated cleanly.

## Hosting

- **Transports**: "App Installer file downloads and updates support
  https, http and smb protocols." The 1709 release supported HTTP only;
  UNC and share access arrived in 1803.
- **MIME types**, from the web-install page and both hosting tutorials:

  | Extension | MIME type |
  | --- | --- |
  | `.msix` | `application/msix` |
  | `.appx` | `application/appx` |
  | `.msixbundle` | `application/msixbundle` |
  | `.appxbundle` | `application/appxbundle` |
  | `.appinstaller` | `application/appinstaller` |

  Visual Studio's how-to gives `application/vns.ms-appx` and
  `application/xml` instead, with no `.msix` entries; every other page
  gives the table above. Only the types actually hosted need mapping,
  and none when the packages sit on a file share the page links to.
- **IIS** maps them in `web.config`:

  ```xml
  <system.webServer>
      <staticContent>
        <mimeMap fileExtension=".appx" mimeType="application/appx" />
        <mimeMap fileExtension=".msix" mimeType="application/msix" />
        <mimeMap fileExtension=".appxbundle" mimeType="application/appxbundle" />
        <mimeMap fileExtension=".msixbundle" mimeType="application/msixbundle" />
        <mimeMap fileExtension=".appinstaller" mimeType="application/appinstaller" />
      </staticContent>
  </system.webServer>
  ```

  ASP.NET Core ignores `web.config` MIME maps for static content, so
  set the types in its static file middleware. Azure Static Web Apps
  and GitHub Pages "may need explicit configuration or a custom hosting
  solution".
- **`Content-Length`**: "all responses need to include a correct
  `Content-Length` header. This includes `GET` as well as `HEAD`
  requests." Without it: `Appinstaller operation failed with error code
  0x80072F76. Detail: Unknown error (0x80072f76)`.
- **Byte-range requests** are listed among the requirements for
  protocol activation.
- **A local IIS** needs App Installer exempted from loopback isolation:
  `CheckNetIsolation.exe LoopbackExempt -a -n=microsoft.desktopappinstaller_8wekyb3d8bbwe`.

## The `ms-appinstaller:` protocol

- **Off by default.** It "was **disabled by default** in App Installer
  version 1.21.3421.0, released December 12, 2023, in response to its
  abuse by the Emotet malware campaign". Learn's tutorial pages built
  around `ms-appinstaller:?source=` links "no longer work for most
  users".
- **What works instead**: "Link directly to the `.appinstaller` file —
  users download and double-click it", or publish through the Store.
- **Re-enabling** is an enterprise act: set the `EnableMSAppInstallerProtocol`
  policy to **Enabled** through the DesktopAppInstaller CSP; "the policy
  value `Disabled` means 'the setting is not configured'". The registry
  form is `EnableMSAppInstallerProtocol=1` under
  `HKLM:\Software\Policies\Microsoft\Windows\AppInstaller`. The CSP
  page scopes the policy to Windows 11 22H2 and later (**excerpt
  only**).
- **The source must end in `.appinstaller`.** A vanity URL, or a
  redirect to such a file, fails with *App installation failed with
  error message: The parameter is incorrect*.
- **What a user sees on a disabled link** is not described in text on
  any page fetched.

## Generating the file with Visual Studio or MSBuild

- **Visual Studio**: *Create App Packages* offers **Enable automatic
  updates** only when `TargetPlatformMinVersion` is Windows 10 1803 or
  later; its *Configure Update Settings* dialog asks for the
  Installation URL and the update frequency. "The output folder
  includes all the files needed to sideload the app, including an HTML
  page that can be used to promote your app." A bundle gets one
  `.appinstaller`; one package per architecture gets one per
  architecture.
- **MSBuild**, as one CI sample shows it:

  ```text
  /p:UapAppxPackageBuildMode=SideLoadOnly /p:AppxBundle=Never
  /p:GenerateAppInstallerFile=True /p:AppInstallerUri=http://yourwebsite.com/packages/
  /p:AppInstallerCheckForUpdateFrequency=OnApplicationRun
  /p:AppInstallerUpdateFrequency=1
  ```

  The page defines neither frequency property's values or unit, and
  names no property for `HoursBetweenUpdateChecks` (2026-10-01). Its
  generated HTML links with
  `<a href="ms-appinstaller:?source=http://yourwebsite.com/packages/Msix_x86.appinstaller">`,
  the disabled scheme.
- **Editing after the build is supported**: "The app installer file
  itself is an uncompiled XML file that can be edited after the build".
  The CI page's release stage rewrites the two `Uri` attributes for the
  location it publishes to, and its build stage raises both `Version`
  attributes.
- **A committed `Package.appinstaller` with `{Version}`-style
  placeholders**: no page documents the placeholders or when they are
  substituted. Read the generated file, not the template.

## Installing, and isolating a failure

- **Users open the `.appinstaller`**, not the package: "At this point
  the familiar App Installer UI will appear and guide the user through
  the installation. Once the user has installed the application using
  these steps, the application is associated with the App Installer
  file."
- **That install is what enrols the app for updates.** "Installing a
  Windows app using the App Installer file will create an entry in the
  App Installer repository with the specified configurations that had
  been set. As long as the Windows app has an entry in the App Installer
  repository, the automatic update and repair of the app can be
  configured through by: Windows Settings App, App Installer file,
  PowerShell, or through a CSP" (auto-update overview).
  `Get-AppxPackageAutoUpdateSettings` "returns the settings configured
  for a specific or all installed Windows Apps in relation to Auto Update
  and Repair", for one `-PackageFullName`, the user's apps, or
  `-AllUsers`; `-ShowUpdateAvailability` "Displays available update
  information". `Set-AppxPackageAutoUpdateSettings` "Configures the
  auto-update and repair settings for a specific Windows app that was
  installed using an App Installer file", by `-PackageFamilyName` and
  `-AppInstallerUri`; whether it can enrol a copy installed from the
  bare package is not stated, and no page says what such a copy gets
  (2026-10-01).
- **From PowerShell**:
  `Add-AppxPackage -AppInstallerFile "C:\Users\user1\Desktop\MyApp.appinstaller"`
  installs "with all update settings specified within the App Installer
  file". The example uses a local path; whether a URL is accepted is
  not stated. The troubleshooting page spells the switch `-Appinstaller`;
  the cmdlet's is `-AppInstallerFile`.
- **Logs**: *Application and Services Logs > Microsoft > Windows >
  AppxDeployment-Server*, plus files under
  `%LocalAppData%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir`.
  For `0x80073CF0`, the AppxPackagingOM log has more.
  `Get-AppxLog | Where-Object {$_.EventId -eq 404} | Select-Object -Last 20`
  lists recent failures.
- **Dependencies**: "If the app package is built in Release mode
  configuration, the framework dependencies will be obtained from the
  Microsoft Store. However, if the app is built in Debug mode
  configuration, the dependencies will be obtained from the location
  specified in the `.appinstaller` file."
- **Every referenced file must be reachable**; the Visual Studio HTML
  page's *Additional Links* go to the `.appinstaller` and the package.
- **Internet installs** show a warning banner, consult SmartScreen's URL
  reputation first, and reject URLs in the *Untrusted Sites* zone by
  default; a blocked zone's dialog reads "Your internet security
  settings prevented this file from being opened".
