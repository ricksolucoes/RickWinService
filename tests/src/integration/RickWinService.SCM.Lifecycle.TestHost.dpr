program RickWinService.SCM.Lifecycle.TestHost;

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
    'RickWinService_IntegrationTest_Lifecycle_4A69B3C2';
  TEST_SERVICE_TITLE =
    'Rick WinService Integration Lifecycle Test';
  TEST_SERVICE_DETAIL =
    'Temporary service used only by RickWinService lifecycle integration tests.';
  TEST_SERVICE_HOST_EXE =
    'RickWinService.Integration.ServiceHost.exe';

  TEST_EXIT_SUCCESS = 100;
  TEST_EXIT_ADMIN_REQUIRED = 10;

  TEST_EXIT_SERVICE_ALREADY_EXISTS = 800;
  TEST_EXIT_SERVICE_HOST_NOT_FOUND = 810;

  TEST_EXIT_NOT_INSTALLED_AFTER_INSTALL = 900;
  TEST_EXIT_NOT_STOPPED_AFTER_INSTALL = 910;

  TEST_EXIT_NOT_RUNNING_AFTER_START_MANAGER = 920;
  TEST_EXIT_NOT_RUNNING_AFTER_START_MODEL = 930;

  TEST_EXIT_NOT_STOPPED_AFTER_STOP_MANAGER = 940;
  TEST_EXIT_NOT_STOPPED_AFTER_STOP_MODEL = 950;

  TEST_EXIT_STILL_INSTALLED_AFTER_UNINSTALL = 960;
  TEST_EXIT_STATE_AFTER_UNINSTALL_UNEXPECTED = 970;

  TEST_EXIT_UNEXPECTED_ERROR = 990;

function ServiceHostPath: string;
begin
  Result := IncludeTrailingPathDelimiter(
    ExtractFilePath(GetModuleName(HInstance))
  ) + TEST_SERVICE_HOST_EXE;
end;

function CreateInstaller: TRickWinServiceInstaller;
begin
  Result := TRickWinServiceInstaller.Create(
    TEST_SERVICE_NAME,
    TEST_SERVICE_TITLE,
    TEST_SERVICE_DETAIL,
    ServiceHostPath
  );
end;

function CreateServiceModel: IRickWinService;
begin
  Result := TRickWinServiceModel.New
    .ServiceName(TEST_SERVICE_NAME)
    .ExeName(ServiceHostPath);
end;

function ValidateInstalledAndStopped: Integer;
begin
  if not TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_NOT_INSTALLED_AFTER_INSTALL);

  if TRickWinServiceManager.GetServiceState(TEST_SERVICE_NAME) <>
    TRickWinServiceState.Stopped then
    Exit(TEST_EXIT_NOT_STOPPED_AFTER_INSTALL);

  Result := TEST_EXIT_SUCCESS;
end;

function ValidateRunning(const AService: IRickWinService): Integer;
begin
  if not TRickWinServiceManager.IsServiceRunning(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_NOT_RUNNING_AFTER_START_MANAGER);

  if not AService.IsRunning then
    Exit(TEST_EXIT_NOT_RUNNING_AFTER_START_MODEL);

  Result := TEST_EXIT_SUCCESS;
end;

function ValidateStopped(const AService: IRickWinService): Integer;
begin
  if TRickWinServiceManager.GetServiceState(TEST_SERVICE_NAME) <>
    TRickWinServiceState.Stopped then
    Exit(TEST_EXIT_NOT_STOPPED_AFTER_STOP_MANAGER);

  if AService.State <> TRickWinServiceState.Stopped then
    Exit(TEST_EXIT_NOT_STOPPED_AFTER_STOP_MODEL);

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

procedure BestEffortStop;
var
  LService: IRickWinService;
begin
  if not TRickWinServiceManager.IsServiceRunning(TEST_SERVICE_NAME) then
    Exit;

  LService := CreateServiceModel;
  try
    LService.Stop;
  except
    // Cleanup defensivo: preserva o resultado original do teste.
  end;
end;

procedure BestEffortUninstall;
var
  LInstaller: TRickWinServiceInstaller;
begin
  if not TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit;

  LInstaller := CreateInstaller;
  try
    try
      LInstaller.Uninstall;
    except
      // Cleanup defensivo: preserva o resultado original do teste.
    end;
  finally
    LInstaller.Free;
  end;
end;

procedure BestEffortCleanup;
begin
  BestEffortStop;
  BestEffortUninstall;
end;

function ExecuteLifecycle: Integer;
var
  LInstaller: TRickWinServiceInstaller;
  LService: IRickWinService;
begin
  if not TRickWinServiceSecurity.IsRunningAsAdministrator then
    Exit(TEST_EXIT_ADMIN_REQUIRED);

  if not FileExists(ServiceHostPath) then
    Exit(TEST_EXIT_SERVICE_HOST_NOT_FOUND);

  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_SERVICE_ALREADY_EXISTS);

  LInstaller := CreateInstaller;
  try
    LInstaller.Install;

    Result := ValidateInstalledAndStopped;
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    LService := CreateServiceModel;

    LService.Start;

    Result := ValidateRunning(LService);
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    LService.Stop;

    Result := ValidateStopped(LService);
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
    Result := ExecuteLifecycle;
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
