unit Rick.WinService.Tests.CommandLine;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Rick.WinService.CommandLine,
  Rick.WinService.Exceptions;

type
  [TestFixture]
  TRickWinServiceCommandLineTests = class
  public
    [Test]
    procedure ExitCodeConstants_ShouldPreservePublicContract;

    [Test]
    procedure AdministratorRequired_ShouldReturnAdminRequiredExitCode;

    [Test]
    procedure FrameworkException_ShouldReturnOperationErrorExitCode;

    [Test]
    procedure UnexpectedException_ShouldReturnUnexpectedErrorExitCode;
  end;

implementation

procedure TRickWinServiceCommandLineTests.
  ExitCodeConstants_ShouldPreservePublicContract;
begin
  Assert.AreEqual(0, RICK_WINSERVICE_EXIT_SUCCESS);
  Assert.AreEqual(10, RICK_WINSERVICE_EXIT_ADMIN_REQUIRED);
  Assert.AreEqual(20, RICK_WINSERVICE_EXIT_OPERATION_ERROR);
  Assert.AreEqual(99, RICK_WINSERVICE_EXIT_UNEXPECTED_ERROR);
end;

procedure TRickWinServiceCommandLineTests.
  AdministratorRequired_ShouldReturnAdminRequiredExitCode;
var
  LException: Exception;
begin
  LException := ERickWinServiceAdministratorRequired.Create(
    'instalar o serviço'
  );
  try
    Assert.AreEqual(
      RICK_WINSERVICE_EXIT_ADMIN_REQUIRED,
      TRickWinServiceCommandLine.ExitCodeForException(LException)
    );
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceCommandLineTests.
  FrameworkException_ShouldReturnOperationErrorExitCode;
var
  LException: Exception;
begin
  LException := ERickWinServiceException.Create(
    'Falha controlada de teste'
  );
  try
    Assert.AreEqual(
      RICK_WINSERVICE_EXIT_OPERATION_ERROR,
      TRickWinServiceCommandLine.ExitCodeForException(LException)
    );
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceCommandLineTests.
  UnexpectedException_ShouldReturnUnexpectedErrorExitCode;
var
  LException: Exception;
begin
  LException := Exception.Create(
    'Falha inesperada de teste'
  );
  try
    Assert.AreEqual(
      RICK_WINSERVICE_EXIT_UNEXPECTED_ERROR,
      TRickWinServiceCommandLine.ExitCodeForException(LException)
    );
  finally
    LException.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceCommandLineTests);

end.
