unit Rick.WinService.Manager;
(*
  ==============================================================================
  Unit: Rick.WinService.Manager
  ==============================================================================

  RESPONSABILIDADE

  Encapsula o acesso ao Windows Service Control Manager (SCM) e as operações de
  consulta e controle de um serviço Windows.

  Esta implementação é responsável por:

  - abrir e fechar corretamente os handles do SCM e do serviço;
  - abrir o serviço somente com os direitos necessários para cada operação;
  - iniciar e parar o serviço;
  - consultar o estado real através de QueryServiceStatusEx;
  - aguardar transições de estado sem utilizar tempos fixos arbitrários;
  - distinguir serviço não instalado de falhas reais de acesso;
  - preservar códigos Win32 no ponto exato das falhas do SCM;
  - fornecer operações de registro necessárias ao Installer.

  ------------------------------------------------------------------------------

  CICLO DE VIDA DOS HANDLES

  Cada instância de TRickWinServiceManager possui, no máximo:

  - um handle para o Service Control Manager;
  - um handle para um serviço específico.

  Os handles são encerrados pelo Destroy através de CloseServiceHandle.

  Não existe Singleton nesta implementação. Dessa forma, uma operação não
  reutiliza handles potencialmente inválidos depois de instalar, desinstalar ou
  recriar um serviço.

  ------------------------------------------------------------------------------

  ESTADO DO SERVIÇO

  O estado é consultado através de QueryServiceStatusEx usando:

  SC_STATUS_PROCESS_INFO
  SERVICE_STATUS_PROCESS

  O valor nativo do Windows é convertido para TRickWinServiceState, declarado
  em Rick.WinService.Types.

  ------------------------------------------------------------------------------

  ESPERA DE START / STOP

  Os caminhos tipados StartServiceOrRaise e StopServiceOrRaise não utilizam
  Sleep com tempo fixo.

  Após solicitar uma transição, WaitForStateOrRaise acompanha o estado informado
  pelo SCM, respeitando:

  - dwCurrentState;
  - dwCheckPoint;
  - dwWaitHint;
  - timeout máximo da operação.

  Além do timeout, o método reconhece transições que terminam em estado
  incompatível e preserva dwWin32ExitCode e dwServiceSpecificExitCode em
  ERickWinServiceStateException. Assim, falha terminal e timeout verdadeiro são
  condições distintas.

  WaitForState permanece disponível somente para compatibilidade interna/legada;
  os caminhos utilizados pela fachada pública trabalham com WaitForStateOrRaise.

  ------------------------------------------------------------------------------

  COMPATIBILIDADE DE MODO DESKTOP

  IsDesktopMode permanece nesta unit por compatibilidade, porém a interpretação
  da linha de comando foi movida para Rick.WinService.CommandLine. O Manager não
  decide mais quais switches representam instalação ou execução como serviço.

  ==============================================================================
*)

interface

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.WinSvc,

  Rick.WinService.CommandLine,
  Rick.WinService.Exceptions,
  Rick.WinService.Types;

