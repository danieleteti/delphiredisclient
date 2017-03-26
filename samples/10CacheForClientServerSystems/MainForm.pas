unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Redis.Client,
  Redis.netlib.INDY, Redis.Commons, Vcl.ExtCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids, System.threading, Winapi.ShellAPI,
  Vcl.ComCtrls, ShellAnimations, FireDAC.UI.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.DApt, FireDAC.Stan.StorageJSON;

type
  TForm2 = class(TForm)
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    Panel1: TPanel;
    Panel3: TPanel;
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    FRedis: IRedisClient;
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses
  rest.json, System.json, Redis.Values;

{$R *.dfm}


procedure TForm2.Button1Click(Sender: TObject);
var
  lData: TRedisString;
  lCacheKey: string;
  lStream: TStringStream;
  lFilterText: string;
begin
  lFilterText := LowerCase(Edit1.Text);
  lCacheKey := 'customers::search::' + lFilterText;
  lStream := TStringStream.Create;
  try
    lData := FRedis.GET(lCacheKey);
    if lData.HasValue then
    begin
      lStream.WriteString(lData);
      lStream.Position := 0;
      FDQuery1.LoadFromStream(lStream, sfJSON);
      Label1.Caption := 'FROM CACHE (key: ' + lCacheKey + ')';
    end
    else
    begin
      FDQuery1.Open('SELECT * FROM CUSTOMER WHERE LOWER(CUSTOMER) STARTING WITH ?', [lFilterText]);
      FDQuery1.SaveToStream(lStream, sfJSON);
      lStream.Position := 0;
      FRedis.&SET(lCacheKey, lStream.DataString, 30);
      Label1.Caption := 'QUERY EXECUTED, CACHE CREATED (key: ' + lCacheKey + ')';
    end;
  finally
    lStream.Free;
  end;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  ShellExecute(0, PChar('open'), PChar(Application.ExeName), nil, nil, SW_SHOW);
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  FRedis := NewRedisClient;
end;

end.
