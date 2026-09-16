unit Rick.WinService.Model;
(*
  ==============================================================================
  Unit: Rick.WinService.Model
  ==============================================================================

  RESPONSABILIDADE

  Implementa o contrato IRickWinService preservado pelo framework.

  Esta classe permanece disponível para compatibilidade com consumidores que
  instanciam IRickWinService diretamente. As operações Start, Stop, Restart e
  consulta utilizam o Manager tipado. Os overloads legados de Install/Uninstall
  continuam encaminhando a operação para uma segunda instância do executável,
  porém essa instância não utiliza mais TServiceApplication para registrar o
  serviço: ela é roteada por Rick.WinService.CommandLine até o Installer único.

  A API procedural recomendada para aplicações novas continua sendo
  Rick.WinService.pas. Nessa fachada, InstallService e UninstallService chamam o
  Installer diretamente, sem processo auxiliar.

  ------------------------------------------------------------------------------

  GERENCIAMENTO DO NOME DO SERVIÇO

  FServiceName é armazenado como string.

  A implementação anterior armazenava PChar(Value), mantendo apenas um ponteiro
  para a memória de uma string recebida como parâmetro. Esse ponteiro poderia
  deixar de ser válido após o término da chamada.

  A conversão para PChar ocorre somente no ponto em que a WinAPI necessita dela.

  ------------------------------------------------------------------------------

  SEGURANÇA DAS OPERAÇÕES

  Install, Uninstall, Start, Stop e Restart são operações administrativas.

  Antes de alterar o estado ou o registro do serviço, a implementação chama
  TRickWinServiceSecurity.RequireAdministrator. Quando o processo atual não está
  elevado, ERickWinServiceAdministratorRequired é lançada antes de qualquer
  acesso mutável ao SCM ou criação do processo auxiliar.

  O framework não tenta elevar automaticamente a aplicação e não apresenta
  interfaces visuais. O tratamento visual permanece sob responsabilidade do
  consumidor.

  ------------------------------------------------------------------------------

  START / STOP

  Cada operação cria uma instância própria de TRickWinServiceManager.

  Não existe reutilização de Singleton ou de handles entre operações.

  Start e Stop delegam ao Manager a espera pelo estado real informado pelo SCM.
  Não existe Sleep(2000) nesta implementação.

  ------------------------------------------------------------------------------

  INSTALL / UNINSTALL DE COMPATIBILIDADE

  Os métodos Install/Uninstall de IRickWinService são mantidos para preservar o
  contrato público existente. Eles executam o próprio binário com:

  /Install /Silent
  /UnInstall /Silent

  O processo filho é interpretado por Rick.WinService.CommandLine e termina em
  Rick.WinService.Installer, que é o mesmo núcleo utilizado pela fachada pública
  direta. O TServiceApplication não registra nem remove o serviço nesse caminho.

  ExecProcess continua existindo somente como adaptador de compatibilidade para
  consumidores antigos da interface. Toda falha conhecida de criação, espera ou
  leitura do ExitCode é convertida em exceção RickService tipada antes de ser
  devolvida ao consumidor.

  ==============================================================================
*)

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Winapi.Windows,
  Winapi.WinSvc,

  Rick.WinService.CommandLine,
  Rick.WinService.Exceptions,
  Rick.WinService.Interfaces,
  Rick.WinService.Manager,
  Rick.WinService.Security,
  Rick.WinService.Types;

type
  /// <summary>
  /// Implementação padrão de IRickWinService.
  /// </summary>
  TRickWinServiceModel = class(TInterfacedObject, IRickWinService)
  private
    FServiceName: string;
    FExeName: string;

    function GetStringParams(AParams: TDictionary<string, string>): string;

    /// <summary>
    /// Valida a elevação do processo antes de uma operação administrativa.
    /// </summary>
    /// <param name="AOperation">
    /// Descrição da operação utilizada em uma eventual exceção de segurança.
    /// </param>
    procedure RequireAdministrator(const AOperation: string);

    /// <summary>
    /// Cria um Manager conectado ao serviço com os direitos informados.
    /// </summary>
    function CreateManager(const AServiceAccess: DWORD;
      const AOperation: TRickWinServiceOperation): TRickWinServiceManager;

    /// <summary>
    /// Executa a operação real de Start após as validações de segurança.
    /// </summary>
    procedure DoStart;

    /// <summary>
    /// Executa a operação real de Stop após as validações de segurança.
    /// </summary>
    procedure DoStop;

    /// <summary>
    /// Executa o próprio binário em modo /Install ou /UnInstall e valida o
    /// código de saída retornado pelo processo auxiliar.
    /// </summary>
    procedure ExecProcess(const AExeName: string;
      AParams: TDictionary<string, string>;
      const AType: TInstallType);
  protected
    function ServiceName(const Value: string): IRickWinService; overload;
    function ServiceName: string; overload;

    function ExeName: string; overload;
    function ExeName(const Value: string): IRickWinService; overload;

    /// <summary>
    /// Instala o serviço exigindo previamente privilégios administrativos.
    /// </summary>
    procedure Install; overload;

    /// <summary>
    /// Instala o serviço com parâmetros adicionais e exige elevação.
    /// </summary>
    procedure Install(Params: TDictionary<string, string>); overload;

    /// <summary>
    /// Desinstala o serviço exigindo previamente privilégios administrativos.
    /// </summary>
    procedure Uninstall; overload;

    /// <summary>
    /// Desinstala o serviço com parâmetros adicionais e exige elevação.
    /// </summary>
    procedure Uninstall(Params: TDictionary<string, string>); overload;

    /// <summary>
    /// Inicia o serviço somente quando o processo está elevado.
    /// </summary>
    procedure Start;

    /// <summary>
    /// Para o serviço somente quando o processo está elevado.
    /// </summary>
    procedure Stop;

    /// <summary>
    /// Reinicia o serviço somente quando o processo está elevado.
    /// </summary>
    procedure Restart;

    function IsInstalled: Boolean;
    function IsRunning: Boolean;
    function State: TRickWinServiceState;
  public
    constructor Create;
    destructor Destroy; override;

    class function New: IRickWinService;
  end;

