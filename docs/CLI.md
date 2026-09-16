# Command line

Command-line parsing is centralized in `Rick.WinService.CommandLine`. Execution of special modes is coordinated by `TRickWinServiceSetup.RunAsService`.

## Recognized commands

```text
/Install
/UnInstall
-RunService
/Silent
```

`FindCmdLineSwitch` is called with the `-` and `/` prefixes and case-insensitive matching. Therefore, the commands being searched accept either prefix and are not case-sensitive.

## Precedence

`TRickWinServiceCommandLine.Command` tests the modes in this order:

1. `INSTALL`;
2. `UNINSTALL`;
3. `RUNSERVICE`;
4. if none is present, `Desktop`.

As a result, if a command line contains more than one of these modes, the first one found in this order is selected.

`/Silent` does not participate in mode selection.

## Desktop

Without `Install`, `Uninstall`, or `RunService`, `Command` returns `Desktop`, and `WinServiceSetup.RunAsService` returns `False` without starting the service runtime.

Typical flow:

```text
Aplicacao.exe
  -> RunAsService
      -> Desktop
          -> returns False
              -> consuming application can call CreateForm
```

## Installation

Example:

```text
Aplicacao.exe /Install /Silent
```

Flow:

```text
RunAsService
  -> ExecuteInstallCommand
      -> RequireAdministrator
      -> OnBeforeInstall, if configured
      -> TRickWinServiceInstaller.Install
          -> SCM
          -> description, when provided
          -> attempt to configure Event Log
      -> OnAfterInstall, if the operation completed without an exception
```

The command does not use `TServiceApplication.RegisterServices` to register the service. The Installer calls the SCM directly.

## Uninstallation

Example:

```text
Aplicacao.exe /UnInstall /Silent
```

Flow:

```text
RunAsService
  -> ExecuteUninstallCommand
      -> RequireAdministrator
      -> OnBeforeUninstall, if configured
      -> TRickWinServiceInstaller.Uninstall
          -> DeleteService in the SCM
          -> attempt to remove the Event Log source
      -> OnAfterUninstall, if the operation completed without an exception
```

## Running as a Windows Service

The Installer registers `ImagePath` in the following format:

```text
"<executable>" -RunService
```

When the SCM starts this command:

```text
RunAsService
  -> RunWindowsService
      -> Vcl.SvcMgr.Application
      -> creates TRickWinService
      -> assigns configured callbacks
      -> Application.Run
```

`TRickWinService` keeps `OnExecute = ServiceExecute` in the DFM. `ServiceExecute` processes requests while `Terminated` is `False`.

## `/Silent`

`TRickWinServiceCommandLine.IsSilent` indicates whether the `SILENT` switch is present.

In the current code, this value does not change the `RunAsService` flow. The `Setup` administrative commands already catch exceptions and do not display their own UI; the compatibility path of `IRickWinService.Install/Uninstall` adds `/Silent` to the helper process.

## ExitCode

`ExecuteInstallCommand` and `ExecuteUninstallCommand` initialize `System.ExitCode` to `0` and catch any `Exception` raised by the command.

`TRickWinServiceCommandLine.ExitCodeForException` applies the following mapping:

| Constant | Value | Condition |
|---|---:|---|
| `RICK_WINSERVICE_EXIT_SUCCESS` | `0` | command completed without a caught exception |
| `RICK_WINSERVICE_EXIT_ADMIN_REQUIRED` | `10` | `ERickWinServiceAdministratorRequired` |
| `RICK_WINSERVICE_EXIT_OPERATION_ERROR` | `20` | any other `ERickWinServiceException` |
| `RICK_WINSERVICE_EXIT_UNEXPECTED_ERROR` | `99` | any other `Exception` |

This handling is explicitly implemented in the `Install` and `Uninstall` paths of `Setup`. This documentation does not extend that guarantee to failures occurring inside `RunWindowsService`, because that path does not use the same `try/except` boundary.

## `IRickWinService` helper process

`TRickWinServiceModel.Install` and `Uninstall` run the binary configured in `ExeName` through `CreateProcess`.

Base command lines:

```text
/Install /Silent
/UnInstall /Silent
```

The parent process waits indefinitely (`WaitForSingleObject(..., INFINITE)`), reads the exit code, and applies:

- `0`: success;
- `10`: raises `ERickWinServiceAdministratorRequired`;
- any other value: raises `ERickWinServiceOperationException`.

Failures while creating the process, waiting for it, or reading its ExitCode are also converted into `ERickWinServiceOperationException`.

## Security note

The installation and uninstallation paths require administrative privileges before the main operation. The framework does not call `runas` and does not implement automatic elevation.
