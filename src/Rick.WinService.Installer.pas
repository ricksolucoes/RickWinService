unit Rick.WinService.Installer;
(*
  ==============================================================================
  Unit: Rick.WinService.Installer
  ==============================================================================

  RESPONSABILIDADE

  Implementa o núcleo único de instalação e desinstalação do Rick WinService.

  A unit registra e remove o serviço diretamente no Windows Service Control
  Manager, sem depender de TServiceApplication.RegisterServices. Dessa forma,
  tanto a API pública quanto a execução por /Install ou /UnInstall podem chegar
  à mesma implementação interna.

  ------------------------------------------------------------------------------

  CONFIGURAÇÃO REGISTRADA

  A configuração reproduz as propriedades padrão utilizadas pelo TService do
  framework atual:

  - SERVICE_WIN32_OWN_PROCESS;
  - SERVICE_AUTO_START;
  - SERVICE_ERROR_NORMAL;
  - conta LocalSystem quando nenhuma conta específica é informada;
  - ImagePath no formato "<executável>" -RunService.

  A descrição é aplicada através de ChangeServiceConfig2 quando ServiceDetail
  estiver preenchido.

  ------------------------------------------------------------------------------

  EVENT LOG

  A origem do Event Log utilizada pelo framework é criada após o registro do
  serviço. Na desinstalação, a mesma chave é removida quando existente.

  ------------------------------------------------------------------------------

  SEGURANÇA

  Install e Uninstall exigem privilégios administrativos através de
  TRickWinServiceSecurity.RequireAdministrator. A unit não eleva o processo e
  não apresenta mensagens ao usuário.

  ==============================================================================
*)

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Instalador direto de um serviço Windows gerenciado pelo Rick WinService.
  /// </summary>
  TRickWinServiceInstaller = class sealed
  private
    FServiceName: string;
    FServiceTitle: string;
    FServiceDetail: string;
    FExeName: string;

    function BinaryPath: string;
    procedure ValidateInstallConfiguration;
    procedure ConfigureEventLog;
    procedure RemoveEventLog;
  public
    /// <summary>
    /// Cria o instalador com os metadados necessários ao registro do serviço.
    /// </summary>
    constructor Create(const AServiceName, AServiceTitle, AServiceDetail,
      AExeName: string);

    /// <summary>
    /// Registra o serviço, aplica descrição e configura a origem do Event Log.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada quando o processo atual não possui elevação administrativa.
    /// </exception>
    /// <exception cref="ERickWinServiceScmException">
    /// Lançada quando o SCM recusa o registro ou a configuração do serviço.
    /// </exception>
    /// <exception cref="ERickWinServiceOperationException">
    /// Lançada para configuração inválida ou falha controlada no Event Log.
    /// </exception>
    procedure Install;

    /// <summary>
    /// Remove o serviço do SCM e limpa a origem do Event Log criada pelo
    /// framework.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada quando o processo atual não possui elevação administrativa.
    /// </exception>
    /// <exception cref="ERickWinServiceScmException">
    /// Lançada quando o SCM recusa a abertura ou remoção do serviço.
    /// </exception>
    /// <exception cref="ERickWinServiceOperationException">
    /// Lançada quando a limpeza do Event Log falha de forma controlada.
    /// </exception>
    procedure Uninstall;
  end;

implementation

uses
  System.Win.Registry,
  Winapi.Windows,
  Winapi.WinSvc,

  Rick.WinService.Exceptions,
  Rick.WinService.Manager,
  Rick.WinService.Security,
  Rick.WinService.Types;

const
  // Máscaras Win32 declaradas como constantes integrais simples para manter
  // compatibilidade com Delphi 10.2. Nessa versão da RTL, o direito padrão
  // DELETE não é exposto por Winapi.Windows. Os valores abaixo correspondem
  // aos direitos documentados pelo Windows para objetos de serviço.
  _SERVICE_CHANGE_CONFIG_ACCESS = $00000002;
  _SERVICE_QUERY_STATUS_ACCESS  = $00000004;
  _STANDARD_RIGHT_DELETE_ACCESS = $00010000;

  _INSTALL_SERVICE_ACCESS =
    _SERVICE_QUERY_STATUS_ACCESS or
    _SERVICE_CHANGE_CONFIG_ACCESS or
    _STANDARD_RIGHT_DELETE_ACCESS;

  _UNINSTALL_SERVICE_ACCESS =
    _STANDARD_RIGHT_DELETE_ACCESS or
    _SERVICE_QUERY_STATUS_ACCESS;

{ TRickWinServiceInstaller }

constructor TRickWinServiceInstaller.Create(const AServiceName,
  AServiceTitle, AServiceDetail, AExeName: string);
begin
  inherited Create;

  FServiceName := Trim(AServiceName);
  FServiceTitle := Trim(AServiceTitle);
  FServiceDetail := Trim(AServiceDetail);
  FExeName := Trim(AExeName);
end;

function TRickWinServiceInstaller.BinaryPath: string;
begin
  Result := '"' + FExeName + '" -RunService';
end;

