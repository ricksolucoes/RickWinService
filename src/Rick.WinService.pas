unit Rick.WinService;
(*
  ==============================================================================
  Unit: Rick.WinService
  ==============================================================================

  RESPONSABILIDADE

  Fornece o ponto público de configuração e inicialização do Rick WinService.

  Esta unit reúne a API procedural pública consumida pela aplicação
  Desktop/Service (WinServiceSetup, InstallService, StartService, IsInstalled,
  IsRunningAsAdministrator, etc.). Antes desta reorganização, essa API
  procedural e o contrato IRickWinServiceSetup estavam juntos em
  Rick.WinService.Setup.Interfaces; o contrato agora reside em
  Rick.WinService.Interfaces e a implementação concreta consumida por
  WinServiceSetup reside em Rick.WinService.Setup.

  Esta unit permite que o mesmo executável seja roteado para:

  1. Desktop
     - VCL por padrão;
     - FMX quando PROJECT_FMX estiver definido.

  2. Comandos administrativos
     - /Install e /UnInstall, tratados pelo CommandLine/Installer.

  3. Windows Service
     - -RunService, executado pelo TService físico.

  ------------------------------------------------------------------------------

  CONFIGURAÇÃO DO SERVIÇO

  WinServiceSetup permite configurar:

  - ServiceName;
  - ServiceTitle;
  - ServiceDetail;
  - callbacks de Start, Stop, Pause, Continue, Create, Destroy e Shutdown;
  - callbacks de Before/After Install/Uninstall.

  A instalação e a desinstalação são encaminhadas ao Installer interno e não
  dependem de TServiceApplication.RegisterServices.

  O callback customizado OnExecute foi removido.

  O TService continua utilizando seu evento físico OnExecute, configurado no
  DFM, exclusivamente para executar ServiceExecute e processar as mensagens do
  Service Control Manager.

  A inicialização da aplicação deve ser executada em OnStart e sua parada em
  OnStop/OnShutdown.

  ------------------------------------------------------------------------------

  API DE ADMINISTRAÇÃO

  A aplicação Desktop pode administrar o serviço sem conhecer Winapi.WinSvc.

  Funções públicas:

  - IsInstalled;
  - ServiceState;
  - IsRunning;
  - IsRunningAsAdministrator;
  - InstallService;
  - UninstallService;
  - StartService;
  - StopService;
  - RestartService.

  Dessa forma, uma View FMX não precisa manipular SC_HANDLE, OpenSCManager,
  OpenService ou constantes SERVICE_*.

  ------------------------------------------------------------------------------

  SEGURANÇA E ELEVAÇÃO

  IsRunningAsAdministrator permite que a aplicação consumidora adapte sua
  interface antes de disponibilizar comandos administrativos.

  Além dessa consulta preventiva, as operações públicas mutáveis aplicam uma
  segunda barreira antes de Install, Uninstall, Start, Stop e Restart. Caso o
  processo não esteja elevado, o framework lança
  ERickWinServiceAdministratorRequired.

  O Rick WinService não apresenta mensagens, não depende de VCL/FMX para o
  tratamento do erro e não tenta elevar o processo automaticamente.

  Exemplo de fluxo recomendado:

    1. consultar IsRunningAsAdministrator para configurar a interface;
    2. executar a operação desejada somente quando apropriado;
    3. capturar ERickWinServiceAdministratorRequired como proteção defensiva.

  ------------------------------------------------------------------------------

  COMPATIBILIDADE FMX

  Para projetos FireMonkey definir:

  PROJECT_FMX

  nas Conditional Defines do projeto.

  CreateForm selecionará FMX.Forms.Application quando a diretiva estiver ativa.

  ==============================================================================
*)

interface

uses
  Rick.WinService.Interfaces,
  Rick.WinService.Types;

/// <summary>
/// Retorna a configuração compartilhada utilizada durante a inicialização.
/// </summary>
function WinServiceSetup: IRickWinServiceSetup;

function ApplicationFramework: TRickApplicationFramework;
function ApplicationFrameworkName: string;
function IsVCLApplication: Boolean;
function IsFMXApplication: Boolean;

/// <summary>
/// Retorna True quando o serviço configurado está registrado no SCM.
/// </summary>
function IsInstalled: Boolean;

/// <summary>
/// Retorna o estado completo do serviço configurado.
/// </summary>
function ServiceState: TRickWinServiceState;

/// <summary>
/// Retorna True somente quando o serviço configurado está Running.
/// </summary>
function IsRunning: Boolean;

