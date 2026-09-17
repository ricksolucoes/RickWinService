program RickWinService.Integration.ServiceHost;

uses
  Rick.WinService;

{$R *.res}

const
  TEST_SERVICE_NAME =
    'RickWinService_IntegrationTest_Lifecycle_4A69B3C2';
  TEST_SERVICE_TITLE =
    'Rick WinService Integration Lifecycle Test';
  TEST_SERVICE_DETAIL =
    'Temporary service used only by RickWinService lifecycle integration tests.';

begin
  WinServiceSetup
    .ServiceName(TEST_SERVICE_NAME)
    .ServiceTitle(TEST_SERVICE_TITLE)
    .ServiceDetail(TEST_SERVICE_DETAIL);

  if WinServiceSetup.RunAsService then
    Exit;
end.
