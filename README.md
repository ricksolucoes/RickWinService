# ⚙️ Rick WinService

<p align="center">
  <strong>Delphi framework for running the same application as a Desktop app or Windows Service.</strong>
</p>

<p align="center">
  <a href="https://docwiki.embarcadero.com/RADStudio/en/Delphi_Language_Guide_Index">
    <img src="https://img.shields.io/badge/Language-Object%20Pascal-5C2D91?style=for-the-badge&logo=delphi&logoColor=white" alt="Object Pascal">
  </a>
  <a href="https://www.embarcadero.com/products/delphi">
    <img src="https://img.shields.io/badge/IDE-Delphi-E62431?style=for-the-badge&logo=delphi&logoColor=white" alt="IDE Delphi">
  </a>
  <a href="https://docwiki.embarcadero.com/RADStudio/en/FireMonkey_Application_Platform">
    <img src="https://img.shields.io/badge/UI-FireMonkey-2563EB?style=for-the-badge" alt="FireMonkey">
  </a>
  <a href="#-overview">
    <img src="https://img.shields.io/badge/UI-VCL-0E7490?style=for-the-badge" alt="VCL">
  </a>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Revocable%20Software%20License-8250DF?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Owner-RickSolu%C3%A7%C3%B5es-1F6FEB?style=flat-square" alt="RickSoluções">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows">
</p>

🌐 **English** | [Português (Brasil)](README.pt-BR.md)

## 📖 Overview

**Rick WinService** is a Delphi framework that lets the same binary run in **Desktop** mode, using either **VCL** or **FireMonkey**, or directly as a **Windows Service**.

The framework provides a high-level facade for:

- installing and removing services;
- starting, stopping, and restarting services;
- querying the service state;
- checking whether the service is installed;
- validating administrative privileges;
- interpreting administrative commands;
- running the application as a Desktop app or Windows Service.

The consuming application does not need to interact directly with the **Windows Service Control Manager — SCM**.



## ✨ Features

- 🖥️ Run the same binary in **Desktop** or **Windows Service** mode.
- 🔷 Desktop support for **VCL**.
- 🔶 Desktop support for **FireMonkey / FMX**.
- 🔀 Desktop framework selection through `PROJECT_FMX`.
- 🪟 Native integration with the **Windows Service Control Manager — SCM**.
- 📦 Service installation and uninstallation directly through the SCM.
- ▶️ `Start`, `Stop`, and `Restart` operations.
- 🔄 Tracking of state transitions reported by the SCM.
- 🔎 Queries for service installation, state, and running status.
- 🛡️ Administrative privilege validation.
- ⚠️ Typed exception hierarchy.
- 🧩 Operation context and native Windows error information.
- ⌨️ Support for `/Install`, `/UnInstall`, `-RunService`, and `/Silent` commands.
- 🚦 Dedicated exit codes for administrative operations.
- 🧱 Simplified public facade through the `Rick.WinService` unit.


## ⚙️ Installation

