program TheApplication;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {MainForm},
  JobU in '..\Commons\JobU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
