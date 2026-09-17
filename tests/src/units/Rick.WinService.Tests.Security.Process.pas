unit Rick.WinService.Tests.Security.Process;

interface

uses
  System.SysUtils,
  Winapi.Windows,
  DUnitX.TestFramework,
  Rick.WinService.Security;

type
  [TestFixture]
  TRickWinServiceSecurityProcessTests = class
  private
    function TestHostPath: string;
    function BuildCommandLine: string;
    procedure CreateHostProcess(out AProcessInfo: TProcessInformation);
    procedure WaitForHost(const AProcessInfo: TProcessInformation);
    function ReadExitCode(
      const AProcessInfo: TProcessInformation
    ): Cardinal;
    function ExecuteTestHost: Cardinal;
    function ExpectedExitCode: Cardinal;
  public
    [Test]
    procedure SecurityHost_ShouldMatchCurrentElevationState;
  end;

implementation

const
  TEST_HOST_EXE = 'RickWinService.Security.TestHost.exe';
  TEST_HOST_TIMEOUT_MS = 10000;

  TEST_EXIT_NOT_ELEVATED = 100;
  TEST_EXIT_ELEVATED = 200;

function TRickWinServiceSecurityProcessTests.TestHostPath: string;
begin
  Result := IncludeTrailingPathDelimiter(
    ExtractFilePath(ParamStr(0))
  ) + TEST_HOST_EXE;
end;

function TRickWinServiceSecurityProcessTests.BuildCommandLine: string;
begin
  Result := '"' + TestHostPath + '"';
end;

procedure TRickWinServiceSecurityProcessTests.CreateHostProcess(
  out AProcessInfo: TProcessInformation
);
var
  LStartupInfo: TStartupInfo;
  LCommandLine: string;
begin
  ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
  LStartupInfo.cb := SizeOf(LStartupInfo);
  ZeroMemory(@AProcessInfo, SizeOf(AProcessInfo));

  LCommandLine := BuildCommandLine;
  UniqueString(LCommandLine);

  Assert.IsTrue(
    CreateProcess(
      nil,
      PChar(LCommandLine),
      nil,
      nil,
      False,
      CREATE_NO_WINDOW,
      nil,
      nil,
      LStartupInfo,
      AProcessInfo
    ),
    Format(
      'Não foi possível iniciar o Security Test Host. Win32Error=%d',
      [GetLastError]
    )
  );
end;

procedure TRickWinServiceSecurityProcessTests.WaitForHost(
  const AProcessInfo: TProcessInformation
);
var
  LWaitResult: Cardinal;
begin
  LWaitResult := WaitForSingleObject(
    AProcessInfo.hProcess,
    TEST_HOST_TIMEOUT_MS
  );

  if LWaitResult = WAIT_TIMEOUT then
  begin
    TerminateProcess(AProcessInfo.hProcess, 1);
    Assert.Fail(
      Format(
        'Security Test Host excedeu o timeout de %d ms.',
        [TEST_HOST_TIMEOUT_MS]
      )
    );
  end;

  Assert.AreEqual(
    Cardinal(WAIT_OBJECT_0),
    LWaitResult,
    'Falha ao aguardar o Security Test Host.'
  );
end;

function TRickWinServiceSecurityProcessTests.ReadExitCode(
  const AProcessInfo: TProcessInformation
): Cardinal;
begin
  Assert.IsTrue(
    GetExitCodeProcess(AProcessInfo.hProcess, Result),
    Format(
      'Não foi possível obter o ExitCode do Security Test Host. '
        + 'Win32Error=%d',
      [GetLastError]
    )
  );
end;

function TRickWinServiceSecurityProcessTests.ExecuteTestHost: Cardinal;
var
  LProcessInfo: TProcessInformation;
begin
  Assert.IsTrue(
    FileExists(TestHostPath),
    Format(
      'Security Test Host não encontrado em "%s".',
      [TestHostPath]
    )
  );

  CreateHostProcess(LProcessInfo);
  try
    WaitForHost(LProcessInfo);
    Result := ReadExitCode(LProcessInfo);
  finally
    CloseHandle(LProcessInfo.hThread);
    CloseHandle(LProcessInfo.hProcess);
  end;
end;

function TRickWinServiceSecurityProcessTests.ExpectedExitCode: Cardinal;
begin
  if TRickWinServiceSecurity.IsRunningAsAdministrator then
    Result := TEST_EXIT_ELEVATED
  else
    Result := TEST_EXIT_NOT_ELEVATED;
end;

procedure TRickWinServiceSecurityProcessTests.
  SecurityHost_ShouldMatchCurrentElevationState;
var
  LActualExitCode: Cardinal;
begin
  LActualExitCode := ExecuteTestHost;

  Assert.AreEqual(
    ExpectedExitCode,
    LActualExitCode,
    'O resultado do Security Test Host diverge do token do runner.'
  );
end;

initialization
  TDUnitX.RegisterTestFixture(
    TRickWinServiceSecurityProcessTests
  );

end.