* [Optional] 
  > For convenience, I recommend using [**Boss**](https://github.com/HashLoad/boss) (Dependency Manager for Delphi). Simply run the following command in a terminal, such as Windows PowerShell:

  ```sh
  boss install github.com/ricksolucoes/RickWinService
  ```

## 🎫 Manual installation for Delphi
If you prefer a manual installation, simply add the following folder to your project under *Project > Options > Building > Delphi Compiler > Search path*:
```
../RickWinService/src
```

## 🚀 Quick Start

### Configure the service

To use the framework, add the configuration below directly to your project's `.dpr` file.

1. Import the main facade:

```delphi
uses
  Rick.WinService;
```

2. **Configure the service lifecycle:**  
Set the service parameters before deciding whether the process will run as a **Windows Service** or as a **Desktop** application:

```delphi
begin
  WinServiceSetup
    .ServiceName('MeuServico')
    .ServiceTitle('Meu Serviço')
    .ServiceDetail('Descrição do serviço')
    .OnStart(OnStartService)
    .OnStop(OnStopService)
    .OnShutdown(OnShutdownService);

  if not WinServiceSetup.RunAsService then
    WinServiceSetup.CreateForm(TfrmMain, frmMain);
end.
```
#### 💥 Important

> **Business Rule:** Your application's main processing should be started in the `OnStart` event and finalized in `OnStop` or `OnShutdown`.

> **Internal Behavior:** The native `TService.OnExecute` event is managed internally by `TRickWinService.ServiceExecute` to process requests sent by the **SCM**. Avoid overriding it manually.


## 🔥 FireMonkey

To use **FireMonkey** in Desktop mode, define:

```text
PROJECT_FMX
```

under:

```text
Project Options
└── Delphi Compiler
    └── Conditional defines
```

When `PROJECT_FMX` is defined, the framework uses:

```delphi
FMX.Forms
```

Without this directive, Desktop mode uses **VCL**.

#### 💥 Important

> The runtime responsible for running as a Windows Service remains based on `Vcl.SvcMgr`, regardless of the Desktop framework used by the application.


## 🧩 Main API

The unit:

```delphi
Rick.WinService
```

exposes the framework's public facade.

### Configuration

```text
WinServiceSetup
```

### Application environment

```text
ApplicationFramework
ApplicationFrameworkName
IsVCLApplication
IsFMXApplication
```

### Service queries

```text
IsInstalled
ServiceState
IsRunning
IsRunningAsAdministrator
```

### Administration

```text
InstallService
UninstallService
StartService
StopService
RestartService
```

## 🔎 Querying the service state

```delphi
uses
  Rick.WinService,
  Rick.WinService.Types;

var
  LState: TRickWinServiceState;
begin
  if IsInstalled then
  begin
    LState := ServiceState;

    if LState = TRickWinServiceState.Running then
    begin
      // Service is running.
    end;
  end;
end;
```

## 🛡️ Administrative privileges

Operations that change the service state require the process to already be running with administrative privileges:

```text
InstallService
UninstallService
StartService
StopService
RestartService
```

The framework **does not attempt to elevate the process automatically**.

Example:

```delphi
if not IsRunningAsAdministrator then
  Exit;

StartService;
```

### 📛 Attention
> The consuming application is responsible for deciding how to request or guide the user regarding the need for administrative privileges.


## 🛠️ Service administration

The main administrative operations are:

```delphi
InstallService;

StartService;

StopService;

RestartService;

UninstallService;
```

### 📦 Installation

During installation, the service is registered with the SCM using the following `ImagePath`:

```text
"<full path to executable>" -RunService
```

When `ServiceDetail` is not empty, the installer asks the SCM to configure the service description.

The installer also attempts to configure a source in the **Windows Event Log**.

### 🗑️ Uninstallation

During uninstallation:

1. the service is removed from the SCM;
2. the framework attempts to remove the corresponding source from the Windows Event Log.



## 🔄 State control

The operations:

```text
StartService
StopService
```

wait for the state transitions reported by the SCM.

Internally, the `Manager` uses:

```text
QueryServiceStatusEx
dwCheckPoint
dwWaitHint
```

The default internal timeout is:

```text
30 seconds
```

## 💻 Command line

The framework recognizes the following commands:

| Command | Description |
|---|---|
| `/Install` | Installs the service |
| `/UnInstall` | Removes the service |
| `-RunService` | Runs the process as a Windows Service |
| `/Silent` | Indicates silent administrative execution |

Command matching is **case-insensitive**.

The following prefixes are accepted:

```text
/
-
```

### Precedence

When more than one special mode is provided, the implementation evaluates the commands in this order:

```text
1. Install
2. Uninstall
3. RunService
```



## 🧪 Command-line examples

### Install

```console
Aplicacao.exe /Install /Silent
```

### Uninstall

```console
Aplicacao.exe /UnInstall /Silent
```

### Run as a service

```console
Aplicacao.exe -RunService
```



## 🚦 Exit Codes

During `/Install` and `/UnInstall`, `RunAsService` catches exceptions and converts the result into `System.ExitCode`.

| ExitCode | Meaning |
|:---|---|
| `0` | ✅ Operation completed without an exception |
| `10` | 🛡️ Administrative privilege required |
| `20` | ⚠️ Handled exception derived from `ERickWinServiceException` |
| `99` | ❌ Exception not classified by the framework |

#### 💥 Important

> `/Silent` is recognized by `TRickWinServiceCommandLine.IsSilent`, but the framework does not display its own UI during administrative commands, regardless of this switch.

📚 More details in [`docs/CLI.md`](docs/CLI.md).

## ⚠️ Exceptions

The public exception hierarchy is available in:

```delphi
Rick.WinService.Exceptions
```

### Hierarchy

```text
ERickWinServiceException
│
├── ERickWinServiceSecurityException
│   └── ERickWinServiceAdministratorRequired
│
└── ERickWinServiceOperationException
    ├── ERickWinServiceScmException
    │
    └── ERickWinServiceStateException
        └── ERickWinServiceTimeoutException
```

### Structured handling

```delphi
uses
  Rick.WinService,
  Rick.WinService.Exceptions;

begin
  try
    StartService;
  except
    on E: ERickWinServiceAdministratorRequired do
    begin
      // The consumer decides how to guide the user.
    end;

    on E: ERickWinServiceException do
    begin
      // Failure handled by the framework.
    end;
  end;
end;
```

📚 More details in [`docs/API.md`](docs/API.md).



## 🏗️ Architecture

The implementation separates responsibilities related to:

- public facade;
- configuration;
- runtime;
- command-line parsing;
- SCM management;
- installation;
- security;
- contracts;
- types;
- exceptions.

### Simplified view

```text
Rick.WinService
│
├── Setup
│   ├── CommandLine
│   └── Service
│
├── Model
│   └── Manager
│
├── Installer
│   └── Manager
│
└── Security
```

The complete description of the **11 `.pas` units**, the **DFM** file, and the internal dependencies is available at:

📚 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)



