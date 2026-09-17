program RickWinService.Security.TestHost;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Rick.WinService,
  Rick.WinService.Exceptions,
  Rick.WinService.Security;

const
  TEST_EXIT_NOT_ELEVATED = 100;
  TEST_EXIT_ELEVATED = 200;

  TEST_EXIT_FACADE_MISMATCH = 900;
  TEST_EXIT_REQUIRE_DID_NOT_RAISE = 910;
  TEST_EXIT_WRONG_EXCEPTION = 920;
  TEST_EXIT_WRONG_OPERATION = 930;
  TEST_EXIT_REQUIRE_FAILED_WHEN_ELEVATED = 940;
  TEST_EXIT_UNEXPECTED_ERROR = 990;

  TEST_OPERATION = 'validar privilégios administrativos';

function ValidateNonElevated: Integer;
begin
  try
    TRickWinServiceSecurity.RequireAdministrator(TEST_OPERATION);
    Result := TEST_EXIT_REQUIRE_DID_NOT_RAISE;
  except
    on E: ERickWinServiceAdministratorRequired do
    begin
      if E.Operation <> TEST_OPERATION then
        Exit(TEST_EXIT_WRONG_OPERATION);

      Result := TEST_EXIT_NOT_ELEVATED;
    end;

    on ERickWinServiceSecurityException do
      Result := TEST_EXIT_WRONG_EXCEPTION;

    on Exception do
      Result := TEST_EXIT_WRONG_EXCEPTION;
  end;
end;

function ValidateElevated: Integer;
begin
  try
    TRickWinServiceSecurity.RequireAdministrator(TEST_OPERATION);
    Result := TEST_EXIT_ELEVATED;
  except
    on Exception do
      Result := TEST_EXIT_REQUIRE_FAILED_WHEN_ELEVATED;
  end;
end;

function Execute: Integer;
var
  LSecurityResult: Boolean;
  LFacadeResult: Boolean;
begin
  LSecurityResult :=
    TRickWinServiceSecurity.IsRunningAsAdministrator;

  LFacadeResult := IsRunningAsAdministrator;

  if LSecurityResult <> LFacadeResult then
    Exit(TEST_EXIT_FACADE_MISMATCH);

  if LSecurityResult then
    Result := ValidateElevated
  else
    Result := ValidateNonElevated;
end;

begin
  try
    Halt(Execute);
  except
    Halt(TEST_EXIT_UNEXPECTED_ERROR);
  end;
end.
