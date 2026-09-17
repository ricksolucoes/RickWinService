unit Rick.WinService.Tests.Service.Component;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  Rick.WinService.Service;

type
  [TestFixture]
  TRickWinServiceServiceComponentTests = class
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Create_ShouldApplyConfiguredServiceName;

    [Test]
    procedure Create_ShouldApplyConfiguredServiceTitle;

    [Test]
    procedure GetServiceController_ShouldReturnAssignedController;

    [Test]
    procedure Create_ShouldLoadServiceExecuteFromDfm;
  end;

implementation

uses
  System.SysUtils,
  Vcl.SvcMgr;

procedure TRickWinServiceServiceComponentTests.Setup;
begin
  ServiceName := EmptyStr;
  ServiceTitle := EmptyStr;
  ServiceDetail := EmptyStr;
end;

procedure TRickWinServiceServiceComponentTests.TearDown;
begin
  ServiceName := EmptyStr;
  ServiceTitle := EmptyStr;
  ServiceDetail := EmptyStr;
end;

procedure TRickWinServiceServiceComponentTests.
  Create_ShouldApplyConfiguredServiceName;
var
  LService: TRickWinService;
begin
  ServiceName := 'RickWinServiceTest';
  ServiceTitle := 'Rick WinService Test';

  LService := TRickWinService.Create(nil);
  try
    Assert.AreEqual('RickWinServiceTest', LService.Name);
  finally
    LService.Free;
  end;
end;

procedure TRickWinServiceServiceComponentTests.
  Create_ShouldApplyConfiguredServiceTitle;
var
  LService: TRickWinService;
begin
  ServiceName := 'RickWinServiceTest';
  ServiceTitle := 'Rick WinService Test';

  LService := TRickWinService.Create(nil);
  try
    Assert.AreEqual(
      'Rick WinService Test',
      LService.DisplayName
    );
  finally
    LService.Free;
  end;
end;

procedure TRickWinServiceServiceComponentTests.
  GetServiceController_ShouldReturnAssignedController;
var
  LService: TRickWinService;
  LController: TServiceController;
begin
  ServiceName := 'RickWinServiceTest';
  ServiceTitle := 'Rick WinService Test';

  LService := TRickWinService.Create(nil);
  try
    LController := LService.GetServiceController();

    Assert.IsTrue(
      Assigned(LController),
      'O ServiceController retornado não pode ser nil.'
    );
  finally
    LService.Free;
  end;
end;

procedure TRickWinServiceServiceComponentTests.
  Create_ShouldLoadServiceExecuteFromDfm;
var
  LService: TRickWinService;
  LConfiguredHandler: TServiceEvent;
  LExpectedHandler: TServiceEvent;
begin
  ServiceName := 'RickWinServiceTest';
  ServiceTitle := 'Rick WinService Test';

  LService := TRickWinService.Create(nil);
  try
    LConfiguredHandler := LService.OnExecute;
    LExpectedHandler := LService.ServiceExecute;

    Assert.IsTrue(
      Assigned(LConfiguredHandler),
      'O evento OnExecute deve estar associado pelo DFM.'
    );

    Assert.AreEqual(
      NativeInt(TMethod(LExpectedHandler).Code),
      NativeInt(TMethod(LConfiguredHandler).Code),
      'OnExecute não aponta para ServiceExecute.'
    );

    Assert.AreEqual(
      NativeInt(TMethod(LExpectedHandler).Data),
      NativeInt(TMethod(LConfiguredHandler).Data),
      'OnExecute não está associado à instância esperada.'
    );
  finally
    LService.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(
    TRickWinServiceServiceComponentTests
  );

end.
