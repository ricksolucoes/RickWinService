unit Rick.WinService.Tests.SCM.Process;


interface

uses
  DUnitX.TestFramework, Winapi.Windows;

type
  [TestFixture]
  TRickWinServiceScmProcessTests = class
  private const
    TEST_EXIT_SUCCESS = 100;
    QUERY_HOST_TIMEOUT_MS = 30000;
    MUTATING_HOST_TIMEOUT_MS = 180000;
    TERMINATION_WAIT_MS = 5000;
  private
    function OutputDirectory: string;
    function HostPath(const AFileName: string): string;
    procedure CreateHostProcess(
      const AFileName: string;
      out AProcessInfo: TProcessInformation
    );
    procedure WaitForHost(
      const AFileName: string;
      const AProcessHandle: THandle;
      const ATimeout: Cardinal
    );
    function ReadExitCode(
      const AProcessHandle: THandle
    ): Cardinal;
    function ExecuteHost(
      const AFileName: string;
      const ATimeout: Cardinal
    ): Cardinal;
    procedure AssertHostSuccess(
      const AFileName: string;
      const ATimeout: Cardinal
    );
    procedure RequireElevatedRunner;
  public
    [Test]
    procedure QueryHost_ShouldValidateRealScmReadOnly;

    [Test]
    procedure InstallRoundTripHost_ShouldInstallAndUninstallRealService;

    [Test]
    procedure LifecycleHost_ShouldStartAndStopRealService;

    [Test]
    procedure RestartHost_ShouldRestartWithNewProcess;
  end;

implementation

uses
  System.SysUtils,
  Rick.WinService.Security;

function TRickWinServiceScmProcessTests.OutputDirectory: string;
begin
  Result := ExtractFilePath(GetModuleName(HInstance));
end;

function TRickWinServiceScmProcessTests.HostPath(
  const AFileName: string
): string;
begin
  Result := IncludeTrailingPathDelimiter(OutputDirectory) + AFileName;
end;

procedure TRickWinServiceScmProcessTests.CreateHostProcess(
  const AFileName: string;
  out AProcessInfo: TProcessInformation
);
var
  LStartupInfo: TStartupInfo;
  LCommandLine: string;
  LHostPath: string;
  LWorkingDirectory: string;
begin
  LHostPath := HostPath(AFileName);

  Assert.IsTrue(
    FileExists(LHostPath),
    Format('Test host não encontrado: %s', [LHostPath])
  );

  ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
  LStartupInfo.cb := SizeOf(LStartupInfo);
  ZeroMemory(@AProcessInfo, SizeOf(AProcessInfo));

  LWorkingDirectory := OutputDirectory;
  LCommandLine := '"' + LHostPath + '"';
  UniqueString(LCommandLine);

  if not CreateProcess(
    nil,
    PChar(LCommandLine),
    nil,
    nil,
    False,
    0,
    nil,
    PChar(LWorkingDirectory),
    LStartupInfo,
    AProcessInfo
  ) then
    RaiseLastOSError;
end;

procedure TRickWinServiceScmProcessTests.WaitForHost(
  const AFileName: string;
  const AProcessHandle: THandle;
  const ATimeout: Cardinal
);
var
  LWaitResult: Cardinal;
begin
  LWaitResult := WaitForSingleObject(AProcessHandle, ATimeout);

  if LWaitResult = WAIT_TIMEOUT then
  begin
    TerminateProcess(AProcessHandle, 1);
    WaitForSingleObject(AProcessHandle, TERMINATION_WAIT_MS);

    Assert.Fail(
      Format('Timeout aguardando o test host: %s', [AFileName])
    );
  end;

  Assert.AreEqual<Cardinal>(
    WAIT_OBJECT_0,
    LWaitResult,
    Format(
      'Falha aguardando o test host %s. WaitResult=%d',
      [AFileName, LWaitResult]
    )
  );
end;

function TRickWinServiceScmProcessTests.ReadExitCode(
  const AProcessHandle: THandle
): Cardinal;
begin
  if not GetExitCodeProcess(AProcessHandle, Result) then
    RaiseLastOSError;
end;

function TRickWinServiceScmProcessTests.ExecuteHost(
  const AFileName: string;
  const ATimeout: Cardinal
): Cardinal;
var
  LProcessInfo: TProcessInformation;
begin
  CreateHostProcess(AFileName, LProcessInfo);
  try
    WaitForHost(AFileName, LProcessInfo.hProcess, ATimeout);
    Result := ReadExitCode(LProcessInfo.hProcess);
  finally
    CloseHandle(LProcessInfo.hThread);
    CloseHandle(LProcessInfo.hProcess);
  end;
end;

procedure TRickWinServiceScmProcessTests.AssertHostSuccess(
  const AFileName: string;
  const ATimeout: Cardinal
);
var
  LExitCode: Cardinal;
begin
  LExitCode := ExecuteHost(AFileName, ATimeout);

  Assert.AreEqual<Cardinal>(
    TEST_EXIT_SUCCESS,
    LExitCode,
    Format(
      '%s retornou ExitCode inesperado: %d',
      [AFileName, LExitCode]
    )
  );
end;

procedure TRickWinServiceScmProcessTests.RequireElevatedRunner;
begin
  Assert.IsTrue(
    TRickWinServiceSecurity.IsRunningAsAdministrator,
    'Execute o runner DUnitX como Administrador para os testes SCM mutáveis.'
  );
end;

procedure TRickWinServiceScmProcessTests.QueryHost_ShouldValidateRealScmReadOnly;
begin
  AssertHostSuccess(
    'RickWinService.Scm.Query.TestHost.exe',
    QUERY_HOST_TIMEOUT_MS
  );
end;

procedure TRickWinServiceScmProcessTests.InstallRoundTripHost_ShouldInstallAndUninstallRealService;
begin
  RequireElevatedRunner;
  AssertHostSuccess(
    'RickWinService.Scm.InstallRoundTrip.TestHost.exe',
    MUTATING_HOST_TIMEOUT_MS
  );
end;

procedure TRickWinServiceScmProcessTests.LifecycleHost_ShouldStartAndStopRealService;
begin
  RequireElevatedRunner;
  AssertHostSuccess(
    'RickWinService.Scm.Lifecycle.TestHost.exe',
    MUTATING_HOST_TIMEOUT_MS
  );
end;

procedure TRickWinServiceScmProcessTests.RestartHost_ShouldRestartWithNewProcess;
begin
  RequireElevatedRunner;
  AssertHostSuccess(
    'RickWinService.Scm.Restart.TestHost.exe',
    MUTATING_HOST_TIMEOUT_MS
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceScmProcessTests);

end.

