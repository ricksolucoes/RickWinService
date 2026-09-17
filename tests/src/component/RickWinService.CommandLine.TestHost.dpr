program RickWinService.CommandLine.TestHost;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Rick.WinService.CommandLine;

const
  TEST_EXIT_DESKTOP = 100;
  TEST_EXIT_DESKTOP_SILENT = 110;
  TEST_EXIT_INSTALL = 200;
  TEST_EXIT_INSTALL_SILENT = 210;
  TEST_EXIT_UNINSTALL = 300;
  TEST_EXIT_UNINSTALL_SILENT = 310;
  TEST_EXIT_RUNSERVICE = 400;
  TEST_EXIT_RUNSERVICE_SILENT = 410;

  TEST_EXIT_DESKTOP_MODE_INCONSISTENT = 900;
  TEST_EXIT_UNEXPECTED_ERROR = 990;

function ExitCodeForCommand(
  ACommand: TRickWinServiceCommand;
  ASilent: Boolean
): Integer;
begin
  case ACommand of
    TRickWinServiceCommand.Desktop:
      Result := TEST_EXIT_DESKTOP;
    TRickWinServiceCommand.Install:
      Result := TEST_EXIT_INSTALL;
    TRickWinServiceCommand.Uninstall:
      Result := TEST_EXIT_UNINSTALL;
    TRickWinServiceCommand.RunService:
      Result := TEST_EXIT_RUNSERVICE;
  else
    Exit(TEST_EXIT_UNEXPECTED_ERROR);
  end;

  if ASilent then
    Inc(Result, 10);
end;

function Execute: Integer;
var
  LCommand: TRickWinServiceCommand;
  LIsDesktopMode: Boolean;
  LIsSilent: Boolean;
begin
  LCommand := TRickWinServiceCommandLine.Command;
  LIsSilent := TRickWinServiceCommandLine.IsSilent;
  LIsDesktopMode := TRickWinServiceCommandLine.IsDesktopMode;

  if LIsDesktopMode <> (LCommand = TRickWinServiceCommand.Desktop) then
    Exit(TEST_EXIT_DESKTOP_MODE_INCONSISTENT);

  Result := ExitCodeForCommand(LCommand, LIsSilent);
end;

begin
  try
    Halt(Execute);
  except
    Halt(TEST_EXIT_UNEXPECTED_ERROR);
  end;
end.