type
  /// <summary>
  /// Gerencia uma conexão pontual com o SCM e com um serviço Windows.
  /// </summary>
  TRickWinServiceManager = class
  private
    const
      DEFAULT_SERVICE_TIMEOUT = 30000;
  private
    FServiceControlManager: SC_HANDLE;
    FServiceHandle: SC_HANDLE;
    FServiceName: string;

    procedure CloseServiceConnection;
    procedure Disconnect;

    function QueryStatus(out AStatus: SERVICE_STATUS_PROCESS): Boolean;
    procedure QueryStatusOrRaise(out AStatus: SERVICE_STATUS_PROCESS;
      const AOperation: TRickWinServiceOperation);
    procedure RaiseScmError(const AOperation: TRickWinServiceOperation;
      const AContext: string; const AErrorCode: DWORD);

    class function ConvertState(const AState: DWORD): TRickWinServiceState; static;

    function DoStartService(const ANumberOfArguments: DWORD;
      AServiceArgVectors: PChar): Boolean;
  public
    /// <summary>
    /// Inicializa uma instância sem handles abertos.
    /// </summary>
    constructor Create;

    /// <summary>
    /// Fecha o handle do serviço e o handle do SCM, quando existentes.
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Abre uma conexão com o Service Control Manager.
    /// </summary>
    function Connect(const AMachineName: string = '';
      const ADatabaseName: string = '';
      const AAccess: DWORD = SC_MANAGER_CONNECT): Boolean;

    /// <summary>
    /// Abre o SCM e lança exceção tipada quando a operação falhar.
    /// </summary>
    procedure ConnectOrRaise(const AMachineName, ADatabaseName: string;
      const AAccess: DWORD; const AOperation: TRickWinServiceOperation;
      const AServiceName: string);

    /// <summary>
    /// Abre um serviço com os direitos de acesso informados.
    /// </summary>
    function OpenServiceConnection(const AServiceName: string;
      const AAccess: DWORD): Boolean;

    /// <summary>
    /// Abre um serviço e lança exceção tipada preservando o erro do SCM.
    /// </summary>
    procedure OpenServiceConnectionOrRaise(const AServiceName: string;
      const AAccess: DWORD; const AOperation: TRickWinServiceOperation);

    /// <summary>
    /// Registra um novo serviço utilizando CreateService.
    /// </summary>
    procedure CreateServiceRegistration(const AServiceName, ADisplayName,
      ABinaryPath: string; const ADesiredAccess, AServiceType, AStartType,
      AErrorControl: DWORD);

    /// <summary>
    /// Remove do SCM o serviço atualmente aberto.
    /// </summary>
    procedure DeleteServiceRegistration(
      const AOperation: TRickWinServiceOperation);

    /// <summary>
    /// Atualiza a descrição do serviço atualmente aberto.
    /// </summary>
    procedure SetServiceDescription(const ADescription: string;
      const AOperation: TRickWinServiceOperation);

    /// <summary>
    /// Inicia o serviço e aguarda o estado Running.
    /// </summary>
    function StartService: Boolean; overload;

    /// <summary>
    /// Inicia o serviço preservando a sobrecarga existente para argumentos.
    /// </summary>
    function StartService(const ANumberOfArguments: DWORD;
      AServiceArgVectors: PChar): Boolean; overload;

    /// <summary>
    /// Solicita a parada e aguarda o estado Stopped.
    /// </summary>
    function StopService: Boolean;

    /// <summary>
    /// Inicia o serviço usando exceções tipadas para qualquer falha.
    /// </summary>
    procedure StartServiceOrRaise;

    /// <summary>
    /// Para o serviço usando exceções tipadas para qualquer falha.
    /// </summary>
    procedure StopServiceOrRaise;

    /// <summary>
    /// Solicita pausa do serviço.
    /// </summary>
    procedure PauseService;

    /// <summary>
    /// Solicita continuação de um serviço pausado.
    /// </summary>
    procedure ContinueService;

    /// <summary>
    /// Envia o controle de shutdown ao serviço.
    /// </summary>
    procedure ShutdownService;

    /// <summary>
    /// Retorna o estado atual do serviço associado à instância.
    /// </summary>
    function State: TRickWinServiceState;

    /// <summary>
    /// Retorna True somente quando o serviço está em SERVICE_RUNNING.
    /// </summary>
    function ServiceRunning: Boolean;

    /// <summary>
    /// Retorna True somente quando o serviço está em SERVICE_STOPPED.
    /// </summary>
    function ServiceStopped: Boolean;

    /// <summary>
    /// Aguarda até que o serviço alcance o estado esperado.
    /// </summary>
    function WaitForState(const AExpectedState: TRickWinServiceState;
      const ATimeout: Cardinal = DEFAULT_SERVICE_TIMEOUT): Boolean;

    /// <summary>
    /// Aguarda uma transição identificando falha terminal e timeout de forma
    /// distinta e preservando SERVICE_STATUS_PROCESS.
    /// </summary>
    procedure WaitForStateOrRaise(const AOperation: TRickWinServiceOperation;
      const AExpectedState: TRickWinServiceState;
      const ATimeout: Cardinal = DEFAULT_SERVICE_TIMEOUT);

    /// <summary>
    /// Informa se o serviço está registrado no SCM.
    /// </summary>
    class function IsServiceInstalled(const AServiceName: string): Boolean; static;

    /// <summary>
    /// Informa se o serviço está efetivamente em execução.
    /// </summary>
    class function IsServiceRunning(const AServiceName: string): Boolean; static;

    /// <summary>
    /// Consulta o estado atual de um serviço pelo nome.
    /// </summary>
    class function GetServiceState(const AServiceName: string): TRickWinServiceState; static;

    /// <summary>
    /// Determina se o executável deve seguir para o modo Desktop.
    /// </summary>
    class function IsDesktopMode: Boolean; static;
  end;