/// <summary>
/// Informa se o processo atual está executando com privilégios administrativos
/// efetivos.
/// </summary>
/// <returns>
/// True quando o token efetivo do processo possui o grupo Administradores
/// habilitado; caso contrário, False.
/// </returns>
/// <remarks>
/// Esta função é apropriada para que aplicações VCL/FMX habilitem ou
/// desabilitem previamente comandos de administração do serviço.
///
/// A verificação não substitui a proteção interna das operações mutáveis.
/// InstallService, UninstallService, StartService, StopService e RestartService
/// também validam a elevação através da implementação padrão do framework.
/// </remarks>
function IsRunningAsAdministrator: Boolean;

/// <summary>
/// Inicia o serviço configurado e aguarda a confirmação do SCM.
/// </summary>
/// <exception cref="ERickWinServiceAdministratorRequired">
/// Lançada quando o processo atual não está executando como administrador.
/// </exception>
procedure StartService;

/// <summary>
/// Para o serviço configurado e aguarda a confirmação do SCM.
/// </summary>
/// <exception cref="ERickWinServiceAdministratorRequired">
/// Lançada quando o processo atual não está executando como administrador.
/// </exception>
procedure StopService;

/// <summary>
/// Reinicia o serviço configurado.
/// </summary>
/// <exception cref="ERickWinServiceAdministratorRequired">
/// Lançada quando o processo atual não está executando como administrador.
/// </exception>
procedure RestartService;

/// <summary>
/// Instala o serviço configurado diretamente no SCM através do Installer.
/// </summary>
/// <exception cref="ERickWinServiceAdministratorRequired">
/// Lançada quando o processo atual não está executando como administrador.
/// </exception>
procedure InstallService;

/// <summary>
/// Remove o serviço configurado diretamente do SCM através do Installer.
/// </summary>
/// <exception cref="ERickWinServiceAdministratorRequired">
/// Lançada quando o processo atual não está executando como administrador.
/// </exception>
procedure UninstallService;

var
  RickSetup: IRickWinServiceSetup;

implementation

uses
  System.SysUtils,

  Rick.WinService.Installer,
  Rick.WinService.Model,
  Rick.WinService.Security,
  Rick.WinService.Service,
  Rick.WinService.Setup;

function CurrentService: IRickWinService;
begin
  Result := TRickWinServiceModel
    .New
    .ServiceName(Rick.WinService.Service.ServiceName);
end;

function CurrentInstaller: TRickWinServiceInstaller;
begin
  Result := TRickWinServiceInstaller.Create(
    Rick.WinService.Service.ServiceName,
    Rick.WinService.Service.ServiceTitle,
    Rick.WinService.Service.ServiceDetail,
    GetModuleName(HInstance)
  );
end;

function ApplicationFramework: TRickApplicationFramework;
begin
{$IFDEF PROJECT_FMX}
  Result := TRickApplicationFramework.FMX;
{$ELSE}
  Result := TRickApplicationFramework.VCL;
{$ENDIF}
end;

function ApplicationFrameworkName: string;
begin
  case ApplicationFramework of
    TRickApplicationFramework.FMX:
      Result := 'FMX';
  else
    Result := 'VCL';
  end;
end;

function IsVCLApplication: Boolean;
begin
  Result := ApplicationFramework = TRickApplicationFramework.VCL;
end;

function IsFMXApplication: Boolean;
begin
  Result := ApplicationFramework = TRickApplicationFramework.FMX;
end;

function IsInstalled: Boolean;
begin
  Result := CurrentService.IsInstalled;
end;

function ServiceState: TRickWinServiceState;
begin
  Result := CurrentService.State;
end;

function IsRunning: Boolean;
begin
  Result := CurrentService.IsRunning;
end;

function IsRunningAsAdministrator: Boolean;
begin
  Result := TRickWinServiceSecurity.IsRunningAsAdministrator;
end;

procedure StartService;
begin
  CurrentService.Start;
end;

procedure StopService;
begin
  CurrentService.Stop;
end;

procedure RestartService;
begin
  CurrentService.Restart;
end;

procedure InstallService;
var
  LInstaller: TRickWinServiceInstaller;
begin
  TRickWinServiceSecurity.RequireAdministrator('instalar o serviço');
  ExecuteBeforeInstallCallback;

  LInstaller := CurrentInstaller;
  try
    LInstaller.Install;
  finally
    LInstaller.Free;
  end;

  ExecuteAfterInstallCallback;
end;

procedure UninstallService;
var
  LInstaller: TRickWinServiceInstaller;
begin
  TRickWinServiceSecurity.RequireAdministrator('desinstalar o serviço');
  ExecuteBeforeUninstallCallback;

  LInstaller := CurrentInstaller;
  try
    LInstaller.Uninstall;
  finally
    LInstaller.Free;
  end;

  ExecuteAfterUninstallCallback;
end;

function WinServiceSetup: IRickWinServiceSetup;
begin
  if not Assigned(RickSetup) then
    RickSetup := TRickWinServiceSetup.New;

  Result := RickSetup;
end;

end.
