unit Rick.WinService.Tests.Setup;

interface

uses
  DUnitX.TestFramework,
  Rick.WinService.Interfaces,
  Rick.WinService.Setup;

type
  [TestFixture]
  TRickWinServiceSetupTests = class
  private
    FSetup: IRickWinServiceSetup;
  public
    [Setup]
    procedure SetUp;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure New_ShouldReturnSetupInstance;

    [Test]
    procedure ServiceName_ShouldUpdateConfiguredServiceName;

    [Test]
    procedure ServiceTitle_ShouldUpdateConfiguredServiceTitle;

    [Test]
    procedure ServiceDetail_ShouldUpdateConfiguredServiceDetail;

    [Test]
    procedure BeforeInstall_ShouldInvokeConfiguredCallback;

    [Test]
    procedure AfterInstall_ShouldInvokeConfiguredCallback;

    [Test]
    procedure BeforeUninstall_ShouldInvokeConfiguredCallback;

    [Test]
    procedure AfterUninstall_ShouldInvokeConfiguredCallback;
  end;

implementation

uses
  Rick.WinService.Service;

procedure TRickWinServiceSetupTests.SetUp;
begin
  FSetup := TRickWinServiceSetup.New;

  Rick.WinService.Service.ServiceName := '';
  Rick.WinService.Service.ServiceTitle := '';
  Rick.WinService.Service.ServiceDetail := '';

  FSetup
    .OnBeforeInstall(nil)
    .OnAfterInstall(nil)
    .OnBeforeUninstall(nil)
    .OnAfterUninstall(nil);
end;

procedure TRickWinServiceSetupTests.TearDown;
begin
  FSetup
    .OnBeforeInstall(nil)
    .OnAfterInstall(nil)
    .OnBeforeUninstall(nil)
    .OnAfterUninstall(nil);

  Rick.WinService.Service.ServiceName := '';
  Rick.WinService.Service.ServiceTitle := '';
  Rick.WinService.Service.ServiceDetail := '';

  FSetup := nil;
end;

procedure TRickWinServiceSetupTests.New_ShouldReturnSetupInstance;
begin
  Assert.IsTrue(Assigned(FSetup));
end;

procedure TRickWinServiceSetupTests.ServiceName_ShouldUpdateConfiguredServiceName;
begin
  FSetup.ServiceName('RickWinServiceTest');

  Assert.AreEqual(
    'RickWinServiceTest',
    Rick.WinService.Service.ServiceName
  );
end;

procedure TRickWinServiceSetupTests.ServiceTitle_ShouldUpdateConfiguredServiceTitle;
begin
  FSetup.ServiceTitle('Rick WinService Test');

  Assert.AreEqual(
    'Rick WinService Test',
    Rick.WinService.Service.ServiceTitle
  );
end;

procedure TRickWinServiceSetupTests.ServiceDetail_ShouldUpdateConfiguredServiceDetail;
begin
  FSetup.ServiceDetail('Descrição do serviço de teste');

  Assert.AreEqual(
    'Descrição do serviço de teste',
    Rick.WinService.Service.ServiceDetail
  );
end;

procedure TRickWinServiceSetupTests.BeforeInstall_ShouldInvokeConfiguredCallback;
var
  LCalls: Integer;
begin
  LCalls := 0;

  FSetup.OnBeforeInstall(
    procedure
    begin
      Inc(LCalls);
    end
  );

  ExecuteBeforeInstallCallback;

  Assert.AreEqual(1, LCalls);
end;

procedure TRickWinServiceSetupTests.AfterInstall_ShouldInvokeConfiguredCallback;
var
  LCalls: Integer;
begin
  LCalls := 0;

  FSetup.OnAfterInstall(
    procedure
    begin
      Inc(LCalls);
    end
  );

  ExecuteAfterInstallCallback;

  Assert.AreEqual(1, LCalls);
end;

procedure TRickWinServiceSetupTests.BeforeUninstall_ShouldInvokeConfiguredCallback;
var
  LCalls: Integer;
begin
  LCalls := 0;

  FSetup.OnBeforeUninstall(
    procedure
    begin
      Inc(LCalls);
    end
  );

  ExecuteBeforeUninstallCallback;

  Assert.AreEqual(1, LCalls);
end;

procedure TRickWinServiceSetupTests.AfterUninstall_ShouldInvokeConfiguredCallback;
var
  LCalls: Integer;
begin
  LCalls := 0;

  FSetup.OnAfterUninstall(
    procedure
    begin
      Inc(LCalls);
    end
  );

  ExecuteAfterUninstallCallback;

  Assert.AreEqual(1, LCalls);
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceSetupTests);

end.