/// <summary>
/// Determina se o processo deve seguir para o modo Desktop.
/// </summary>
/// <remarks>
/// O parâmetro ServiceName é preservado por compatibilidade com o contrato
/// público anterior. A decisão atual é baseada exclusivamente nos switches de
/// inicialização administrados pelo framework.
/// </remarks>
function IsDesktopMode(const ServiceName: string): Boolean;

implementation

{ TRickWinServiceManager }

constructor TRickWinServiceManager.Create;
begin
  inherited Create;

  FServiceControlManager := 0;
  FServiceHandle := 0;
  FServiceName := EmptyStr;
end;

destructor TRickWinServiceManager.Destroy;
begin
  CloseServiceConnection;
  Disconnect;

  inherited;
end;

procedure TRickWinServiceManager.CloseServiceConnection;
begin
  if FServiceHandle <> 0 then
  begin
    CloseServiceHandle(FServiceHandle);
    FServiceHandle := 0;
  end;
end;

procedure TRickWinServiceManager.Disconnect;
begin
  if FServiceControlManager <> 0 then
  begin
    CloseServiceHandle(FServiceControlManager);
    FServiceControlManager := 0;
  end;
end;

function TRickWinServiceManager.Connect(const AMachineName,
  ADatabaseName: string; const AAccess: DWORD): Boolean;
var
  LMachineName: PChar;
  LDatabaseName: PChar;
begin
  Disconnect;

  LMachineName := nil;
  LDatabaseName := nil;

  if not AMachineName.IsEmpty then
    LMachineName := PChar(AMachineName);

  if not ADatabaseName.IsEmpty then
    LDatabaseName := PChar(ADatabaseName);

  FServiceControlManager := OpenSCManager(
    LMachineName,
    LDatabaseName,
    AAccess
  );

  Result := FServiceControlManager <> 0;
end;

function TRickWinServiceManager.OpenServiceConnection(
  const AServiceName: string; const AAccess: DWORD): Boolean;
begin
  CloseServiceConnection;
  FServiceName := AServiceName;

  if FServiceControlManager = 0 then
  begin
    SetLastError(ERROR_INVALID_HANDLE);
    Exit(False);
  end;

  FServiceHandle := OpenService(
    FServiceControlManager,
    PChar(AServiceName),
    AAccess
  );

  Result := FServiceHandle <> 0;
end;

procedure TRickWinServiceManager.RaiseScmError(
  const AOperation: TRickWinServiceOperation; const AContext: string;
  const AErrorCode: DWORD);
begin
  raise ERickWinServiceScmException.Create(
    AOperation,
    FServiceName,
    AContext,
    AErrorCode
  );
end;

procedure TRickWinServiceManager.ConnectOrRaise(const AMachineName,
  ADatabaseName: string; const AAccess: DWORD;
  const AOperation: TRickWinServiceOperation; const AServiceName: string);
var
  LMachineName: PChar;
  LDatabaseName: PChar;
  LError: DWORD;
