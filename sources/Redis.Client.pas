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

unit Redis.Client;

interface

uses
  Generics.Collections, System.SysUtils, Redis.Command, Redis.Commons,
  Redis.Values;

type
  TRedisClient = class(TRedisClientBase, IRedisClient)
  private
    FTCPLibInstance: IRedisNetLibAdapter;
    FHostName: string;
    FPort: Word;
    FCommandTimeout: Int32;
    FRedisCmdParts: IRedisCommand;
    FNotExists: boolean;
    FNextCMD: IRedisCommand;
    FValidResponse: boolean;
    FIsValidResponse: boolean;
    FInTransaction: boolean;
    FIsTimeout: boolean;
    function Redis_BytesToString(aValue: TRedisBytes): TRedisString;
    function ParseSimpleStringResponse(var AValidResponse: boolean): string;
    function ParseIntegerResponse(var AValidResponse: boolean): Int64;
    // function ParseArrayResponse(var AValidResponse: boolean): TArray<string>;
    // deprecated 'Use: ParseArrayResponseNULL';
    function ParseArrayResponseNULL: TRedisArray;
    function ParseMatrixResponse: TRedisMatrix;
    procedure CheckResponseType(Expected, Actual: string);
    function ParseSimpleStringResponseAsByteNULL: TRedisBytes;
    function ParseSimpleStringResponseAsStringNULL: TRedisString;
  protected
    function GetGEORADIUSCommand(const Key: string;
      const Longitude, Latitude: Extended; const Radius: Extended;
      const &Unit: TRedisGeoUnit; const Sorting: TRedisSorting;
      const Count: Int64): IRedisCommand;

    function POPCommands(const aCommand: string; const aListKey: string)
      : TRedisString;
    procedure CheckResponseError(const aResponse: string);
    function GetCmdList(const Cmd: string): IRedisCommand;
    procedure NextToken(out Msg: string);
    function NextBytes(const ACount: UInt32): TBytes;
    /// //
    // function InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand;
    // AKeys: array of string; ATimeout: Int32;
    // var AIsValidResponse: boolean): TArray<string>; overload;
    function InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand;
      AKeys: array of string; ATimeout: Int32): TRedisArray; overload;
    constructor Create(TCPLibInstance: IRedisNetLibAdapter;
      const HostName: string; const Port: Word); overload;
  public
    function Tokenize(const ARedisCommand: string): TArray<string>;
    constructor Create(const HostName: string = '127.0.0.1';
      const Port: Word = 6379; const Lib: string = REDIS_NETLIB_INDY); overload;
    destructor Destroy; override;
    procedure Connect;
    { *** Methods using the nullable Redis Values *** }
    function GET(const aKey: string): TRedisString; overload;
    function GET_AsBytes(const aKey: string): TRedisBytes;
    function HGET_AsBytes(const aKey, aField: string): TRedisBytes;
    function HGET(const aKey, aField: string): TRedisString; overload;
    function RPOP(const aListKey: string): TRedisString; overload;
    function LPOP(const aListKey: string): TRedisString; overload;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32)
      : TRedisArray; overload;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32)
      : TRedisArray; overload;
    { *********************************************** }
    /// SET key value [EX seconds] [PX milliseconds] [NX|XX]
    function &SET(const aKey, aValue: string): boolean; overload;
    function &SET(const aKey, aValue: TBytes): boolean; overload;
    function &SET(const aKey: string; aValue: TBytes): boolean; overload;
    function &SET(const aKey: TBytes; aValue: TBytes; ASecsExpire: UInt64)
      : boolean; overload;
    function &SET(const aKey: string; aValue: TBytes; ASecsExpire: UInt64)
      : boolean; overload;
    function &SET(const aKey: string; aValue: string; ASecsExpire: UInt64)
      : boolean; overload;
    function SETNX(const aKey, aValue: string): boolean; overload;
    function SETNX(const aKey, aValue: TBytes): boolean; overload;
    function GET(const aKey: string; out aValue: string): boolean; overload;
    function GET(const aKey: TBytes; out aValue: TBytes): boolean; overload;
    function GET(const aKey: string; out aValue: TBytes): boolean; overload;
    function TTL(const aKey: string): Integer;
    function DEL(const AKeys: array of string): Integer;
    function EXISTS(const aKey: string): boolean;
    function INCR(const aKey: string): NativeInt;
    function DECR(const aKey: string): NativeInt;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TRedisArray;
    function EXPIRE(const aKey: string; AExpireInSecond: UInt32): boolean;
    // string functions
    function APPEND(const aKey, aValue: TBytes): UInt64; overload;
    function APPEND(const aKey, aValue: string): UInt64; overload;
    function STRLEN(const aKey: string): UInt64;
    function GETRANGE(const aKey: string;
      const AStart, AEnd: NativeInt): string;
    function SETRANGE(const aKey: string; const AOffset: NativeInt;
      const aValue: string): NativeInt;

    // hash
    function HSET(const aKey, aField: string; aValue: string): Integer;
      overload;
    function HSET(const aKey, aField: string; aValue: TBytes): Integer;
      overload;
    procedure HMSET(const aKey: string; aFields: TArray<string>;
      aValues: TArray<string>); overload;
    procedure HMSET(const aKey: string; aFields: TArray<string>;
      aValues: TArray<TBytes>); overload;
    function HMGET(const aKey: string; aFields: TArray<string>): TRedisArray;
    function HGET(const aKey, aField: string; out aValue: TBytes)
      : boolean; overload;
    function HGET(const aKey, aField: string; out aValue: string)
      : boolean; overload;
    function HDEL(const aKey: string; aFields: TArray<string>): Integer;
    // lists
    function RPUSH(const aListKey: string; aValues: array of string): Integer;
    function RPUSHX(const aListKey: string; aValues: array of string): Integer;
    function RPOP(const aListKey: string; var Value: string): boolean; overload;
    function LPUSH(const aListKey: string; aValues: array of string): Integer;
    function LPUSHX(const aListKey: string; aValues: array of string): Integer;
    function LPOP(const aListKey: string; out Value: string): boolean; overload;
    function LRANGE(const aListKey: string; aIndexStart, aIndexStop: Integer)
      : TRedisArray;
    function LLEN(const aListKey: string): Integer;
    procedure LTRIM(const aListKey: string;
      const aIndexStart, aIndexStop: Integer);
    function RPOPLPUSH(const ARightListKey, ALeftListKey: string;
      var APoppedAndPushedElement: string): boolean; overload;
    function BRPOPLPUSH(const ARightListKey, ALeftListKey: string;
      var APoppedAndPushedElement: string; ATimeout: Int32): boolean; overload;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32;
      out Value: TArray<string>): boolean; overload;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32;
      out Value: TArray<string>): boolean; overload;
    function LREM(const aListKey: string; const ACount: Integer;
      const aValue: string): Integer;
    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string;
      aCallback: TProc<string, string>;
      aContinueOnTimeoutCallback: TRedisTimeoutCallback = nil;
      aAfterSubscribe: TRedisAction = nil);
    function PUBLISH(const AChannel: string; AMessage: string): Integer;
    // sets
    function SADD(const aKey, aValue: TBytes): Integer; overload;
    function SADD(const aKey, aValue: string): Integer; overload;
    function SREM(const aKey, aValue: TBytes): Integer; overload;
    function SREM(const aKey, aValue: string): Integer; overload;
    function SMEMBERS(const aKey: string): TRedisArray;
    function SCARD(const aKey: string): Integer;

    // ordered sets
    function ZADD(const aKey: string; const AScore: Int64;
      const AMember: string): Integer;
    function ZREM(const aKey: string; const AMember: string): Integer;
    function ZCARD(const aKey: string): Integer;
    function ZCOUNT(const aKey: string; const AMin, AMax: Int64): Integer;
    function ZRANK(const aKey: string; const AMember: string;
      out ARank: Int64): boolean;
    function ZRANGE(const aKey: string; const AStart, AStop: Int64)
      : TRedisArray;
    function ZRANGEWithScore(const aKey: string; const AStart, AStop: Int64)
      : TRedisArray;
    function ZINCRBY(const aKey: string; const AIncrement: Int64;
      const AMember: string): string;

    // geo REDIS 3.2
    function GEOADD(const Key: string; const Latitude, Longitude: Extended;
      Member: string): Integer;
    function GEODIST(const Key: string; const Member1, Member2: string;
      const &Unit: TRedisGeoUnit): TRedisString;
    function GEOHASH(const Key: string; const Members: array of string)
      : TRedisArray;
    function GEOPOS(const Key: string; const Members: array of string)
      : TRedisMatrix;
    function GEORADIUS(const Key: string; const Longitude, Latitude: Extended;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisArray;
    function GEORADIUS_WITHDIST(const Key: string;
      const Longitude, Latitude: Extended; const Radius: Extended;
      const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisMatrix;

    // lua scripts
    function EVAL(const AScript: string; AKeys: array of string;
      aValues: array of string): Integer;
    // system
    procedure FLUSHDB;
    procedure FLUSHALL;
    procedure SELECT(const ADBIndex: Integer);
    procedure AUTH(const aPassword: string);
    function MOVE(const aKey: string; const aDB: Byte): boolean;
    function PERSIST(const aKey: string): boolean;
    function RANDOMKEY: TRedisString;
    // non system
    function InTransaction: boolean;
    // transations
    function MULTI(ARedisTansactionProc: TRedisTransactionProc)
      : TRedisArray; overload;
    procedure MULTI; overload;
    function EXEC: TRedisArray;
    procedure WATCH(const AKeys: array of string);
    procedure DISCARD;
    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand): TRedisArray;
    function ExecuteAndGetArrayNULL(const RedisCommand: IRedisCommand)
      : TRedisArray;
    function ExecuteAndGetMatrix(const RedisCommand: IRedisCommand)
      : TRedisMatrix;
    function ExecuteWithIntegerResult(const RedisCommand: IRedisCommand)
      : Int64; overload;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand)
      : TRedisString;
    procedure Disconnect;
    procedure SetCommandTimeout(const Timeout: Int32);
    // client
    procedure ClientSetName(const ClientName: string);
    function Clone: IRedisClient;
  end;

