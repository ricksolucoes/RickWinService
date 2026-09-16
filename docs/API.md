# API

This reference describes the public surface observable in the current code. The recommended facade for common usage is `Rick.WinService`.

## `Rick.WinService` facade

### Shared configuration

```delphi
function WinServiceSetup: IRickWinServiceSetup;
```

Returns the shared configuration. On the first call, the implementation creates `TRickWinServiceSetup` and stores the interface in the public `RickSetup` variable.

The unit also exposes:

```delphi
var
  RickSetup: IRickWinServiceSetup;
```

For normal usage, `WinServiceSetup` avoids the need to manipulate this variable directly.

### Desktop framework identification

```delphi
function ApplicationFramework: TRickApplicationFramework;
function ApplicationFrameworkName: string;
function IsVCLApplication: Boolean;
function IsFMXApplication: Boolean;
```

The decision is made at compile time:

- with `PROJECT_FMX`: `TRickApplicationFramework.FMX` and name `FMX`;
- without `PROJECT_FMX`: `TRickApplicationFramework.VCL` and name `VCL`.

These functions describe the framework used in Desktop mode. The Windows Service runtime uses `Vcl.SvcMgr`.

### Queries

```delphi
function IsInstalled: Boolean;
function ServiceState: TRickWinServiceState;
function IsRunning: Boolean;
function IsRunningAsAdministrator: Boolean;
```

`IsInstalled`, `ServiceState`, and `IsRunning` create a `TRickWinServiceModel` for the name currently configured in `WinServiceSetup` and query the SCM through `TRickWinServiceManager`.

`IsRunningAsAdministrator` queries the effective process token and checks membership in the local Administrators group through `CheckTokenMembership`.

### Administrative operations

```delphi
procedure InstallService;
procedure UninstallService;
procedure StartService;
procedure StopService;
procedure RestartService;
```

All five operations require administrative privileges in the default implementation.

`InstallService` and `UninstallService` use `TRickWinServiceInstaller` directly. `StartService`, `StopService`, and `RestartService` use `TRickWinServiceModel`, which delegates SCM access to `TRickWinServiceManager`.

## `IRickWinServiceSetup`

Current GUID:

```text
{02F69C40-E367-43FC-BEE5-E974750FD09B}
```

Configuration methods:

```delphi
function ServiceName(const Value: string): IRickWinServiceSetup;
function ServiceTitle(const Value: string): IRickWinServiceSetup;
function ServiceDetail(const Value: string): IRickWinServiceSetup;
```

Available callbacks:

```delphi
function OnStart(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnStop(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnPause(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnContinue(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnCreate(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnDestroy(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnShutdown(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnBeforeInstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnAfterInstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnBeforeUninstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
function OnAfterUninstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
```

Execution:

```delphi
function CreateForm(Component: TComponentClass;
  var Reference;
  ReportLeaks: Boolean = True): IRickWinServiceSetup;

function RunAsService: Boolean;
```

### `RunAsService`

The return value indicates whether the process was consumed by a special mode:

| Command | Action | Return value |
|---|---|---:|
| none | continues to Desktop | `False` |
| `Install` | executes `ExecuteInstallCommand` | `True` |
| `Uninstall` | executes `ExecuteUninstallCommand` | `True` |
| `RunService` | executes `RunWindowsService` | `True` after the runtime returns |

On the Desktop path, `CreateForm` initializes and runs `FMX.Forms.Application` when `PROJECT_FMX` is defined; otherwise, it uses `Vcl.Forms.Application`.

### Runtime callbacks

During `RunWindowsService`, configured callbacks are assigned to the corresponding `TRickWinService` events only when they have been provided.

For `OnStart`, `OnStop`, `OnPause`, and `OnContinue`, the handlers set the `Started`, `Stopped`, `Paused`, and `Continued` parameters to `True` only when the callback completes without an exception.

`OnCreate`, `OnDestroy`, and `OnShutdown` are forwarded directly to the configured callback.

The physical `OnExecute` event is not part of `IRickWinServiceSetup`. It remains bound to `TRickWinService.ServiceExecute` in the DFM.

### Installation callbacks

`OnBeforeInstall`, `OnAfterInstall`, `OnBeforeUninstall`, and `OnAfterUninstall` are executed both through the facade paths and through commands handled by `Setup`.

The observable order is:

```text
Before -> main operation -> After
```

The `After` callback is reached only when the main operation returns without an exception.

## `IRickWinService`

Current GUID:

```text
{CF698484-2DCE-439C-9D79-6EC2DCC07109}
```

