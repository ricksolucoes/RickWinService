unit Rick.WinService.Tests.CommandLine.Process;

interface

uses
  System.SysUtils,
  Winapi.Windows,
  DUnitX.TestFramework;

type
  [TestFixture]
  TRickWinServiceCommandLineProcessTests = class
  private
    function TestHostPath: string;
    function BuildCommandLine(const AArguments: string): string;
    procedure CreateHostProcess(
      const AArguments: string;
      out AProcessInfo: TProcessInformation
    );
    procedure WaitForHost(const AProcessInfo: TProcessInformation);
    function ReadExitCode(
      const AProcessInfo: TProcessInformation
    ): Cardinal;
    function ExecuteTestHost(const AArguments: string): Cardinal;
    procedure AssertHostExitCode(
      const AArguments: string;
      AExpectedExitCode: Cardinal
    );
  public
    [Test]
    procedure Desktop_NoArguments_ShouldReturn100;

    [Test]
    procedure Desktop_Silent_ShouldReturn110;

    [Test]
    procedure Install_ShouldReturn200;

    [Test]
    procedure Install_Silent_ShouldReturn210;

    [Test]
    procedure Uninstall_ShouldReturn300;

    [Test]
    procedure Uninstall_Silent_ShouldReturn310;

    [Test]
    procedure RunService_ShouldReturn400;

    [Test]
    procedure RunService_Silent_ShouldReturn410;

    [Test]
    procedure Install_ShouldHavePriorityOverOtherCommands;

    [Test]
    procedure Uninstall_ShouldHavePriorityOverRunService;

    [Test]
    procedure Install_DashPrefix_ShouldReturn200;

    [Test]
    procedure Install_ShouldBeCaseInsensitive;

    [Test]
    procedure Uninstall_DashPrefix_ShouldReturn300;

    [Test]
    procedure Uninstall_ShouldBeCaseInsensitive;

    [Test]
    procedure RunService_SlashPrefix_ShouldReturn400;

    [Test]
    procedure RunService_ShouldBeCaseInsensitive;

    [Test]
    procedure Silent_DashPrefix_ShouldReturn110;

    [Test]
    procedure Silent_ShouldBeCaseInsensitive;

    [Test]
    procedure UnknownSwitch_ShouldRemainDesktop;
  end;

implementation

const
  TEST_HOST_EXE = 'RickWinService.CommandLine.TestHost.exe';
  TEST_HOST_TIMEOUT_MS = 10000;

  TEST_EXIT_DESKTOP = 100;
  TEST_EXIT_DESKTOP_SILENT = 110;
  TEST_EXIT_INSTALL = 200;
  TEST_EXIT_INSTALL_SILENT = 210;
  TEST_EXIT_UNINSTALL = 300;
  TEST_EXIT_UNINSTALL_SILENT = 310;
  TEST_EXIT_RUNSERVICE = 400;
  TEST_EXIT_RUNSERVICE_SILENT = 410;

function TRickWinServiceCommandLineProcessTests.TestHostPath: string;
begin
  Result := IncludeTrailingPathDelimiter(
    ExtractFilePath(ParamStr(0))
  ) + TEST_HOST_EXE;
end;

function TRickWinServiceCommandLineProcessTests.BuildCommandLine(
  const AArguments: string
): string;
begin
  Result := '"' + TestHostPath + '"';

  if AArguments <> EmptyStr then
    Result := Result + ' ' + AArguments;
end;

procedure TRickWinServiceCommandLineProcessTests.CreateHostProcess(
  const AArguments: string;
  out AProcessInfo: TProcessInformation
);
var
  LStartupInfo: TStartupInfo;
  LCommandLine: string;
begin
  ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
  LStartupInfo.cb := SizeOf(LStartupInfo);
  ZeroMemory(@AProcessInfo, SizeOf(AProcessInfo));

  LCommandLine := BuildCommandLine(AArguments);
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
      'Não foi possível iniciar o Test Host. Win32Error=%d',
      [GetLastError]
    )
  );
end;

procedure TRickWinServiceCommandLineProcessTests.WaitForHost(
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
        'Test Host excedeu o timeout de %d ms.',
        [TEST_HOST_TIMEOUT_MS]
      )
    );
  end;

  Assert.AreEqual(
    Cardinal(WAIT_OBJECT_0),
    LWaitResult,
    'Falha ao aguardar a finalização do Test Host.'
  );
end;

function TRickWinServiceCommandLineProcessTests.ReadExitCode(
  const AProcessInfo: TProcessInformation
): Cardinal;
begin
  Assert.IsTrue(
    GetExitCodeProcess(AProcessInfo.hProcess, Result),
    Format(
      'Não foi possível obter o ExitCode. Win32Error=%d',
      [GetLastError]
    )
  );
end;

