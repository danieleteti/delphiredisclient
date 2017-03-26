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


unit Redis.NetLib.Factory;

interface

uses Redis.Client, System.Generics.Collections, System.SysUtils, Redis.Command,
  Redis.Commons;

type
  // this class introduce the virtual constructor
  TRedisNetLibAdapter = class abstract(TInterfacedObject, IRedisNetLibAdapter)
    constructor Create; virtual;
  protected
    procedure Connect(const HostName: string; const Port: Word);
      virtual; abstract;
    procedure Send(const Value: string); virtual; abstract;
    procedure SendCmd(const Values: IRedisCommand); virtual; abstract;
    procedure Write(const Bytes: TBytes); virtual; abstract;
    procedure WriteCrLf(const Bytes: TBytes); virtual; abstract;
    function Receive(const Timeout: Int32): string; virtual; abstract;
    function ReceiveBytes(const ACount: Int64; const Timeout: Int32)
      : System.TArray<System.Byte>; virtual; abstract;
    procedure Disconnect; virtual; abstract;
    function LastReadWasTimedOut: boolean; virtual; abstract;
    function LibName: string; virtual;
  end;

  TRedisTCPLibClass = class of TRedisNetLibAdapter;

  TRedisNetLibFactory = class sealed
    class function Get(const LibName: string): IRedisNetLibAdapter;
    class procedure RegisterRedisTCPLib(const LibName: string;
      Clazz: TRedisTCPLibClass);
  end;

implementation

var
  RedisTCPLibraryRegistry: TDictionary<string, TRedisTCPLibClass>;

  { TLibFactory }

class function TRedisNetLibFactory.Get(const LibName: string): IRedisNetLibAdapter;
var
  Clazz: TRedisTCPLibClass;
begin
  if not RedisTCPLibraryRegistry.TryGetValue(LibName, Clazz) then
    raise Exception.Createfmt('Cannot instantiate %s TCP lib.' + sLineBreak +
      '[HINT] Did you included Redis.NetLib.%s.pas?', [LibName, LibName]);
  Result := Clazz.Create;
end;

class procedure TRedisNetLibFactory.RegisterRedisTCPLib(const LibName: string;
  Clazz: TRedisTCPLibClass);
begin
  RedisTCPLibraryRegistry.Add(LibName, Clazz);
end;

{ TRedisTCPLib }

constructor TRedisNetLibAdapter.Create;
begin
  inherited Create;
end;

function TRedisNetLibAdapter.LibName: string;
begin
  raise ERedisException.Create('This method must be overrided by the descendant classes');
end;

initialization

RedisTCPLibraryRegistry := TDictionary<string, TRedisTCPLibClass>.Create;

finalization

RedisTCPLibraryRegistry.Free;

end.