Contract:

```delphi
function ServiceName(const Value: string): IRickWinService; overload;
function ServiceName: string; overload;
function ExeName: string; overload;
function ExeName(const Value: string): IRickWinService; overload;

procedure Install; overload;
procedure Install(Params: TDictionary<string, string>); overload;
procedure Uninstall; overload;
procedure Uninstall(Params: TDictionary<string, string>); overload;
procedure Start;
procedure Stop;
procedure Restart;

function IsInstalled: Boolean;
function IsRunning: Boolean;
function State: TRickWinServiceState;
```

`TRickWinServiceModel` is the current implementation of this contract.

### Contract `Install`/`Uninstall`

Unlike the procedural facade, the `IRickWinService` methods run the executable configured in `ExeName` as a helper process:

```text
/Install /Silent
/UnInstall /Silent
```

Additional parameters from `TDictionary<string,string>` are appended to the command line by the adapter. The parent process waits for completion, reads the `ExitCode`, and turns known failures into Rick WinService exceptions.

This behavior is observable in the current implementation. This documentation does not state when or why this contract was introduced historically.

## Public types

### `TRickWinServiceState`

```text
NotInstalled
Stopped
StartPending
StopPending
Running
ContinuePending
PausePending
Paused
Unknown
```

`NotInstalled` is returned by `TRickWinServiceManager.GetServiceState` when `OpenService` fails with `ERROR_SERVICE_DOES_NOT_EXIST`.

### `TInstallType`

```text
Install
Uninstall
```

Used by the `TRickWinServiceModel.ExecProcess` adapter.

### `TRickWinServiceOperation`

```text
Query
Install
Uninstall
Start
Stop
Restart
```

Used to provide context for exceptions and SCM operations.

### `TRickApplicationFramework`

```text
VCL
FMX
```

### `TOnRickWinServiceEvent`

```delphi
TOnRickWinServiceEvent = reference to procedure;
```

## Exceptions

### Hierarchy

```text
ERickWinServiceException
├── ERickWinServiceSecurityException
│   └── ERickWinServiceAdministratorRequired
└── ERickWinServiceOperationException
    ├── ERickWinServiceScmException
    └── ERickWinServiceStateException
        └── ERickWinServiceTimeoutException
```

### `ERickWinServiceAdministratorRequired`

Exposes:

```text
Operation: string
```

Raised when `RequireAdministrator` determines that the process is not running with effective administrative privileges.

### `ERickWinServiceOperationException`

Exposes:

```text
Operation: TRickWinServiceOperation
ServiceName: string
```

### `ERickWinServiceScmException`

Adds:

```text
Win32ErrorCode: DWORD
Context: string
```

The `Manager` captures `GetLastError` at the point where the SCM call fails and constructs this exception.

### `ERickWinServiceStateException`

Adds:

```text
ExpectedState: TRickWinServiceState
CurrentState: TRickWinServiceState
ServiceWin32ExitCode: DWORD
ServiceSpecificExitCode: DWORD
```

### `ERickWinServiceTimeoutException`

Adds:

```text
Timeout: Cardinal
```

The `Manager` uses it when the transition exceeds the configured timeout or stops demonstrating progress according to `dwCheckPoint` and `dwWaitHint`.

## Handling example

```delphi
uses
  System.SysUtils,
  Rick.WinService,
  Rick.WinService.Exceptions;

begin
  try
    StartService;
  except
    on E: ERickWinServiceAdministratorRequired do
    begin
      // Define the presentation policy in the consuming application.
    end;

    on E: ERickWinServiceException do
    begin
      // Failure handled by the framework.
    end;

    on E: Exception do
    begin
      // Failure not classified by the framework contract.
    end;
  end;
end;
```

## Technically accessible infrastructure units

The units below declare public classes, although the common flow goes through the `Rick.WinService` facade:

- `Rick.WinService.CommandLine` — `TRickWinServiceCommandLine` and exit codes;
- `Rick.WinService.Security` — `TRickWinServiceSecurity`;
- `Rick.WinService.Manager` — `TRickWinServiceManager` and `IsDesktopMode`;
- `Rick.WinService.Installer` — `TRickWinServiceInstaller`;
- `Rick.WinService.Model` — `TRickWinServiceModel`;
- `Rick.WinService.Setup` — `TRickWinServiceSetup` and helper callbacks;
- `Rick.WinService.Service` — `TRickWinService` and global service metadata.

The architecture and dependencies of these units are documented in [ARCHITECTURE.md](ARCHITECTURE.md).
