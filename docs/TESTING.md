# Testing

This document describes the test suite currently maintained for RickWinService, including DUnitX tests, Test Hosts executed in separate processes, and real integration scenarios against the Windows Service Control Manager (SCM).

The documentation records only behavior and validations observed in the current project state. The results below correspond to the environment where the suite was actually built and executed; they are not a guarantee of identical behavior on every machine, Windows version, or Delphi configuration.

## Suite scope

The suite covers four complementary levels:

- **unit tests**, for contracts, types, configuration, and isolated behavior;
- **process tests**, for scenarios where arguments or privileges depend on a real process;
- **component testing**, including `TRickWinService` creation and loading the `OnExecute` handler defined in the DFM;
- **real SCM integration**, including querying, installing, starting, stopping, restarting, and removing temporary services.

Production code under `../src` is consumed by the suite as a dependency and is outside the test-organization scope described in this document.

## Validated environment

The recorded validation was executed with:

```text
Windows
Delphi 10.2 Tokyo
Win32 target
DUnitX
```

Tests that modify the SCM require administrative privileges. Therefore, the DUnitX runner must be started as Administrator to execute the complete suite.

The unit tests, CommandLine Test Host, Security validation, and read-only SCM query do not intrinsically require elevated execution according to the suite itself. The Security fixture adapts its expectation to the actual elevation state of the process.

## Structure

```text
tests/
├── RickWinService.Tests.dpr
├── RickWinService.Tests.dproj
├── RickWinService.Tests.res
├── RickWinService.groupproj
└── src/
    ├── units/
    │   ├── Rick.WinService.Tests.CommandLine.pas
    │   ├── Rick.WinService.Tests.CommandLine.Process.pas
    │   ├── Rick.WinService.Tests.Exceptions.pas
    │   ├── Rick.WinService.Tests.Facade.pas
    │   ├── Rick.WinService.Tests.Model.pas
    │   ├── Rick.WinService.Tests.Security.Process.pas
    │   ├── Rick.WinService.Tests.Service.Component.pas
    │   └── Rick.WinService.Tests.Setup.pas
    ├── component/
    │   ├── RickWinService.CommandLine.TestHost.*
    │   └── RickWinService.Security.TestHost.*
    └── integration/
        ├── Rick.WinService.Tests.Scm.Process.pas
        ├── RickWinService.Integration.ServiceHost.*
        ├── RickWinService.SCM.Query.TestHost.*
        ├── RickWinService.SCM.InstallRoundTrip.TestHost.*
        ├── RickWinService.SCM.Lifecycle.TestHost.*
        └── RickWinService.SCM.Restart.TestHost.*
```

### `tests/src/units`

Contains the DUnitX fixtures responsible for unit, process, and component-level validation.

### `tests/src/component`

Contains helper executables used when behavior must be observed in a real process:

- `RickWinService.CommandLine.TestHost`;
- `RickWinService.Security.TestHost`.

### `tests/src/integration`

Contains the fixture that orchestrates real SCM tests, the integration Test Hosts, and the service executable used by the Lifecycle and Restart scenarios.

## DUnitX runner

The suite entry point is:

```text
RickWinService.Tests.dpr
```

The runner uses `DUnitX.Loggers.GUI.VCL` and registers nine fixtures:

| Fixture | Category | Tests |
|---|---|---:|
| `CommandLine` | Unit | 4 |
| `CommandLine.Process` | Process | 19 |
| `Exceptions` | Unit | 6 |
| `Facade` | Unit | 5 |
| `Model` | Unit | 6 |
| `Security.Process` | Process | 1 |
| `Service.Component` | Component | 4 |
| `Setup` | Unit | 8 |
| `Scm.Process` | SCM integration | 4 |
| **Total** |  | **57** |

## Process tests

### CommandLine

`Rick.WinService.Tests.CommandLine.Process` starts `RickWinService.CommandLine.TestHost.exe` with real argument combinations.

The 19 tests cover, among other points:

- Desktop execution with no arguments;
- `/Silent`;
- Install, Uninstall, and RunService;
- `-` and `/` prefix variants;
- case-insensitive matching;
- command precedence;
- remaining in Desktop mode for an unknown switch.

The Test Host uses semantic exit codes to represent the command and Silent mode. Therefore, **there is no project-wide `ExitCode = 100` convention for every Test Host**.

### Security

`Rick.WinService.Tests.Security.Process` starts `RickWinService.Security.TestHost.exe`.

The Test Host compares:

```text
TRickWinServiceSecurity.IsRunningAsAdministrator
IsRunningAsAdministrator
```

and validates `RequireAdministrator` according to the actual process token.

The expected result depends on elevation:

```text
100 = validated non-elevated process
200 = validated elevated process
```

## Service component test

`Rick.WinService.Tests.Service.Component` validates service-component creation and covers:

- applying `ServiceName`;
- applying `ServiceTitle`;
- assigning the service controller;
- loading `ServiceExecute` from the DFM.

This test does not start a real service through the SCM.

## Real SCM integration

The fixture:

```text
Rick.WinService.Tests.Scm.Process
```

executes four Test Hosts in separate processes.

The read-only query has an external timeout of `30000 ms`. Hosts that modify the SCM have an external timeout of `180000 ms`. If a host exceeds its timeout, the runner terminates the process and records a failure.

For the four SCM Test Hosts, the fixture uses:

```text
ExitCode = 100
```

as the success result for the complete scenario.

### Query

Executable:

```text
RickWinService.SCM.Query.TestHost.exe
```