function NewRedisClient(const AHostName: string = 'localhost';
  const APort: Word = 6379; const ALibName: string = REDIS_NETLIB_INDY)
  : IRedisClient;
function NewRedisCommand(const RedisCommandString: string): IRedisCommand;

implementation

uses Redis.NetLib.Factory, System.Generics.Collections;

const
  REDIS_GEO_UNIT_STRING: array [TRedisGeoUnit.Meters .. TRedisGeoUnit.Feet]
    of string = ('m', 'km', 'mi', 'ft');

  { TRedisClient }

function TRedisClient.SADD(const aKey, aValue: TBytes): Integer;
begin
  FNextCMD := GetCmdList('SADD').Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.SADD(const aKey, aValue: string): Integer;
begin
  Result := SADD(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

function TRedisClient.SCARD(const aKey: string): Integer;
begin
  FNextCMD := GetCmdList('SCARD').Add(aKey);
  Result := ExecuteWithIntegerResult(FNextCMD);
end;

procedure TRedisClient.SELECT(const ADBIndex: Integer);
begin
  FNextCMD := GetCmdList('SELECT').Add(ADBIndex.ToString);
  ExecuteWithStringResult(FNextCMD);
end;

function TRedisClient.&SET(const aKey, aValue: TBytes): boolean;
var
  lRes: TRedisString;
begin
  FNextCMD := GetCmdList('SET');
  FNextCMD.Add(aKey);
  FNextCMD.Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  lRes := ParseSimpleStringResponseAsStringNULL;
  Result := lRes.HasValue;
end;

function TRedisClient.&SET(const aKey: string; aValue: TBytes): boolean;
begin
  Result := &SET(BytesOf(aKey), aValue);
end;

function TRedisClient.APPEND(const aKey, aValue: TBytes): UInt64;
begin
  FNextCMD := GetCmdList('APPEND');
  FNextCMD.Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FIsValidResponse);
end;

function TRedisClient.APPEND(const aKey, aValue: string): UInt64;
begin
  Result := APPEND(BytesOf(aKey), BytesOf(aValue));
end;

procedure TRedisClient.AUTH(const aPassword: string);
begin
  FNextCMD := GetCmdList('AUTH');
  FNextCMD.Add(aPassword);
  FTCPLibInstance.SendCmd(FNextCMD);
  ParseSimpleStringResponse(FIsValidResponse);
end;

function TRedisClient.BLPOP(const AKeys: array of string; const ATimeout: Int32;
  out Value: TArray<string>): boolean;
var
  lRes: TRedisArray;
begin
  FNextCMD := GetCmdList('BLPOP');
  lRes := InternalBlockingLeftOrRightPOP(FNextCMD, AKeys, ATimeout);
  Result := lRes.HasValue;
  if Result then
    Value := lRes.ToArray;
  // Value := InternalBlockingLeftOrRightPOP(FNextCMD, AKeys, ATimeout,
  // FIsValidResponse);
  // Result := FIsValidResponse;
end;

function TRedisClient.BLPOP(const AKeys: array of string; const ATimeout: Int32)
  : TRedisArray;