begin
  Disconnect;
  FServiceName := AServiceName;

  LMachineName := nil;
  LDatabaseName := nil;

  if not AMachineName.IsEmpty then
    LMachineName := PChar(AMachineName);

  if not ADatabaseName.IsEmpty then
    LDatabaseName := PChar(ADatabaseName);

  FServiceControlManager := OpenSCManager(
    LMachineName,
    LDatabaseName,
    AAccess
  );

  if FServiceControlManager <> 0 then
    Exit;

  LError := GetLastError;
  RaiseScmError(AOperation, 'Falha ao abrir o Service Control Manager.', LError);
end;

procedure TRickWinServiceManager.OpenServiceConnectionOrRaise(
  const AServiceName: string; const AAccess: DWORD;
  const AOperation: TRickWinServiceOperation);
var
  LError: DWORD;
begin
  CloseServiceConnection;
  FServiceName := AServiceName;

  if FServiceControlManager = 0 then
    RaiseScmError(
      AOperation,
      'O handle do Service Control Manager não está disponível.',
      ERROR_INVALID_HANDLE
    );

  FServiceHandle := OpenService(
    FServiceControlManager,
    PChar(AServiceName),
    AAccess
  );

  if FServiceHandle <> 0 then
    Exit;

  LError := GetLastError;
  RaiseScmError(AOperation, 'Falha ao abrir o serviço no SCM.', LError);
end;

procedure TRickWinServiceManager.CreateServiceRegistration(
  const AServiceName, ADisplayName, ABinaryPath: string;
  const ADesiredAccess, AServiceType, AStartType, AErrorControl: DWORD);
var
  LError: DWORD;
begin
  CloseServiceConnection;
  FServiceName := AServiceName;

  if FServiceControlManager = 0 then
    RaiseScmError(
      TRickWinServiceOperation.Install,
      'O handle do Service Control Manager não está disponível.',
      ERROR_INVALID_HANDLE
    );

  FServiceHandle := CreateService(
    FServiceControlManager,
    PChar(AServiceName),
    PChar(ADisplayName),
    ADesiredAccess,
    AServiceType,
    AStartType,
    AErrorControl,
    PChar(ABinaryPath),
    nil,
    nil,
    nil,
    nil,
    nil
  );

  if FServiceHandle <> 0 then
    Exit;

  LError := GetLastError;
  RaiseScmError(
    TRickWinServiceOperation.Install,
    'Falha ao registrar o serviço.',
    LError
  );
end;

procedure TRickWinServiceManager.DeleteServiceRegistration(
  const AOperation: TRickWinServiceOperation);
var
  LError: DWORD;
begin
  if FServiceHandle = 0 then
    RaiseScmError(
      AOperation,
      'O handle do serviço não está disponível para remoção.',
      ERROR_INVALID_HANDLE
    );

  if DeleteService(FServiceHandle) then
    Exit;

  LError := GetLastError;
  RaiseScmError(AOperation, 'Falha ao remover o serviço do SCM.', LError);
end;

procedure TRickWinServiceManager.SetServiceDescription(
  const ADescription: string; const AOperation: TRickWinServiceOperation);
var
  LDescription: SERVICE_DESCRIPTION;
  LError: DWORD;
begin
  if FServiceHandle = 0 then
    RaiseScmError(
      AOperation,
      'O handle do serviço não está disponível para configurar a descrição.',
      ERROR_INVALID_HANDLE
    );

  LDescription := Default(SERVICE_DESCRIPTION);
  LDescription.lpDescription := PChar(ADescription);

  if ChangeServiceConfig2(
    FServiceHandle,
    SERVICE_CONFIG_DESCRIPTION,
    @LDescription
  ) then
    Exit;

  LError := GetLastError;
  RaiseScmError(AOperation, 'Falha ao configurar a descrição do serviço.', LError);
end;

class function TRickWinServiceManager.ConvertState(
  const AState: DWORD): TRickWinServiceState;
begin
  case AState of
    SERVICE_STOPPED:
      Result := TRickWinServiceState.Stopped;

    SERVICE_START_PENDING:
      Result := TRickWinServiceState.StartPending;

    SERVICE_STOP_PENDING:
      Result := TRickWinServiceState.StopPending;

    SERVICE_RUNNING:
      Result := TRickWinServiceState.Running;

    SERVICE_CONTINUE_PENDING:
      Result := TRickWinServiceState.ContinuePending;

    SERVICE_PAUSE_PENDING:
      Result := TRickWinServiceState.PausePending;

    SERVICE_PAUSED:
      Result := TRickWinServiceState.Paused;
  else
    Result := TRickWinServiceState.Unknown;
  end;