implementation

{ TRickWinServiceModel }

constructor TRickWinServiceModel.Create;
begin
  inherited Create;

  FServiceName := EmptyStr;
  FExeName := GetModuleName(HInstance);
end;

destructor TRickWinServiceModel.Destroy;
begin
  inherited;
end;

class function TRickWinServiceModel.New: IRickWinService;
begin
  Result := Self.Create;
end;

function TRickWinServiceModel.ServiceName(
  const Value: string): IRickWinService;
begin
  Result := Self;
  FServiceName := Value;
end;

function TRickWinServiceModel.ServiceName: string;
begin
  Result := FServiceName;
end;

function TRickWinServiceModel.ExeName(
  const Value: string): IRickWinService;
begin
  Result := Self;
  FExeName := Value;
end;

function TRickWinServiceModel.ExeName: string;
begin
  Result := FExeName;
end;

function TRickWinServiceModel.GetStringParams(
  AParams: TDictionary<string, string>): string;
var
  LKey: string;
begin
  Result := ' /Silent';

  if not Assigned(AParams) then
    Exit;

  for LKey in AParams.Keys do
    Result := Result + ' ' + LKey + '"' + AParams.Items[LKey] + '"';
end;

procedure TRickWinServiceModel.ExecProcess(
  const AExeName: string;
  AParams: TDictionary<string, string>;
  const AType: TInstallType);
var
  LParams: string;
  LCommandLine: string;
  LCurrentDirectory: string;
  LStartupInfo: TStartupInfo;
  LProcessInformation: TProcessInformation;
  LWaitResult: DWORD;
  LExitCode: DWORD;
  LErrorCode: DWORD;
  LOperation: TRickWinServiceOperation;
begin
  case AType of
    TInstallType.Install:
    begin
      LParams := ' /Install';
      LOperation := TRickWinServiceOperation.Install;
    end;

    TInstallType.Uninstall:
    begin
      LParams := ' /UnInstall';
      LOperation := TRickWinServiceOperation.Uninstall;
    end;
  else
    raise ERickWinServiceOperationException.Create(
      TRickWinServiceOperation.Query,
      FServiceName,
      'Operação de instalação inválida.'
    );
  end;

  if AExeName.Trim.IsEmpty then
    raise ERickWinServiceOperationException.Create(
      LOperation,
      FServiceName,
      'O executável do serviço não foi informado.'
    );

  if not FileExists(AExeName) then
    raise ERickWinServiceOperationException.Create(
      LOperation,
      FServiceName,
      Format('O executável do serviço não foi encontrado: %s', [AExeName])
    );

  LParams := LParams + GetStringParams(AParams);
  LCommandLine := '"' + AExeName + '"' + LParams;
  LCurrentDirectory := ExtractFileDir(AExeName);

  UniqueString(LCommandLine);

  LStartupInfo := Default(TStartupInfo);
  LProcessInformation := Default(TProcessInformation);

  LStartupInfo.cb := SizeOf(LStartupInfo);
  LStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  LStartupInfo.wShowWindow := SW_HIDE;

  if not CreateProcess(
    PChar(AExeName),
    PChar(LCommandLine),
    nil,
    nil,
    False,
    NORMAL_PRIORITY_CLASS,
    nil,
    PChar(LCurrentDirectory),
    LStartupInfo,
    LProcessInformation
  ) then
  begin
    LErrorCode := GetLastError;

    raise ERickWinServiceOperationException.Create(
      LOperation,
      FServiceName,
      Format(
        'Não foi possível iniciar o processo auxiliar. ' +
        'Código do Windows: %d. %s',
        [LErrorCode, SysErrorMessage(LErrorCode)]
      )
    );
  end;

  try
    LWaitResult := WaitForSingleObject(
      LProcessInformation.hProcess,
      INFINITE
    );

    if LWaitResult = WAIT_FAILED then
    begin
      LErrorCode := GetLastError;

      raise ERickWinServiceOperationException.Create(
        LOperation,
        FServiceName,
        Format(
          'Não foi possível aguardar o processo auxiliar. ' +
          'Código do Windows: %d. %s',
          [LErrorCode, SysErrorMessage(LErrorCode)]
        )
      );
    end;

    if not GetExitCodeProcess(
      LProcessInformation.hProcess,
      LExitCode
    ) then
    begin
      LErrorCode := GetLastError;

      raise ERickWinServiceOperationException.Create(
        LOperation,
        FServiceName,
        Format(
          'Não foi possível obter o código de saída do processo auxiliar. ' +
          'Código do Windows: %d. %s',
          [LErrorCode, SysErrorMessage(LErrorCode)]
        )
      );
    end;

    if LExitCode <> RICK_WINSERVICE_EXIT_SUCCESS then
    begin
      if LExitCode = RICK_WINSERVICE_EXIT_ADMIN_REQUIRED then
        raise ERickWinServiceAdministratorRequired.Create(
          'executar a operação solicitada pelo processo auxiliar'
        );

      raise ERickWinServiceOperationException.Create(
        LOperation,
        FServiceName,
        Format(
          'A operação do serviço retornou o código de saída %d. Comando: %s',
          [LExitCode, LParams.Trim]
        )
      );
    end;
  finally
    if LProcessInformation.hThread <> 0 then
      CloseHandle(LProcessInformation.hThread);

    if LProcessInformation.hProcess <> 0 then
      CloseHandle(LProcessInformation.hProcess);
  end;
