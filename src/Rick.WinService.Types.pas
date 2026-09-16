unit Rick.WinService.Types;
(*
  ==============================================================================
  Unit: Rick.WinService.Types
  ==============================================================================

  RESPONSABILIDADE

  Declara os tipos públicos utilizados pelo Rick WinService, sem nenhuma
  interface, classe ou lógica de execução.

  Esta unit reúne:

  - TRickWinServiceState e TInstallType, anteriormente declarados em
    Rick.WinService.Model.Interfaces;
  - TRickApplicationFramework e TOnRickWinServiceEvent, anteriormente
    declarados em Rick.WinService.Setup.Interfaces.

  ------------------------------------------------------------------------------

  ESTADO DO SERVIÇO

  TRickWinServiceState representa os estados relevantes do Service Control
  Manager sem expor constantes SERVICE_* diretamente para a interface gráfica.

  O estado NotInstalled é específico do framework e representa a ausência do
  serviço no SCM.

  ==============================================================================
*)

interface

type
{$SCOPEDENUMS ON}
  /// <summary>
  /// Estados normalizados de um serviço Windows utilizados pelo framework.
  /// </summary>
  TRickWinServiceState = (
    NotInstalled,
    Stopped,
    StartPending,
    StopPending,
    Running,
    ContinuePending,
    PausePending,
    Paused,
    Unknown
  );

  /// <summary>
  /// Define a operação do adaptador legado que executa o próprio binário para
  /// encaminhar Install/Uninstall ao CommandLine/Installer.
  /// </summary>
  TInstallType = (
    Install,
    Uninstall
  );

  /// <summary>
  /// Identifica semanticamente uma operação executada pelo framework.
  /// </summary>
  /// <remarks>
  /// O tipo é utilizado por exceções e diagnósticos estruturados para evitar
  /// interpretação de mensagens textuais pelo consumidor.
  /// </remarks>
  TRickWinServiceOperation = (
    Query,
    Install,
    Uninstall,
    Start,
    Stop,
    Restart
  );

  /// <summary>
  /// Framework visual utilizado pelo processo em modo Desktop.
  /// </summary>
  TRickApplicationFramework = (
    VCL,
    FMX
  );
{$SCOPEDENUMS OFF}

  /// <summary>
  /// Callback sem parâmetros utilizado para eventos do ciclo de vida.
  /// </summary>
  TOnRickWinServiceEvent = reference to procedure;

implementation

end.
