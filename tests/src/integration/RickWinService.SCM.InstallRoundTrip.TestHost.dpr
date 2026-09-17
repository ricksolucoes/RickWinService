program RickWinService.SCM.InstallRoundTrip.TestHost;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Rick.WinService.Installer,
  Rick.WinService.Interfaces,
  Rick.WinService.Manager,
  Rick.WinService.Model,
  Rick.WinService.Security,
  Rick.WinService.Types;

const
  TEST_SERVICE_NAME =
    'RickWinService_IntegrationTest_Install_4A69B3C2';
  TEST_SERVICE_TITLE =
    'Rick WinService Integration Test';
  TEST_SERVICE_DETAIL =
    'Temporary service created only by RickWinService integration tests.';

  TEST_EXIT_SUCCESS = 100;
  TEST_EXIT_ADMIN_REQUIRED = 10;

  TEST_EXIT_SERVICE_ALREADY_EXISTS = 800;

  TEST_EXIT_MANAGER_NOT_INSTALLED = 900;
  TEST_EXIT_MANAGER_STATE_UNEXPECTED = 910;
  TEST_EXIT_MANAGER_RUNNING_UNEXPECTED = 920;

  TEST_EXIT_MODEL_NOT_INSTALLED = 930;
  TEST_EXIT_MODEL_STATE_UNEXPECTED = 940;
  TEST_EXIT_MODEL_RUNNING_UNEXPECTED = 950;

  TEST_EXIT_STILL_INSTALLED_AFTER_UNINSTALL = 960;
  TEST_EXIT_STATE_AFTER_UNINSTALL_UNEXPECTED = 970;

  TEST_EXIT_UNEXPECTED_ERROR = 990;

function CreateInstaller: TRickWinServiceInstaller;
begin
  Result := TRickWinServiceInstaller.Create(
    TEST_SERVICE_NAME,
    TEST_SERVICE_TITLE,
    TEST_SERVICE_DETAIL,
    GetModuleName(HInstance)
  );
end;

function ValidateInstalledWithManager: Integer;
begin
  if not TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_MANAGER_NOT_INSTALLED);

  if TRickWinServiceManager.GetServiceState(TEST_SERVICE_NAME) <>
    TRickWinServiceState.Stopped then
    Exit(TEST_EXIT_MANAGER_STATE_UNEXPECTED);

  if TRickWinServiceManager.IsServiceRunning(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_MANAGER_RUNNING_UNEXPECTED);

  Result := TEST_EXIT_SUCCESS;
end;

function ValidateInstalledWithModel: Integer;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New
    .ServiceName(TEST_SERVICE_NAME);

  if not LService.IsInstalled then
    Exit(TEST_EXIT_MODEL_NOT_INSTALLED);

  if LService.State <> TRickWinServiceState.Stopped then
    Exit(TEST_EXIT_MODEL_STATE_UNEXPECTED);

  if LService.IsRunning then
    Exit(TEST_EXIT_MODEL_RUNNING_UNEXPECTED);

  Result := TEST_EXIT_SUCCESS;
end;

function ValidateUninstalled: Integer;
begin
  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_STILL_INSTALLED_AFTER_UNINSTALL);

  if TRickWinServiceManager.GetServiceState(TEST_SERVICE_NAME) <>
    TRickWinServiceState.NotInstalled then
    Exit(TEST_EXIT_STATE_AFTER_UNINSTALL_UNEXPECTED);

  Result := TEST_EXIT_SUCCESS;
end;

procedure BestEffortCleanup;
var
  LInstaller: TRickWinServiceInstaller;
begin
  try
    if not TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
      Exit;

    LInstaller := CreateInstaller;
    try
      try
        LInstaller.Uninstall;
      except
        // O cleanup não substitui o resultado original do teste.
      end;
    finally
      LInstaller.Free;
    end;
  except
    // O cleanup é defensivo e nunca substitui o resultado original.
  end;
end;

function ExecuteRoundTrip: Integer;
var
  LInstaller: TRickWinServiceInstaller;
begin
  if not TRickWinServiceSecurity.IsRunningAsAdministrator then
    Exit(TEST_EXIT_ADMIN_REQUIRED);

  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_SERVICE_ALREADY_EXISTS);

  LInstaller := CreateInstaller;
  try
    LInstaller.Install;

    Result := ValidateInstalledWithManager;
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    Result := ValidateInstalledWithModel;
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    LInstaller.Uninstall;

    Result := ValidateUninstalled;
  finally
    LInstaller.Free;
  end;
end;

function Execute: Integer;
begin
  Result := TEST_EXIT_UNEXPECTED_ERROR;

  try
    Result := ExecuteRoundTrip;
  finally
    if Result <> TEST_EXIT_SUCCESS then
      BestEffortCleanup;
  end;
end;

begin
  try
    Halt(Execute);
  except
    BestEffortCleanup;
    Halt(TEST_EXIT_UNEXPECTED_ERROR);
  end;
end.
