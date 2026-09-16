unit Rick.WinService.CommandLine;
(*
  ==============================================================================
  Unit: Rick.WinService.CommandLine
  ==============================================================================

  RESPONSABILIDADE

  Centraliza exclusivamente a interpretação dos switches de inicialização do
  Rick WinService e a conversão de exceções controladas em códigos de saída.

  Esta unit não instala serviços, não acessa o SCM e não cria interfaces
  visuais. Ela apenas informa ao chamador qual modo foi solicitado:

  - Desktop;
  - Install;
  - Uninstall;
  - RunService.

  ------------------------------------------------------------------------------

  INSTALAÇÃO SILENCIOSA

  /Silent é reconhecido e exposto por IsSilent para compatibilidade com
  consumidores existentes. O switch não altera a política visual do framework:
  o Rick WinService não mostra janelas durante comandos administrativos. A
  fronteira de execução converte falhas em ExitCode antes que uma exceção possa
  alcançar o runtime visual.

  ------------------------------------------------------------------------------

  COMPATIBILIDADE

  São reconhecidas as formas '-' e '/' já utilizadas pelo framework:

    /Install
    /UnInstall
    -RunService
    /Silent

  A comparação não diferencia maiúsculas de minúsculas.

  ==============================================================================
*)

interface

uses
  System.SysUtils;

type
{$SCOPEDENUMS ON}
  /// <summary>
  /// Modo de inicialização identificado na linha de comando.
  /// </summary>
  TRickWinServiceCommand = (
    Desktop,
    Install,
    Uninstall,
    RunService
  );
{$SCOPEDENUMS OFF}

const
  /// <summary>Operação concluída com sucesso.</summary>
  RICK_WINSERVICE_EXIT_SUCCESS = 0;

  /// <summary>Operação bloqueada por ausência de privilégio administrativo.</summary>
  RICK_WINSERVICE_EXIT_ADMIN_REQUIRED = 10;

  /// <summary>Falha controlada de operação, SCM, estado ou timeout.</summary>
  RICK_WINSERVICE_EXIT_OPERATION_ERROR = 20;

  /// <summary>Falha inesperada não classificada pelo framework.</summary>
  RICK_WINSERVICE_EXIT_UNEXPECTED_ERROR = 99;

type
  /// <summary>
  /// Interpretador estático da linha de comando do processo.
  /// </summary>
  TRickWinServiceCommandLine = class sealed
  public
    /// <summary>
    /// Retorna o modo solicitado na linha de comando atual.
    /// </summary>
    class function Command: TRickWinServiceCommand; static;

    /// <summary>
    /// Retorna True quando o switch /Silent está presente.
    /// </summary>
    class function IsSilent: Boolean; static;

    /// <summary>
    /// Retorna True somente quando nenhum modo especial do framework foi
    /// solicitado e o processo deve seguir para a aplicação Desktop.
    /// </summary>
    class function IsDesktopMode: Boolean; static;

    /// <summary>
    /// Converte uma exceção em código de saída estável para execução por linha
    /// de comando.
    /// </summary>
    class function ExitCodeForException(AException: Exception): Integer; static;
  end;

implementation

uses
  Rick.WinService.Exceptions;

{ TRickWinServiceCommandLine }

class function TRickWinServiceCommandLine.Command: TRickWinServiceCommand;
begin
  if FindCmdLineSwitch('INSTALL', ['-', '/'], True) then
    Exit(TRickWinServiceCommand.Install);

  if FindCmdLineSwitch('UNINSTALL', ['-', '/'], True) then
    Exit(TRickWinServiceCommand.Uninstall);

  if FindCmdLineSwitch('RUNSERVICE', ['-', '/'], True) then
    Exit(TRickWinServiceCommand.RunService);

  Result := TRickWinServiceCommand.Desktop;
end;

class function TRickWinServiceCommandLine.IsSilent: Boolean;
begin
  Result := FindCmdLineSwitch('SILENT', ['-', '/'], True);
end;

class function TRickWinServiceCommandLine.IsDesktopMode: Boolean;
begin
  Result := Command = TRickWinServiceCommand.Desktop;
end;

class function TRickWinServiceCommandLine.ExitCodeForException(
  AException: Exception): Integer;
begin
  if AException is ERickWinServiceAdministratorRequired then
    Exit(RICK_WINSERVICE_EXIT_ADMIN_REQUIRED);

  if AException is ERickWinServiceException then
    Exit(RICK_WINSERVICE_EXIT_OPERATION_ERROR);

  Result := RICK_WINSERVICE_EXIT_UNEXPECTED_ERROR;
end;

end.
