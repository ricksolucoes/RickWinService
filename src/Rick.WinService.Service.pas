unit Rick.WinService.Service;
(*
  ==============================================================================
  Unit: Rick.WinService.Service
  ==============================================================================

  RESPONSABILIDADE

  Implementa exclusivamente o TService utilizado quando o executável é iniciado
  pelo Windows Service Control Manager através do ImagePath configurado pelo
  Rick.WinService.Installer.

  Esta unit é responsável por:

  - representar o processo como um serviço Windows;
  - expor Name e DisplayName configurados por WinServiceSetup;
  - fornecer o ServiceController ao SCM;
  - manter o loop de processamento de mensagens do serviço em OnExecute.

  A instalação, desinstalação, descrição e configuração do Event Log não
  pertencem mais a esta unit. Essas responsabilidades residem em
  Rick.WinService.Installer.

  ------------------------------------------------------------------------------

  SERVICEEXECUTE

  ServiceExecute permanece ligado ao evento OnExecute do TService no DFM.

  Sua única responsabilidade é manter o loop de processamento das mensagens do
  SCM enquanto o serviço não estiver terminado:

    while not Terminated do
      ServiceThread.ProcessRequests(True);

  A inicialização da aplicação deve ocorrer em OnStart e sua finalização em
  OnStop/OnShutdown, configurados através de WinServiceSetup.

  ==============================================================================
*)

interface

uses
  System.Classes,
  Winapi.Windows,
  Vcl.SvcMgr;

type
  /// <summary>
  /// Serviço Windows de runtime utilizado pelo Rick WinService.
  /// </summary>
  TRickWinService = class(TService)
    /// <summary>
    /// Mantém o processamento das solicitações enviadas pelo SCM enquanto o
    /// serviço estiver ativo.
    /// </summary>
    procedure ServiceExecute(Sender: TService);
  public
    /// <summary>
    /// Inicializa Name e DisplayName com a configuração definida por
    /// WinServiceSetup.
    /// </summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>
    /// Retorna o callback utilizado pelo SCM para encaminhar códigos de controle
    /// ao TService.
    /// </summary>
    function GetServiceController: TServiceController; override;
  end;

var
  /// <summary>Instância criada quando o processo executa em modo serviço.</summary>
  RickWinServiceApp: TRickWinService;

  /// <summary>Nome interno do serviço configurado pela aplicação.</summary>
  ServiceName: string;

  /// <summary>Nome de exibição do serviço configurado pela aplicação.</summary>
  ServiceTitle: string;

  /// <summary>Descrição opcional do serviço configurada pela aplicação.</summary>
  ServiceDetail: string;

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWORD); stdcall;
begin
  RickWinServiceApp.Controller(CtrlCode);
end;

{ TRickWinService }

constructor TRickWinService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Self.Name := ServiceName;
  Self.DisplayName := ServiceTitle;
end;

function TRickWinService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TRickWinService.ServiceExecute(Sender: TService);
begin
  while not Self.Terminated do
    ServiceThread.ProcessRequests(True);
end;

end.
