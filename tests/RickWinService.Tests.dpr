program RickWinService.Tests;

uses
  Vcl.Forms,
  DUnitX.Loggers.GUI.VCL,
  Rick.WinService.Tests.CommandLine in 'src\units\Rick.WinService.Tests.CommandLine.pas',
  Rick.WinService.Tests.Exceptions in 'src\units\Rick.WinService.Tests.Exceptions.pas',
  Rick.WinService.Tests.Facade in 'src\units\Rick.WinService.Tests.Facade.pas',
  Rick.WinService.Tests.Model in 'src\units\Rick.WinService.Tests.Model.pas',
  Rick.WinService.Tests.Setup in 'src\units\Rick.WinService.Tests.Setup.pas',
  Rick.WinService.Tests.CommandLine.Process in 'src\units\Rick.WinService.Tests.CommandLine.Process.pas',
  Rick.WinService.Tests.Security.Process in 'src\units\Rick.WinService.Tests.Security.Process.pas',
  Rick.WinService.Tests.Service.Component in 'src\units\Rick.WinService.Tests.Service.Component.pas',
  Rick.WinService.Tests.Scm.Process in 'src\integration\Rick.WinService.Tests.Scm.Process.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
end.