end;

function TRickWinServiceManager.QueryStatus(
  out AStatus: SERVICE_STATUS_PROCESS): Boolean;
var
  LBytesNeeded: DWORD;
begin
  AStatus := Default(SERVICE_STATUS_PROCESS);
  LBytesNeeded := 0;

  if FServiceHandle = 0 then
  begin
    SetLastError(ERROR_INVALID_HANDLE);
    Exit(False);
  end;

  Result := QueryServiceStatusEx(
    FServiceHandle,
    SC_STATUS_PROCESS_INFO,
    @AStatus,
    SizeOf(AStatus),
    LBytesNeeded
  );
end;

procedure TRickWinServiceManager.QueryStatusOrRaise(
  out AStatus: SERVICE_STATUS_PROCESS;
  const AOperation: TRickWinServiceOperation);
var
  LBytesNeeded: DWORD;
  LError: DWORD;
begin
  AStatus := Default(SERVICE_STATUS_PROCESS);
  LBytesNeeded := 0;

  if FServiceHandle = 0 then
    RaiseScmError(
      AOperation,
      'O handle do serviço não está disponível para consulta de estado.',
      ERROR_INVALID_HANDLE
    );

  if QueryServiceStatusEx(
    FServiceHandle,
    SC_STATUS_PROCESS_INFO,
    @AStatus,
    SizeOf(AStatus),
    LBytesNeeded
  ) then
    Exit;

  LError := GetLastError;
  RaiseScmError(AOperation, 'Falha ao consultar o estado do serviço.', LError);
end;

function TRickWinServiceManager.State: TRickWinServiceState;
var
  LStatus: SERVICE_STATUS_PROCESS;
begin
  QueryStatusOrRaise(LStatus, TRickWinServiceOperation.Query);
  Result := ConvertState(LStatus.dwCurrentState);
end;

function TRickWinServiceManager.ServiceRunning: Boolean;
begin
  Result := State = TRickWinServiceState.Running;
end;

function TRickWinServiceManager.ServiceStopped: Boolean;
begin
  Result := State = TRickWinServiceState.Stopped;
end;

function TRickWinServiceManager.DoStartService(
  const ANumberOfArguments: DWORD; AServiceArgVectors: PChar): Boolean;
var
  LServiceArgVectors: PChar;
begin
  LServiceArgVectors := AServiceArgVectors;

  Result := Winapi.WinSvc.StartService(
    FServiceHandle,
    ANumberOfArguments,
    LServiceArgVectors
  );
end;

function TRickWinServiceManager.StartService: Boolean;
var
  LArgs: PChar;
  LState: TRickWinServiceState;
  LError: DWORD;
begin
  LState := State;

  case LState of
    TRickWinServiceState.Running:
      Exit(True);

    TRickWinServiceState.StartPending:
      Exit(WaitForState(TRickWinServiceState.Running));
  end;

  if LState <> TRickWinServiceState.Stopped then
  begin
    SetLastError(ERROR_SERVICE_CANNOT_ACCEPT_CTRL);
    Exit(False);
  end;

  LArgs := nil;

  if not DoStartService(0, LArgs) then
  begin
    LError := GetLastError;

    if LError = ERROR_SERVICE_ALREADY_RUNNING then
      Exit(WaitForState(TRickWinServiceState.Running));

    SetLastError(LError);
    Exit(False);
  end;

  Result := WaitForState(TRickWinServiceState.Running);
end;

function TRickWinServiceManager.StartService(
  const ANumberOfArguments: DWORD; AServiceArgVectors: PChar): Boolean;
var
  LState: TRickWinServiceState;
  LError: DWORD;
