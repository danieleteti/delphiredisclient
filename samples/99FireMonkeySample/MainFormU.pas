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
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.Edit, FMX.Layouts, FMX.ListBox,
  Redis.Commons, // Interfaces and types
  Redis.Client, // The client itself
  Redis.NetLib.INDY, // The tcp library used
  Redis.Values; // nullable types for redis commands

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

uses ConstantsU;

procedure TMainForm.Button1Click(Sender: TObject);
var
  lRedis: IRedisClient;
  lValue: TRedisString;
begin
  lRedis := TRedisClient.Create(REDIS_HOSTNAME, 6379);
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