## 🧪 Testing and quality

The project includes an automated DUnitX suite with **57 tests across 9 fixtures**, covering unit tests, separate-process execution, the service component, and real integration with the Windows Service Control Manager (SCM).

The integration suite exercises real scenarios for:

```text
Query
Install / Uninstall
Start / Stop
Restart
```

For Restart, the suite also verifies service-process replacement through a PID change, in addition to returning to the `Running` state.

In the baseline validated on **2026-09-17**, the test group completed `Build All Projects` successfully and the runner reported **57 passed tests, 0 ignored, 0 failed, 0 errors, and 0 tests reported as leaked by DUnitX**.

The complete suite should be executed as Administrator because mutable SCM scenarios install, start, stop, restart, and remove temporary services.

📚 Strategy, structure, Test Hosts, execution, and Method Toxicity Metrics: [`docs/TESTING.md`](docs/TESTING.md)



## 📚 Documentation

| Document | Description |
|---|---|
| 📘 [`docs/API.md`](docs/API.md) | Facade, contracts, types, callbacks, and exceptions |
| 💻 [`docs/CLI.md`](docs/CLI.md) | Switches, precedence, and exit codes |
| 🏗️ [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Responsibilities, dependencies, and internal flows |
| 🧪 [`docs/TESTING.md`](docs/TESTING.md) | Test strategy, Test Hosts, SCM integration, and metrics |
| 🔄 [`docs/MIGRATION.md`](docs/MIGRATION.md) | Verifiable history and audit of the previous documentation |
| 📝 [`CHANGELOG.md`](CHANGELOG.md) | Changes not yet associated with a verified release |



## 📂 Documentation structure

```text
.
├── src/
│   └── ...
│
├── docs/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   ├── CLI.md
│   ├── MIGRATION.md
│   ├── TESTING.md
│   ├── API.pt-BR.md
│   ├── ARCHITECTURE.pt-BR.md
│   ├── CLI.pt-BR.md
│   ├── MIGRATION.pt-BR.md
│   └── TESTING.pt-BR.md
│
├── CHANGELOG.md
├── LICENSE
├── README.md
├── CHANGELOG.pt-BR.md
├── LICENSE-pt-BR
└── README.pt-BR.md
```

## 📜 License

This project is distributed under a revocable license (**Revocable Software License**).

Before using the software, read the [`LICENSE`](LICENSE) file for the complete terms, usage restrictions, and permissions.

<div align="center">

## ⚙️ RickWinService

**Windows Service made simple for Delphi applications.**

Developed by **RickSoluções**

<br>

[🇧🇷 Leia a versão oficial em Português (Brasil)](./README.pt-BR.md)
