unit MainFormU;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation,
  Redis.Commons, // Interfaces and types
  Redis.Client, // The client itself
  Redis.NetLib.INDY, // The tcp library used
  Redis.Values, FMX.Edit, FMX.Layouts, FMX.ListBox; // nullable types for redis commands

type
  TMainForm = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    Button1: TButton;
    ListBox1: TListBox;
    procedure Button1Click(Sender: TObject);
  private
    procedure Log(const Value: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}


procedure TMainForm.Button1Click(Sender: TObject);
var
  lRedis: IRedisClient;
  lValue: TRedisString;
begin
  lRedis := TRedisClient.Create('192.168.1.109', 6379);
  lRedis.Connect;
  lRedis.&SET('firstname', 'Daniele');
  lValue := lRedis.GET('firstname');
  if not lValue.IsNull then
    Log('KEY FOUND! key "firstname" => ' + lValue.Value);
  Log('deleting firstname...');
  lRedis.DEL(['firstname']); // remove the key
  lValue := lRedis.GET('firstname');
  if lValue.IsNull then
    Log('Key "firstname" doesn''t exist (it''s correct!)')
  else
    Log(lValue.Value); // never printed
end;

procedure TMainForm.Log(const Value: string);
begin
  ListBox1.Items.Add(Value);
end;

end.
