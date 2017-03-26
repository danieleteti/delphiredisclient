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

program CmdsSample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Redis.Commons, // Interfaces and types
  Redis.Client, // The client itself
  Redis.NetLib.INDY, // The tcp library used
  Redis.Values; // nullable types for redis commands

var
  lRedis: IRedisClient;
  lValue: TRedisString;

begin
  try
    lRedis := TRedisClient.Create;
    lRedis.Connect;
    lRedis.&SET('firstname', 'Daniele');
    lValue := lRedis.GET('firstname');
    if not lValue.IsNull then
      WriteLn('KEY FOUND! key "firstname" => ', lValue.Value);
    WriteLn('DEL firstname');
    lRedis.DEL(['firstname']); // remove the key
    lValue := lRedis.GET('firstname');
    if lValue.IsNull then
      WriteLn('Key "firstname" doesn''t exist (it''s correct!)')
    else
      WriteLn(lValue.Value); // never printed

  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
  readln; // just to keep the command prompt open

end.