procedure TRickWinServiceInstaller.ValidateInstallConfiguration;
begin
  if FServiceName = EmptyStr then
    raise ERickWinServiceOperationException.Create(
      TRickWinServiceOperation.Install,
      FServiceName,
      'O nome interno do serviço não foi informado.'
    );

  if FExeName = EmptyStr then
    raise ERickWinServiceOperationException.Create(
      TRickWinServiceOperation.Install,
      FServiceName,
      'O executável do serviço não foi informado.'
    );

  if not FileExists(FExeName) then
    raise ERickWinServiceOperationException.Create(
      TRickWinServiceOperation.Install,
      FServiceName,
      Format('O executável do serviço não foi encontrado: %s', [FExeName])
    );

  if FServiceTitle = EmptyStr then
    FServiceTitle := FServiceName;
end;

procedure TRickWinServiceInstaller.ConfigureEventLog;
var
  LRegistry: TRegistry;
  LKey: string;
begin
  LKey := '\SYSTEM\CurrentControlSet\Services\Eventlog\Application\' +
    FServiceName;

  try
    LRegistry := TRegistry.Create(KEY_READ or KEY_WRITE);
    try
      LRegistry.RootKey := HKEY_LOCAL_MACHINE;

      if not LRegistry.OpenKey(LKey, True) then
        Exit;

      try
        LRegistry.WriteString('EventMessageFile', FExeName);
        LRegistry.WriteInteger('TypesSupported', 7);

        if FServiceDetail <> EmptyStr then
          LRegistry.WriteString('Description', FServiceDetail);
      finally
        LRegistry.CloseKey;
      end;
    finally
      LRegistry.Free;
    end;
  except
    on E: ERickWinServiceException do
      raise;

    on E: Exception do
      raise ERickWinServiceOperationException.Create(
        TRickWinServiceOperation.Install,
        FServiceName,
        'Não foi possível configurar a origem do Event Log. ' + E.Message
      );
  end;
end;

procedure TRickWinServiceInstaller.RemoveEventLog;
var
  LRegistry: TRegistry;
  LKey: string;
begin
  LKey := '\SYSTEM\CurrentControlSet\Services\Eventlog\Application\' +
    FServiceName;

  try
    LRegistry := TRegistry.Create(KEY_READ or KEY_WRITE);
    try
      LRegistry.RootKey := HKEY_LOCAL_MACHINE;
      LRegistry.DeleteKey(LKey);
    finally
      LRegistry.Free;
    end;
  except
    on E: ERickWinServiceException do
      raise;

    on E: Exception do
      raise ERickWinServiceOperationException.Create(
        TRickWinServiceOperation.Uninstall,
        FServiceName,
        'Não foi possível remover a origem do Event Log. ' + E.Message
      );
  end;
end;

procedure TRickWinServiceInstaller.Install;
var
  LManager: TRickWinServiceManager;
  LServiceCreated: Boolean;
begin
  TRickWinServiceSecurity.RequireAdministrator('instalar o serviço');
  ValidateInstallConfiguration;

  LManager := TRickWinServiceManager.Create;
  try
    LManager.ConnectOrRaise(
      '',
      '',
      SC_MANAGER_CREATE_SERVICE,
      TRickWinServiceOperation.Install,
      FServiceName
    );

    LServiceCreated := False;
    try
      LManager.CreateServiceRegistration(
        FServiceName,
        FServiceTitle,
        BinaryPath,
        _INSTALL_SERVICE_ACCESS,
        SERVICE_WIN32_OWN_PROCESS,
        SERVICE_AUTO_START,
        SERVICE_ERROR_NORMAL
      );

      LServiceCreated := True;

      if FServiceDetail <> EmptyStr then
        LManager.SetServiceDescription(
          FServiceDetail,
          TRickWinServiceOperation.Install
        );

      ConfigureEventLog;
    except
      if LServiceCreated then
      begin
        try
          LManager.DeleteServiceRegistration(
            TRickWinServiceOperation.Install
          );
        except
          // A exceção original da instalação deve permanecer prioritária.
        end;

        try
          RemoveEventLog;
        except
          // A limpeza de rollback não pode substituir a exceção original.
        end;
      end;

      raise;
    end;
  finally
    LManager.Free;
  end;
end;

procedure TRickWinServiceInstaller.Uninstall;
var
  LManager: TRickWinServiceManager;
begin
  TRickWinServiceSecurity.RequireAdministrator('desinstalar o serviço');

  if FServiceName = EmptyStr then
    raise ERickWinServiceOperationException.Create(
      TRickWinServiceOperation.Uninstall,
      FServiceName,
      'O nome interno do serviço não foi informado.'
    );

  LManager := TRickWinServiceManager.Create;
  try
    LManager.ConnectOrRaise(
      '',
      '',
      SC_MANAGER_CONNECT,
      TRickWinServiceOperation.Uninstall,
      FServiceName
    );

    LManager.OpenServiceConnectionOrRaise(
      FServiceName,
      _UNINSTALL_SERVICE_ACCESS,
      TRickWinServiceOperation.Uninstall
    );

    LManager.DeleteServiceRegistration(
      TRickWinServiceOperation.Uninstall
    );

    RemoveEventLog;
  finally
    LManager.Free;
  end;
end;

end.
