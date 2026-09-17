unit Rick.WinService.Tests.Model;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Rick.WinService.Interfaces,
  Rick.WinService.Model;

type
  [TestFixture]
  TRickWinServiceModelTests = class
  public
    [Test]
    procedure New_ShouldReturnServiceInstance;

    [Test]
    procedure New_ShouldInitializeServiceNameAsEmpty;

    [Test]
    procedure New_ShouldInitializeExeNameWithCurrentModule;

    [Test]
    procedure ServiceName_ShouldPreserveConfiguredValue;

    [Test]
    procedure ExeName_ShouldPreserveConfiguredValue;

    [Test]
    procedure FluentConfiguration_ShouldPreserveBothValues;
  end;

implementation

procedure TRickWinServiceModelTests.New_ShouldReturnServiceInstance;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New;

  Assert.IsTrue(Assigned(LService));
end;

procedure TRickWinServiceModelTests.New_ShouldInitializeServiceNameAsEmpty;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New;

  Assert.AreEqual(EmptyStr, LService.ServiceName);
end;

procedure TRickWinServiceModelTests.New_ShouldInitializeExeNameWithCurrentModule;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New;

  Assert.AreEqual(GetModuleName(HInstance), LService.ExeName);
end;

procedure TRickWinServiceModelTests.ServiceName_ShouldPreserveConfiguredValue;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New;

  LService.ServiceName('RickWinServiceTest');

  Assert.AreEqual('RickWinServiceTest', LService.ServiceName);
end;

procedure TRickWinServiceModelTests.ExeName_ShouldPreserveConfiguredValue;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New;

  LService.ExeName('C:\Tests\RickWinServiceTest.exe');

  Assert.AreEqual(
    'C:\Tests\RickWinServiceTest.exe',
    LService.ExeName
  );
end;

procedure TRickWinServiceModelTests.FluentConfiguration_ShouldPreserveBothValues;
var
  LService: IRickWinService;
begin
  LService := TRickWinServiceModel.New
    .ServiceName('RickWinServiceTest')
    .ExeName('C:\Tests\RickWinServiceTest.exe');

  Assert.AreEqual('RickWinServiceTest', LService.ServiceName);
  Assert.AreEqual(
    'C:\Tests\RickWinServiceTest.exe',
    LService.ExeName
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceModelTests);

end.
