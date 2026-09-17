program RickWinService.SCM.Restart.TestHost;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.WinSvc,
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

  TEST_EXIT_INSTALL_STATE_UNEXPECTED = 900;
  TEST_EXIT_START_STATE_UNEXPECTED = 910;
  TEST_EXIT_INITIAL_PID_UNAVAILABLE = 920;

  TEST_EXIT_RESTART_STATE_UNEXPECTED = 930;
  TEST_EXIT_RESTARTED_PID_UNAVAILABLE = 940;
  TEST_EXIT_PID_DID_NOT_CHANGE = 950;

  TEST_EXIT_STOP_STATE_UNEXPECTED = 960;
  TEST_EXIT_STILL_INSTALLED = 970;
  TEST_EXIT_FINAL_STATE_UNEXPECTED = 980;

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

function QueryServiceProcessId: Cardinal;
var
  LScm: SC_HANDLE;
  LService: SC_HANDLE;
  LStatus: SERVICE_STATUS_PROCESS;
  LBytesNeeded: DWORD;
begin
  Result := 0;
  LScm := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if LScm = 0 then
    Exit;

  try
    LService := OpenService(
      LScm,
      PChar(TEST_SERVICE_NAME),
      SERVICE_QUERY_STATUS
    );
    if LService = 0 then
      Exit;

    try
      ZeroMemory(@LStatus, SizeOf(LStatus));
      LBytesNeeded := 0;

      if QueryServiceStatusEx(
        LService,
        SC_STATUS_PROCESS_INFO,
        PByte(@LStatus),
        SizeOf(LStatus),
        LBytesNeeded
      ) then
        Result := LStatus.dwProcessId;
    finally
      CloseServiceHandle(LService);
    end;
  finally
    CloseServiceHandle(LScm);
  end;
end;

function ValidateState(
  AExpectedState: TRickWinServiceState;
  AErrorCode: Integer
): Integer;
begin
  if TRickWinServiceManager.GetServiceState(TEST_SERVICE_NAME) <>
    AExpectedState then
    Exit(AErrorCode);

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
    // Cleanup defensivo.
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
      // Cleanup defensivo.
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

function InstallAndStart(
  const AInstaller: TRickWinServiceInstaller;
  const AService: IRickWinService
): Integer;
begin
  AInstaller.Install;

  Result := ValidateState(
    TRickWinServiceState.Stopped,
    TEST_EXIT_INSTALL_STATE_UNEXPECTED
  );
  if Result <> TEST_EXIT_SUCCESS then
    Exit;

  AService.Start;

  Result := ValidateState(
    TRickWinServiceState.Running,
    TEST_EXIT_START_STATE_UNEXPECTED
  );
end;

function RestartAndValidate(
  const AService: IRickWinService;
  AInitialPid: Cardinal
): Integer;
var
  LRestartedPid: Cardinal;
begin
  AService.Restart;

  Result := ValidateState(
    TRickWinServiceState.Running,
    TEST_EXIT_RESTART_STATE_UNEXPECTED
  );
  if Result <> TEST_EXIT_SUCCESS then
    Exit;

  LRestartedPid := QueryServiceProcessId;
  if LRestartedPid = 0 then
    Exit(TEST_EXIT_RESTARTED_PID_UNAVAILABLE);

  if LRestartedPid = AInitialPid then
    Exit(TEST_EXIT_PID_DID_NOT_CHANGE);

  Result := TEST_EXIT_SUCCESS;
end;

function StopAndUninstall(
  const AInstaller: TRickWinServiceInstaller;
  const AService: IRickWinService
): Integer;
begin
  AService.Stop;

  Result := ValidateState(
    TRickWinServiceState.Stopped,
    TEST_EXIT_STOP_STATE_UNEXPECTED
  );
  if Result <> TEST_EXIT_SUCCESS then
    Exit;

  AInstaller.Uninstall;

  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_STILL_INSTALLED);

  Result := ValidateState(
    TRickWinServiceState.NotInstalled,
    TEST_EXIT_FINAL_STATE_UNEXPECTED
  );
end;

function ExecuteRestartRoundTrip: Integer;
var
  LInstaller: TRickWinServiceInstaller;
  LService: IRickWinService;
  LInitialPid: Cardinal;
begin
  if not TRickWinServiceSecurity.IsRunningAsAdministrator then
    Exit(TEST_EXIT_ADMIN_REQUIRED);

  if not FileExists(ServiceHostPath) then
    Exit(TEST_EXIT_SERVICE_HOST_NOT_FOUND);

  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_SERVICE_ALREADY_EXISTS);

  LInstaller := CreateInstaller;
  try
    LService := CreateServiceModel;

    Result := InstallAndStart(LInstaller, LService);
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    LInitialPid := QueryServiceProcessId;
    if LInitialPid = 0 then
      Exit(TEST_EXIT_INITIAL_PID_UNAVAILABLE);

    Result := RestartAndValidate(LService, LInitialPid);
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    Result := StopAndUninstall(LInstaller, LService);
  finally
    LInstaller.Free;
  end;
end;

function Execute: Integer;
begin
  Result := TEST_EXIT_UNEXPECTED_ERROR;
  try
    Result := ExecuteRestartRoundTrip;
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
