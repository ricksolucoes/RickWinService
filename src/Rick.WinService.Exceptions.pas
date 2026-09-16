unit Rick.WinService.Exceptions;
(*
  ==============================================================================
  Unit: Rick.WinService.Exceptions
  ==============================================================================

  RESPONSABILIDADE

  Declara a hierarquia pública de exceções tipadas utilizada pelo Rick
  WinService.

  O objetivo desta unit é preservar o erro no ponto em que ele é conhecido e
  permitir que aplicações VCL, FMX, console ou outros consumidores tratem a
  causa sem interpretar textos retornados pelo Windows.

  ------------------------------------------------------------------------------

  HIERARQUIA

  ERickWinServiceException
    Exceção base para erros controlados do framework.

  ERickWinServiceSecurityException
    Base para falhas de segurança e validação do token do processo.

  ERickWinServiceAdministratorRequired
    Informa que uma operação administrativa foi solicitada sem elevação.

  ERickWinServiceOperationException
    Representa uma falha contextualizada por operação e serviço.

  ERickWinServiceScmException
    Preserva o código Win32 capturado imediatamente após uma falha no SCM.

  ERickWinServiceStateException
    Representa uma transição que terminou em estado incompatível e preserva os
    códigos retornados por SERVICE_STATUS_PROCESS.

  ERickWinServiceTimeoutException
    Representa exclusivamente uma transição que excedeu o tempo permitido.

  ------------------------------------------------------------------------------

  APRESENTAÇÃO AO USUÁRIO

  Esta unit não possui dependência de VCL, FMX ou RickDialog. O framework
  informa a condição por exceção tipada; a aplicação consumidora decide como
  apresentar, registrar ou converter o erro.

  ==============================================================================
*)

interface

uses
  System.SysUtils,
  Winapi.Windows,

  Rick.WinService.Types;

type
  /// <summary>
  /// Exceção base para erros controlados produzidos pelo Rick WinService.
  /// </summary>
  ERickWinServiceException = class(Exception);

  /// <summary>
  /// Exceção base para erros ocorridos durante validações de segurança.
  /// </summary>
  ERickWinServiceSecurityException = class(ERickWinServiceException);

  /// <summary>
  /// Indica que a operação solicitada exige privilégios administrativos e o
  /// processo atual não está executando com esses privilégios.
  /// </summary>
  ERickWinServiceAdministratorRequired = class(ERickWinServiceSecurityException)
  private
    FOperation: string;
  public
    /// <summary>
    /// Cria a exceção informando a descrição da operação bloqueada.
    /// </summary>
    constructor Create(const AOperation: string); reintroduce;

    /// <summary>
    /// Retorna a descrição textual da operação administrativa bloqueada.
    /// </summary>
    property Operation: string read FOperation;
  end;

  /// <summary>
  /// Exceção base para falhas associadas a uma operação sobre um serviço.
  /// </summary>
  ERickWinServiceOperationException = class(ERickWinServiceException)
  private
    FOperation: TRickWinServiceOperation;
    FServiceName: string;
  public
    /// <summary>
    /// Cria uma exceção operacional com mensagem controlada pelo framework.
    /// </summary>
    constructor Create(const AOperation: TRickWinServiceOperation;
      const AServiceName: string; const AMessage: string); reintroduce;

    /// <summary>
    /// Operação durante a qual a falha ocorreu.
    /// </summary>
    property Operation: TRickWinServiceOperation read FOperation;

    /// <summary>
    /// Nome interno do serviço relacionado à falha.
    /// </summary>
    property ServiceName: string read FServiceName;
  end;

  /// <summary>
  /// Representa uma falha retornada diretamente pelo Service Control Manager.
  /// </summary>
  ERickWinServiceScmException = class(ERickWinServiceOperationException)
  private
    FWin32ErrorCode: DWORD;
    FContext: string;
  public
    /// <summary>
    /// Cria a exceção preservando imediatamente o código retornado pelo Windows.
    /// </summary>
    constructor Create(const AOperation: TRickWinServiceOperation;
      const AServiceName: string; const AContext: string;
      const AWin32ErrorCode: DWORD); reintroduce;

    /// <summary>
    /// Código Win32 capturado no ponto exato da falha.
    /// </summary>
    property Win32ErrorCode: DWORD read FWin32ErrorCode;

    /// <summary>
    /// Descrição do ponto da operação em que a WinAPI falhou.
    /// </summary>
    property Context: string read FContext;
  end;

  /// <summary>
  /// Representa uma transição do serviço encerrada em estado incompatível.
  /// </summary>
  ERickWinServiceStateException = class(ERickWinServiceOperationException)
  private
    FExpectedState: TRickWinServiceState;
    FCurrentState: TRickWinServiceState;
    FServiceWin32ExitCode: DWORD;
    FServiceSpecificExitCode: DWORD;
  public
    /// <summary>
    /// Cria a exceção preservando o estado esperado, o estado observado e os
    /// códigos de saída informados por SERVICE_STATUS_PROCESS.
    /// </summary>
    constructor Create(const AOperation: TRickWinServiceOperation;
      const AServiceName: string;
      const AExpectedState, ACurrentState: TRickWinServiceState;
      const AServiceWin32ExitCode, AServiceSpecificExitCode: DWORD); reintroduce;

    property ExpectedState: TRickWinServiceState read FExpectedState;
    property CurrentState: TRickWinServiceState read FCurrentState;
    property ServiceWin32ExitCode: DWORD read FServiceWin32ExitCode;
    property ServiceSpecificExitCode: DWORD read FServiceSpecificExitCode;
  end;

  /// <summary>
  /// Indica que uma transição válida não concluiu dentro do tempo permitido.
  /// </summary>
  ERickWinServiceTimeoutException = class(ERickWinServiceStateException)
  private
    FTimeout: Cardinal;
  public
    /// <summary>
    /// Cria a exceção de timeout preservando o último estado observado.
    /// </summary>
    constructor Create(const AOperation: TRickWinServiceOperation;
      const AServiceName: string;
      const AExpectedState, ACurrentState: TRickWinServiceState;
      const AServiceWin32ExitCode, AServiceSpecificExitCode: DWORD;
      const ATimeout: Cardinal); reintroduce;

    /// <summary>
    /// Tempo máximo, em milissegundos, aguardado pela operação.
    /// </summary>
    property Timeout: Cardinal read FTimeout;
  end;

