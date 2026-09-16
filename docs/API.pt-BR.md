# API

Esta referência descreve a superfície pública observável no código atual. A fachada recomendada para consumo comum está em `Rick.WinService`.

## Fachada `Rick.WinService`

### Configuração compartilhada

```delphi
function WinServiceSetup: IRickWinServiceSetup;
```

Retorna a configuração compartilhada. Na primeira chamada, a implementação cria `TRickWinServiceSetup` e armazena a interface na variável pública `RickSetup`.

A unit também expõe:

```delphi
var
  RickSetup: IRickWinServiceSetup;
```

Para uso normal, `WinServiceSetup` evita a necessidade de manipular essa variável diretamente.

### Identificação do framework Desktop

```delphi
function ApplicationFramework: TRickApplicationFramework;
function ApplicationFrameworkName: string;
function IsVCLApplication: Boolean;
function IsFMXApplication: Boolean;
```

A decisão é feita em tempo de compilação:

- com `PROJECT_FMX`: `TRickApplicationFramework.FMX` e nome `FMX`;
- sem `PROJECT_FMX`: `TRickApplicationFramework.VCL` e nome `VCL`.

Essas funções descrevem o framework do modo Desktop. O runtime do Windows Service usa `Vcl.SvcMgr`.

### Consultas

```delphi
function IsInstalled: Boolean;
function ServiceState: TRickWinServiceState;
function IsRunning: Boolean;
function IsRunningAsAdministrator: Boolean;
```

`IsInstalled`, `ServiceState` e `IsRunning` criam um `TRickWinServiceModel` para o nome atualmente configurado em `WinServiceSetup` e consultam o SCM por meio de `TRickWinServiceManager`.

`IsRunningAsAdministrator` consulta o token efetivo do processo e verifica a associação ao grupo local Administrators por meio de `CheckTokenMembership`.

### Operações administrativas

```delphi
procedure InstallService;
procedure UninstallService;
procedure StartService;
procedure StopService;
procedure RestartService;
```

As cinco operações exigem privilégios administrativos na implementação padrão.

`InstallService` e `UninstallService` utilizam `TRickWinServiceInstaller` diretamente. `StartService`, `StopService` e `RestartService` usam `TRickWinServiceModel`, que delega o acesso ao SCM a `TRickWinServiceManager`.

## `IRickWinServiceSetup`

GUID atual:

```text
{02F69C40-E367-43FC-BEE5-E974750FD09B}
```

Métodos de configuração:

```delphi
function ServiceName(const Value: string): IRickWinServiceSetup;
function ServiceTitle(const Value: string): IRickWinServiceSetup;
function ServiceDetail(const Value: string): IRickWinServiceSetup;
```

Callbacks disponíveis:

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

Execução:

```delphi
function CreateForm(Component: TComponentClass;
  var Reference;
  ReportLeaks: Boolean = True): IRickWinServiceSetup;

function RunAsService: Boolean;
```

### `RunAsService`

O retorno indica se o processo foi consumido por um modo especial:

| Comando | Ação | Retorno |
|---|---|---:|
| nenhum | segue para Desktop | `False` |
| `Install` | executa `ExecuteInstallCommand` | `True` |
| `Uninstall` | executa `ExecuteUninstallCommand` | `True` |
| `RunService` | executa `RunWindowsService` | `True` após o retorno do runtime |

No caminho Desktop, `CreateForm` inicializa e executa `FMX.Forms.Application` quando `PROJECT_FMX` está definido; caso contrário usa `Vcl.Forms.Application`.

### Callbacks de runtime

Durante `RunWindowsService`, os callbacks configurados são associados aos eventos correspondentes do `TRickWinService` somente quando foram informados.

Para `OnStart`, `OnStop`, `OnPause` e `OnContinue`, os handlers ajustam os parâmetros `Started`, `Stopped`, `Paused` e `Continued` para `True` apenas quando o callback termina sem exceção.

`OnCreate`, `OnDestroy` e `OnShutdown` são encaminhados diretamente ao callback configurado.

O evento físico `OnExecute` não faz parte de `IRickWinServiceSetup`. Ele permanece ligado a `TRickWinService.ServiceExecute` no DFM.