end;

procedure TRickWinServiceModel.RequireAdministrator(
  const AOperation: string);
begin
  TRickWinServiceSecurity.RequireAdministrator(AOperation);
end;

procedure TRickWinServiceModel.DoStart;
var
  LManager: TRickWinServiceManager; // Conexão pontual usada somente no Start.
begin
  LManager := CreateManager(
    SERVICE_START or SERVICE_QUERY_STATUS,
    TRickWinServiceOperation.Start
  );
  try
    LManager.StartServiceOrRaise;
  finally
    LManager.Free;
  end;
end;

procedure TRickWinServiceModel.DoStop;
var
  LManager: TRickWinServiceManager; // Conexão pontual usada somente no Stop.
begin
  LManager := CreateManager(
    SERVICE_STOP or SERVICE_QUERY_STATUS,
    TRickWinServiceOperation.Stop
  );
  try
    LManager.StopServiceOrRaise;
  finally
    LManager.Free;
  end;
end;

function TRickWinServiceModel.CreateManager(
  const AServiceAccess: DWORD;
  const AOperation: TRickWinServiceOperation): TRickWinServiceManager;
begin
  Result := TRickWinServiceManager.Create;

  try
    Result.ConnectOrRaise(
      '',
      '',
      SC_MANAGER_CONNECT,
      AOperation,
      FServiceName
    );

    Result.OpenServiceConnectionOrRaise(
      FServiceName,
      AServiceAccess,
      AOperation
    );
  except
    Result.Free;
    raise;
  end;
end;

procedure TRickWinServiceModel.Install;
begin
  Install(nil);
end;

procedure TRickWinServiceModel.Install(
  Params: TDictionary<string, string>);
begin
  RequireAdministrator('instalar o serviço');

  ExecProcess(
    FExeName,
    Params,
    TInstallType.Install
  );
end;

procedure TRickWinServiceModel.Uninstall;
begin
  Uninstall(nil);
end;

procedure TRickWinServiceModel.Uninstall(
  Params: TDictionary<string, string>);
begin
  RequireAdministrator('desinstalar o serviço');

  ExecProcess(
    FExeName,
    Params,
    TInstallType.Uninstall
  );
end;

procedure TRickWinServiceModel.Start;
begin
  RequireAdministrator('iniciar o serviço');
  DoStart;
end;

procedure TRickWinServiceModel.Stop;
begin
  RequireAdministrator('parar o serviço');
  DoStop;
end;

procedure TRickWinServiceModel.Restart;
begin
  RequireAdministrator('reiniciar o serviço');

  DoStop;
  DoStart;
end;

function TRickWinServiceModel.IsInstalled: Boolean;
begin
  Result := TRickWinServiceManager.IsServiceInstalled(FServiceName);
end;

function TRickWinServiceModel.IsRunning: Boolean;
begin
  Result := TRickWinServiceManager.IsServiceRunning(FServiceName);
end;

function TRickWinServiceModel.State: TRickWinServiceState;
begin
  Result := TRickWinServiceManager.GetServiceState(FServiceName);
end;

end.