begin
  FNextCMD := GetCmdList('BLPOP');
  Result := InternalBlockingLeftOrRightPOP(FNextCMD, AKeys, ATimeout);
end;

function TRedisClient.BRPOP(const AKeys: array of string; const ATimeout: Int32;
  out Value: TArray<string>): boolean;
var
  lRes: TRedisArray;
begin
  FNextCMD := GetCmdList('BRPOP');
  lRes := InternalBlockingLeftOrRightPOP(FNextCMD, AKeys, ATimeout);
  Result := lRes.HasValue;
  if Result then
    Value := lRes.ToArray;
end;

procedure TRedisClient.CheckResponseError(const aResponse: string);
begin
  if aResponse.Chars[0] = '-' then
    raise ERedisException.Create(aResponse.Substring(1))
end;

procedure TRedisClient.CheckResponseType(Expected, Actual: string);
begin
  if Expected <> Actual then
  begin
    raise ERedisException.CreateFmt('Expected %s got %s', [Expected, Actual]);
  end;
end;

procedure TRedisClient.ClientSetName(const ClientName: string);
begin
  FNextCMD := GetCmdList('CLIENT');
  FNextCMD.Add('SETNAME');
  FNextCMD.Add(ClientName);
  FTCPLibInstance.SendCmd(FNextCMD);
  CheckResponseType('OK', ParseSimpleStringResponse(FValidResponse));
end;

function TRedisClient.Clone: IRedisClient;
begin
  Result := NewRedisClient(FHostName, FPort, FTCPLibInstance.LibName);
end;

procedure TRedisClient.Connect;
begin
  FTCPLibInstance.Connect(FHostName, FPort);
end;

constructor TRedisClient.Create(const HostName: string; const Port: Word;
  const Lib: string);
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  inherited Create;
  TCPLibInstance := TRedisNetLibFactory.GET(Lib);
  Create(TCPLibInstance, HostName, Port);
end;

constructor TRedisClient.Create(TCPLibInstance: IRedisNetLibAdapter;
  const HostName: string; const Port: Word);
begin
  inherited Create;
  FTCPLibInstance := TCPLibInstance;
  FHostName := HostName;
  FPort := Port;
  FRedisCmdParts := TRedisCommand.Create;
  FCommandTimeout := -1;
end;

function TRedisClient.DECR(const aKey: string): NativeInt;
begin
  FTCPLibInstance.SendCmd(GetCmdList('DECR').Add(aKey));
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.DEL(const AKeys: array of string): Integer;
begin
  FNextCMD := GetCmdList('DEL');
  FNextCMD.AddRange(AKeys);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

destructor TRedisClient.Destroy;
begin
  inherited;
end;

procedure TRedisClient.DISCARD;
begin
  FNextCMD := GetCmdList('DISCARD');
  FTCPLibInstance.SendCmd(FNextCMD);
  ParseSimpleStringResponseAsStringNULL;
end;

procedure TRedisClient.Disconnect;
begin
  try
    FTCPLibInstance.Disconnect;
  except
  end;
end;

function TRedisClient.ExecuteWithIntegerResult(const RedisCommand
  : IRedisCommand): Int64;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.ExecuteWithStringResult(const RedisCommand: IRedisCommand)
  : TRedisString;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseSimpleStringResponseAsStringNULL;
end;

function TRedisClient.EXISTS(const aKey: string): boolean;
begin
  FNextCMD := GetCmdList('EXISTS');
  FNextCMD.Add(aKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse) = 1;
end;

function TRedisClient.EXPIRE(const aKey: string;
  AExpireInSecond: UInt32): boolean;
begin
  FTCPLibInstance.Write(GetCmdList('EXPIRE').Add(aKey)
    .Add(AExpireInSecond.ToString).ToRedisCommand);

  {
    1 if the timeout was set.
    0 if key does not exist or the timeout could not be set.
  }
  Result := ParseIntegerResponse(FValidResponse) = 1;
end;

function TRedisClient.EVAL(const AScript: string;
  AKeys, aValues: array of string): Integer;
var
  lCmd: IRedisCommand;
  lParamsCount: Integer;
  lPar: string;
begin
  lCmd := NewRedisCommand('EVAL');
  lParamsCount := Length(AKeys);
  lCmd.Add(AScript).Add(IntToStr(lParamsCount));

  if lParamsCount > 0 then
  begin
    for lPar in AKeys do
    begin
      lCmd.Add(lPar);
    end;
    for lPar in aValues do
    begin
      lCmd.Add(lPar);
    end;
  end;

  Result := ExecuteWithIntegerResult(lCmd);
end;

function TRedisClient.EXEC: TRedisArray;
begin
  FNextCMD := GetCmdList('EXEC');
  FTCPLibInstance.SendCmd(FNextCMD);
  FInTransaction := False;
  Result := ParseArrayResponseNULL;
  if Result.IsNull then
    raise ERedisException.Create('Transaction failed');
end;

function TRedisClient.ExecuteAndGetArray(const RedisCommand: IRedisCommand)
  : TRedisArray;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseArrayResponseNULL;
  // Result := ParseArrayResponse(FValidResponse);
  // if FTCPLibInstance.LastReadWasTimedOut then
  // Exit;
  // if not FValidResponse then
  // raise ERedisException.Create('Not valid response');
end;

function TRedisClient.ExecuteAndGetArrayNULL(const RedisCommand: IRedisCommand)
  : TRedisArray;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseArrayResponseNULL;
  if FTCPLibInstance.LastReadWasTimedOut then
    Exit;
end;

function TRedisClient.ExecuteAndGetMatrix(const RedisCommand: IRedisCommand)
  : TRedisMatrix;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseMatrixResponse;
  if FTCPLibInstance.LastReadWasTimedOut then
    Exit;
end;

procedure TRedisClient.FLUSHALL;
var
  lRes: TRedisNullable<string>;
begin
  FTCPLibInstance.SendCmd(GetCmdList('FLUSHALL'));
  lRes := ParseSimpleStringResponseAsStringNULL;
  if lRes.Value <> 'OK' then
    raise ERedisException.Create('Cannot flush DBs: ' + lRes.Value);
end;

procedure TRedisClient.FLUSHDB;
begin
  FTCPLibInstance.SendCmd(GetCmdList('FLUSHDB'));
  ParseSimpleStringResponse(FNotExists);
end;

function TRedisClient.GET(const aKey: string; out aValue: string): boolean;
var
  Resp: TBytes;
begin
  Result := GET(BytesOfUnicode(aKey), Resp);
  aValue := StringOfUnicode(Resp);
end;

