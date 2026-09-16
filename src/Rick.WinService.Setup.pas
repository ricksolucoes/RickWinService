unit Rick.WinService.Setup;
(*
  ==============================================================================
  Unit: Rick.WinService.Setup
  ==============================================================================

  RESPONSABILIDADE

  Implementa IRickWinServiceSetup, configura os callbacks do ciclo de vida e
  decide qual modo do mesmo executável deve ser executado.

  A interpretação dos switches reside em Rick.WinService.CommandLine. A
  instalação e a desinstalação residem em Rick.WinService.Installer. Esta unit
  apenas coordena essas operações quando o próprio executável é iniciado por
  linha de comando.

  ------------------------------------------------------------------------------

  MODOS DE EXECUÇÃO

  Desktop
    RunAsService retorna False e o DPR pode criar a interface VCL/FMX.

  Install / Uninstall
    RunAsService executa o Installer diretamente, respeita os callbacks públicos
    Before/After já existentes, converte qualquer Exception em System.ExitCode e
    retorna True. Essa fronteira é responsável por impedir que /Install /Silent
    ou /UnInstall /Silent exibam a caixa nativa "Application Error".

  RunService
    Cria TRickWinService, associa os callbacks de runtime e executa
    Vcl.SvcMgr.Application.Run.

  ------------------------------------------------------------------------------

  COMPATIBILIDADE

  IRickWinServiceSetup, seus GUIDs, métodos e callbacks públicos são preservados.
  Os callbacks Before/After Install/Uninstall continuam sendo disparados na
  mesma ordem lógica, porém a operação real não depende mais do mecanismo de
  instalação interno do TServiceApplication.

  ==============================================================================
*)

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.SvcMgr,

{$IFDEF PROJECT_FMX}
  FMX.Forms,
{$ELSE}
  Vcl.Forms,
{$ENDIF}

  Rick.WinService.Interfaces,
  Rick.WinService.Types;