begin
  LState := State;

  case LState of
    TRickWinServiceState.Running:
      Exit(True);

    TRickWinServiceState.StartPending:
      Exit(WaitForState(TRickWinServiceState.Running));
  end;

  if LState <> TRickWinServiceState.Stopped then
  begin
    SetLastError(ERROR_SERVICE_CANNOT_ACCEPT_CTRL);
    Exit(False);
  end;

  if not DoStartService(ANumberOfArguments, AServiceArgVectors) then
  begin
    LError := GetLastError;

    if LError = ERROR_SERVICE_ALREADY_RUNNING then
      Exit(WaitForState(TRickWinServiceState.Running));

    SetLastError(LError);
    Exit(False);
  end;

  Result := WaitForState(TRickWinServiceState.Running);
end;

function TRickWinServiceManager.StopService: Boolean;
var
  LServiceStatus: TServiceStatus;
  LState: TRickWinServiceState;
  LError: DWORD;
begin
  LState := State;

  case LState of
    TRickWinServiceState.Stopped:
      Exit(True);

    TRickWinServiceState.StopPending:
      Exit(WaitForState(TRickWinServiceState.Stopped));
  end;

  if not ControlService(
    FServiceHandle,
    SERVICE_CONTROL_STOP,
    LServiceStatus
  ) then
  begin
    LError := GetLastError;

    if LError = ERROR_SERVICE_NOT_ACTIVE then
      Exit(True);

    SetLastError(LError);
    Exit(False);
  end;

  Result := WaitForState(TRickWinServiceState.Stopped);
end;

procedure TRickWinServiceManager.StartServiceOrRaise;
var
  LStatus: SERVICE_STATUS_PROCESS;
  LState: TRickWinServiceState;
  LError: DWORD;
  LArgs: PChar;
begin
  QueryStatusOrRaise(LStatus, TRickWinServiceOperation.Start);
  LState := ConvertState(LStatus.dwCurrentState);

  case LState of
    TRickWinServiceState.Running:
      Exit;

    TRickWinServiceState.StartPending:
    begin
      WaitForStateOrRaise(
        TRickWinServiceOperation.Start,
        TRickWinServiceState.Running
      );
      Exit;
    end;
  end;

  if LState <> TRickWinServiceState.Stopped then
    raise ERickWinServiceStateException.Create(
      TRickWinServiceOperation.Start,
      FServiceName,
      TRickWinServiceState.Stopped,
      LState,
      LStatus.dwWin32ExitCode,
      LStatus.dwServiceSpecificExitCode
    );

  LArgs := nil;

  if not Winapi.WinSvc.StartService(
    FServiceHandle,
    0,
    LArgs
  ) then
  begin
    LError := GetLastError;

    if LError = ERROR_SERVICE_ALREADY_RUNNING then
    begin
      WaitForStateOrRaise(
        TRickWinServiceOperation.Start,
        TRickWinServiceState.Running
      );
      Exit;
    end;

    RaiseScmError(
      TRickWinServiceOperation.Start,
      'A chamada StartService foi recusada pelo SCM.',
      LError
    );
  end;

  WaitForStateOrRaise(
    TRickWinServiceOperation.Start,
    TRickWinServiceState.Running
  );
end;

procedure TRickWinServiceManager.StopServiceOrRaise;
var
  LServiceStatus: TServiceStatus;
  LStatus: SERVICE_STATUS_PROCESS;
  LState: TRickWinServiceState;
  LError: DWORD;
begin
  QueryStatusOrRaise(LStatus, TRickWinServiceOperation.Stop);
  LState := ConvertState(LStatus.dwCurrentState);

  case LState of
    TRickWinServiceState.Stopped:
      Exit;

    TRickWinServiceState.StopPending:
    begin
      WaitForStateOrRaise(
        TRickWinServiceOperation.Stop,
        TRickWinServiceState.Stopped
      );
      Exit;
    end;
  end;

  if not ControlService(
    FServiceHandle,
    SERVICE_CONTROL_STOP,
    LServiceStatus
  ) then
  begin
    LError := GetLastError;

    if LError = ERROR_SERVICE_NOT_ACTIVE then
      Exit;

    RaiseScmError(
      TRickWinServiceOperation.Stop,
      'A chamada ControlService(SERVICE_CONTROL_STOP) foi recusada pelo SCM.',
      LError
    );
  end;

  WaitForStateOrRaise(
    TRickWinServiceOperation.Stop,
    TRickWinServiceState.Stopped
  );
