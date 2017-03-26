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

unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, redis.client, redis.commons,
  redis.netlib.indy, System.threading,
  Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    Edit2: TEdit;
    Label1: TLabel;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Edit2KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    _redis: IRedisClient;
    FTask: ITask;
    FClosing: Boolean;
    procedure SendChatMessage;
    procedure OnMessage(const ANickName, AMessage: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses System.json, ShellAPI;
{$R *.dfm}


procedure TForm2.Button1Click(Sender: TObject);
begin
  ShellExecute(0, pchar('open'), pchar(Application.ExeName), nil, nil, SW_SHOW);
end;

procedure TForm2.Edit2KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    SendChatMessage;
    Key := 0;
    Edit2.Clear;
  end;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FClosing := True;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  FClosing := False;
  Label1.Caption := InputBox('Chat user name',
    'What is your user name in this chat?', 'd.teti' + (100 + Random(999))
    .ToString);
  _redis := NewRedisClient();
  FTask := TTask.Run(
    procedure
    var
      r: IRedisClient;
    begin
      r := NewRedisClient;
      r.SUBSCRIBE(['chat'],
        procedure(channel, message: string)
        var
          jobj: TJSONObject;
          msg, nickname: string;
        begin
          jobj := TJSONObject.ParseJSONValue(message) as TJSONObject;
          nickname := jobj.GetValue<TJSONString>('nickname').Value;
          msg := jobj.GetValue<TJSONString>('message').Value;
          TThread.Synchronize(nil,
            procedure
            begin
              Self.OnMessage(nickname, msg);
            end);
        end,
        function: Boolean
        begin
          Result := Assigned(Self) and (not FClosing);
        end);
    end);
end;

procedure TForm2.OnMessage(const ANickName, AMessage: string);
begin
  Memo1.Lines.Add('[' + ANickName + '] ' + DateTimeToStr(now));
  Memo1.Lines.Add(AMessage);
  Memo1.Lines.Add('---');
end;

procedure TForm2.SendChatMessage;
var
  jobj: TJSONObject;
begin
  jobj := TJSONObject.Create;
  try
    jobj.AddPair('nickname', Label1.Caption).AddPair('message', Edit2.Text);
    _redis.PUBLISH('chat', jobj.ToString);
  finally
    jobj.Free;
  end;
end;

end.