function TRedisClient.GET(const aKey: TBytes; out aValue: TBytes): boolean;
var
  Pieces: IRedisCommand;
  lRes: TRedisBytes;
begin
  Pieces := GetCmdList('GET');
  Pieces.Add(aKey);
  FTCPLibInstance.SendCmd(Pieces);

  lRes := ParseSimpleStringResponseAsByteNULL;
  Result := lRes.HasValue;
  if Result then
    aValue := lRes.Value;
end;

function TRedisClient.GetCmdList(const Cmd: string): IRedisCommand;
begin
  FRedisCmdParts.Clear;
  Result := FRedisCmdParts;
  Result.SetCommand(Cmd);
end;

function TRedisClient.GetGEORADIUSCommand(const Key: string;
  const Longitude, Latitude, Radius: Extended; const &Unit: TRedisGeoUnit;
  const Sorting: TRedisSorting; const Count: Int64): IRedisCommand;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEORADIUS');
  lCmd.Add(Key);
  lCmd.Add(FormatFloat('0.0000000', Latitude));
  lCmd.Add(FormatFloat('0.0000000', Longitude));
  lCmd.Add(FormatFloat('0.0000000', Radius));
  lCmd.Add(REDIS_GEO_UNIT_STRING[&Unit]);
  if Count > -1 then
    lCmd.Add('COUNT').Add(Count);

  case Sorting of
    TRedisSorting.Asc:
      lCmd.Add('ASC');
    TRedisSorting.Desc:
      lCmd.Add('DESC');
  end;
  Result := lCmd;
end;

function TRedisClient.GETRANGE(const aKey: string;
  const AStart, AEnd: NativeInt): string;
begin
  FNextCMD := GetCmdList('GETRANGE').Add(aKey).Add(AStart).Add(AEnd);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseSimpleStringResponse(FIsValidResponse);
end;

function TRedisClient.GET_AsBytes(const aKey: string): TRedisBytes;
var
  Pieces: IRedisCommand;
begin
  Pieces := GetCmdList('GET');
  Pieces.Add(aKey);
  FTCPLibInstance.SendCmd(Pieces);
  Result := ParseSimpleStringResponseAsByteNULL;
end;

function TRedisClient.HSET(const aKey, aField: string; aValue: string): Integer;
begin
  Result := HSET(aKey, aField, BytesOfUnicode(aValue));
end;

function TRedisClient.HGET(const aKey, aField: string;
  out aValue: TBytes): boolean;
var
  Pieces: IRedisCommand;
  lRes: TRedisNullable<TBytes>;
begin
  Pieces := GetCmdList('HGET');
  Pieces.Add(aKey);
  Pieces.Add(aField);
  FTCPLibInstance.SendCmd(Pieces);
  lRes := ParseSimpleStringResponseAsByteNULL;
  Result := lRes.HasValue;
  if Result then
    aValue := lRes.Value;
end;

function TRedisClient.HDEL(const aKey: string; aFields: TArray<string>)
  : Integer;
var
  lCommand: IRedisCommand;
begin
  lCommand := GetCmdList('HDEL');
  lCommand.Add(aKey);
  lCommand.AddRange(aFields);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.HGET(const aKey, aField: string;
  out aValue: string): boolean;
var
  Resp: TBytes;
begin
  Result := HGET(aKey, aField, Resp);
  aValue := StringOfUnicode(Resp);
end;

function TRedisClient.HGET(const aKey, aField: string): TRedisString;
var
  lResp: TRedisBytes;
begin
  lResp := HGET_AsBytes(aKey, aField);
  Result := Redis_BytesToString(lResp);
end;

function TRedisClient.HGET_AsBytes(const aKey, aField: string): TRedisBytes;
var
  Pieces: IRedisCommand;
begin
  Pieces := GetCmdList('HGET');
  Pieces.Add(aKey);
  Pieces.Add(aField);
  FTCPLibInstance.SendCmd(Pieces);
  Result := ParseSimpleStringResponseAsByteNULL;
end;

function TRedisClient.HMGET(const aKey: string; aFields: TArray<string>)
  : TRedisArray;
var
  Pieces: IRedisCommand;
  I: Integer;
begin
  Pieces := GetCmdList('HMGET');
  Pieces.Add(aKey);
  for I := low(aFields) to high(aFields) do
  begin
    Pieces.Add(aFields[I]);
  end;
  FTCPLibInstance.SendCmd(Pieces);
  Result := ParseArrayResponseNULL;
end;

procedure TRedisClient.HMSET(const aKey: string; aFields: TArray<string>;
  aValues: TArray<TBytes>);
var
  I: Integer;
begin
  if Length(aFields) <> Length(aValues) then
    raise ERedisException.Create('Fields count and values count are different');

  FNextCMD := GetCmdList('HMSET');
  FNextCMD.Add(aKey);
  for I := low(aFields) to high(aFields) do
  begin
    FNextCMD.Add(aFields[I]);
    FNextCMD.Add(aValues[I]);
  end;
  FTCPLibInstance.SendCmd(FNextCMD);
  if FInTransaction then
    CheckResponseType('QUEUED', ParseSimpleStringResponseAsStringNULL.Value)
  else
    CheckResponseType('OK', ParseSimpleStringResponseAsStringNULL.Value);
end;

procedure TRedisClient.HMSET(const aKey: string; aFields: TArray<string>;
  aValues: TArray<string>);
var
  I: Integer;
begin
  if Length(aFields) <> Length(aValues) then
    raise ERedisException.Create('Fields count and values count are different');

  FNextCMD := GetCmdList('HMSET');
  FNextCMD.Add(aKey);
  for I := low(aFields) to high(aFields) do
  begin
    FNextCMD.Add(aFields[I]);
    FNextCMD.Add(aValues[I]);
  end;
  FTCPLibInstance.SendCmd(FNextCMD);
  if FInTransaction then
    CheckResponseType('QUEUED', ParseSimpleStringResponseAsStringNULL.Value)
  else
    CheckResponseType('OK', ParseSimpleStringResponseAsStringNULL.Value);
end;

function TRedisClient.HSET(const aKey, aField: string; aValue: TBytes): Integer;
begin
  FNextCMD := GetCmdList('HSET');
  FNextCMD.Add(aKey);
  FNextCMD.Add(aField);
  FNextCMD.Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.INCR(const aKey: string): NativeInt;
begin
  FTCPLibInstance.SendCmd(GetCmdList('INCR').Add(aKey));
  Result := ParseIntegerResponse(FValidResponse);
end;