function TRickWinServiceCommandLineProcessTests.ExecuteTestHost(
  const AArguments: string
): Cardinal;
var
  LProcessInfo: TProcessInformation;
begin
  Assert.IsTrue(
    FileExists(TestHostPath),
    Format(
      'Test Host não encontrado em "%s".',
      [TestHostPath]
    )
  );

  CreateHostProcess(AArguments, LProcessInfo);
  try
    WaitForHost(LProcessInfo);
    Result := ReadExitCode(LProcessInfo);
  finally
    CloseHandle(LProcessInfo.hThread);
    CloseHandle(LProcessInfo.hProcess);
  end;
end;

procedure TRickWinServiceCommandLineProcessTests.AssertHostExitCode(
  const AArguments: string;
  AExpectedExitCode: Cardinal
);
var
  LActualExitCode: Cardinal;
begin
  LActualExitCode := ExecuteTestHost(AArguments);

  Assert.AreEqual(
    AExpectedExitCode,
    LActualExitCode,
    Format(
      'ExitCode inesperado para os argumentos "%s".',
      [AArguments]
    )
  );
end;

procedure TRickWinServiceCommandLineProcessTests.
  Desktop_NoArguments_ShouldReturn100;
begin
  AssertHostExitCode(EmptyStr, TEST_EXIT_DESKTOP);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Desktop_Silent_ShouldReturn110;
begin
  AssertHostExitCode('/Silent', TEST_EXIT_DESKTOP_SILENT);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Install_ShouldReturn200;
begin
  AssertHostExitCode('/Install', TEST_EXIT_INSTALL);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Install_Silent_ShouldReturn210;
begin
  AssertHostExitCode('/Install /Silent', TEST_EXIT_INSTALL_SILENT);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Uninstall_ShouldReturn300;
begin
  AssertHostExitCode('/UnInstall', TEST_EXIT_UNINSTALL);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Uninstall_Silent_ShouldReturn310;
begin
  AssertHostExitCode(
    '/UnInstall /Silent',
    TEST_EXIT_UNINSTALL_SILENT
  );
end;

procedure TRickWinServiceCommandLineProcessTests.
  RunService_ShouldReturn400;
begin
  AssertHostExitCode('-RunService', TEST_EXIT_RUNSERVICE);
end;

procedure TRickWinServiceCommandLineProcessTests.
  RunService_Silent_ShouldReturn410;
begin
  AssertHostExitCode(
    '-RunService /Silent',
    TEST_EXIT_RUNSERVICE_SILENT
  );
end;

procedure TRickWinServiceCommandLineProcessTests.
  Install_ShouldHavePriorityOverOtherCommands;
begin
  AssertHostExitCode(
    '/Install /UnInstall -RunService',
    TEST_EXIT_INSTALL
  );
end;

procedure TRickWinServiceCommandLineProcessTests.
  Uninstall_ShouldHavePriorityOverRunService;
begin
  AssertHostExitCode(
    '/UnInstall -RunService',
    TEST_EXIT_UNINSTALL
  );
end;

procedure TRickWinServiceCommandLineProcessTests.
  Install_DashPrefix_ShouldReturn200;
begin
  AssertHostExitCode('-Install', TEST_EXIT_INSTALL);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Install_ShouldBeCaseInsensitive;
begin
  AssertHostExitCode('/iNsTaLl', TEST_EXIT_INSTALL);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Uninstall_DashPrefix_ShouldReturn300;
begin
  AssertHostExitCode('-UnInstall', TEST_EXIT_UNINSTALL);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Uninstall_ShouldBeCaseInsensitive;
begin
  AssertHostExitCode('/uNiNsTaLl', TEST_EXIT_UNINSTALL);
end;

procedure TRickWinServiceCommandLineProcessTests.
  RunService_SlashPrefix_ShouldReturn400;
begin
  AssertHostExitCode('/RunService', TEST_EXIT_RUNSERVICE);
end;

procedure TRickWinServiceCommandLineProcessTests.
  RunService_ShouldBeCaseInsensitive;
begin
  AssertHostExitCode('-rUnSeRvIcE', TEST_EXIT_RUNSERVICE);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Silent_DashPrefix_ShouldReturn110;
begin
  AssertHostExitCode('-Silent', TEST_EXIT_DESKTOP_SILENT);
end;

procedure TRickWinServiceCommandLineProcessTests.
  Silent_ShouldBeCaseInsensitive;
begin
  AssertHostExitCode('/sIlEnT', TEST_EXIT_DESKTOP_SILENT);
end;

procedure TRickWinServiceCommandLineProcessTests.
  UnknownSwitch_ShouldRemainDesktop;
begin
  AssertHostExitCode('/UnknownSwitch', TEST_EXIT_DESKTOP);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TRickWinServiceCommandLineProcessTests
  );

end.