end;

procedure TRickWinServiceManager.PauseService;
var
  LServiceStatus: TServiceStatus;
begin
  if not ControlService(
    FServiceHandle,
    SERVICE_CONTROL_PAUSE,
    LServiceStatus
  ) then
    RaiseLastOSError;
end;

procedure TRickWinServiceManager.ContinueService;
var
  LServiceStatus: TServiceStatus;
begin
  if not ControlService(
    FServiceHandle,
    SERVICE_CONTROL_CONTINUE,
    LServiceStatus
  ) then
    RaiseLastOSError;
end;

procedure TRickWinServiceManager.ShutdownService;
var
  LServiceStatus: TServiceStatus;
begin
  if not ControlService(
    FServiceHandle,
    SERVICE_CONTROL_SHUTDOWN,
    LServiceStatus
  ) then
    RaiseLastOSError;
end;

function TRickWinServiceManager.WaitForState(
  const AExpectedState: TRickWinServiceState;
  const ATimeout: Cardinal): Boolean;
var
  LStatus: SERVICE_STATUS_PROCESS;
  LCurrentState: TRickWinServiceState;
  LStartTick: UInt64;
  LCheckPointTick: UInt64;
  LPreviousCheckPoint: DWORD;
  LWaitTime: DWORD;
  LNow: UInt64;
begin
  LStartTick := GetTickCount64;
  LCheckPointTick := LStartTick;
  LPreviousCheckPoint := 0;

  repeat
    if not QueryStatus(LStatus) then
      RaiseLastOSError;

    LCurrentState := ConvertState(LStatus.dwCurrentState);

    if LCurrentState = AExpectedState then
      Exit(True);

    LNow := GetTickCount64;

    if (ATimeout > 0) and ((LNow - LStartTick) >= ATimeout) then
    begin
      SetLastError(ERROR_TIMEOUT);
      Exit(False);
    end;

    if LStatus.dwCheckPoint > LPreviousCheckPoint then
    begin
      LPreviousCheckPoint := LStatus.dwCheckPoint;
      LCheckPointTick := LNow;
    end
    else if (LStatus.dwWaitHint > 0) and
            ((LNow - LCheckPointTick) > LStatus.dwWaitHint) then
    begin
      SetLastError(ERROR_TIMEOUT);
      Exit(False);
    end;

    LWaitTime := LStatus.dwWaitHint div 10;

    if LWaitTime < 100 then
      LWaitTime := 100
    else if LWaitTime > 1000 then
      LWaitTime := 1000;

    Sleep(LWaitTime);
  until False;
end;

procedure TRickWinServiceManager.WaitForStateOrRaise(
  const AOperation: TRickWinServiceOperation;
  const AExpectedState: TRickWinServiceState; const ATimeout: Cardinal);
var
  LStatus: SERVICE_STATUS_PROCESS;
  LCurrentState: TRickWinServiceState;
  LStartTick: UInt64;
  LCheckPointTick: UInt64;
  LPreviousCheckPoint: DWORD;
  LWaitTime: DWORD;
  LNow: UInt64;
  LTransitionObserved: Boolean;