// function TRedisClient.InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand;
// AKeys: array of string; ATimeout: Int32; var AIsValidResponse: boolean)
// : TArray<string>;
// begin
// NextCMD.AddRange(AKeys);
// NextCMD.Add(ATimeout.ToString);
// FTCPLibInstance.SendCmd(NextCMD);
// Result := ParseArrayResponse(AIsValidResponse);
// end;

function TRedisClient.InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand;
  AKeys: array of string; ATimeout: Int32): TRedisArray;
begin
  NextCMD.AddRange(AKeys);
  NextCMD.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.InTransaction: boolean;
begin
  Result := FInTransaction;
end;

function TRedisClient.KEYS(const AKeyPattern: string): TRedisArray;
begin
  FNextCMD := GetCmdList('KEYS');
  FNextCMD.Add(BytesOfUnicode(AKeyPattern));
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.LLEN(const aListKey: string): Integer;
begin
  FNextCMD := GetCmdList('LLEN');
  FNextCMD.Add(aListKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.LPOP(const aListKey: string; out Value: string): boolean;
begin
  FNextCMD := GetCmdList('LPOP');
  FNextCMD.Add(aListKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.LPOP(const aListKey: string): TRedisString;
begin
  Result := POPCommands('LPOP', aListKey);
end;

function TRedisClient.LPUSH(const aListKey: string;
  aValues: array of string): Integer;
begin
  FNextCMD := GetCmdList('LPUSH');
  FNextCMD.Add(aListKey);
  FNextCMD.AddRange(aValues);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.LPUSHX(const aListKey: string;
  aValues: array of string): Integer;
begin
  FNextCMD := GetCmdList('LPUSHX');
  FNextCMD.Add(aListKey);
  FNextCMD.AddRange(aValues);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.LRANGE(const aListKey: string;
  aIndexStart, aIndexStop: Integer): TRedisArray;
begin
  FNextCMD := GetCmdList('LRANGE');
  FNextCMD.Add(aListKey);
  FNextCMD.Add(aIndexStart.ToString);
  FNextCMD.Add(aIndexStop.ToString);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.LREM(const aListKey: string; const ACount: Integer;
  const aValue: string): Integer;
begin
  FNextCMD := GetCmdList('LREM');
  FNextCMD.Add(aListKey);
  FNextCMD.Add(ACount.ToString);
  FNextCMD.Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

procedure TRedisClient.LTRIM(const aListKey: string;
  const aIndexStart, aIndexStop: Integer);
var
  lResult: string;
begin
  FNextCMD := GetCmdList('LTRIM').Add(aListKey).Add(aIndexStart.ToString)
    .Add(aIndexStop.ToString);
  lResult := ExecuteWithStringResult(FNextCMD);
  if lResult <> 'OK' then
    raise ERedisException.Create(lResult);
end;

function TRedisClient.MOVE(const aKey: string; const aDB: Byte): boolean;
begin
  FNextCMD := GetCmdList('MOVE').Add(aKey).Add(aDB.ToString);
  Result := ExecuteWithIntegerResult(FNextCMD) = 1;
end;

function TRedisClient.MSET(const AKeysValues: array of string): boolean;
begin
  FNextCMD := GetCmdList('MSET');
  FNextCMD.AddRange(AKeysValues);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseSimpleStringResponse(FNotExists) = 'OK';
end;

procedure TRedisClient.MULTI;
begin
  FNextCMD := GetCmdList('MULTI');
  FTCPLibInstance.SendCmd(FNextCMD);
  ParseSimpleStringResponse(FValidResponse);
  FInTransaction := True;
end;

function TRedisClient.MULTI(ARedisTansactionProc: TRedisTransactionProc)
  : TRedisArray;
begin
  FNextCMD := GetCmdList('MULTI');
  try
    FTCPLibInstance.SendCmd(FNextCMD);
    ParseSimpleStringResponse(FValidResponse);
    FInTransaction := True;
    try
      ARedisTansactionProc(self);
    except
      DISCARD;
      raise;
    end;
    Result := EXEC;
    if Result.IsNull then
      raise ERedisException.Create('Transaction failed');
  finally
    FInTransaction := False;
  end;
end;

procedure TRedisClient.NextToken(out Msg: string);
begin
  Msg := FTCPLibInstance.Receive(FCommandTimeout);
  FIsTimeout := FTCPLibInstance.LastReadWasTimedOut;
end;

function TRedisClient.NextBytes(const ACount: UInt32): TBytes;
begin
  FTCPLibInstance.ReceiveBytes(ACount, FCommandTimeout);
end;

// function TRedisClient.ParseArrayResponse(var AValidResponse: boolean)
// : TArray<string>;
// var
// lRes: TRedisArray;
// begin
// lRes := ParseArrayResponseNULL;
// AValidResponse := lRes.HasValue;
// if AValidResponse then
// Result := lRes.ToArray;
//
// // In RESP, the type of some data depends on the first byte:
// // For Simple Strings the first byte of the reply is "+"
// // For Errors the first byte of the reply is "-"
// // For Integers the first byte of the reply is ":"
// // For Bulk Strings the first byte of the reply is "$"
// // For Arrays the first byte of the reply is "*"
//
// // SetLength(Result, 0);
// // AValidResponse := True;
// // NextToken(R);
// // if FIsTimeout then
// // Exit;
// // CheckResponseError(R);
// //
// // if R = TRedisConsts.NULL_ARRAY then
// // begin
// // AValidResponse := False;
// // Exit;
// // end;
// //
// // if R.Chars[0] = '*' then
// // begin
// // ArrLength := R.Substring(1).ToInteger;
// // // if ArrLength = -1 then // REDIS_NULL_BULK_STRING
// // // begin
// // // AValidResponse := False;
// // // Exit;
// // // end;
// // end
// // else
// // raise ERedisException.Create('Invalid response length, invalid array response');
// // SetLength(Result, ArrLength);
// // if ArrLength = 0 then
// // Exit;
// // I := 0;
// // while True do
// // begin
// // Result[I] := StringOfUnicode(ParseSimpleStringResponseAsByte(FNotExists));
// // inc(I);
// // if I >= ArrLength then
// // break;
// // end;
// end;

function TRedisClient.ParseArrayResponseNULL: TRedisArray;
var
  R: string;
  ArrLength: Integer;
  I: Integer;
  Values: TArray<TRedisString>;
begin
  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"
  Result := nil;
  NextToken(R);
  if FIsTimeout then
    Exit;
  CheckResponseError(R);

  if R = TRedisConsts.NULL_ARRAY then
  begin
    Exit;
  end;

  if R.Chars[0] = '*' then
  begin
    ArrLength := R.Substring(1).ToInteger;
  end
  else
    raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_ARRAY_RESPONSE);

  SetLength(Values, ArrLength);
  if ArrLength = 0 then
    Exit;
  I := 0;
  while True do
  begin
    Values[I] := Redis_BytesToString(ParseSimpleStringResponseAsByteNULL);
    inc(I);
    if I >= ArrLength then
      break;
  end;
  Result := Values;
end;

function TRedisClient.ParseIntegerResponse(var AValidResponse: boolean): Int64;
var
  R: string;
  I: Integer;
  HowMany: Integer;
begin
  Result := -1;
  if FInTransaction then
  begin
    R := ParseSimpleStringResponse(FValidResponse);
    if R <> 'QUEUED' then
      raise ERedisException.Create(R);
    Exit;
  end;

  NextToken(R);
  if FIsTimeout then
    Exit;
  CheckResponseError(R);

  case R.Chars[0] of
    ':':
      begin
        if not TryStrToInt(R.Substring(1), I) then
          raise ERedisException.CreateFmt
            (TRedisConsts.ERR_NOT_A_VALID_INTEGER_RESPONSE +
            ' - Expected Integer got [%s]', [R]);
        Result := I;
      end;
    '$':
      begin
        HowMany := R.Substring(1).ToInteger;
        if HowMany = -1 then
        begin
          AValidResponse := False;
          Result := -1;
        end
        else
          raise ERedisException.Create
            (TRedisConsts.ERR_NOT_A_VALID_INTEGER_RESPONSE);
      end;
  else
    raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_INTEGER_RESPONSE);
  end;