implementation

function OperationText(const AOperation: TRickWinServiceOperation): string;
begin
  case AOperation of
    TRickWinServiceOperation.Install:
      Result := 'instalar';
    TRickWinServiceOperation.Uninstall:
      Result := 'desinstalar';
    TRickWinServiceOperation.Start:
      Result := 'iniciar';
    TRickWinServiceOperation.Stop:
      Result := 'parar';
    TRickWinServiceOperation.Restart:
      Result := 'reiniciar';
  else
    Result := 'consultar';
  end;
end;

function StateText(const AState: TRickWinServiceState): string;
begin
  case AState of
    TRickWinServiceState.NotInstalled:
      Result := 'NotInstalled';
    TRickWinServiceState.Stopped:
      Result := 'Stopped';
    TRickWinServiceState.StartPending:
      Result := 'StartPending';
    TRickWinServiceState.StopPending:
      Result := 'StopPending';
    TRickWinServiceState.Running:
      Result := 'Running';
    TRickWinServiceState.ContinuePending:
      Result := 'ContinuePending';
    TRickWinServiceState.PausePending:
      Result := 'PausePending';
    TRickWinServiceState.Paused:
      Result := 'Paused';
  else
    Result := 'Unknown';
  end;
end;

{ ERickWinServiceAdministratorRequired }

constructor ERickWinServiceAdministratorRequired.Create(
  const AOperation: string);
var
  LOperation: string;
begin
  LOperation := Trim(AOperation);

  if LOperation = EmptyStr then
    LOperation := 'executar esta operação';

  FOperation := LOperation;

  inherited CreateFmt(
    'Privilégios administrativos são necessários para %s. ' +
    'Execute a aplicação como administrador e tente novamente.',
    [FOperation]
  );
end;

{ ERickWinServiceOperationException }

constructor ERickWinServiceOperationException.Create(
  const AOperation: TRickWinServiceOperation; const AServiceName,
  AMessage: string);
begin
  FOperation := AOperation;
  FServiceName := AServiceName;

  inherited Create(AMessage);
end;

{ ERickWinServiceScmException }

constructor ERickWinServiceScmException.Create(
  const AOperation: TRickWinServiceOperation; const AServiceName,
  AContext: string; const AWin32ErrorCode: DWORD);
var
  LMessage: string;
begin
  FWin32ErrorCode := AWin32ErrorCode;
  FContext := AContext;

  LMessage := Format(
    'Não foi possível %s o serviço "%s". %s ' +
    'Código do Windows: %d. %s',
    [OperationText(AOperation), AServiceName, AContext,
     AWin32ErrorCode, SysErrorMessage(AWin32ErrorCode)]
  );

  inherited Create(AOperation, AServiceName, LMessage);
end;

{ ERickWinServiceStateException }

constructor ERickWinServiceStateException.Create(
  const AOperation: TRickWinServiceOperation; const AServiceName: string;
  const AExpectedState, ACurrentState: TRickWinServiceState;
  const AServiceWin32ExitCode, AServiceSpecificExitCode: DWORD);
var
  LMessage: string;
begin
  FExpectedState := AExpectedState;
  FCurrentState := ACurrentState;
  FServiceWin32ExitCode := AServiceWin32ExitCode;
  FServiceSpecificExitCode := AServiceSpecificExitCode;

  LMessage := Format(
    'O serviço "%s" não concluiu a operação de %s no estado esperado. ' +
    'Esperado: %s. Atual: %s. Win32ExitCode: %d. ' +
    'ServiceSpecificExitCode: %d.',
    [AServiceName, OperationText(AOperation), StateText(AExpectedState),
     StateText(ACurrentState), AServiceWin32ExitCode,
     AServiceSpecificExitCode]
  );

  inherited Create(AOperation, AServiceName, LMessage);
end;

{ ERickWinServiceTimeoutException }

constructor ERickWinServiceTimeoutException.Create(
  const AOperation: TRickWinServiceOperation; const AServiceName: string;
  const AExpectedState, ACurrentState: TRickWinServiceState;
  const AServiceWin32ExitCode, AServiceSpecificExitCode: DWORD;
  const ATimeout: Cardinal);
begin
  FTimeout := ATimeout;

  inherited Create(
    AOperation,
    AServiceName,
    AExpectedState,
    ACurrentState,
    AServiceWin32ExitCode,
    AServiceSpecificExitCode
  );

  Message := Format(
    'O serviço "%s" excedeu o tempo de %d ms durante a operação de %s. ' +
    'Esperado: %s. Atual: %s. Win32ExitCode: %d. ' +
    'ServiceSpecificExitCode: %d.',
    [AServiceName, ATimeout, OperationText(AOperation),
     StateText(AExpectedState), StateText(ACurrentState),
     AServiceWin32ExitCode, AServiceSpecificExitCode]
  );
end;

end.