Uses a test-specific service name and validates through both `TRickWinServiceManager` and `IRickWinService` that a deliberately absent service is reported as:

```text
NotInstalled
IsInstalled = False
IsRunning = False
```

This is a read-only scenario.

### InstallRoundTrip

Executable:

```text
RickWinService.SCM.InstallRoundTrip.TestHost.exe
```

Flow:

```text
preconditions
    ↓
Install
    ↓
Manager validation
    ↓
Model validation
    ↓
Uninstall
    ↓
NotInstalled
```

The service is installed and removed without being started.

### Lifecycle

Executable:

```text
RickWinService.SCM.Lifecycle.TestHost.exe
```

Uses:

```text
RickWinService.Integration.ServiceHost.exe
```

as the temporary service executable.

Validated flow:

```text
Install
  ↓
Stopped
  ↓
Start
  ↓
Running
  ↓
Stop
  ↓
Stopped
  ↓
Uninstall
  ↓
NotInstalled
```

State validation uses both Manager and Model where applicable.

### Restart

Executable:

```text
RickWinService.SCM.Restart.TestHost.exe
```

Also uses `RickWinService.Integration.ServiceHost.exe`.

Flow:

```text
Install
  ↓
Start
  ↓
Running
  ↓
initial PID
  ↓
Restart
  ↓
Running
  ↓
new PID
  ↓
Stop
  ↓
Uninstall
```

The test does not rely only on the service returning to `Running`. It queries the service process PID before and after `Restart` and requires:

```text
initial PID <> 0
PID after Restart <> 0
PID after Restart <> initial PID
```

This validates that the service process was replaced during the Restart executed in the test environment.

## `Integration.ServiceHost`

`RickWinService.Integration.ServiceHost.exe` is a minimal executable configured through `WinServiceSetup`.

It is used as the service process by the Lifecycle and Restart scenarios. When started by the SCM with `-RunService`, it enters the RickWinService service runtime.

It is not a DUnitX fixture; it is integration infrastructure.

## Temporary services and cleanup

SCM scenarios use service names beginning with:

```text
RickWinService_IntegrationTest_
```

The mutable Test Hosts implement defensive cleanup when a scenario fails. However, external termination of a process during an SCM operation can leave a temporary service or process behind in Windows.

To inspect leftovers:

```powershell
Get-CimInstance Win32_Service |
  Where-Object {
    $_.Name -like "RickWinService_IntegrationTest_*"
  } |
  Select-Object Name, State, ProcessId, PathName
```

Before manually removing any entry, confirm that it belongs to the RickWinService integration suite.

## Build

Open:

```text
tests/RickWinService.groupproj
```

and run:

```text
Build All Projects
```

The group contains eight projects:

1. `RickWinService.Tests`;
2. `RickWinService.CommandLine.TestHost`;
3. `RickWinService.Security.TestHost`;
4. `RickWinService.SCM.Query.TestHost`;
5. `RickWinService.SCM.InstallRoundTrip.TestHost`;
6. `RickWinService.Integration.ServiceHost`;
7. `RickWinService.SCM.Lifecycle.TestHost`;
8. `RickWinService.SCM.Restart.TestHost`.

The runner and helper executables are configured to be generated under the repository-relative `App\<Config>` directory. This layout allows fixtures to locate Test Hosts in the same directory as the runner.

## Execution

To execute the complete suite:

1. build the group;
2. start `RickWinService.Tests.exe` as Administrator;
3. run the suite through the DUnitX GUI runner.

Administrator privileges are required for the three mutable SCM scenarios:

```text
InstallRoundTrip
Lifecycle
Restart
```

## Validated baseline

On **2026-09-17**, in the validation environment used during the project review, `Build All Projects` finished with:

```text
Success
```

The complete DUnitX runner execution reported:

```text
Tests Found   : 57
Tests Ignored : 0
Tests Passed  : 57
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```

These values record the observed run in that environment. `Tests Leaked : 0` is the result reported by DUnitX for that execution and must not be interpreted as general proof that no leak can occur in every possible scenario.

## Method Toxicity Metrics

A real CSV exported by **RAD Studio Method Toxicity Metrics** was provided for the suite.

The report contains **84 methods** across the **9 `.pas` units** registered in the DUnitX runner.

The highest observed values were:

| Metric | Observed maximum | Project threshold |
|---|---:|---:|
| `Length` | 10 | 20 |
| `Parameters` | 3 | 6 |
| `If Depth` | 1 | 5 |
| `Cyclomatic Complexity` | 2 | 6 |
| `Toxicity` | 0.346 | 1 |

None of the methods present in this report exceeded the configured project thresholds.

### Measurement limitation

The provided CSV does not contain methods implemented directly in the Test Host `.dpr` files.

Therefore:

- the values above are **real measurements** for methods present in the 9 `.pas` units in the report;
- the Test Host `.dpr` files were built and exercised during their corresponding validations;
- the real composed `Toxicity` value for methods declared in those `.dpr` files is **Not confirmed**.

No estimated or manually derived Toxicity value should be assigned to those `.dpr` methods.

## Suite maintenance

When adding or changing tests:

- keep `RickWinService.Tests.dpr` synchronized with the fixtures;
- keep `RickWinService.groupproj` synchronized with required Test Hosts;
- preserve unique temporary service names;
- preserve defensive cleanup for SCM scenarios;
- update documented counts only after confirming the real suite;
- record build, execution, and Method Toxicity results only when they have actually been measured.
