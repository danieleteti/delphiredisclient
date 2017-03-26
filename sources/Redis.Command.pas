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


unit Redis.Command;

interface

uses
  System.SysUtils, System.Generics.Collections, Redis.Commons;

type
  TRedisCommand = class(TRedisClientBase, IRedisCommand)
  private
    FCommandIsSet: Boolean;
  protected
    FParts: TList<TBytes>;

  const
    ASTERISK_BYTE: Byte = Byte('*');
    DOLLAR_BYTE: Byte = Byte('$');
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetToken(const Index: Integer): TBytes;
    procedure Clear;
    function Count: Integer;
    function Add(ABytes: TBytes): IRedisCommand; overload;
    function Add(AString: string): IRedisCommand; overload;
    function Add(AInteger: NativeInt): IRedisCommand; overload;
    function SetCommand(AString: string): IRedisCommand; overload;
    function AddRange(AStrings: array of string): IRedisCommand;
    function ToRedisCommand: TBytes;
  end;

implementation

function TRedisCommand.Add(ABytes: TBytes): IRedisCommand;
begin
  FParts.Add(ABytes);
  Result := Self;
end;

function TRedisCommand.Add(AString: string): IRedisCommand;
begin
  FParts.Add(BytesOf(AString));
  Result := Self;
end;

function TRedisCommand.Add(AInteger: NativeInt): IRedisCommand;
begin
  Result := Add(IntToStr(AInteger));
end;

function TRedisCommand.AddRange(AStrings: array of string): IRedisCommand;
var
  s: string;
begin
  for s in AStrings do
    Add(s);
  Result := Self;
end;

procedure TRedisCommand.Clear;
begin
  FParts.Clear;
  FCommandIsSet := False;
end;

function TRedisCommand.Count: Integer;
begin
  Result := FParts.Count;
end;

constructor TRedisCommand.Create;
begin
  inherited Create;
  FParts := TList<TBytes>.Create;
end;

destructor TRedisCommand.Destroy;
begin
  FParts.Free;
  inherited;
end;

function TRedisCommand.GetToken(
  const
  Index:
  Integer): TBytes;
begin
  Result := FParts[index];
end;

function TRedisCommand.SetCommand(AString: string): IRedisCommand;
begin
  FParts.Clear;
  FParts.Add(TEncoding.ASCII.GetBytes(AString));
  FCommandIsSet := True;
end;

function TRedisCommand.ToRedisCommand: TBytes;
var
  L: TList<Byte>;
  I: Integer;
begin
  if not FCommandIsSet then
    raise ERedisException.Create('Command is not set. Use SetCommand.');
  L := TList<Byte>.Create;
  try
    L.Add(ASTERISK_BYTE); // bytesof('*')[0]);
    L.AddRange(BytesOf(IntToStr(Count)));
    L.Add(Byte(#13));
    L.Add(Byte(#10));

    for I := 0 to Count - 1 do
    begin
      L.Add(DOLLAR_BYTE); // bytesof('$')[0]);
      L.AddRange(BytesOf(IntToStr(Length(FParts[I]))));
      L.Add(Byte(#13));
      L.Add(Byte(#10));
      L.AddRange(FParts[I]);
      L.Add(Byte(#13));
      L.Add(Byte(#10));
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

end.
