unit Rick.WinService.Tests.Scm.Process;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TRickWinServiceScmProcessTests = class
  private const
    TEST_EXIT_SUCCESS = 100;
    PROCESS_TIMEOUT_MS = 60000;
  private
    function OutputDirectory: string;
    function HostPath(const AFileName: string): string;
    function ExecuteHost(const AFileName: string): Cardinal;
    procedure AssertHostSuccess(const AFileName: string);
    procedure RequireElevatedRunner;
  public
    [Test]
    procedure QueryHost_ShouldValidateRealScmReadOnly;

    [Test]
    procedure InstallRoundTripHost_ShouldInstallAndUninstallRealService;

    [Test]
    procedure LifecycleHost_ShouldStartAndStopRealService;

    [Test]
    procedure RestartDiagnosticHost_ShouldRestartWithNewProcess;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
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

function TRickWinServiceScmProcessTests.ExecuteHost(
  const AFileName: string
): Cardinal;
var
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LCommandLine: string;
  LHostPath: string;
  LWorkingDirectory: string;
  LWaitResult: Cardinal;
begin
  LHostPath := HostPath(AFileName);

  Assert.IsTrue(
    FileExists(LHostPath),
    Format('Test host não encontrado: %s', [LHostPath])
  );

  ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
  LStartupInfo.cb := SizeOf(LStartupInfo);
  ZeroMemory(@LProcessInfo, SizeOf(LProcessInfo));

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
    LProcessInfo
  ) then
    RaiseLastOSError;

  try
    LWaitResult := WaitForSingleObject(
      LProcessInfo.hProcess,
      PROCESS_TIMEOUT_MS
    );

    if LWaitResult = WAIT_TIMEOUT then
    begin
      TerminateProcess(LProcessInfo.hProcess, 1);
      WaitForSingleObject(LProcessInfo.hProcess, 5000);

      Assert.Fail(
        Format(
          'Timeout aguardando o test host: %s',
          [AFileName]
        )
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

    if not GetExitCodeProcess(LProcessInfo.hProcess, Result) then
      RaiseLastOSError;
  finally
    CloseHandle(LProcessInfo.hThread);
    CloseHandle(LProcessInfo.hProcess);
  end;
end;

procedure TRickWinServiceScmProcessTests.AssertHostSuccess(
  const AFileName: string
);
var
  LExitCode: Cardinal;
begin
  LExitCode := ExecuteHost(AFileName);

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
  AssertHostSuccess('RickWinService.Scm.Query.TestHost.exe');
end;

procedure TRickWinServiceScmProcessTests.InstallRoundTripHost_ShouldInstallAndUninstallRealService;
begin
  RequireElevatedRunner;
  AssertHostSuccess('RickWinService.Scm.InstallRoundTrip.TestHost.exe');
end;

procedure TRickWinServiceScmProcessTests.LifecycleHost_ShouldStartAndStopRealService;
begin
  RequireElevatedRunner;
  AssertHostSuccess('RickWinService.Scm.Lifecycle.TestHost.exe');
end;

procedure TRickWinServiceScmProcessTests.RestartDiagnosticHost_ShouldRestartWithNewProcess;
begin
  RequireElevatedRunner;
  AssertHostSuccess('RickWinService.Scm.Restart.Diagnostic.TestHost.exe');
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceScmProcessTests);

end.