### Callbacks de instalação

`OnBeforeInstall`, `OnAfterInstall`, `OnBeforeUninstall` e `OnAfterUninstall` são executados nos caminhos da fachada e nos comandos tratados pelo `Setup`.

A ordem observável é:

```text
Before -> operação principal -> After
```

O callback `After` só é alcançado quando a operação principal retorna sem exceção.

## `IRickWinService`

GUID atual:

```text
{CF698484-2DCE-439C-9D79-6EC2DCC07109}
```

Contrato:

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

`TRickWinServiceModel` é a implementação atual desse contrato.

### `Install`/`Uninstall` do contrato

Diferentemente da fachada procedural, os métodos de `IRickWinService` executam o executável configurado em `ExeName` como processo auxiliar:

```text
/Install /Silent
/UnInstall /Silent
```

Parâmetros adicionais do `TDictionary<string,string>` são anexados à linha de comando pelo adaptador. O processo pai aguarda o término, lê o `ExitCode` e transforma falhas conhecidas em exceções do Rick WinService.

Esse comportamento é observável na implementação atual. Esta documentação não afirma quando ou por que esse contrato foi introduzido historicamente.

## Tipos públicos

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

`NotInstalled` é retornado por `TRickWinServiceManager.GetServiceState` quando `OpenService` falha com `ERROR_SERVICE_DOES_NOT_EXIST`.

### `TInstallType`

```text
Install
Uninstall
```

Usado pelo adaptador de `TRickWinServiceModel.ExecProcess`.

### `TRickWinServiceOperation`

```text
Query
Install
Uninstall
Start
Stop
Restart
```

Usado para contextualizar exceções e operações do SCM.

### `TRickApplicationFramework`

```text
VCL
FMX
```

### `TOnRickWinServiceEvent`

```delphi
TOnRickWinServiceEvent = reference to procedure;
```

## Exceções

### Hierarquia

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

Expõe:

```text
Operation: string
```

É lançada quando `RequireAdministrator` identifica que o processo não está executando com privilégios administrativos efetivos.

### `ERickWinServiceOperationException`

Expõe:

```text
Operation: TRickWinServiceOperation
ServiceName: string
```

### `ERickWinServiceScmException`

Adiciona:

```text
Win32ErrorCode: DWORD
Context: string
```

O `Manager` captura `GetLastError` no ponto em que a chamada ao SCM falha e constrói essa exceção.

### `ERickWinServiceStateException`

Adiciona:

```text
ExpectedState: TRickWinServiceState
CurrentState: TRickWinServiceState
ServiceWin32ExitCode: DWORD
ServiceSpecificExitCode: DWORD
```

### `ERickWinServiceTimeoutException`

Adiciona:

```text
Timeout: Cardinal
```

O `Manager` a utiliza quando a transição excede o timeout configurado ou deixa de demonstrar progresso conforme `dwCheckPoint` e `dwWaitHint`.

## Exemplo de tratamento

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
      // Defina a política de apresentação no consumidor.
    end;

    on E: ERickWinServiceException do
    begin
      // Falha controlada pelo framework.
    end;

    on E: Exception do
    begin
      // Falha não classificada pelo contrato do framework.
    end;
  end;
end;
```

## Units de infraestrutura tecnicamente acessíveis

As units abaixo declaram classes públicas, embora o fluxo comum passe pela fachada `Rick.WinService`:

- `Rick.WinService.CommandLine` — `TRickWinServiceCommandLine` e códigos de saída;
- `Rick.WinService.Security` — `TRickWinServiceSecurity`;
- `Rick.WinService.Manager` — `TRickWinServiceManager` e `IsDesktopMode`;
- `Rick.WinService.Installer` — `TRickWinServiceInstaller`;
- `Rick.WinService.Model` — `TRickWinServiceModel`;
- `Rick.WinService.Setup` — `TRickWinServiceSetup` e callbacks auxiliares;
- `Rick.WinService.Service` — `TRickWinService` e metadados globais do serviço.

A arquitetura e as dependências dessas units estão em [ARCHITECTURE.md](ARCHITECTURE.md).
