// *************************************************************************** }
//
// Delphi REDIS Client
//
// Copyright (c) 2015-2017 Daniele Teti
//
// https://github.com/danieleteti/delphiredisclient
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit MainFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Redis.Client,
  Redis.netlib.INDY, Redis.Commons, Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    Memo1: TMemo;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FRedis: IRedisClient;
    FUserName: string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  rest.json, JobU, System.json, ConstantsU;

{$R *.dfm}

procedure TMainForm.Button1Click(Sender: TObject);
var
  lRedis: IRedisClient;
  lJob: TEvalJob;
  lJobString: string;
begin
  lRedis := NewRedisClient(REDIS_HOSTNAME);

  lJob := TEvalJob.Create;
  try
    lJob.ReplyTo := 'replies:' + FUserName;
    lJob.Expression := Edit1.Text;
    lJobString := TJson.ObjectToJsonString(lJob);
    lRedis.LPUSH('jobs', lJobString);
  finally
    lJob.free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  while FUserName = '' do
  begin
    FUserName := 'd.teti' + (100 + Random(999)).ToString;
    // (eg. d.teti1, d.teti2 or whatever. It is used to indicate your responses queue))
    InputQuery('Redis JobQueue Sample', 'Username', FUserName);
    FUserName := FUserName.ToLower.Trim;
  end;
  Caption := Caption + ' (Response QUEUE = ' + FUserName + ')';
  FRedis := TRedisClient.Create(REDIS_HOSTNAME);
  FRedis.Connect;
  Timer1.Enabled := true;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  lJobj: TJSONObject;
  lExpression, lRes: string;
  lResponse: string;
begin
  if FRedis.RPOP('replies:' + FUserName, lResponse) then
  begin
    lJobj := TJSONObject.ParseJSONValue(lResponse) as TJSONObject;
    try
      lExpression := lJobj.GetValue<TJSONString>('expression').Value;
      lRes := lJobj.GetValue<TJSONString>('result').Value;
      Memo1.Lines.Add(Format('Response: %s = %s', [lExpression, lRes]));
    finally
      lJobj.free;
    end;
  end;
end;

end.
