// *************************************************************************** }
//
// Delphi REDIS Client
//
// Copyright (c) 2015-2016 Daniele Teti
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


unit Redis.Utils;

interface

uses
  Redis.Values, System.SysUtils, Generics.Collections;

  function RedisArrayGetItems(const AArray: TRedisArray; const aIndex: UInt64): TRedisString;
  function RedisArrayToArray(const AArray: TRedisArray): TArray<string>;

  function StringChars(const S: string; I: Integer): Char;
  function StringIsEmpty(const S: string): Boolean;
  function StringJoin(const Separator: string; const Values: TArray<string>): string;
  function StringSubstring(const S: string; I: Integer): string;
  function StringSubstringToInteger(const S: string; I: Integer): Integer;

implementation

uses
  System.SysConst, Redis.Commons;

function RedisArrayGetItems(const AArray: TRedisArray; const aIndex: UInt64): TRedisString;
begin
  Result := AArray.Value[aIndex];
end;

function RedisArrayToArray(const AArray: TRedisArray): TArray<string>;
var
  lItem: TRedisString;
  i: UInt64;
begin
  if AArray.IsNull then
    raise ERedisException.Create(VALUE_IS_NULL);
  SetLength(Result, Length(AArray.Value));
  i := 0;
  for lItem in AArray.Value do
  begin
    Result[i] := lItem.Value;
    inc(i);
  end;
end;

function StringChars(const S: string; I: Integer): Char;
begin
  if (I < 0) or (I >= Length(S)) then
    raise ERangeError.CreateResFmt(@SCharIndexOutOfBounds, [I]);
  Result := S[I + 1];
end;

function StringIsEmpty(const S: string): Boolean;
begin
  Result := S = '';
end;

function StringJoin(const Separator: string; const Values: TArray<string>): string;
var
  I, Len: Integer;
begin
  Len := System.Length(Values);
  if Len <= 0 then
    Result := ''
  else begin
    Result := Values[0];
    for I := 1 to Len - 1 do
      Result := Result + Separator + Values[I];
  end;
end;

function StringSubstring(const S: string; I: Integer): string;
begin
  Result := System.Copy(S, I + 1, MaxInt);
end;

function StringSubstringToInteger(const S: string; I: Integer): Integer;
var
  D: string;
begin
  D := System.Copy(S, I + 1, MaxInt);
  Result := StrToInt(D);
end;

end.
