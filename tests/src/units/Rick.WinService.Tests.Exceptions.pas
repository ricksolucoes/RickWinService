unit Rick.WinService.Tests.Exceptions;

interface

uses
  System.SysUtils,
  Winapi.Windows,
  DUnitX.TestFramework,
  Rick.WinService.Exceptions,
  Rick.WinService.Types;

type
  [TestFixture]
  TRickWinServiceExceptionsTests = class
  public
    [Test]
    procedure AdministratorRequired_ShouldTrimOperation;

    [Test]
    procedure AdministratorRequired_EmptyOperation_ShouldUseDefault;

    [Test]
    procedure OperationException_ShouldPreserveOperationAndServiceName;

    [Test]
    procedure ScmException_ShouldPreserveContextAndWin32ErrorCode;

    [Test]
    procedure StateException_ShouldPreserveStatesAndExitCodes;

    [Test]
    procedure TimeoutException_ShouldPreserveTimeoutAndStateData;
  end;

implementation

procedure TRickWinServiceExceptionsTests.AdministratorRequired_ShouldTrimOperation;
var
  LException: ERickWinServiceAdministratorRequired;
begin
  LException := ERickWinServiceAdministratorRequired.Create(
    '  instalar o serviço  '
  );
  try
    Assert.AreEqual('instalar o serviço', LException.Operation);
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceExceptionsTests.
  AdministratorRequired_EmptyOperation_ShouldUseDefault;
var
  LException: ERickWinServiceAdministratorRequired;
begin
  LException := ERickWinServiceAdministratorRequired.Create('');
  try
    Assert.AreEqual('executar esta operação', LException.Operation);
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceExceptionsTests.
  OperationException_ShouldPreserveOperationAndServiceName;
var
  LException: ERickWinServiceOperationException;
begin
  LException := ERickWinServiceOperationException.Create(
    TRickWinServiceOperation.Restart,
    'RickWinServiceTest',
    'Falha controlada de teste'
  );
  try
    Assert.AreEqual(
      Ord(TRickWinServiceOperation.Restart),
      Ord(LException.Operation)
    );
    Assert.AreEqual('RickWinServiceTest', LException.ServiceName);
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceExceptionsTests.
  ScmException_ShouldPreserveContextAndWin32ErrorCode;
var
  LException: ERickWinServiceScmException;
begin
  LException := ERickWinServiceScmException.Create(
    TRickWinServiceOperation.Start,
    'RickWinServiceTest',
    'OpenService',
    ERROR_ACCESS_DENIED
  );
  try
    Assert.AreEqual(
      Ord(TRickWinServiceOperation.Start),
      Ord(LException.Operation)
    );
    Assert.AreEqual('RickWinServiceTest', LException.ServiceName);
    Assert.AreEqual('OpenService', LException.Context);
    Assert.AreEqual(
      Integer(ERROR_ACCESS_DENIED),
      Integer(LException.Win32ErrorCode)
    );
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceExceptionsTests.
  StateException_ShouldPreserveStatesAndExitCodes;
var
  LException: ERickWinServiceStateException;
begin
  LException := ERickWinServiceStateException.Create(
    TRickWinServiceOperation.Start,
    'RickWinServiceTest',
    TRickWinServiceState.Running,
    TRickWinServiceState.Stopped,
    123,
    456
  );
  try
    Assert.AreEqual(
      Ord(TRickWinServiceOperation.Start),
      Ord(LException.Operation)
    );
    Assert.AreEqual('RickWinServiceTest', LException.ServiceName);
    Assert.AreEqual(
      Ord(TRickWinServiceState.Running),
      Ord(LException.ExpectedState)
    );
    Assert.AreEqual(
      Ord(TRickWinServiceState.Stopped),
      Ord(LException.CurrentState)
    );
    Assert.AreEqual(123, Integer(LException.ServiceWin32ExitCode));
    Assert.AreEqual(456, Integer(LException.ServiceSpecificExitCode));
  finally
    LException.Free;
  end;
end;

procedure TRickWinServiceExceptionsTests.
  TimeoutException_ShouldPreserveTimeoutAndStateData;
var
  LException: ERickWinServiceTimeoutException;
begin
  LException := ERickWinServiceTimeoutException.Create(
    TRickWinServiceOperation.Restart,
    'RickWinServiceTest',
    TRickWinServiceState.Running,
    TRickWinServiceState.StartPending,
    7,
    8,
    30000
  );
  try
    Assert.AreEqual(
      Ord(TRickWinServiceOperation.Restart),
      Ord(LException.Operation)
    );
    Assert.AreEqual('RickWinServiceTest', LException.ServiceName);
    Assert.AreEqual(
      Ord(TRickWinServiceState.Running),
      Ord(LException.ExpectedState)
    );
    Assert.AreEqual(
      Ord(TRickWinServiceState.StartPending),
      Ord(LException.CurrentState)
    );
    Assert.AreEqual(7, Integer(LException.ServiceWin32ExitCode));
    Assert.AreEqual(8, Integer(LException.ServiceSpecificExitCode));
    Assert.AreEqual(30000, Integer(LException.Timeout));
  finally
    LException.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceExceptionsTests);

end.
