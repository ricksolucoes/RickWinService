program RickWinService.SCM.Restart.Diagnostic.TestHost;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.WinSvc,
  Rick.WinService.Exceptions,
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

  TEST_EXIT_SCM_EXCEPTION = 991;
  TEST_EXIT_TIMEOUT_EXCEPTION = 992;
  TEST_EXIT_STATE_EXCEPTION = 993;
  TEST_EXIT_OPERATION_EXCEPTION = 994;
  TEST_EXIT_UNEXPECTED_EXCEPTION = 995;

var
  GStage: string;

function ServiceStateText(
  const AState: TRickWinServiceState
): string;
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

function ExecuteRestartRoundTrip: Integer;
var
  LInstaller: TRickWinServiceInstaller;
  LService: IRickWinService;
  LInitialPid: Cardinal;
  LRestartedPid: Cardinal;
begin
  GStage := 'Validate administrator';
  if not TRickWinServiceSecurity.IsRunningAsAdministrator then
    Exit(TEST_EXIT_ADMIN_REQUIRED);

  GStage := 'Validate service host executable';
  if not FileExists(ServiceHostPath) then
    Exit(TEST_EXIT_SERVICE_HOST_NOT_FOUND);

  GStage := 'Validate service absence';
  if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
    Exit(TEST_EXIT_SERVICE_ALREADY_EXISTS);

  LInstaller := CreateInstaller;
  try
    LService := CreateServiceModel;

    GStage := 'Install';
    LInstaller.Install;

    GStage := 'Validate Stopped after Install';
    Result := ValidateState(
      TRickWinServiceState.Stopped,
      TEST_EXIT_INSTALL_STATE_UNEXPECTED
    );
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    GStage := 'Start';
    LService.Start;

    GStage := 'Validate Running after Start';
    Result := ValidateState(
      TRickWinServiceState.Running,
      TEST_EXIT_START_STATE_UNEXPECTED
    );
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    GStage := 'Read initial PID';
    LInitialPid := QueryServiceProcessId;
    if LInitialPid = 0 then
      Exit(TEST_EXIT_INITIAL_PID_UNAVAILABLE);

    WriteLn('Initial PID: ', LInitialPid);

    GStage := 'Restart';
    LService.Restart;

    GStage := 'Validate Running after Restart';
    Result := ValidateState(
      TRickWinServiceState.Running,
      TEST_EXIT_RESTART_STATE_UNEXPECTED
    );
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    GStage := 'Read restarted PID';
    LRestartedPid := QueryServiceProcessId;
    if LRestartedPid = 0 then
      Exit(TEST_EXIT_RESTARTED_PID_UNAVAILABLE);

    WriteLn('Restarted PID: ', LRestartedPid);

    if LRestartedPid = LInitialPid then
      Exit(TEST_EXIT_PID_DID_NOT_CHANGE);

    GStage := 'Stop';
    LService.Stop;

    GStage := 'Validate Stopped after Stop';
    Result := ValidateState(
      TRickWinServiceState.Stopped,
      TEST_EXIT_STOP_STATE_UNEXPECTED
    );
    if Result <> TEST_EXIT_SUCCESS then
      Exit;

    GStage := 'Uninstall';
    LInstaller.Uninstall;

    GStage := 'Validate absence after Uninstall';
    if TRickWinServiceManager.IsServiceInstalled(TEST_SERVICE_NAME) then
      Exit(TEST_EXIT_STILL_INSTALLED);

    Result := ValidateState(
      TRickWinServiceState.NotInstalled,
      TEST_EXIT_FINAL_STATE_UNEXPECTED
    );
  finally
    LInstaller.Free;
  end;
end;

procedure ReportScmException(const E: ERickWinServiceScmException);
begin
  WriteLn('Stage: ', GStage);
  WriteLn('Exception: ', E.ClassName);
  WriteLn('Message: ', E.Message);
  WriteLn('Win32ErrorCode: ', E.Win32ErrorCode);
  WriteLn('Context: ', E.Context);
  WriteLn('ServiceName: ', E.ServiceName);
end;

procedure ReportTimeoutException(
  const E: ERickWinServiceTimeoutException
);
begin
  WriteLn('Stage: ', GStage);
  WriteLn('Exception: ', E.ClassName);
  WriteLn('Message: ', E.Message);
  WriteLn('ExpectedState: ', ServiceStateText(E.ExpectedState));
  WriteLn('CurrentState: ', ServiceStateText(E.CurrentState));
  WriteLn('ServiceWin32ExitCode: ', E.ServiceWin32ExitCode);
  WriteLn('ServiceSpecificExitCode: ', E.ServiceSpecificExitCode);
  WriteLn('Timeout: ', E.Timeout);
end;

procedure ReportStateException(
  const E: ERickWinServiceStateException
);
begin
  WriteLn('Stage: ', GStage);
  WriteLn('Exception: ', E.ClassName);
  WriteLn('Message: ', E.Message);
  WriteLn('ExpectedState: ', ServiceStateText(E.ExpectedState));
  WriteLn('CurrentState: ', ServiceStateText(E.CurrentState));
  WriteLn('ServiceWin32ExitCode: ', E.ServiceWin32ExitCode);
  WriteLn('ServiceSpecificExitCode: ', E.ServiceSpecificExitCode);
end;

procedure ReportOperationException(
  const E: ERickWinServiceOperationException
);
begin
  WriteLn('Stage: ', GStage);
  WriteLn('Exception: ', E.ClassName);
  WriteLn('Message: ', E.Message);
  WriteLn('ServiceName: ', E.ServiceName);
end;

procedure ReportUnexpectedException(const E: Exception);
begin
  WriteLn('Stage: ', GStage);
  WriteLn('Exception: ', E.ClassName);
  WriteLn('Message: ', E.Message);
end;

function Execute: Integer;
begin
  Result := TEST_EXIT_UNEXPECTED_EXCEPTION;

  try
    try
      Result := ExecuteRestartRoundTrip;
    except
      on E: ERickWinServiceTimeoutException do
      begin
        ReportTimeoutException(E);
        Result := TEST_EXIT_TIMEOUT_EXCEPTION;
      end;

      on E: ERickWinServiceScmException do
      begin
        ReportScmException(E);
        Result := TEST_EXIT_SCM_EXCEPTION;
      end;

      on E: ERickWinServiceStateException do
      begin
        ReportStateException(E);
        Result := TEST_EXIT_STATE_EXCEPTION;
      end;

      on E: ERickWinServiceOperationException do
      begin
        ReportOperationException(E);
        Result := TEST_EXIT_OPERATION_EXCEPTION;
      end;

      on E: Exception do
      begin
        ReportUnexpectedException(E);
        Result := TEST_EXIT_UNEXPECTED_EXCEPTION;
      end;
    end;
  finally
    if Result <> TEST_EXIT_SUCCESS then
      BestEffortCleanup;
  end;
end;

begin
  Halt(Execute);
end.