begin
  LStartTick := GetTickCount64;
  LCheckPointTick := LStartTick;
  LPreviousCheckPoint := 0;
  LTransitionObserved := AOperation = TRickWinServiceOperation.Start;

  repeat
    QueryStatusOrRaise(LStatus, AOperation);
    LCurrentState := ConvertState(LStatus.dwCurrentState);

    if LCurrentState = AExpectedState then
      Exit;

    case AOperation of
      TRickWinServiceOperation.Start:
      begin
        if LCurrentState = TRickWinServiceState.StartPending then
          LTransitionObserved := True
        else if (LCurrentState = TRickWinServiceState.Stopped) and
                (LTransitionObserved or (LStatus.dwWin32ExitCode <> NO_ERROR) or
                 (LStatus.dwServiceSpecificExitCode <> 0)) then
          raise ERickWinServiceStateException.Create(
            AOperation,
            FServiceName,
            AExpectedState,
            LCurrentState,
            LStatus.dwWin32ExitCode,
            LStatus.dwServiceSpecificExitCode
          );
      end;

      TRickWinServiceOperation.Stop:
      begin
        if LCurrentState = TRickWinServiceState.StopPending then
          LTransitionObserved := True
        else if LTransitionObserved and
                (LCurrentState <> TRickWinServiceState.StopPending) then
          raise ERickWinServiceStateException.Create(
            AOperation,
            FServiceName,
            AExpectedState,
            LCurrentState,
            LStatus.dwWin32ExitCode,
            LStatus.dwServiceSpecificExitCode
          );
      end;
    end;

    LNow := GetTickCount64;

    if (ATimeout > 0) and ((LNow - LStartTick) >= ATimeout) then
      raise ERickWinServiceTimeoutException.Create(
        AOperation,
        FServiceName,
        AExpectedState,
        LCurrentState,
        LStatus.dwWin32ExitCode,
        LStatus.dwServiceSpecificExitCode,
        ATimeout
      );

    if LStatus.dwCheckPoint > LPreviousCheckPoint then
    begin
      LPreviousCheckPoint := LStatus.dwCheckPoint;
      LCheckPointTick := LNow;
    end
    else if (LStatus.dwWaitHint > 0) and
            ((LNow - LCheckPointTick) > LStatus.dwWaitHint) then
      raise ERickWinServiceTimeoutException.Create(
        AOperation,
        FServiceName,
        AExpectedState,
        LCurrentState,
        LStatus.dwWin32ExitCode,
        LStatus.dwServiceSpecificExitCode,
        ATimeout
      );

    LWaitTime := LStatus.dwWaitHint div 10;

    if LWaitTime < 100 then
      LWaitTime := 100
    else if LWaitTime > 1000 then
      LWaitTime := 1000;

    Sleep(LWaitTime);
  until False;
end;

class function TRickWinServiceManager.GetServiceState(
  const AServiceName: string): TRickWinServiceState;
var
  LManager: TRickWinServiceManager;
  LStatus: SERVICE_STATUS_PROCESS;
begin
  LManager := TRickWinServiceManager.Create;
  try
    LManager.ConnectOrRaise(
      '',
      '',
      SC_MANAGER_CONNECT,
      TRickWinServiceOperation.Query,
      AServiceName
    );

    try
      LManager.OpenServiceConnectionOrRaise(
        AServiceName,
        SERVICE_QUERY_STATUS,
        TRickWinServiceOperation.Query
      );
    except
      on E: ERickWinServiceScmException do
      begin
        if E.Win32ErrorCode = ERROR_SERVICE_DOES_NOT_EXIST then
          Exit(TRickWinServiceState.NotInstalled);

        raise;
      end;
    end;

    LManager.QueryStatusOrRaise(
      LStatus,
      TRickWinServiceOperation.Query
    );

    Result := ConvertState(LStatus.dwCurrentState);
  finally
    LManager.Free;
  end;
end;

class function TRickWinServiceManager.IsServiceInstalled(
  const AServiceName: string): Boolean;
begin
  Result := GetServiceState(AServiceName) <>
    TRickWinServiceState.NotInstalled;
end;

class function TRickWinServiceManager.IsServiceRunning(
  const AServiceName: string): Boolean;
begin
  Result := GetServiceState(AServiceName) =
    TRickWinServiceState.Running;
end;

class function TRickWinServiceManager.IsDesktopMode: Boolean;
begin
  Result := TRickWinServiceCommandLine.IsDesktopMode;
end;

function IsDesktopMode(const ServiceName: string): Boolean;
begin
  Result := TRickWinServiceManager.IsDesktopMode;
end;

end.
