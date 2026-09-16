# Migration

This document records only migration information that can be supported by the material provided. It **does not reconstruct the project's history by inference**.

## Historical limitation

No Git repository, tag, release, or complete snapshot of a previous public version was provided that would allow Rick WinService's evolution to be reconstructed safely.

The current package contains a few `.~1~` files under `src/__history`, but they represent only local backups of four units and do not constitute a complete release baseline. For that reason, they are not used to claim that a particular API, GUID, unit, or behavior was preserved across public versions.

Historical claims from the former `Leia-me.md` that would require comparison with an earlier version are classified below as **Not confirmed** and are not promoted to migration facts.

## Current documented state

In the provided state, `src` contains 11 `.pas` units:

```text
Rick.WinService.pas
Rick.WinService.Types.pas
Rick.WinService.Interfaces.pas
Rick.WinService.Exceptions.pas
Rick.WinService.Security.pas
Rick.WinService.Manager.pas
Rick.WinService.Installer.pas
Rick.WinService.CommandLine.pas
Rick.WinService.Model.pas
Rick.WinService.Setup.pas
Rick.WinService.Service.pas
```

In addition, `Rick.WinService.Service.dfm` is present.

The current architecture is documented in [ARCHITECTURE.md](ARCHITECTURE.md), without inferring the structure of previous versions.

## Documentation migration matrix for the former `Leia-me.md`

The matrix below covers all relevant sections and information from the removed file. Its purpose is to demonstrate that the content was migrated, corrected, deliberately discarded, or marked as not confirmed before the competing source was removed.

