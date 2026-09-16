unit Rick.WinService.Interfaces;
(*
  ==============================================================================
  Unit: Rick.WinService.Interfaces
  ==============================================================================

  RESPONSABILIDADE

  Declara os contratos públicos utilizados pelo Rick WinService para
  instalação, remoção, controle e configuração de serviços Windows.

  Esta unit reúne IRickWinService (anteriormente em
  Rick.WinService.Model.Interfaces) e IRickWinServiceSetup (anteriormente em
  Rick.WinService.Setup.Interfaces). Os tipos utilizados pelos dois contratos
  residem em Rick.WinService.Types. As implementações concretas residem em
  Rick.WinService.Model e Rick.WinService.Setup.

  Esta unit não executa chamadas diretas à WinAPI. Ela define a abstração que
  será utilizada pelas camadas superiores, inclusive por uma aplicação FMX.

  ------------------------------------------------------------------------------

  CONTRATO IRickWinService

  O contrato permite:

  - definir o nome do serviço;
  - definir o executável utilizado em Install/Uninstall;
  - instalar e desinstalar;
  - iniciar, parar e reiniciar;
  - exigir privilégios administrativos para operações de alteração;
  - consultar se o serviço está instalado;
  - consultar se está efetivamente em execução;
  - consultar seu estado completo.

  A antiga função IsRunnig foi removida e substituída por IsRunning.

  Nesta implementação os métodos e GUIDs existentes do contrato são
  preservados. A nova infraestrutura de Installer, CommandLine e exceções
  tipadas foi introduzida sem alterar a assinatura de IRickWinService.

  ------------------------------------------------------------------------------

  CONTRATO IRickWinServiceSetup

  Contrato de configuração do processo Desktop/Windows Service: permite
  configurar ServiceName, ServiceTitle, ServiceDetail, os callbacks do ciclo
  de vida (Start, Stop, Pause, Continue, Create, Destroy, Shutdown,
  Before/After Install/Uninstall), criar o formulário principal (CreateForm) e
  iniciar o processo em modo serviço (RunAsService).

  ------------------------------------------------------------------------------

  SEGURANÇA DAS OPERAÇÕES

  A implementação padrão do framework exige que o processo esteja executando
  com privilégios administrativos para Install, Uninstall, Start, Stop e
  Restart.

  Quando essa pré-condição não é atendida, a implementação padrão lança
  ERickWinServiceAdministratorRequired antes de qualquer alteração no SCM. No
  caminho legado de Install/Uninstall, a validação também ocorre antes da
  criação do processo auxiliar de compatibilidade.

  A interface permanece desacoplada de qualquer tecnologia visual. O consumidor
  decide como apresentar a exceção ao usuário.

  ==============================================================================
*)

interface

uses
  System.Classes,
  System.Generics.Collections,

  Rick.WinService.Types;

type
  /// <summary>
  /// Contrato de alto nível para administração de um serviço Windows.
  /// </summary>
  IRickWinService = interface
    ['{CF698484-2DCE-439C-9D79-6EC2DCC07109}']

    /// <summary>
    /// Define o nome interno do serviço no SCM.
    /// </summary>
    function ServiceName(const Value: string): IRickWinService; overload;

    /// <summary>
    /// Retorna o nome interno configurado para o serviço.
    /// </summary>
    function ServiceName: string; overload;

    /// <summary>
    /// Retorna o executável utilizado nas operações Install/Uninstall.
    /// </summary>
    function ExeName: string; overload;

    /// <summary>
    /// Define o executável utilizado nas operações Install/Uninstall.
    /// </summary>
    function ExeName(const Value: string): IRickWinService; overload;

    /// <summary>
    /// Instala o serviço sem parâmetros adicionais.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado.
    /// </exception>
    procedure Install; overload;

    /// <summary>
    /// Instala o serviço adicionando parâmetros à linha de comando.
    /// </summary>
    /// <param name="Params">
    /// Parâmetros adicionais encaminhados ao executável durante a instalação.
    /// </param>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado.
    /// </exception>
    procedure Install(Params: TDictionary<string, string>); overload;

    /// <summary>
    /// Desinstala o serviço sem parâmetros adicionais.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado.
    /// </exception>
    procedure Uninstall; overload;

    /// <summary>
    /// Desinstala o serviço adicionando parâmetros à linha de comando.
    /// </summary>
    /// <param name="Params">
    /// Parâmetros adicionais encaminhados ao executável durante a remoção.
    /// </param>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado.
    /// </exception>
    procedure Uninstall(Params: TDictionary<string, string>); overload;

    /// <summary>
    /// Inicia o serviço e aguarda a confirmação do SCM.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado para
    /// iniciar o serviço.
    /// </exception>
    procedure Start;

    /// <summary>
    /// Para o serviço e aguarda a confirmação do SCM.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado para
    /// parar o serviço.
    /// </exception>
    procedure Stop;

    /// <summary>
    /// Para e inicia novamente o serviço.
    /// </summary>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada pela implementação padrão quando o processo não está elevado para
    /// reiniciar o serviço.
    /// </exception>
    procedure Restart;

    /// <summary>
    /// Retorna True quando o serviço está registrado no SCM.
    /// </summary>
    function IsInstalled: Boolean;

    /// <summary>
    /// Retorna True somente quando o serviço está no estado Running.
    /// </summary>
    function IsRunning: Boolean;

    /// <summary>
    /// Retorna o estado completo do serviço.
    /// </summary>
    function State: TRickWinServiceState;
  end;

  /// <summary>
  /// Contrato de configuração do processo Desktop/Windows Service.
  /// </summary>
  IRickWinServiceSetup = interface
    ['{02F69C40-E367-43FC-BEE5-E974750FD09B}']

    function ServiceName(const Value: string): IRickWinServiceSetup;
    function ServiceTitle(const Value: string): IRickWinServiceSetup;
    function ServiceDetail(const Value: string): IRickWinServiceSetup;

    function OnStart(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnStop(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnPause(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnCreate(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
    function OnContinue(Value: TOnRickWinServiceEvent): IRickWinServiceSetup;
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
  end;

implementation

end.