type
  /// <summary>
  /// Implementação padrão de IRickWinServiceSetup.
  /// </summary>
  TRickWinServiceSetup = class(TInterfacedObject, IRickWinServiceSetup)
  private
    FOnStart: TOnRickWinServiceEvent;
    FOnStop: TOnRickWinServiceEvent;
    FOnPause: TOnRickWinServiceEvent;
    FOnShutdown: TOnRickWinServiceEvent;
    FOnCreate: TOnRickWinServiceEvent;
    FOnDestroy: TOnRickWinServiceEvent;
    FOnContinue: TOnRickWinServiceEvent;
    FOnBeforeInstall: TOnRickWinServiceEvent;
    FOnBeforeUninstall: TOnRickWinServiceEvent;
    FOnAfterInstall: TOnRickWinServiceEvent;
    FOnAfterUninstall: TOnRickWinServiceEvent;

    procedure OnServiceStart(Service: TService; var Started: Boolean);
    procedure OnServiceStop(Service: TService; var Stopped: Boolean);
    procedure OnServicePause(Sender: TService; var Paused: Boolean);
    procedure OnServiceCreate(Sender: TObject);
    procedure OnServiceDestroy(Sender: TObject);
    procedure OnServiceShutdown(Sender: TService);
    procedure OnServiceContinue(Sender: TService; var Continued: Boolean);

    procedure ExecuteInstallCommand;
    procedure ExecuteUninstallCommand;
    procedure RunWindowsService;
  protected
    function ServiceName(const Value: string): IRickWinServiceSetup;
    function ServiceTitle(const Value: string): IRickWinServiceSetup;
    function ServiceDetail(const Value: string): IRickWinServiceSetup;

    function OnStart(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnStop(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnPause(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnContinue(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnCreate(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnDestroy(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnShutdown(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnBeforeUninstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnBeforeInstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnAfterInstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnAfterUninstall(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;

    function CreateForm(Component: TComponentClass;
      var Reference;
      ReportLeaks: Boolean = True): IRickWinServiceSetup;

    function RunAsService: Boolean;
  public
    class function New: IRickWinServiceSetup;
  end;

/// <summary>
/// Executa o callback público BeforeInstall atualmente configurado, quando
/// existente. É utilizado internamente pela fachada procedural.
/// </summary>
procedure ExecuteBeforeInstallCallback;

/// <summary>
/// Executa o callback público AfterInstall atualmente configurado.
/// </summary>
procedure ExecuteAfterInstallCallback;

/// <summary>
/// Executa o callback público BeforeUninstall atualmente configurado.
/// </summary>
procedure ExecuteBeforeUninstallCallback;

/// <summary>
/// Executa o callback público AfterUninstall atualmente configurado.
/// </summary>
procedure ExecuteAfterUninstallCallback;

implementation

uses
  Rick.WinService.CommandLine,
  Rick.WinService.Installer,
  Rick.WinService.Security,
  Rick.WinService.Service;

var
  GOnBeforeInstall: TOnRickWinServiceEvent;
  GOnBeforeUninstall: TOnRickWinServiceEvent;
  GOnAfterInstall: TOnRickWinServiceEvent;
  GOnAfterUninstall: TOnRickWinServiceEvent;

procedure ExecuteBeforeInstallCallback;
begin
  if Assigned(GOnBeforeInstall) then
    GOnBeforeInstall;
end;

procedure ExecuteAfterInstallCallback;
begin
  if Assigned(GOnAfterInstall) then
    GOnAfterInstall;
end;

procedure ExecuteBeforeUninstallCallback;
begin
  if Assigned(GOnBeforeUninstall) then
    GOnBeforeUninstall;
end;

procedure ExecuteAfterUninstallCallback;
begin
  if Assigned(GOnAfterUninstall) then
    GOnAfterUninstall;
end;

{ TRickWinServiceSetup }

class function TRickWinServiceSetup.New: IRickWinServiceSetup;
begin
  Result := Self.Create;
end;

function TRickWinServiceSetup.CreateForm(
  Component: TComponentClass;
  var Reference;
  ReportLeaks: Boolean): IRickWinServiceSetup;
begin
  Result := Self;

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := ReportLeaks;
{$ENDIF}

{$IFDEF PROJECT_FMX}
  FMX.Forms.Application.Initialize;
  FMX.Forms.Application.Title := Rick.WinService.Service.ServiceTitle;
  FMX.Forms.Application.CreateForm(Component, Reference);
  FMX.Forms.Application.Run;
{$ELSE}
  Vcl.Forms.Application.Initialize;
  Vcl.Forms.Application.Title := Rick.WinService.Service.ServiceTitle;
  Vcl.Forms.Application.CreateForm(Component, Reference);
  Vcl.Forms.Application.Run;
{$ENDIF}
end;

function TRickWinServiceSetup.ServiceName(
  const Value: string): IRickWinServiceSetup;
begin
  Result := Self;
  Rick.WinService.Service.ServiceName := Value;
end;

function TRickWinServiceSetup.ServiceTitle(
  const Value: string): IRickWinServiceSetup;
begin
  Result := Self;
  Rick.WinService.Service.ServiceTitle := Value;
end;

function TRickWinServiceSetup.ServiceDetail(
  const Value: string): IRickWinServiceSetup;
begin
  Result := Self;
  Rick.WinService.Service.ServiceDetail := Value;
end;

function TRickWinServiceSetup.OnStart(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnStart := Value;
end;

function TRickWinServiceSetup.OnStop(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnStop := Value;
end;

function TRickWinServiceSetup.OnPause(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnPause := Value;
end;

function TRickWinServiceSetup.OnContinue(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnContinue := Value;
end;

function TRickWinServiceSetup.OnCreate(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnCreate := Value;
end;

function TRickWinServiceSetup.OnDestroy(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnDestroy := Value;
end;

function TRickWinServiceSetup.OnShutdown(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnShutdown := Value;
end;

function TRickWinServiceSetup.OnBeforeInstall(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnBeforeInstall := Value;
  GOnBeforeInstall := Value;
end;

function TRickWinServiceSetup.OnBeforeUninstall(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnBeforeUninstall := Value;
  GOnBeforeUninstall := Value;
end;

function TRickWinServiceSetup.OnAfterInstall(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnAfterInstall := Value;
  GOnAfterInstall := Value;
end;

function TRickWinServiceSetup.OnAfterUninstall(
  Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
begin
  Result := Self;
  FOnAfterUninstall := Value;
  GOnAfterUninstall := Value;
end;

procedure TRickWinServiceSetup.OnServiceStart(
  Service: TService;
  var Started: Boolean);
begin
  Started := False;

  try
    if Assigned(FOnStart) then
      FOnStart;

    Started := True;
  except
    Started := False;
    raise;
  end;
end;

procedure TRickWinServiceSetup.OnServiceStop(
  Service: TService;
  var Stopped: Boolean);
begin
  Stopped := False;

  try
    if Assigned(FOnStop) then
      FOnStop;

    Stopped := True;
  except
    Stopped := False;
    raise;
  end;
end;

procedure TRickWinServiceSetup.OnServicePause(
  Sender: TService;
  var Paused: Boolean);
begin
  Paused := False;

  try
    if Assigned(FOnPause) then
      FOnPause;

    Paused := True;
  except
    Paused := False;
    raise;
  end;
end;

procedure TRickWinServiceSetup.OnServiceContinue(
  Sender: TService;
  var Continued: Boolean);
begin
  Continued := False;

  try
    if Assigned(FOnContinue) then
      FOnContinue;

    Continued := True;
  except
    Continued := False;
    raise;
  end;
end;

procedure TRickWinServiceSetup.OnServiceCreate(Sender: TObject);
begin
  if Assigned(FOnCreate) then
    FOnCreate;
end;

procedure TRickWinServiceSetup.OnServiceDestroy(Sender: TObject);
begin
  if Assigned(FOnDestroy) then
    FOnDestroy;
end;

procedure TRickWinServiceSetup.OnServiceShutdown(Sender: TService);
begin
  if Assigned(FOnShutdown) then
    FOnShutdown;
end;

procedure TRickWinServiceSetup.ExecuteInstallCommand;
var
  LInstaller: TRickWinServiceInstaller;
begin
  System.ExitCode := RICK_WINSERVICE_EXIT_SUCCESS;

  try
    TRickWinServiceSecurity.RequireAdministrator('instalar o serviço');

    if Assigned(FOnBeforeInstall) then
      FOnBeforeInstall;

    LInstaller := TRickWinServiceInstaller.Create(
      Rick.WinService.Service.ServiceName,
      Rick.WinService.Service.ServiceTitle,
      Rick.WinService.Service.ServiceDetail,
      GetModuleName(HInstance)
    );
    try
      LInstaller.Install;
    finally
      LInstaller.Free;
    end;

    if Assigned(FOnAfterInstall) then
      FOnAfterInstall;
  except
    on E: Exception do
      System.ExitCode := TRickWinServiceCommandLine.ExitCodeForException(E);
  end;
end;

procedure TRickWinServiceSetup.ExecuteUninstallCommand;
var
  LInstaller: TRickWinServiceInstaller;
begin
  System.ExitCode := RICK_WINSERVICE_EXIT_SUCCESS;

  try
    TRickWinServiceSecurity.RequireAdministrator('desinstalar o serviço');

    if Assigned(FOnBeforeUninstall) then
      FOnBeforeUninstall;

    LInstaller := TRickWinServiceInstaller.Create(
      Rick.WinService.Service.ServiceName,
      Rick.WinService.Service.ServiceTitle,
      Rick.WinService.Service.ServiceDetail,
      GetModuleName(HInstance)
    );
    try
      LInstaller.Uninstall;
    finally
      LInstaller.Free;
    end;

    if Assigned(FOnAfterUninstall) then
      FOnAfterUninstall;
  except
    on E: Exception do
      System.ExitCode := TRickWinServiceCommandLine.ExitCodeForException(E);
  end;
end;

procedure TRickWinServiceSetup.RunWindowsService;
begin
  if not Vcl.SvcMgr.Application.DelayInitialize then
    Vcl.SvcMgr.Application.Initialize;

  Vcl.SvcMgr.Application.Title := Rick.WinService.Service.ServiceTitle;

  Vcl.SvcMgr.Application.CreateForm(
    TRickWinService,
    RickWinServiceApp
  );

  if Assigned(FOnStart) then
    RickWinServiceApp.OnStart := OnServiceStart;

  if Assigned(FOnStop) then
    RickWinServiceApp.OnStop := OnServiceStop;

  if Assigned(FOnPause) then
    RickWinServiceApp.OnPause := OnServicePause;

  if Assigned(FOnShutdown) then
    RickWinServiceApp.OnShutdown := OnServiceShutdown;

  if Assigned(FOnCreate) then
    RickWinServiceApp.OnCreate := OnServiceCreate;

  if Assigned(FOnDestroy) then
    RickWinServiceApp.OnDestroy := OnServiceDestroy;

  if Assigned(FOnContinue) then
    RickWinServiceApp.OnContinue := OnServiceContinue;

  Vcl.SvcMgr.Application.Run;
end;

function TRickWinServiceSetup.RunAsService: Boolean;
var
  LCommand: TRickWinServiceCommand;
begin
  Result := False;
  LCommand := TRickWinServiceCommandLine.Command;

  case LCommand of
    TRickWinServiceCommand.Desktop:
      Exit;

    TRickWinServiceCommand.Install:
    begin
      ExecuteInstallCommand;
      Result := True;
      Exit;
    end;

    TRickWinServiceCommand.Uninstall:
    begin
      ExecuteUninstallCommand;
      Result := True;
      Exit;
    end;

    TRickWinServiceCommand.RunService:
    begin
      RunWindowsService;
      Result := True;
    end;
  end;
end;

initialization

finalization
  GOnBeforeInstall := nil;
  GOnBeforeUninstall := nil;
  GOnAfterInstall := nil;
  GOnAfterUninstall := nil;

end.
