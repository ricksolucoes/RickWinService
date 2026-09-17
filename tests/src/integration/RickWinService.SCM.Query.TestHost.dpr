program RickWinService.SCM.Query.TestHost;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Rick.WinService.Interfaces,
  Rick.WinService.Manager,
  Rick.WinService.Model,
  Rick.WinService.Types;

const
  TEST_SERVICE_NAME =
    'RickWinService_IntegrationTest_QueryOnly_4A69B3C2';

  TEST_EXIT_SUCCESS = 100;

  TEST_EXIT_MANAGER_STATE_UNEXPECTED = 900;
  TEST_EXIT_MANAGER_INSTALLED_UNEXPECTED = 910;
  TEST_EXIT_MANAGER_RUNNING_UNEXPECTED = 920;

  TEST_EXIT_MODEL_STATE_UNEXPECTED = 930;
  TEST_EXIT_MODEL_INSTALLED_UNEXPECTED = 940;
  TEST_EXIT_MODEL_RUNNING_UNEXPECTED = 950;

  TEST_EXIT_UNEXPECTED_ERROR = 990;

function ValidateManager: Integer;
begin
  if TRickWinServiceManager.GetServiceState(TEST_SERVICE_NAME) <>
    TRickWinServiceState.NotInstalled then
    Exit(TEST_EXIT_MANAGER_STATE_UNEXPECTED);

  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_MANAGER_INSTALLED_UNEXPECTED);

  if TRickWinServiceManager.IsServiceRunning(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_MANAGER_RUNNING_UNEXPECTED);

  Result := TEST_EXIT_SUCCESS;
end;

function ValidateModel: Integer;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New
    .ServiceName(TEST_SERVICE_NAME);

  if LService.State <> TRickWinServiceState.NotInstalled then
    Exit(TEST_EXIT_MODEL_STATE_UNEXPECTED);

  if LService.IsInstalled then
    Exit(TEST_EXIT_MODEL_INSTALLED_UNEXPECTED);

  if LService.IsRunning then
    Exit(TEST_EXIT_MODEL_RUNNING_UNEXPECTED);

  Result := TEST_EXIT_SUCCESS;
end;

function Execute: Integer;
begin
  Result := ValidateManager;
  if Result <> TEST_EXIT_SUCCESS then
    Exit;

  Result := ValidateModel;
end;

begin
  try
    Halt(Execute);
  except
    Halt(TEST_EXIT_UNEXPECTED_ERROR);
  end;
end.
