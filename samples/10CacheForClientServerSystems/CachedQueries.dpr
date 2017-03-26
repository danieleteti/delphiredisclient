// JCL_DEBUG_EXPERT_INSERTJDBG OFF
program CachedQueries;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form2},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Tablet Light');
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