| Content from `Leia-me.md` | Classification | Destination/Action | Evidence used |
|---|---|---|---|
| Description: same binary in Desktop or Windows Service mode | Confirmed | `README.md` and `ARCHITECTURE.md` | `Setup.RunAsService`, `Service`, `CreateForm` |
| FMX through `PROJECT_FMX`; without the directive, Desktop uses VCL | Confirmed | `README.md`, `API.md`, `ARCHITECTURE.md` | conditionals in `Rick.WinService.Setup` and `Rick.WinService.ApplicationFramework` |
| Basic example with `WinServiceSetup`, `RunAsService`, and `CreateForm` | Confirmed | `README.md` | contracts and implementation of `IRickWinServiceSetup` |
| Main processing in `OnStart`; finalization in `OnStop`/`OnShutdown` | Confirmed as guidance compatible with the runtime | `README.md` and `API.md` | callbacks assigned by `RunWindowsService`; `ServiceExecute` reserved for the loop |
| `TService.OnExecute` not exposed as a public callback | Confirmed | `README.md`, `API.md`, `ARCHITECTURE.md` | `IRickWinServiceSetup` has no `OnExecute`; DFM binds `OnExecute = ServiceExecute` |
| Two administrative barriers: preventive check and validation in state-changing operations | Confirmed | `README.md` and `API.md` | `IsRunningAsAdministrator`, `RequireAdministrator`, facade and Model/Installer |
| Framework does not elevate automatically or display its own UI for the administrative error | Confirmed in the analyzed code | `README.md`, `API.md`, `CLI.md` | no `runas`; exceptions and ExitCode; administrative units without visual presentation |
| Example with `RickDialog` | External to the provided material | Discarded | no reference to `RickDialog` in `src` |
| Service states shown in the example | Confirmed, but incomplete in the old document | Corrected in `API.md` and `README.md`, including `NotInstalled` | `TRickWinServiceState` |
| `InstallService` | Confirmed | `README.md` and `API.md` | `Rick.WinService` facade |
| `UninstallService` | Confirmed | `README.md` and `API.md` | `Rick.WinService` facade |
| `StartService` | Confirmed | `README.md` and `API.md` | `Rick.WinService` facade |
| `StopService` | Confirmed | `README.md` and `API.md` | `Rick.WinService` facade |
| `RestartService` | Confirmed | `README.md` and `API.md` | `Rick.WinService` facade |
| Examples of `TfrmMain.btn*Click` handlers that only called the five administrative operations | Confirmed, but UI-specific and redundant | Simplified to direct calls in `README.md`; full reference in `API.md` | the handlers added no behavior beyond the facade functions |
| Normal Desktop flow | Confirmed | `ARCHITECTURE.md` | `CommandLine.Command` and `RunAsService` |
| `-RunService` flow to `TService` | Confirmed | `README.md`, `CLI.md`, `ARCHITECTURE.md` | `Installer.BinaryPath`, `RunWindowsService`, `TRickWinService` |
| `ImagePath` with quoted executable and `-RunService` | Confirmed | `README.md`, `CLI.md`, `ARCHITECTURE.md` | `TRickWinServiceInstaller.BinaryPath` |
| Internal organization: `Rick.WinService.Types` | Partially correct, but the old list does not include `TRickWinServiceOperation` | Corrected in `API.md` and `ARCHITECTURE.md` | current `Rick.WinService.Types` |
| Internal organization: `Rick.WinService.Interfaces` | Confirmed for the current state | `API.md` and `ARCHITECTURE.md` | current unit |
| `Rick.WinService.Model` implements `IRickWinService` | Confirmed | `API.md` and `ARCHITECTURE.md` | declaration of `TRickWinServiceModel` |
| `Rick.WinService.Setup` implements `IRickWinServiceSetup` | Confirmed | `API.md` and `ARCHITECTURE.md` | declaration of `TRickWinServiceSetup` |
| `Rick.WinService` is the procedural facade | Confirmed | `README.md`, `API.md`, `ARCHITECTURE.md` | unit interface |
| `Manager` encapsulates SCM access | Confirmed | `ARCHITECTURE.md` | `TRickWinServiceManager` |
| `Security` validates administrative privileges | Confirmed | `ARCHITECTURE.md` | `TRickWinServiceSecurity` |
| `Service` contains the runtime `TService` | Confirmed | `ARCHITECTURE.md` | `TRickWinService` |
| `Exceptions` contains the typed hierarchy | Confirmed | `API.md` and `ARCHITECTURE.md` | `Rick.WinService.Exceptions` |
| Old diagram `Types -> Interfaces -> Model / Setup -> facade` | Divergent/incomplete | Replaced in `ARCHITECTURE.md` | `uses` and implementation of the current 11 units |
| Claim that `Manager`, `Security`, and `Service` do not depend on upper layers | Partially inaccurate | Replaced by the actual graph in `ARCHITECTURE.md` | `Manager` depends on `CommandLine`, `Exceptions`, and `Types`; other current dependencies |
| “There used to be 7 units” | Historical claim without a complete baseline | **Not confirmed**; not promoted to fact | no repository/tag/release or complete previous snapshot |
| “The reorganization resulted in 9 units” | Divergent from the current state | Discarded as a current description | there are 11 `.pas` units in the current package |
| Split of `Rick.WinService.Model.Interfaces` | Historical claim without a complete baseline | **Not confirmed** | no complete previous version is available for comparison |
| Split of `Rick.WinService.Setup.Interfaces` | Historical claim without a complete baseline | **Not confirmed** | no complete previous version is available for comparison |
| Rename from `Rick.WinService.Model.Default` to `Rick.WinService.Model` | Historical claim without a complete baseline | **Not confirmed** | no complete previous version is available for comparison |
| “No public signature was changed” | Comparative historical claim | **Not confirmed** | requires comparison with a previous baseline |
| “GUIDs were preserved” | Comparative historical claim | **Not confirmed** | current GUIDs are known, but preservation requires a previous baseline |
| “No business rule or observable behavior was changed” | Comparative historical claim | **Not confirmed** | requires behavioral comparison with a previous baseline |
| Instruction to replace `uses Rick.WinService.Setup.Interfaces` with `Rick.WinService` | Historical migration dependent on an earlier unit | **Not confirmed**; omitted from the current guide | the earlier unit is not available in a complete baseline |
| “Public identifiers retain the same signature” | Comparative historical claim | **Not confirmed** | requires comparison with a previous baseline |

## Audit of `Leia-me.md` removal

Matrix result:

- current functional content: migrated or corrected in the canonical documents;
- unsupported external content: deliberately discarded;
- historical claims without a complete baseline: not promoted to facts and identified as **Not confirmed** in the matrix;
- divergent structural information: replaced by the current structure observed in `src`.

With every block from the former document classified, it is no longer required as a second documentation source.

## Historical points not confirmed

The following remain unconfirmed due to the absence of a complete historical baseline:

- number of units in an earlier version;
- historical origin of the current units;
- unit renames between releases;
- preservation of GUIDs relative to previous versions;
- preservation of public signatures relative to previous versions;
- full preservation of business rules and behavior relative to previous versions;
- migration instructions based on unit names that do not exist in the current snapshot.

If commits, tags, releases, or complete earlier snapshots are provided in the future, these items can be reassessed through direct comparison.