end;

function TRedisClient.ParseMatrixResponse: TRedisMatrix;
var
  R: string;
  ArrLength: Integer;
  I: Integer;
  Values: TArray<TRedisArray>;
begin
  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"
  Result := nil;
  NextToken(R);
  if FIsTimeout then
    Exit;
  CheckResponseError(R);

  if R = TRedisConsts.NULL_ARRAY then
  begin
    Exit;
  end;

  if R.Chars[0] = '*' then
  begin
    ArrLength := R.Substring(1).ToInteger;
  end
  else
    raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_ARRAY_RESPONSE);

  SetLength(Values, ArrLength);
  if ArrLength = 0 then
    Exit;
  I := 0;
  while True do
  begin
    Values[I] := ParseArrayResponseNULL;
    // Redis_BytesToString(ParseSimpleStringResponseAsByteNULL);
    inc(I);
    if I >= ArrLength then
      break;
  end;
  Result := Values;
end;

function TRedisClient.ParseSimpleStringResponse(var AValidResponse
  : boolean): string;
var
  lRes: TRedisBytes;
begin
  lRes := ParseSimpleStringResponseAsByteNULL;
  AValidResponse := lRes.HasValue;
  if AValidResponse then
    Result := StringOf(lRes.Value);
end;

function TRedisClient.ParseSimpleStringResponseAsByteNULL: TRedisBytes;
var
  R: string;
  HowMany: Integer;
begin
  Result := nil;
  NextToken(R);
  if FIsTimeout then
    raise ERedisException.Create('Command Timeout');

  if (R = TRedisConsts.NULL_BULK_STRING) or (R = TRedisConsts.NULL_ARRAY) then
  begin
    // A client library API should return a null object and not an empty Array when
    // Redis replies with a Null Array. This is necessary to distinguish between an empty
    // list and a different condition (for instance the timeout condition of the BLPOP command).
    Exit;
  end;
  CheckResponseError(R);

  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"

  case R.Chars[0] of
    '+':
      Result := BytesOf(R.Substring(1));
    ':':
      Result := BytesOf(R.Substring(1));
    '$':
      begin
        HowMany := R.Substring(1).ToInteger;
        Result := FTCPLibInstance.ReceiveBytes(HowMany, FCommandTimeout);
        // eat crlf
        FTCPLibInstance.ReceiveBytes(2, FCommandTimeout);
      end;
  else
    raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_STRING_RESPONSE);
  end;
end;

function TRedisClient.ParseSimpleStringResponseAsStringNULL: TRedisString;
var
  lRes: TRedisBytes;
begin
  lRes := ParseSimpleStringResponseAsByteNULL;
  Result := Redis_BytesToString(lRes);
end;

function TRedisClient.PERSIST(const aKey: string): boolean;
begin
  FNextCMD := GetCmdList('PERSIST').Add(aKey);
  Result := ExecuteWithIntegerResult(FNextCMD) = 1;
end;

function TRedisClient.POPCommands(const aCommand: string;
  const aListKey: string): TRedisString;
