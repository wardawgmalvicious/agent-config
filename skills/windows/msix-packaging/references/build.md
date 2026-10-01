# Building an MSIX from a Windows App SDK or .NET desktop project

Read on Microsoft Learn on 2026-10-01; the pages show no date except
the release notes' own. A claim marked **excerpt only** comes from a
search excerpt of a page that was not fetched in full.

Sources:

- [Package and deploy overview](https://learn.microsoft.com/windows/apps/package-and-deploy/) and [Windows App SDK deployment overview](https://learn.microsoft.com/windows/apps/package-and-deploy/deploy-overview)
- [Packaging overview](https://learn.microsoft.com/windows/apps/package-and-deploy/packaging/)
- [Deployment architecture](https://learn.microsoft.com/windows/apps/windows-app-sdk/deployment-architecture) and [framework-dependent packaged apps](https://learn.microsoft.com/windows/apps/windows-app-sdk/deploy-packaged-apps)
- [Self-contained apps](https://learn.microsoft.com/windows/apps/package-and-deploy/self-contained-deploy/deploy-self-contained-apps) and [unpackaged WinUI apps](https://learn.microsoft.com/windows/apps/package-and-deploy/unpackage-winui-app)
- [Single-project MSIX](https://learn.microsoft.com/windows/apps/windows-app-sdk/single-project-msix) and [project properties](https://learn.microsoft.com/windows/apps/package-and-deploy/project-properties)
- [Package a .NET app with MSIX](https://learn.microsoft.com/windows/apps/desktop/modernize/dotnet/package-app)
- [CI for WinUI apps](https://learn.microsoft.com/windows/apps/package-and-deploy/ci-for-winui3) and [CI/CD with YAML](https://learn.microsoft.com/windows/msix/desktop/azure-dev-ops)
- [Windows App SDK release channels](https://learn.microsoft.com/windows/apps/windows-app-sdk/stable-channel), with the [1.5](https://learn.microsoft.com/windows/apps/windows-app-sdk/release-notes/windows-app-sdk-1-5), [1.8](https://learn.microsoft.com/windows/apps/windows-app-sdk/release-notes/windows-app-sdk-1-8) and [2.0](https://learn.microsoft.com/windows/apps/windows-app-sdk/release-notes/windows-app-sdk-2-0) notes
- [.NET SDK uses a smaller RID graph](https://learn.microsoft.com/dotnet/core/compatibility/sdk/8.0/rid-graph)
- [Using winapp CLI with .NET](https://learn.microsoft.com/windows/apps/dev-tools/winapp-cli/guides/dotnet) and the [Windows developer FAQ](https://learn.microsoft.com/windows/apps/get-started/windows-developer-faq)

## Two independent choices

- **Packaging**: "A **packaged app** contains its files, identity, and
  deployment information in a package such as MSIX. An **unpackaged
  app** uses an installer or deployment process outside the Windows
  package system and doesn't have package identity by default." A third
  model, packaging with external location, registers a small identity
  package beside an existing installer; it is outside this skill.
- **Runtime**: "apps that use the Windows App SDK choose how to carry
  their runtime dependencies: **framework-dependent** (the Windows App
  SDK runtime is installed on the user's machine) or **self-contained**
  (all Windows App SDK binaries ship with your app). This choice is
  independent of packaging."
- **Defaults**: "WinUI 3 apps are packaged by default". A WPF, WinForms
  or Win32 app is unpackaged by default (**excerpt only**).

Learn's scenario table, for the packaged rows:

| Distribution | Runtime | Where the runtime comes from |
| --- | --- | --- |
| Microsoft Store | Framework-dependent | "Auto-installed by Store" |
| Direct download with App Installer | Either | "Bundled if self-contained; the framework package must be distributed with the app if framework-dependent" |
| Intune or Configuration Manager | Either | "Packaged apps can declare framework dependencies" |

## Framework-dependent packaged apps

- **The runtime is four MSIX packages**: Framework (most features),
  Main (enables Framework updates from the Store), Singleton (push
  notifications and other brokered components) and DDLM (only for
  unpackaged or external-location apps).
- **The Framework dependency is declared in the manifest.** The WinUI
  templates generate the `PackageDependency`; "if you build your app
  package manually using a separate Windows Application Packaging
  Project, then you must declare a **PackageReference** in your
  `Application (package).wapproj` file":

  ```xml
  <ItemGroup>
     <PackageReference Include="Microsoft.WindowsAppSDK" Version="1.8.260209005">
         <IncludeAssets>build</IncludeAssets>
     </PackageReference>
  </ItemGroup>
  ```

  The sample's version lags the stable line; use the version the app
  project references.
- **Outside the Store, you deliver the framework**: "For packaged apps
  that are *not* distributed through the Store, you as the developer
  are responsible for distributing the Framework package. We recommend
  that you call the Deployment API so that any critical servicing
  updates are delivered."
- **The Deployment API** installs Main and Singleton, which a manifest
  cannot declare. `WindowsAppSdkDeploymentManagerInitialize` defaults
  to `true`, and from 1.8 the auto-initializer runs by default; an app
  that needs neither package should set it to `false`. Only full-trust
  apps, or apps with the `packageManagement` restricted capability, may
  call it. From 1.8, an AppContainer app needs that capability.
- **VCLibs** is a required framework dependency for packaged apps.

## Self-contained apps

- **The switch**: "In the app project file, inside the main
  `PropertyGroup`, add
  `<WindowsAppSDKSelfContained>true</WindowsAppSDKSelfContained>`".
  "Library projects should not be changed"; with a `.wapproj`, make the
  same change in the packaging project too.
- **.NET must be self-contained as well** to be fully self-contained,
  and C++ needs the hybrid CRT; a packaged app also sets
  `<UseCrtSDKReferenceStaticWarning>false</UseCrtSDKReferenceStaticWarning>`.
- **Packaged**: "the Windows App SDK dependencies will be included as
  content inside the MSIX package. Deploying the app still requires
  registering the MSIX package like any other packaged app."
- **Not serviceable**: the bundled SDK "can be updated only by
  releasing a new version of your app".
- **Which is the default is disputed.** "A Windows App SDK project is
  framework-dependent by default" (the self-contained guide), against
  the 1.8 notes: "The default experience behaves as if
  `WindowsAppSDKSelfContained` had been set as True, but the
  `Microsoft.WindowsAppSDK.Runtime` package can be referenced to use
  framework package deployment." The 2.0 notes say neither. Read the
  project.
- **No page found** says `WindowsAppSDKSelfContained` needs a
  RuntimeIdentifier or a non-AnyCPU platform; .NET's NETSDK1031 covers
  self-contained publishing without a RID in general (**excerpt only**).

## The unpackaged boundary

`<WindowsPackageType>None</WindowsPackageType>` "causes the
*auto-initializer* to locate and load a version of the Windows App SDK
that's most appropriate for your app". Such an app has no package
identity: "no automatic updates via App Installer or Store". It ships
the runtime installer or goes self-contained; `PublishSingleFile` works
only for unpackaged and self-contained apps, from 1.5. None of this
produces an MSIX, which is where this skill stops.

## Single-project MSIX or a packaging project

- **Single-project MSIX** builds "a packaged WinUI 3 desktop app without
  the need for a separate packaging project", for the WinUI templates
  only. "Single-project MSIX supports only a single executable in the
  generated MSIX package." It is `<EnableMsixTooling>true</EnableMsixTooling>`
  with `Package.appxmanifest` in the app project; the tools are built
  into Visual Studio 2026 and later.
- **A Windows Application Packaging Project** (`.wapproj`) packages WPF
  and WinForms apps, or several executables. Learn's steps add the
  project, delete `<WindowsPackageType>None</WindowsPackageType>` from
  the app, and "pick *x64* (instead of *Any Cpu*)".

## msbuild

"WinUI 3 XAML projects currently require MSBuild, although Visual
Studio isn't required and `dotnet build` can invoke MSBuild from the
command line." A plain `dotnet build` output "does not have package
identity"; the preview winapp CLI's `winapp pack` packages such a build,
and is the route for apps outside msbuild's packaging targets.

| Property | Value | Effect |
| --- | --- | --- |
| `GenerateAppxPackageOnBuild` | `true` | Produces the package. "Without that option, the project will build, but you won't get an MSIX package." |
| `UapAppxPackageBuildMode` | `SideloadOnly` | "Generates the **_Test** folder for sideloading only." |
| `UapAppxPackageBuildMode` | `StoreUpload` | "Generates the .msixupload/.appxupload file and the **_Test** folder for sideloading." |
| `UapAppxPackageBuildMode` | `CI` | "Generates the .msixupload/.appxupload file only." |
| `AppxBundle` | `Always` or `Never` | `Always` creates an `.msixbundle` from the platforms built |
| `AppxBundlePlatforms` | `x86\|x64\|arm64` | The architectures in the bundle |
| `AppxPackageDir` | a folder | Where the artifacts go |
| `AppxPackageSigningEnabled` | `true` or `false` | Signing during the build (`signing.md`) |

Learn's sideload command:

```text
/p:AppxPackageDir="Packages"
/p:UapAppxPackageBuildMode=SideloadOnly
/p:AppxBundle=Never
/p:GenerateAppxPackageOnBuild=true
```

Learn's Store bundle command, where "The `Platform=x86` property selects
the solution configuration that invokes the packaging target.
`AppxBundlePlatforms=x86|x64` controls which architectures that target
builds and includes in the bundle":

```powershell
msbuild YourSolution.sln `
    /p:Configuration=Release `
    /p:Platform=x86 `
    /p:AppxBundlePlatforms="x86|x64" `
    /p:AppxBundle=Always `
    /p:UapAppxPackageBuildMode=StoreUpload `
    /p:AppxPackageDir="Packages\" `
    /p:AppxPackageSigningEnabled=false `
    /p:GenerateAppxPackageOnBuild=true
```

**Bundles from single-project MSIX** are disputed: the single-project
page says it "doesn't currently support producing MSIX bundles"; the 1.8
notes say "several feature gaps with Single-Project solutions have been
addressed including generation of MSIX bundles and MSIX upload
packages"; the CI page above builds one with a single-project app as
its prerequisite.

`dotnet build` hid XAML compiler errors behind `MSB3073: exited with
code 1` until the fix listed under Windows App SDK 2.1.3.

## Architecture and runtime identifiers

- **Any CPU**: the Windows App SDK "is written in native code and thus
  does not support **Any CPU** build configurations" (2021 preview
  notes, **excerpt only**); the WPF and WinForms guide says to pick
  x64.
- **Bundles carry the architectures**: "Create an `.msixbundle` that
  includes both `x64` and `ARM64` architectures ... The Store and App
  Installer select the correct architecture at install time."
- **Portable RIDs from .NET 8**: "the SDK won't recognize
  version-specific or distro-specific RIDs by default", so `win10-x64`
  fails with
  `error NETSDK1083: The specified RuntimeIdentifier 'win10-x64' is not recognized.`
  Use `win-<arch>` in the project file and in a `--runtime` argument;
  `<UseRidGraph>true</UseRidGraph>` restores the old graph, which "won't
  be updated in the future". The 1.4 notes told WinUI projects to move
  `<RuntimeIdentifiers>` and each publish profile from `win10` to `win`
  (**excerpt only**); the 1.5 notes say the platform-specific-RID warning
  is gone. The single-project page still shows
  `<PublishProfile>Properties\PublishProfiles\win10-$(Platform).pubxml</PublishProfile>`,
  stale against that change.
- **Across architectures**: an update may change architecture where the
  OS supports the new one, but the same version cannot be reinstalled
  as a different architecture (`identity-and-store.md`).

## CI

- **GitHub Actions**, from Learn's WinUI workflow: `runs-on:
  windows-latest`; checkout, `actions/setup-dotnet@v4`
  (`dotnet-version: 8.0.x`) and `microsoft/setup-msbuild@v2`; decode the
  `BASE64_ENCODED_PFX` secret to a `.pfx`; restore with
  `msbuild $env:Solution_Name /t:Restore /p:Configuration=$env:Configuration`;
  build with `/p:UapAppxPackageBuildMode`, `/p:AppxBundle`,
  `/p:PackageCertificateKeyFile=GitHubActionsWorkflow.pfx`,
  `/p:AppxPackageDir` and `/p:GenerateAppxPackageOnBuild=true`; remove
  the `.pfx`; upload the artifact.
- **Azure Pipelines**: a `VSBuild@1` task with the same properties.
  "Never store signing certificates or their passwords in source
  control. Use pipeline secret variables for the certificate password
  and Azure Pipelines Secure Files for the certificate itself." The
  `MsixPackaging@1` task "uses MSBuild 4.8.4161.0 (instead of MSBuild
  16+) and was built against Node 16"; the status page's workaround is
  MSBuild directly.
- **SignTool** is not on the runner images (`signing.md`).

## The version line, to date this file

| Version | Status on 2026-10-01 |
| --- | --- |
| 2.0 (latest patch 2.5.1, 2026-09-16) | Current; servicing to 2027-04-29 |
| 1.8 | Maintenance; end of servicing 2026-09-24, already past |
| 1.7 | Out of support |

From 2.0 the SDK uses Semantic Versioning, the NuGet version is the SDK
version, and "the next side-by-side release of Windows App SDK will be
version 3.0.0".
