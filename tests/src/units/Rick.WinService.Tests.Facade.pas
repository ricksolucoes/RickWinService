unit Rick.WinService.Tests.Facade;

interface

uses
  DUnitX.TestFramework,
  Rick.WinService,
  Rick.WinService.Interfaces,
  Rick.WinService.Types;

type
  [TestFixture]
  TRickWinServiceFacadeTests = class
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure ApplicationFramework_ShouldMatchProjectConfiguration;

    [Test]
    procedure ApplicationFrameworkName_ShouldMatchProjectConfiguration;

    [Test]
    procedure IsVCLApplication_ShouldMatchProjectConfiguration;

    [Test]
    procedure IsFMXApplication_ShouldMatchProjectConfiguration;

    [Test]
    procedure WinServiceSetup_ShouldReturnSharedInstance;
  end;

implementation

procedure TRickWinServiceFacadeTests.Setup;
begin
  RickSetup := nil;
end;

procedure TRickWinServiceFacadeTests.TearDown;
begin
  RickSetup := nil;
end;

procedure TRickWinServiceFacadeTests.
  ApplicationFramework_ShouldMatchProjectConfiguration;
begin
{$IFDEF PROJECT_FMX}
  Assert.AreEqual(
    Ord(TRickApplicationFramework.FMX),
    Ord(ApplicationFramework)
  );
{$ELSE}
  Assert.AreEqual(
    Ord(TRickApplicationFramework.VCL),
    Ord(ApplicationFramework)
  );
{$ENDIF}
end;

procedure TRickWinServiceFacadeTests.
  ApplicationFrameworkName_ShouldMatchProjectConfiguration;
begin
{$IFDEF PROJECT_FMX}
  Assert.AreEqual('FMX', ApplicationFrameworkName);
{$ELSE}
  Assert.AreEqual('VCL', ApplicationFrameworkName);
{$ENDIF}
end;

procedure TRickWinServiceFacadeTests.
  IsVCLApplication_ShouldMatchProjectConfiguration;
begin
{$IFDEF PROJECT_FMX}
  Assert.IsFalse(IsVCLApplication);
{$ELSE}
  Assert.IsTrue(IsVCLApplication);
{$ENDIF}
end;

procedure TRickWinServiceFacadeTests.
  IsFMXApplication_ShouldMatchProjectConfiguration;
begin
{$IFDEF PROJECT_FMX}
  Assert.IsTrue(IsFMXApplication);
{$ELSE}
  Assert.IsFalse(IsFMXApplication);
{$ENDIF}
end;

procedure TRickWinServiceFacadeTests.
  WinServiceSetup_ShouldReturnSharedInstance;
var
  LFirstSetup: IRickWinServiceSetup;
  LSecondSetup: IRickWinServiceSetup;
begin
  LFirstSetup := WinServiceSetup;
  LSecondSetup := WinServiceSetup;

  Assert.IsTrue(Assigned(LFirstSetup));
  Assert.IsTrue(Assigned(LSecondSetup));
  Assert.IsTrue(LFirstSetup = LSecondSetup);
end;

initialization
  TDUnitX.RegisterTestFixture(TRickWinServiceFacadeTests);

end.