begin
  FNextCMD := GetCmdList(aCommand);
  FNextCMD.Add(aListKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := Redis_BytesToString(ParseSimpleStringResponseAsByteNULL);
end;

function TRedisClient.PUBLISH(const AChannel: string; AMessage: string)
  : Integer;
begin
  FNextCMD := GetCmdList('PUBLISH');
  FNextCMD.Add(AChannel);
  FNextCMD.Add(AMessage);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.RANDOMKEY: TRedisString;
begin
  FNextCMD := GetCmdList('RANDOMKEY');
  Result := ExecuteWithStringResult(FNextCMD);
end;

function TRedisClient.Redis_BytesToString(aValue: TRedisBytes): TRedisString;
begin
  if aValue.HasValue then
    Result := TRedisString.Create(StringOf(aValue.Value))
  else
    Result := TRedisString.Empty;
end;

function TRedisClient.RPOP(const aListKey: string; var Value: string): boolean;
begin
  FNextCMD := GetCmdList('RPOP');
  FNextCMD.Add(aListKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.BRPOP(const AKeys: array of string; const ATimeout: Int32)
  : TRedisArray;
begin
  FNextCMD := GetCmdList('BRPOP');
  Result := InternalBlockingLeftOrRightPOP(FNextCMD, AKeys, ATimeout);
end;

function TRedisClient.BRPOPLPUSH(const ARightListKey, ALeftListKey: string;
  var APoppedAndPushedElement: string; ATimeout: Int32): boolean;
var
  lValue: string;
begin
  APoppedAndPushedElement := '';
  FNextCMD := GetCmdList('BRPOPLPUSH');
  FNextCMD.Add(ARightListKey);
  FNextCMD.Add(ALeftListKey);
  FNextCMD.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(FNextCMD);

  lValue := ParseSimpleStringResponse(FValidResponse);
  Result := FValidResponse; // and (not(lValue = TRedisConsts.NULL_ARRAY));
  if Result then
  begin
    APoppedAndPushedElement := lValue;
    // Result := FValidResponse;
  end;
end;

function TRedisClient.RPOP(const aListKey: string): TRedisString;
begin
  Result := POPCommands('RPOP', aListKey);
end;

function TRedisClient.RPOPLPUSH(const ARightListKey, ALeftListKey: string;
  var APoppedAndPushedElement: string): boolean;
begin
  FNextCMD := GetCmdList('RPOPLPUSH');
  FNextCMD.Add(ARightListKey);
  FNextCMD.Add(ALeftListKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  APoppedAndPushedElement := ParseSimpleStringResponse(FValidResponse);
  Result := FValidResponse;
end;

function TRedisClient.RPUSH(const aListKey: string;
  aValues: array of string): Integer;
begin
  FNextCMD := GetCmdList('RPUSH');
  FNextCMD.Add(aListKey);
  FNextCMD.AddRange(aValues);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.RPUSHX(const aListKey: string;
  aValues: array of string): Integer;
begin
  FNextCMD := GetCmdList('RPUSHX');
  FNextCMD.Add(aListKey);
  FNextCMD.AddRange(aValues);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.&SET(const aKey, aValue: string): boolean;
begin
  Result := &SET(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

procedure TRedisClient.SetCommandTimeout(const Timeout: Int32);
begin
  FCommandTimeout := Timeout;
end;

function TRedisClient.SETNX(const aKey, aValue: string): boolean;
begin
  Result := SETNX(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

function TRedisClient.&SET(const aKey: string; aValue: TBytes;
  ASecsExpire: UInt64): boolean;
begin
  Result := &SET(BytesOfUnicode(aKey), aValue, ASecsExpire);
end;

function TRedisClient.&SET(const aKey: TBytes; aValue: TBytes;
  ASecsExpire: UInt64): boolean;
begin
  FNextCMD := GetCmdList('SET');
  FNextCMD.Add(aKey);
  FNextCMD.Add(aValue);
  FNextCMD.Add('EX');
  FNextCMD.Add(IntToStr(ASecsExpire));
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseSimpleStringResponseAsByteNULL.HasValue
end;

function TRedisClient.&SET(const aKey: string; aValue: string;
  ASecsExpire: UInt64): boolean;
begin
  Result := &SET(BytesOfUnicode(aKey), BytesOfUnicode(aValue), ASecsExpire);
end;

function TRedisClient.SETNX(const aKey, aValue: TBytes): boolean;
begin
  FNextCMD := GetCmdList('SETNX');
  FNextCMD.Add(aKey);
  FNextCMD.Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse) = 1;
end;

function TRedisClient.SETRANGE(const aKey: string; const AOffset: NativeInt;
  const aValue: string): NativeInt;
begin
  FNextCMD := GetCmdList('SETRANGE').Add(aKey).Add(AOffset).Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FIsValidResponse);
end;

function TRedisClient.SMEMBERS(const aKey: string): TRedisArray;
begin
  FNextCMD := GetCmdList('SMEMBERS').Add(aKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.SREM(const aKey, aValue: string): Integer;
begin
  Result := SREM(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

function TRedisClient.STRLEN(const aKey: string): UInt64;
begin
  FNextCMD := GetCmdList('STRLEN').Add(aKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.SREM(const aKey, aValue: TBytes): Integer;
begin
  FNextCMD := GetCmdList('SREM').Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

procedure TRedisClient.SUBSCRIBE(const AChannels: array of string;
  aCallback: TProc<string, string>;
  aContinueOnTimeoutCallback: TRedisTimeoutCallback = nil;
  aAfterSubscribe: TRedisAction = nil);
var
  I: Integer;
  lChannel, lValue: string;
  // lArr: TArray<string>;
  lContinue: boolean;
  lArrNull: TRedisArray;
begin
  FNextCMD := GetCmdList('SUBSCRIBE');
  FNextCMD.AddRange(AChannels);
  FTCPLibInstance.SendCmd(FNextCMD);
  // just to implement a sort of non blocking subscribe
  SetCommandTimeout(RedisDefaultSubscribeTimeout);

  for I := 0 to Length(AChannels) - 1 do
  begin
    lArrNull := ParseArrayResponseNULL;
    if (lArrNull.Items[0].Value.ToLower <> 'subscribe') or
      (lArrNull.Items[1] <> AChannels[I]) then
      raise ERedisException.Create('Invalid subscription response: ' +
        string.Join('-', lArrNull.ToArray))
  end;
  // all is fine, now read the callbacks message
  if Assigned(aAfterSubscribe) then
    try
      aAfterSubscribe()
    except
      // do nothing
    end;

  while True do
  begin
    lArrNull := ParseArrayResponseNULL;
    if FTCPLibInstance.LastReadWasTimedOut then
    begin
      if Assigned(aContinueOnTimeoutCallback) then
      begin
        lContinue := aContinueOnTimeoutCallback();
        if not lContinue then
          break;
      end;
    end
    else
    begin
      if lArrNull.Items[0] <> 'message' then
        raise ERedisException.CreateFmt('Invalid reply: %s',
          [string.Join('-', lArrNull.ToArray)]);
      lChannel := lArrNull.Value[1];
      lValue := lArrNull.Value[2];
      try
        aCallback(lChannel, lValue);
      except
        // do nothing
      end;
    end;
  end;
end;

function TRedisClient.Tokenize(const ARedisCommand: string): TArray<string>;
var
  C: Char;
  List: TList<string>;
  CurState: Integer;
  Piece: string;
const
  SSINK = 1;
  SQUOTED = 2;
  SESCAPE = 3;
begin
  Piece := '';
  List := TList<string>.Create;
  try
    CurState := SSINK;
    for C in ARedisCommand do
    begin
      case CurState of
        SESCAPE: // only in quoted mode
          begin
            if C = '"' then
            begin
              Piece := Piece + '"';
              CurState := SQUOTED;
            end
            else if C = '\' then
            begin
              Piece := Piece + '\';
            end
            else
            begin
              Piece := Piece + '\' + C;
              CurState := SQUOTED;
            end
          end;

        SQUOTED:
          begin
            if C = '\' then
              CurState := SESCAPE
            else if C = '"' then
              CurState := SSINK
            else
              Piece := Piece + C;
          end;
        SSINK:
          begin
            if C = '"' then
            begin
              CurState := SQUOTED;
              if not Piece.IsEmpty then
              begin
                List.Add(Piece);
                Piece := '';
              end;
            end
            else if C = ' ' then
            begin
              if not Piece.IsEmpty then
              begin
                List.Add(Piece);
                Piece := '';
              end;
            end
            else
              Piece := Piece + C;
          end;
      end;
    end;

    if CurState <> SSINK then
      raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_COMMAND);

    if not Piece.IsEmpty then
      List.Add(Piece);

    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TRedisClient.TTL(const aKey: string): Integer;
begin
  FNextCMD := GetCmdList('TTL');
  FNextCMD.Add(aKey);
  FTCPLibInstance.SendCmd(FNextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

procedure TRedisClient.WATCH(const AKeys: array of string);
var
  lKey: string;
begin
  FNextCMD := GetCmdList('WATCH');
  for lKey in AKeys do
  begin
    FNextCMD.Add(lKey);
  end;
  ExecuteWithStringResult(FNextCMD); // ALWAYS 'OK' OR EXCEPTION
end;

function TRedisClient.ZADD(const aKey: string; const AScore: Int64;
  const AMember: string): Integer;
begin
  FNextCMD := GetCmdList('ZADD');
  FNextCMD.Add(aKey).Add(AScore.ToString).Add(AMember);
  Result := ExecuteWithIntegerResult(FNextCMD);
end;

function TRedisClient.ZCARD(const aKey: string): Integer;
begin
  FNextCMD := GetCmdList('ZCARD').Add(aKey);
  Result := ExecuteWithIntegerResult(FNextCMD);
end;

function TRedisClient.ZCOUNT(const aKey: string;
  const AMin, AMax: Int64): Integer;
begin
  FNextCMD := GetCmdList('ZCOUNT');
  FNextCMD.Add(aKey).Add(AMin.ToString).Add(AMax.ToString);
  Result := ExecuteWithIntegerResult(FNextCMD);
end;

function TRedisClient.ZINCRBY(const aKey: string; const AIncrement: Int64;
  const AMember: string): string;
begin
  FNextCMD := GetCmdList('ZINCRBY');
  FNextCMD.Add(aKey).Add(AIncrement.ToString).Add(AMember);
  Result := ExecuteWithStringResult(FNextCMD);
end;

function TRedisClient.ZRANGE(const aKey: string; const AStart, AStop: Int64)
  : TRedisArray;
begin
  FNextCMD := GetCmdList('ZRANGE');
  FNextCMD.Add(aKey).Add(AStart.ToString).Add(AStop.ToString);
  Result := ExecuteAndGetArrayNULL(FNextCMD);
end;

function TRedisClient.ZRANGEWithScore(const aKey: string;
  const AStart, AStop: Int64): TRedisArray;
begin
  FNextCMD := GetCmdList('ZRANGE');
  FNextCMD.Add(aKey).Add(AStart.ToString).Add(AStop.ToString).Add('WITHSCORES');
  Result := ExecuteAndGetArrayNULL(FNextCMD);
end;

function TRedisClient.ZRANK(const aKey: string; const AMember: string;
  out ARank: Int64): boolean;
begin
  FNextCMD := GetCmdList('ZRANK');
  FNextCMD.Add(aKey).Add(AMember);
  ARank := ExecuteWithIntegerResult(FNextCMD);
  Result := ARank <> -1;
end;

function TRedisClient.ZREM(const aKey, AMember: string): Integer;
begin
  FNextCMD := GetCmdList('ZREM');
  FNextCMD.Add(aKey).Add(AMember);
  Result := ExecuteWithIntegerResult(FNextCMD);
end;

function NewRedisClient(const AHostName: string; const APort: Word;
  const ALibName: string): IRedisClient;
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  TCPLibInstance := TRedisNetLibFactory.GET(ALibName);
  Result := TRedisClient.Create(TCPLibInstance, AHostName, APort);
  try
    TRedisClient(Result).Connect;
  except
    Result := nil;
    raise;
  end;
end;

function NewRedisCommand(const RedisCommandString: string): IRedisCommand;
begin
  Result := TRedisCommand.Create;
  TRedisCommand(Result).SetCommand(RedisCommandString);
end;

function TRedisClient.GEOADD(const Key: string;
  const Latitude, Longitude: Extended; Member: string): Integer;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEOADD');
  lCmd.Add(Key);
  lCmd.Add(FormatFloat('0.0000000', Latitude));
  lCmd.Add(FormatFloat('0.0000000', Longitude));
  lCmd.Add(Member);
  Result := ExecuteWithIntegerResult(lCmd);
end;

function TRedisClient.GEODIST(const Key, Member1, Member2: string;
  const &Unit: TRedisGeoUnit): TRedisString;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEODIST');
  lCmd.Add(Key);
  lCmd.Add(Member1);
  lCmd.Add(Member2);
  lCmd.Add(REDIS_GEO_UNIT_STRING[&Unit]);
  Result := ExecuteWithStringResult(lCmd);
end;

function TRedisClient.GEOHASH(const Key: string; const Members: array of string)
  : TRedisArray;
var
  lCmd: IRedisCommand;
  lMember: string;
begin
  lCmd := NewRedisCommand('GEOHASH');
  lCmd.Add(Key);
  for lMember in Members do
  begin
    lCmd.Add(lMember);
  end;
  Result := ExecuteAndGetArrayNULL(lCmd);
end;

function TRedisClient.GEOPOS(const Key: string; const Members: array of string)
  : TRedisMatrix;
var
  lCmd: IRedisCommand;
  lMember: string;
begin
  lCmd := NewRedisCommand('GEOPOS');
  lCmd.Add(Key);
  for lMember in Members do
  begin
    lCmd.Add(lMember);
  end;
  Result := ExecuteAndGetMatrix(lCmd);
end;

function TRedisClient.GEORADIUS(const Key: string;
  const Longitude, Latitude: Extended; const Radius: Extended;
  const &Unit: TRedisGeoUnit; const Sorting: TRedisSorting; const Count: Int64)
  : TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := GetGEORADIUSCommand(Key, Longitude, Latitude, Radius, &Unit,
    Sorting, Count);
  Result := ExecuteAndGetArrayNULL(lCmd);
end;

function TRedisClient.GEORADIUS_WITHDIST(const Key: string;
  const Longitude, Latitude: Extended; const Radius: Extended;
  const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
  const Sorting: TRedisSorting = TRedisSorting.None; const Count: Int64 = -1)
  : TRedisMatrix;
var
  lCmd: IRedisCommand;
begin
  lCmd := GetGEORADIUSCommand(Key, Longitude, Latitude, Radius, &Unit,
    Sorting, Count);
  lCmd.Add('WITHDIST');
  Result := ExecuteAndGetMatrix(lCmd);
end;

function TRedisClient.GET(const aKey: string; out aValue: TBytes): boolean;
begin
  Result := GET(BytesOf(aKey), aValue);
end;

function TRedisClient.GET(const aKey: string): TRedisString;
var
  lResp: TRedisBytes;
begin
  lResp := GET_AsBytes(aKey);
  if lResp.HasValue then
    Result := TRedisString.Create(StringOf(lResp.Value))
  else
    Result := TRedisString.Empty;
end;

end.
