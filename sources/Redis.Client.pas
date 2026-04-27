// *************************************************************************** }
//
// Delphi REDIS Client
//
// Copyright c 2015-2025 Daniele Teti
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
  System.Generics.Collections, System.SysUtils, System.SyncObjs,
  Redis.Command, Redis.Commons, Redis.Values;

type
  TRedisClient = class(TRedisClientBase, IRedisClient)
  private
    FTCPLibInstance: IRedisNetLibAdapter;
    FHostName: string;
    FPort: Word;
    FCommandTimeout: Int32;
    FInTransaction: boolean;
    FIsConnected: boolean;
    FFormatSettings: TFormatSettings;
    FTransactionLock: TCriticalSection;
    function Redis_BytesToString(aValue: TRedisBytes): TRedisString;
    function ParseSimpleStringResponse(var AValidResponse: boolean): string;
    function ParseIntegerResponse(var AValidResponse: boolean): Int64;
    function ParseFloatResponse(var AValidResponse: boolean): Double;
    function ParseRESPArray: TRedisRESPArray;
    procedure InternalParseRESPArray(const aRESPArray: TRedisRESPArray; const aSize: Int64);
    function ParseArrayResponseNULL: TRedisArray;
    function ParseMatrixResponse: TRedisMatrix;
    procedure CheckResponseType(Expected, Actual: string);
    function ParseSimpleStringResponseAsByteNULL: TRedisBytes;
    function ParseSimpleStringResponseAsStringNULL: TRedisString;
    function AppendKeyValueParams(const aRedisCommand: IRedisCommand; const Keys, Values: array of string): String;
  protected
    function BuildZUNIONSTOREDefault(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string): IRedisCommand;

    function GetGEORADIUSCommand(const Key: string;
      const Longitude, Latitude: Extended; const Radius: Extended;
      const &Unit: TRedisGeoUnit; const Sorting: TRedisSorting;
      const Count: Int64): IRedisCommand;

    function POPCommands(const aCommand: string; const aListKey: string): TRedisString;
    procedure CheckResponseError(const aResponse: string);
    function GetCmdList(const Cmd: string): IRedisCommand;
    procedure NextToken(out Msg: string; out AIsTimeout: Boolean);
    function NextBytes(const ACount: UInt32): TBytes;
    function InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand; aKeys: array of string; ATimeout: Int32): TRedisArray; overload;
    constructor Create(TCPLibInstance: IRedisNetLibAdapter; const HostName: string; const Port: Word); overload;
  public
    function Tokenize(const ARedisCommand: string): TArray<string>;
    constructor Create(const HostName: string = '127.0.0.1'; const Port: Word = 6379; const Lib: string = REDIS_NETLIB_INDY); overload;
    destructor Destroy; override;
    procedure Connect;
    { *** Methods using the nullable Redis Values *** }
    function GET(const aKey: string): TRedisString; overload;
    function GET_AsBytes(const aKey: string): TRedisBytes;

    // Redis 6.2+ commands
    function GETEX(const aKey: string; aExpirationMs: UInt64): TRedisString; overload;
    function GETEX(const aKey: string; aExpirationSec: UInt64; const UseSeconds: Boolean): TRedisString; overload;
    function GETDEL(const aKey: string): TRedisString;
    function COPY(const aSourceKey, aDestKey: string; const aReplace: Boolean = False): Boolean;

    function HGET_AsBytes(const aKey, aField: string): TRedisBytes;
    function HGET(const aKey, aField: string): TRedisString; overload;
    function RPOP(const aListKey: string): TRedisString; overload;
    function LPOP(const aListKey: string): TRedisString; overload;
    function BRPOP(const aKeys: array of string; const ATimeout: Int32): TRedisArray; overload;
    function BLPOP(const aKeys: array of string; const ATimeout: Int32): TRedisArray; overload;
    { *********************************************** }
    /// SET key value [EX seconds] [PX milliseconds] [NX|XX]
    function &SET(const aKey, aValue: string): boolean; overload;
    function &SET(const aKey, aValue: TBytes): boolean; overload;
    function &SET(const aKey: string; aValue: TBytes): boolean; overload;
    function &SET(const aKey: TBytes; aValue: TBytes; ASecsExpire: UInt64): boolean; overload;
    function &SET(const aKey: string; aValue: TBytes; ASecsExpire: UInt64): boolean; overload;
    function &SET(const aKey: string; aValue: string; ASecsExpire: UInt64): boolean; overload;
    function SETNX(const aKey, aValue: string): boolean; overload;
    function SETNX(const aKey, aValue: TBytes): boolean; overload;
    function GET(const aKey: string; out aValue: string): boolean; overload;
    function GET(const aKey: TBytes; out aValue: TBytes): boolean; overload;
    function GET(const aKey: string; out aValue: TBytes): boolean; overload;
    function TTL(const aKey: string): Integer;
    function DEL(const aKeys: array of string): Integer;
    function EXISTS(const aKey: string): boolean;
    function INCR(const aKey: string): Int64;
    function DECR(const aKey: string): Int64;
    function INCRBY(const aKey: string; const AValue: Int64): Int64;
    function INCRBYFLOAT(const aKey: string; const AValue: double): double;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TRedisArray;
    function EXPIRE(const aKey: string; AExpireInSecond: UInt32): boolean;
    function RENAME(const aKey, aNewKey: string): boolean;
    function RENAMENX(const aKey, aNewKey: string): boolean;
    function &TYPE(const aKey: string):string;

    // string functions
    function APPEND(const aKey, aValue: TBytes): UInt64; overload;
    function APPEND(const aKey, aValue: string): UInt64; overload;
    function STRLEN(const aKey: string): UInt64;
    function GETRANGE(const aKey: string; const AStart, AEnd: NativeInt): string;
    function SETRANGE(const aKey: string; const AOffset: NativeInt; const aValue: string): NativeInt;

    // hash
    function HSET(const aKey, aField: string; aValue: string): Integer; overload;
    function HSET(const aKey, aField: string; aValue: TBytes): Integer; overload;
    function HSETNX(const aKey, aField: string; aValue: string): Boolean; overload;
    function HSETNX(const aKey, aField: string; aValue: TBytes): Boolean; overload;


    procedure HMSET(const aKey: string; aFields: TArray<string>; aValues: TArray<string>); overload;
    procedure HMSET(const aKey: string; aFields: TArray<string>; aValues: TArray<TBytes>); overload;
    function HMGET(const aKey: string; aFields: TArray<string>): TRedisArray;
    function HGET(const aKey, aField: string; out aValue: TBytes): boolean; overload;
    function HGET(const aKey, aField: string; out aValue: string): boolean; overload;
    function HDEL(const aKey: string; aFields: TArray<string>): Integer;
    function HKEYS(const aKey: string): TRedisArray;
    function HVALS(const aKey: string): TRedisArray;
    function HEXISTS(const aKey, aField: string): Boolean;
    function HLEN(const aKey: string): Integer;
    function HINCRBY(const aKey, aField: string; const AIncrement: NativeInt): Integer;
    function HINCRBYFLOAT(const aKey, aField: string; const AIncrement: Double): Double;
    // lists
{$REGION LIST COMMANDS}
    function RPUSH(const aListKey: string; aValues: array of string): Integer;
    function RPUSHX(const aListKey: string; aValues: array of string): Integer;
    function RPOP(const aListKey: string; var Value: string): boolean; overload;
    function LPUSH(const aListKey: string; aValues: array of string): Integer;
    function LPUSHX(const aListKey: string; aValues: array of string): Integer;
    function LPOP(const aListKey: string; out Value: string): boolean; overload;
    function LRANGE(const aListKey: string; aIndexStart, aIndexStop: Integer): TRedisArray;
    function LLEN(const aListKey: string): Integer;
    procedure LTRIM(const aListKey: string; const aIndexStart, aIndexStop: Integer);
    function RPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string): boolean; overload;
    function BRPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string; ATimeout: Int32): boolean; overload;
    function BLPOP(const aKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean; overload;
    function BRPOP(const aKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean; overload;
    function LREM(const aListKey: string; const ACount: Integer; const aValue: string): Integer;
    procedure LSET(const aListKey: string; const aIndex: Integer; const aValue: string);
    function LINDEX(const aListKey: string; const AIndex: Integer): string; overload;
    function LINDEX(const aListKey: string; const AIndex: Integer; out AValue: string): boolean; overload;

{$ENDREGION}
    // pubsub
{$REGION PUBSUB}
    procedure SUBSCRIBE(const AChannels: array of string;
      aCallback: TProc<string, string>;
      aContinueOnTimeoutCallback: TRedisTimeoutCallback = nil;
      aAfterSubscribe: TRedisAction = nil);
    function PUBLISH(const AChannel: string; AMessage: string): Integer;
    // sets
    function SADD(const aKey, aValue: TBytes): Integer; overload;
    function SADD(const aKey, aValue: string): Integer; overload;
    function SDIFF(const aKeys: array of string): TRedisArray;
    function SREM(const aKey, aValue: TBytes): Integer; overload;
    function SREM(const aKey, aValue: string): Integer; overload;
    function SMEMBERS(const aKey: string): TRedisArray;
    function SISMEMBER(const aKey, aValue: TBytes): Integer; overload;
    function SISMEMBER(const aKey, aValue: string): Integer; overload;
    function SCARD(const aKey: string): Integer;
    function SUNION(const aKeys: array of string): TRedisArray;
    function SUNIONSTORE(const aDestination: string; const aKeys: array of string): Integer;
    // Redis 6.2+ Set commands
    function SMOVE(const aSource, aDestination, aMember: string): Boolean;
{$ENDREGION}
    // ordered sets
{$REGION ORDEREDSETS}
    function ZADD(const aKey: string; const AScore: Int64; const AMember: string): Integer;
    function ZREM(const aKey: string; const AMember: string): Integer;
    function ZCARD(const aKey: string): Integer;
    function ZCOUNT(const aKey: string; const AMin, AMax: Int64): Integer;
    function ZRANK(const aKey: string; const AMember: string; out ARank: Int64): boolean;
    function ZRANGE(const aKey: string; const AStart, AStop: Int64; const aScoreMode: TRedisScoreMode = TRedisScoreMode.WithoutScores): TRedisArray;
    function ZREVRANGE(const aKey: string; const AStart, AStop: Int64; const aScoreMode: TRedisScoreMode = TRedisScoreMode.WithoutScores): TRedisArray;
    // function ZRANGEWithScore(const aKey: string; const AStart, AStop: Int64)
    // : TRedisArray;
    function ZINCRBY(const aKey: string; const AIncrement: Int64; const AMember: string): string;
    function ZUNIONSTORE(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string): Int64; overload;
    function ZUNIONSTORE(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string; const aWeights: array of Integer): Int64; overload;
    function ZUNIONSTORE(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string; const aWeights: array of Integer; const aAggregate: TRedisAggregate): Int64; overload;
    // Redis 5.0+ Sorted Set commands
    function ZPOPMIN(const aKey: string): TRedisArray; overload;
    function ZPOPMIN(const aKey: string; aCount: Integer): TRedisArray; overload;
    function ZPOPMAX(const aKey: string): TRedisArray; overload;
    function ZPOPMAX(const aKey: string; aCount: Integer): TRedisArray; overload;
{$ENDREGION}
    // geo REDIS 3.2
    function GEOADD(const Key: string; const Latitude, Longitude: Extended; Member: string): Integer;
    function GEODIST(const Key: string; const Member1, Member2: string; const &Unit: TRedisGeoUnit): TRedisString;
    function GEOHASH(const Key: string; const Members: array of string): TRedisArray;
    function GEOPOS(const Key: string; const Members: array of string): TRedisMatrix;
    function GEORADIUS(const Key: string; const Longitude, Latitude: Extended;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisArray;
    function GEORADIUS_WITHDIST(const Key: string;
      const Longitude, Latitude: Extended; const Radius: Extended;
      const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisMatrix;
    // Redis 6.2+ Geo commands
    function GEOSEARCH(const Key: string; const FromMember: string;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisArray; overload;
    function GEOSEARCH(const Key: string; const Longitude, Latitude: Extended;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisArray; overload;
    function GEOSEARCHSTORE(const Destination, Source: string; const FromMember: string;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): Integer; overload;
    function GEOSEARCHSTORE(const Destination, Source: string; const Longitude, Latitude: Extended;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): Integer; overload;

    {$REGION STREAMS}
      function XADD(const aStreamName: String; const MaxLength: UInt64; const MaxLengthType: TRedisMaxLengthType; const Keys, Values: array of string; const ID: UInt64 = 0): String; overload;
      function XADD(const aStreamName: String; const Keys, Values: array of string; const ID: UInt64 = 0): String; overload;
    {$ENDREGION}

    // lua scripts
    function EVAL(const AScript: string; aKeys: array of string; aValues: array of string): Integer;
    // system
    procedure FLUSHDB;
    procedure FLUSHALL;
    function PING: string;
    procedure SELECT(const ADBIndex: Integer);
    procedure AUTH(const aPassword: string); overload;
    procedure AUTH(const aUsername, aPassword: string); overload;
    function MOVE(const aKey: string; const aDB: Byte): boolean;
    function PERSIST(const aKey: string): boolean;
    function RANDOMKEY: TRedisString;
    procedure SCAN(aPattern: string; aCallback: TProc<TArray<string>>);
    // non system
    function InTransaction: boolean;
    // transations
    function MULTI(ARedisTansactionProc: TRedisTransactionProc): TRedisArray; overload;
    procedure MULTI; overload;
    function EXEC: TRedisArray;
    procedure WATCH(const aKeys: array of string);
    procedure DISCARD;
    // raw execute
    function ExecuteAndGetRESPArray(const RedisCommand: IRedisCommand): TRedisRESPArray;
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand): TRedisArray;
    function ExecuteAndGetArrayNULL(const RedisCommand: IRedisCommand): TRedisArray;
    function ExecuteAndGetMatrix(const RedisCommand: IRedisCommand): TRedisMatrix;
    function ExecuteWithIntegerResult(const RedisCommand: IRedisCommand): Int64; overload;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand): TRedisString;
    procedure Disconnect;
    function IsConnected: Boolean; overload;
    function IsConnected(const aVerifyConnection: Boolean): Boolean; overload;
    procedure SetCommandTimeout(const Timeout: Int32);
    // client
    procedure ClientSetName(const ClientName: string);
    function INFO(const ASection: string = ''): string;
    function Clone: IRedisClient;
    function Adapter: IRedisNetLibAdapter;
  end;

function NewRedisClient(const AHostName: string = 'localhost'; const APort: Word = 6379; const ALibName: string = REDIS_NETLIB_INDY): IRedisClient;
function NewRedisCommand(const RedisCommandString: string): IRedisCommand;

implementation

uses Redis.NetLib.Factory;

const
  REDIS_GEO_UNIT_STRING: array [TRedisGeoUnit.Meters .. TRedisGeoUnit.Feet] of string = ('m', 'km', 'mi', 'ft');
  REDIS_AGGREGATE: array [TRedisAggregate.Sum .. TRedisAggregate.Max] of string = ('SUM', 'MIN', 'MAX');

  { TRedisClient }

function TRedisClient.SADD(const aKey, aValue: TBytes): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('SADD').Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.SADD(const aKey, aValue: string): Integer;
begin
  Result := SADD(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

procedure TRedisClient.SCAN(aPattern: string; aCallback: TProc<TArray<string>>);
var
  lCmd: IRedisCommand;
  aCursor: integer;
  AResp: TRedisRESPArray;
  AKey: string;
  Values: TArray<string>;
begin
  aCursor := 0;
{$HINTS OFF} // H2443 - about inline function
  repeat
    lCmd := NewRedisCommand('SCAN');
    lCmd.Add(aCursor);
    lCmd.Add('MATCH');
    lCmd.Add(Apattern);
    AResp := ExecuteAndGetRESPArray(lCmd);
    try
      ACursor := AResp.I[0];
      SetLength(Values, 0);
      for AKey in AResp[1].ArrayValue do
        Values := Values + [AKey];
    finally
      AResp.Free;
    end;
    aCallback(Values);
  until aCursor = 0;
end;

function TRedisClient.SCARD(const aKey: string): Integer;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('SCARD').Add(aKey);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.SDIFF(const aKeys: array of string): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('SDIFF').AddRange(aKeys);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

procedure TRedisClient.SELECT(const ADBIndex: Integer);
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('SELECT').Add(ADBIndex.ToString);
  ExecuteWithStringResult(LCmd);
end;

function TRedisClient.&SET(const aKey, aValue: TBytes): boolean;
var
  LCmd: IRedisCommand;
  lRes: TRedisString;
begin
  LCmd := GetCmdList('SET');
  LCmd.Add(aKey);
  LCmd.Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  lRes := ParseSimpleStringResponseAsStringNULL;
  Result := lRes.HasValue;
end;

function TRedisClient.&SET(const aKey: string; aValue: TBytes): boolean;
begin
  Result := &SET(BytesOf(aKey), aValue);
end;

function TRedisClient.APPEND(const aKey, aValue: TBytes): UInt64;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('APPEND');
  LCmd.Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.APPEND(const aKey, aValue: string): UInt64;
begin
  Result := APPEND(BytesOf(aKey), BytesOf(aValue));
end;

procedure TRedisClient.AUTH(const aPassword: string);
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('AUTH');
  LCmd.Add(aPassword);
  FTCPLibInstance.SendCmd(LCmd);
  ParseSimpleStringResponse(LValid);
end;

procedure TRedisClient.AUTH(const aUsername, aPassword: string);
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('AUTH');
  LCmd.Add(aUsername).Add(aPassword);
  FTCPLibInstance.SendCmd(LCmd);
  ParseSimpleStringResponse(LValid);
end;

function TRedisClient.BLPOP(const aKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
var
  LCmd: IRedisCommand;
  lRes: TRedisArray;
begin
  LCmd := GetCmdList('BLPOP');
  lRes := InternalBlockingLeftOrRightPOP(LCmd, aKeys, ATimeout);
  Result := lRes.HasValue;
  if Result then
    Value := lRes.ToArray;
end;

function TRedisClient.BLPOP(const aKeys: array of string; const ATimeout: Int32): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('BLPOP');
  Result := InternalBlockingLeftOrRightPOP(LCmd, aKeys, ATimeout);
end;

function TRedisClient.BRPOP(const aKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
var
  LCmd: IRedisCommand;
  lRes: TRedisArray;
begin
  LCmd := GetCmdList('BRPOP');
  lRes := InternalBlockingLeftOrRightPOP(LCmd, aKeys, ATimeout);
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
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('CLIENT');
  LCmd.Add('SETNAME');
  LCmd.Add(ClientName);
  FTCPLibInstance.SendCmd(LCmd);
  CheckResponseType('OK', ParseSimpleStringResponse(LValid));
end;

function TRedisClient.Clone: IRedisClient;
begin
  Result := NewRedisClient(FHostName, FPort, FTCPLibInstance.LibName);
end;

function TRedisClient.Adapter: IRedisNetLibAdapter;
begin
  Result := FTCPLibInstance;
end;

procedure TRedisClient.Connect;
begin
  FTCPLibInstance.Connect(FHostName, FPort);
  FIsConnected := True;
end;

constructor TRedisClient.Create(const HostName: string; const Port: Word; const Lib: string);
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  inherited Create;
  TCPLibInstance := TRedisNetLibFactory.GET(Lib);
  Create(TCPLibInstance, HostName, Port);
  FFormatSettings.DecimalSeparator := '.';
end;

constructor TRedisClient.Create(TCPLibInstance: IRedisNetLibAdapter; const HostName: string; const Port: Word);
begin
  inherited Create;
  FTCPLibInstance := TCPLibInstance;
  FHostName := HostName;
  FPort := Port;
  FTransactionLock := TCriticalSection.Create;
  FCommandTimeout := -1;
end;

function TRedisClient.DECR(const aKey: string): Int64;
var
  LValid: Boolean;
begin
  FTCPLibInstance.SendCmd(GetCmdList('DECR').Add(aKey));
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.DEL(const aKeys: array of string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('DEL');
  LCmd.AddRange(aKeys);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

destructor TRedisClient.Destroy;
begin
  FTransactionLock.Free;
  inherited;
end;

procedure TRedisClient.DISCARD;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('DISCARD');
  FTCPLibInstance.SendCmd(LCmd);
  ParseSimpleStringResponseAsStringNULL;
end;

procedure TRedisClient.Disconnect;
begin
  try
    FIsConnected := False;
    FTCPLibInstance.Disconnect;
  except
  end;
end;

function TRedisClient.IsConnected: Boolean;
begin
  Result := FIsConnected;
end;

function TRedisClient.IsConnected(const aVerifyConnection: Boolean): Boolean;
begin
  if aVerifyConnection and FIsConnected then
  begin
    try
      PING;
    except
      FIsConnected := False;
    end;
  end;
  Result := FIsConnected;
end;

function TRedisClient.ExecuteWithIntegerResult(const RedisCommand: IRedisCommand): Int64;
var
  LValid: Boolean;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.ExecuteWithStringResult(const RedisCommand: IRedisCommand): TRedisString;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseSimpleStringResponseAsStringNULL;
end;

function TRedisClient.EXISTS(const aKey: string): boolean;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('EXISTS');
  LCmd.Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid) = 1;
end;

function TRedisClient.EXPIRE(const aKey: string; AExpireInSecond: UInt32): boolean;
var
  LValid: Boolean;
begin
  FTCPLibInstance
  .Write(GetCmdList('EXPIRE')
  .Add(aKey)
  .Add(AExpireInSecond.ToString).ToRedisCommand);

  {
    1 if the timeout was set.
    0 if key does not exist or the timeout could not be set.
  }
  Result := ParseIntegerResponse(LValid) = 1;
end;

function TRedisClient.RENAME(const aKey, aNewKey: string): boolean;
var
  LCmd: IRedisCommand;
  lRes: TRedisString;
begin
  LCmd := GetCmdList('RENAME');
  LCmd.Add(aKey);
  LCmd.Add(aNewKey);
  FTCPLibInstance.SendCmd(LCmd);
  lRes := ParseSimpleStringResponseAsStringNULL;
  Result := lRes.HasValue;
end;

function TRedisClient.RENAMENX(const aKey, aNewKey: string): boolean;
var
  LCmd: IRedisCommand;
  lRes: TRedisString;
begin
  LCmd := GetCmdList('RENAMENX');
  LCmd.Add(aKey);
  LCmd.Add(aNewKey);
  FTCPLibInstance.SendCmd(LCmd);
  lRes := ParseSimpleStringResponseAsStringNULL;
  Result := lRes.HasValue;
end;

function TRedisClient.&TYPE(const aKey: string): string;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('TYPE');
  LCmd.Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseSimpleStringResponse(LValid);
end;

function TRedisClient.EVAL(const AScript: string; aKeys, aValues: array of string): Integer;
var
  lCmd: IRedisCommand;
  lParamsCount: Integer;
  lPar: string;
begin
  lCmd := NewRedisCommand('EVAL');
  lParamsCount := Length(aKeys);
  lCmd.Add(AScript).Add(IntToStr(lParamsCount));

  if lParamsCount > 0 then
  begin
    for lPar in aKeys do
    begin
      lCmd.Add(lPar);
    end;
  end;
  
  for lPar in aValues do
  begin
    lCmd.Add(lPar);
  end;

  Result := ExecuteWithIntegerResult(lCmd);
end;

function TRedisClient.EXEC: TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('EXEC');
  FTCPLibInstance.SendCmd(LCmd);
  FTransactionLock.Enter;
  try
    FInTransaction := False;
  finally
    FTransactionLock.Leave;
  end;
  Result := ParseArrayResponseNULL;
  if Result.IsNull then
    raise ERedisException.Create('Transaction failed');
end;

function TRedisClient.ExecuteAndGetArray(const RedisCommand: IRedisCommand): TRedisArray;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseArrayResponseNULL;
  // Result := ParseArrayResponse(FValidResponse);
  // if FTCPLibInstance.LastReadWasTimedOut then
  // Exit;
  // if not FValidResponse then
  // raise ERedisException.Create('Not valid response');
end;

function TRedisClient.ExecuteAndGetArrayNULL(const RedisCommand: IRedisCommand): TRedisArray;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseArrayResponseNULL;
  if FTCPLibInstance.LastReadWasTimedOut then
    Exit;
end;

function TRedisClient.ExecuteAndGetMatrix(const RedisCommand: IRedisCommand): TRedisMatrix;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseMatrixResponse;
  if FTCPLibInstance.LastReadWasTimedOut then
    Exit;
end;

function TRedisClient.ExecuteAndGetRESPArray(const RedisCommand: IRedisCommand): TRedisRESPArray;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseRESPArray;
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
var
  LValid: Boolean;
begin
  FTCPLibInstance.SendCmd(GetCmdList('FLUSHDB'));
  ParseSimpleStringResponse(LValid);
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
  Result := TRedisCommand.Create;
  Result.SetCommand(Cmd);
end;

function TRedisClient.GetGEORADIUSCommand(const Key: string; const Longitude, Latitude, Radius: Extended; const &Unit: TRedisGeoUnit; const Sorting: TRedisSorting; const Count: Int64): IRedisCommand;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEORADIUS');
  lCmd.Add(Key);
  lCmd.Add(FormatFloat('0.0000000', Longitude));
  lCmd.Add(FormatFloat('0.0000000', Latitude));
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

function TRedisClient.GETRANGE(const aKey: string; const AStart, AEnd: NativeInt): string;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('GETRANGE').Add(aKey).Add(AStart).Add(AEnd);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseSimpleStringResponse(LValid);
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

function TRedisClient.HGET(const aKey, aField: string; out aValue: TBytes): boolean;
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
  LValid: Boolean;
begin
  lCommand := GetCmdList('HDEL');
  lCommand.Add(aKey);
  lCommand.AddRange(aFields);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.HEXISTS(const aKey, aField: string): Boolean;
var
  lCommand: IRedisCommand;
  LValid: Boolean;
begin
  lCommand := GetCmdList('HEXISTS');
  lCommand.Add(aKey);
  lCommand.Add(aField);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseIntegerResponse(LValid) = 1;
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

function TRedisClient.HINCRBY(const aKey, aField: string; const AIncrement: NativeInt): Integer;
var
  lCommand: IRedisCommand;
  LValid: Boolean;
begin
  lCommand := GetCmdList('HINCRBY');
  lCommand.Add(aKey);
  lCommand.Add(aField);
  lCommand.Add(AIncrement);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.HINCRBYFLOAT(const aKey, aField: string; const AIncrement: Double): Double;
var
  lCommand: IRedisCommand;
  LValid: Boolean;
begin
  lCommand := GetCmdList('HINCRBYFLOAT');
  lCommand.Add(aKey);
  lCommand.Add(aField);
  lCommand.Add(AIncrement);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseFloatResponse(LValid);
end;

function TRedisClient.HKEYS(const aKey: string): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('HKEYS');
  LCmd.Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.HLEN(const aKey: string): Integer;
var
  lCommand: IRedisCommand;
  LValid: Boolean;
begin
  lCommand := GetCmdList('HLEN');
  lCommand.Add(aKey);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.HMGET(const aKey: string; aFields: TArray<string>): TRedisArray;
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

procedure TRedisClient.HMSET(const aKey: string; aFields: TArray<string>; aValues: TArray<TBytes>);
var
  LCmd: IRedisCommand;
  I: Integer;
begin
  if Length(aFields) <> Length(aValues) then
    raise ERedisException.Create('Fields count and values count are different');

  LCmd := GetCmdList('HMSET');
  LCmd.Add(aKey);
  for I := low(aFields) to high(aFields) do
  begin
    LCmd.Add(aFields[I]);
    LCmd.Add(aValues[I]);
  end;
  FTCPLibInstance.SendCmd(LCmd);
  if FInTransaction then
    CheckResponseType('QUEUED', ParseSimpleStringResponseAsStringNULL.Value)
  else
    CheckResponseType('OK', ParseSimpleStringResponseAsStringNULL.Value);
end;

procedure TRedisClient.HMSET(const aKey: string; aFields: TArray<string>; aValues: TArray<string>);
var
  LCmd: IRedisCommand;
  I: Integer;
begin
  if Length(aFields) <> Length(aValues) then
    raise ERedisException.Create('Fields count and values count are different');

  LCmd := GetCmdList('HMSET');
  LCmd.Add(aKey);
  for I := low(aFields) to high(aFields) do
  begin
    LCmd.Add(aFields[I]);
    LCmd.Add(aValues[I]);
  end;
  FTCPLibInstance.SendCmd(LCmd);
  if FInTransaction then
    CheckResponseType('QUEUED', ParseSimpleStringResponseAsStringNULL.Value)
  else
    CheckResponseType('OK', ParseSimpleStringResponseAsStringNULL.Value);
end;

function TRedisClient.HSET(const aKey, aField: string; aValue: TBytes): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('HSET');
  LCmd.Add(aKey);
  LCmd.Add(aField);
  LCmd.Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.HSETNX(const aKey, aField: string;
  aValue: TBytes): Boolean;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('HSETNX');
  LCmd.Add(aKey);
  LCmd.Add(aField);
  LCmd.Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid) = 1;
end;

function TRedisClient.HSETNX(const aKey, aField: string;
  aValue: string): Boolean;
begin
  Result := HSETNX(aKey, aField,BytesOfUnicode(aValue));
end;

function TRedisClient.HVALS(const aKey: string): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('HVALS');
  LCmd.Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.INCR(const aKey: string): Int64;
var
  LValid: Boolean;
begin
  FTCPLibInstance.SendCmd(GetCmdList('INCR').Add(aKey));
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.INCRBY(const aKey: string; const AValue: Int64): Int64;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('INCRBY');
  LCmd.Add(aKey);
  LCmd.Add(AValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.INCRBYFLOAT(const aKey: string; const AValue: double): double;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('INCRBYFLOAT');
  LCmd.Add(aKey);
  LCmd.Add(AValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseFloatResponse(LValid);
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

function TRedisClient.InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand; aKeys: array of string; ATimeout: Int32): TRedisArray;
begin
  NextCMD.AddRange(aKeys);
  NextCMD.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponseNULL;
end;

procedure TRedisClient.InternalParseRESPArray(const aRESPArray: TRedisRESPArray; const aSize: Int64);
var
  lTokenType: Char;
  lArrLen: Int64;
  lStrValue: String;
  I: Integer;
  R: string;
  lStrSize: Integer;
  lIntValue: Integer;
  LIsTimeout: Boolean;
begin
  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"

  for I := 0 to aSize - 1 do
  begin
    NextToken(R, LIsTimeout);
    CheckResponseError(R);
    lTokenType := R.Chars[0];
    if lTokenType = '*' then { parse RESP array }
    begin
      lArrLen := R.Substring(1).ToInteger;
      InternalParseRESPArray(aRESPArray.AddArray, lArrLen);
    end
    else if lTokenType = '$' then { parse string }
    begin
      lStrSize := R.Substring(1).ToInteger;
      lStrValue := Redis_BytesToString(FTCPLibInstance.ReceiveBytes(lStrSize, FCommandTimeout));
      // eat crlf
      FTCPLibInstance.ReceiveBytes(2, FCommandTimeout);
      aRESPArray.Add(lStrValue);
    end
    else if lTokenType = ':' then { parse integer }
    begin
      lIntValue := R.Substring(1).ToInteger;
      // eat crlf
      FTCPLibInstance.ReceiveBytes(2, FCommandTimeout);
      aRESPArray.Add(lIntValue);
    end
    else
    begin
      raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_ARRAY_RESPONSE);
    end;
  end;
end;

function TRedisClient.InTransaction: boolean;
begin
  FTransactionLock.Enter;
  try
    Result := FInTransaction;
  finally
    FTransactionLock.Leave;
  end;
end;

function TRedisClient.KEYS(const AKeyPattern: string): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('KEYS');
  LCmd.Add(BytesOfUnicode(AKeyPattern));
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.LINDEX(const aListKey: string; const AIndex: Integer; out AValue: string): boolean;
var
  LCmd: IRedisCommand;
  lRes: TRedisNullable<TBytes>;
begin
  LCmd := GetCmdList('LINDEX');
  LCmd.Add(aListKey);
  LCmd.Add(AIndex);
  FTCPLibInstance.SendCmd(LCmd);
  lRes := ParseSimpleStringResponseAsByteNULL;
  Result := lRes.HasValue;
  if Result then
    aValue := StringOfUnicode(lRes.Value);
end;

function TRedisClient.LINDEX(const aListKey: string; const AIndex: Integer): string;
begin
  if not LINDEX(aListKey, AIndex, result) then
    exit('');
end;

function TRedisClient.LLEN(const aListKey: string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('LLEN');
  LCmd.Add(aListKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.LPOP(const aListKey: string; out Value: string): boolean;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('LPOP');
  LCmd.Add(aListKey);
  FTCPLibInstance.SendCmd(LCmd);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.LPOP(const aListKey: string): TRedisString;
begin
  Result := POPCommands('LPOP', aListKey);
end;

function TRedisClient.LPUSH(const aListKey: string; aValues: array of string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('LPUSH');
  LCmd.Add(aListKey);
  LCmd.AddRange(aValues);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.LPUSHX(const aListKey: string; aValues: array of string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('LPUSHX');
  LCmd.Add(aListKey);
  LCmd.AddRange(aValues);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.LRANGE(const aListKey: string; aIndexStart, aIndexStop: Integer): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('LRANGE');
  LCmd.Add(aListKey);
  LCmd.Add(aIndexStart.ToString);
  LCmd.Add(aIndexStop.ToString);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.LREM(const aListKey: string; const ACount: Integer; const aValue: string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('LREM');
  LCmd.Add(aListKey);
  LCmd.Add(ACount.ToString);
  LCmd.Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

procedure TRedisClient.LSET(const aListKey: string; const aIndex: Integer; const aValue: string);
var
  LCmd: IRedisCommand;
  lResult: string;
begin
  LCmd := GetCmdList('LSET');
  LCmd.Add(aListKey);
  LCmd.Add(aIndex.ToString);
  LCmd.Add(aValue);
  lResult := ExecuteWithStringResult(LCmd);
  if lResult <> 'OK' then
    raise ERedisException.Create(lResult);
end;

procedure TRedisClient.LTRIM(const aListKey: string; const aIndexStart, aIndexStop: Integer);
var
  LCmd: IRedisCommand;
  lResult: string;
begin
  LCmd := GetCmdList('LTRIM').Add(aListKey).Add(aIndexStart.ToString)
    .Add(aIndexStop.ToString);
  lResult := ExecuteWithStringResult(LCmd);
  if lResult <> 'OK' then
    raise ERedisException.Create(lResult);
end;

function TRedisClient.MOVE(const aKey: string; const aDB: Byte): boolean;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('MOVE').Add(aKey).Add(aDB.ToString);
  Result := ExecuteWithIntegerResult(LCmd) = 1;
end;

function TRedisClient.MSET(const AKeysValues: array of string): boolean;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('MSET');
  LCmd.AddRange(AKeysValues);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseSimpleStringResponse(LValid) = 'OK';
end;

procedure TRedisClient.MULTI;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('MULTI');
  FTCPLibInstance.SendCmd(LCmd);
  ParseSimpleStringResponse(LValid);
  FTransactionLock.Enter;
  try
    FInTransaction := True;
  finally
    FTransactionLock.Leave;
  end;
end;

function TRedisClient.MULTI(ARedisTansactionProc: TRedisTransactionProc): TRedisArray;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('MULTI');
  try
    FTCPLibInstance.SendCmd(LCmd);
    ParseSimpleStringResponse(LValid);
    FTransactionLock.Enter;
    try
      FInTransaction := True;
    finally
      FTransactionLock.Leave;
    end;
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
    FTransactionLock.Enter;
    try
      FInTransaction := False;
    finally
      FTransactionLock.Leave;
    end;
  end;
end;

procedure TRedisClient.NextToken(out Msg: string; out AIsTimeout: Boolean);
begin
  Msg := FTCPLibInstance.Receive(FCommandTimeout);
  AIsTimeout := FTCPLibInstance.LastReadWasTimedOut;
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
  LIsTimeout: Boolean;
begin
  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"
  Result := nil;
  NextToken(R, LIsTimeout);
  if LIsTimeout then
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

function TRedisClient.ParseFloatResponse(var AValidResponse: boolean): Double;
var
  LFormatSettings: TFormatSettings;
  LResponse: string;
 begin
  Result := -1;

  LFormatSettings.DecimalSeparator := '.';
  LResponse := ParseSimpleStringResponse(AValidResponse);
  TryStrtoFloat(LResponse, Result, LFormatSettings);
end;

function TRedisClient.ParseIntegerResponse(var AValidResponse: boolean): Int64;
var
  R: string;
  I: Int64;
  HowMany: Integer;
  LIsTimeout: Boolean;
  LValid: Boolean;
begin
  Result := -1;
  if FInTransaction then
  begin
    R := ParseSimpleStringResponse(LValid);
    if R <> 'QUEUED' then
      raise ERedisException.Create(R);
    Exit;
  end;

  NextToken(R, LIsTimeout);
  if LIsTimeout then
    Exit;
  CheckResponseError(R);

  case R.Chars[0] of
    ':':
      begin
        if not TryStrToInt64(R.Substring(1), I) then
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
  LIsTimeout: Boolean;
begin
  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"
  Result := nil;
  NextToken(R, LIsTimeout);
  if LIsTimeout then
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

function TRedisClient.ParseRESPArray: TRedisRESPArray;
var
  lTokenType: String;
  R: String;
  lArrLength: Int64;
  LIsTimeout: Boolean;
begin
  // In RESP, the type of some data depends on the first byte:
  // For Simple Strings the first byte of the reply is "+"
  // For Errors the first byte of the reply is "-"
  // For Integers the first byte of the reply is ":"
  // For Bulk Strings the first byte of the reply is "$"
  // For Arrays the first byte of the reply is "*"
  Result := nil;
  NextToken(R, LIsTimeout);
  if LIsTimeout then
    Exit;
  CheckResponseError(R);

  if R = TRedisConsts.NULL_ARRAY then
  begin
    Exit;
  end;

  lTokenType := R.Chars[0];
  if lTokenType = '*' then
  begin
    lArrLength := R.Substring(1).ToInteger;
  end
  else
  begin
    raise ERedisException.Create(TRedisConsts.ERR_NOT_A_VALID_ARRAY_RESPONSE);
  end;

  Result := TRedisRESPArray.Create;
  try
    if lArrLength = 0 then
    begin
      Exit;
    end;
    InternalParseRESPArray(Result, lArrLength);
  except
    Result.Free;
    raise;
  end;
end;

function TRedisClient.ParseSimpleStringResponse(var AValidResponse: boolean): string;
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
  LIsTimeout: Boolean;
begin
  Result := nil;
  NextToken(R, LIsTimeout);
  if LIsTimeout then
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
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('PERSIST').Add(aKey);
  Result := ExecuteWithIntegerResult(LCmd) = 1;
end;

function TRedisClient.PING: string;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('PING');
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseSimpleStringResponse(LValid);
end;

function TRedisClient.POPCommands(const aCommand: string;
  const aListKey: string): TRedisString;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList(aCommand);
  LCmd.Add(aListKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := Redis_BytesToString(ParseSimpleStringResponseAsByteNULL);
end;

function TRedisClient.PUBLISH(const AChannel: string; AMessage: string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('PUBLISH');
  LCmd.Add(AChannel);
  LCmd.Add(AMessage);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.RANDOMKEY: TRedisString;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('RANDOMKEY');
  Result := ExecuteWithStringResult(LCmd);
end;

function TRedisClient.Redis_BytesToString(aValue: TRedisBytes): TRedisString;
begin
  if aValue.HasValue then
    Result := TRedisString.Create(StringOf(aValue.Value))
  else
    Result := TRedisString.Empty;
end;

function TRedisClient.RPOP(const aListKey: string; var Value: string): boolean;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('RPOP');
  LCmd.Add(aListKey);
  FTCPLibInstance.SendCmd(LCmd);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.BRPOP(const aKeys: array of string; const ATimeout: Int32): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('BRPOP');
  Result := InternalBlockingLeftOrRightPOP(LCmd, aKeys, ATimeout);
end;

function TRedisClient.BRPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string; ATimeout: Int32): boolean;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
  lValue: string;
begin
  APoppedAndPushedElement := '';
  LCmd := GetCmdList('BRPOPLPUSH');
  LCmd.Add(ARightListKey);
  LCmd.Add(ALeftListKey);
  LCmd.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(LCmd);

  lValue := ParseSimpleStringResponse(LValid);
  Result := LValid;
  if Result then
  begin
    APoppedAndPushedElement := lValue;
  end;
end;

function TRedisClient.BuildZUNIONSTOREDefault(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string): IRedisCommand;
var
  lKey: string;
begin
  Result := GetCmdList('ZUNIONSTORE');
  Result.Add(aDestination).Add(aNumKeys);
  for lKey in aKeys do
  begin
    Result.Add(lKey);
  end;
end;

function TRedisClient.RPOP(const aListKey: string): TRedisString;
begin
  Result := POPCommands('RPOP', aListKey);
end;

function TRedisClient.RPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string): boolean;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('RPOPLPUSH');
  LCmd.Add(ARightListKey);
  LCmd.Add(ALeftListKey);
  FTCPLibInstance.SendCmd(LCmd);
  APoppedAndPushedElement := ParseSimpleStringResponse(LValid);
  Result := LValid;
end;

function TRedisClient.RPUSH(const aListKey: string; aValues: array of string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('RPUSH');
  LCmd.Add(aListKey);
  LCmd.AddRange(aValues);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.RPUSHX(const aListKey: string; aValues: array of string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('RPUSHX');
  LCmd.Add(aListKey);
  LCmd.AddRange(aValues);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
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

function TRedisClient.&SET(const aKey: string; aValue: TBytes; ASecsExpire: UInt64): boolean;
begin
  Result := &SET(BytesOfUnicode(aKey), aValue, ASecsExpire);
end;

function TRedisClient.&SET(const aKey: TBytes; aValue: TBytes; ASecsExpire: UInt64): boolean;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('SET');
  LCmd.Add(aKey);
  LCmd.Add(aValue);
  LCmd.Add('EX');
  LCmd.Add(IntToStr(ASecsExpire));
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseSimpleStringResponseAsByteNULL.HasValue
end;

function TRedisClient.&SET(const aKey: string; aValue: string; ASecsExpire: UInt64): boolean;
begin
  Result := &SET(BytesOfUnicode(aKey), BytesOfUnicode(aValue), ASecsExpire);
end;

function TRedisClient.SETNX(const aKey, aValue: TBytes): boolean;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('SETNX');
  LCmd.Add(aKey);
  LCmd.Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid) = 1;
end;

function TRedisClient.SETRANGE(const aKey: string; const AOffset: NativeInt; const aValue: string): NativeInt;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('SETRANGE').Add(aKey).Add(AOffset).Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.SISMEMBER(const aKey, aValue: string): Integer;
begin
  Result := SISMEMBER(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

function TRedisClient.SISMEMBER(const aKey, aValue: TBytes): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('SISMEMBER').Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.SMEMBERS(const aKey: string): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('SMEMBERS').Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.SREM(const aKey, aValue: string): Integer;
begin
  Result := SREM(BytesOfUnicode(aKey), BytesOfUnicode(aValue));
end;

function TRedisClient.STRLEN(const aKey: string): UInt64;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('STRLEN').Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.SREM(const aKey, aValue: TBytes): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('SREM').Add(aKey).Add(aValue);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

procedure TRedisClient.SUBSCRIBE(const AChannels: array of string; aCallback: TProc<string, string>; aContinueOnTimeoutCallback: TRedisTimeoutCallback = nil; aAfterSubscribe: TRedisAction = nil);
var
  LCmd: IRedisCommand;
  I: Integer;
  lChannel, lValue: string;
  lContinue: boolean;
  lArrNull: TRedisArray;
begin
  LCmd := GetCmdList('SUBSCRIBE');
  LCmd.AddRange(AChannels);
  FTCPLibInstance.SendCmd(LCmd);
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

function TRedisClient.SUNION(const aKeys: array of string): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('SUNION').AddRange(aKeys);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.SUNIONSTORE(const aDestination: string; const aKeys: array of string): Integer;
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('SUNIONSTORE').Add(aDestination).AddRange(aKeys);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

function TRedisClient.SMOVE(const aSource, aDestination, aMember: string): Boolean;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('SMOVE');
  lCmd.Add(aSource);
  lCmd.Add(aDestination);
  lCmd.Add(aMember);
  Result := ExecuteWithIntegerResult(lCmd) = 1;
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
var
  LCmd: IRedisCommand;
  LValid: Boolean;
begin
  LCmd := GetCmdList('TTL');
  LCmd.Add(aKey);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseIntegerResponse(LValid);
end;

procedure TRedisClient.WATCH(const aKeys: array of string);
var
  LCmd: IRedisCommand;
  lKey: string;
begin
  LCmd := GetCmdList('WATCH');
  for lKey in aKeys do
  begin
    LCmd.Add(lKey);
  end;
  ExecuteWithStringResult(LCmd); // ALWAYS 'OK' OR EXCEPTION
end;

function TRedisClient.XADD(const aStreamName: String; const MaxLength: UInt64; const MaxLengthType: TRedisMaxLengthType; const Keys, Values: array of string; const ID: UInt64): String;
var
  lCmd: IRedisCommand;
const
  MAX_LENGTH_TYPE: array[TRedisMaxLengthType.Exact..TRedisMaxLengthType.AtLeast] of string = ('','');
begin
  Assert(Length(Keys) = Length(Values), 'Keys and Values arrays must have the same length');

  lCmd := NewRedisCommand('XADD');
  lCmd.Add(aStreamName).Add('MAXLEN');
  if MaxLengthType = TRedisMaxLengthType.AtLeast then
  begin
    lCmd.Add('~');
  end;
  lCmd.Add(MaxLength);

  if ID = 0 then
  begin
    lCmd.Add('*')
  end
  else
  begin
    lCmd.Add(ID);
  end;

  AppendKeyValueParams(lCmd, Keys, Values);
  Result := ExecuteWithStringResult(lCmd);
end;

function TRedisClient.AppendKeyValueParams(const aRedisCommand: IRedisCommand; const Keys, Values: array of string): String;
var
  I: Integer;
begin
  Assert(Length(Keys) = Length(Values), 'Keys and Values arrays must have the same length');
  for I := 0 to Length(Keys)-1 do
  begin
    aRedisCommand.Add(Keys[I]).Add(Values[I]);
  end;
end;

function TRedisClient.XADD(const aStreamName: String; const Keys, Values: array of string; const ID: UInt64 = 0): String;
var
  lCmd: IRedisCommand;
begin
  Assert(Length(Keys) = Length(Values), 'Keys and Values arrays must have the same length');
  lCmd := NewRedisCommand('XADD');
  lCmd.Add(aStreamName);
  if ID = 0 then
  begin
    lCmd.Add('*')
  end
  else
  begin
    lCmd.Add(ID);
  end;
  AppendKeyValueParams(lCmd, Keys, Values);
  Result := ExecuteWithStringResult(lCmd);
end;

function TRedisClient.ZADD(const aKey: string; const AScore: Int64; const AMember: string): Integer;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZADD');
  LCmd.Add(aKey).Add(AScore.ToString).Add(AMember);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.ZCARD(const aKey: string): Integer;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZCARD').Add(aKey);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.ZCOUNT(const aKey: string; const AMin, AMax: Int64): Integer;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZCOUNT');
  LCmd.Add(aKey).Add(AMin.ToString).Add(AMax.ToString);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.ZINCRBY(const aKey: string; const AIncrement: Int64; const AMember: string): string;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZINCRBY');
  LCmd.Add(aKey).Add(AIncrement.ToString).Add(AMember);
  Result := ExecuteWithStringResult(LCmd);
end;

function TRedisClient.ZRANGE(const aKey: string; const AStart, AStop: Int64; const aScoreMode: TRedisScoreMode): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZRANGE');
  LCmd.Add(aKey).Add(AStart.ToString).Add(AStop.ToString);
  if aScoreMode = TRedisScoreMode.WithScores then
  begin
    LCmd.Add('WITHSCORES');
  end;
  Result := ExecuteAndGetArrayNULL(LCmd);
end;

// function TRedisClient.ZRANGEWithScore(const aKey: string;
// const AStart, AStop: Int64): TRedisArray;
// begin
// FNextCMD := GetCmdList('ZRANGE');
// FNextCMD.Add(aKey).Add(AStart.ToString).Add(AStop.ToString).Add('WITHSCORES');
// Result := ExecuteAndGetArrayNULL(FNextCMD);
// end;

function TRedisClient.ZRANK(const aKey: string; const AMember: string; out ARank: Int64): boolean;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZRANK');
  LCmd.Add(aKey).Add(AMember);
  ARank := ExecuteWithIntegerResult(LCmd);
  Result := ARank <> -1;
end;

function TRedisClient.ZREM(const aKey, AMember: string): Integer;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZREM');
  LCmd.Add(aKey).Add(AMember);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.ZREVRANGE(const aKey: string; const AStart, AStop: Int64; const aScoreMode: TRedisScoreMode): TRedisArray;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('ZREVRANGE');
  LCmd.Add(aKey).Add(AStart.ToString).Add(AStop.ToString);
  if aScoreMode = TRedisScoreMode.WithScores then
  begin
    LCmd.Add('WITHSCORES');
  end;
  Result := ExecuteAndGetArrayNULL(LCmd);
end;

function TRedisClient.ZUNIONSTORE(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string; const aWeights: array of Integer; const aAggregate: TRedisAggregate): Int64;
var
  LCmd: IRedisCommand;
  lWeight: Integer;
begin
  LCmd := BuildZUNIONSTOREDefault(aDestination, aNumKeys, aKeys);
  LCmd.Add('WEIGHTS');
  for lWeight in aWeights do
  begin
    LCmd.Add(lWeight);
  end;
  LCmd.AddRange(['AGGREGATE', REDIS_AGGREGATE[aAggregate]]);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.ZUNIONSTORE(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string; const aWeights: array of Integer): Int64;
var
  LCmd: IRedisCommand;
  lWeight: NativeInt;
begin
  LCmd := BuildZUNIONSTOREDefault(aDestination, aNumKeys, aKeys);
  LCmd.Add('WEIGHTS');
  for lWeight in aWeights do
  begin
    LCmd.Add(lWeight);
  end;
  Result := ExecuteWithIntegerResult(LCmd);
end;

function TRedisClient.ZPOPMIN(const aKey: string): TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('ZPOPMIN');
  lCmd.Add(aKey);
  FTCPLibInstance.SendCmd(lCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.ZPOPMIN(const aKey: string; aCount: Integer): TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('ZPOPMIN');
  lCmd.Add(aKey);
  lCmd.Add(aCount);
  FTCPLibInstance.SendCmd(lCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.ZPOPMAX(const aKey: string): TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('ZPOPMAX');
  lCmd.Add(aKey);
  FTCPLibInstance.SendCmd(lCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.ZPOPMAX(const aKey: string; aCount: Integer): TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('ZPOPMAX');
  lCmd.Add(aKey);
  lCmd.Add(aCount);
  FTCPLibInstance.SendCmd(lCmd);
  Result := ParseArrayResponseNULL;
end;

function TRedisClient.ZUNIONSTORE(const aDestination: string; const aNumKeys: NativeInt; const aKeys: array of string): Int64;
var
  LCmd: IRedisCommand;
begin
  LCmd := BuildZUNIONSTOREDefault(aDestination, aNumKeys, aKeys);
  Result := ExecuteWithIntegerResult(LCmd);
end;

function NewRedisClient(const AHostName: string; const APort: Word; const ALibName: string): IRedisClient;
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  TCPLibInstance := TRedisNetLibFactory.GET(ALibName);
  Result := TRedisClient.Create(TCPLibInstance, AHostName, APort);
  try
    TRedisClient(Result).Connect;
  except
    on E: Exception do
    begin
      Result := nil;
      raise ERedisConnectionException.Create('Cannot connect to REDIS server [' + E.Message + ']');
    end;
  end;
end;

function NewRedisCommand(const RedisCommandString: string): IRedisCommand;
begin
  Result := TRedisCommand.Create;
  TRedisCommand(Result).SetCommand(RedisCommandString);
end;

function TRedisClient.GEOADD(const Key: string; const Latitude, Longitude: Extended; Member: string): Integer;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEOADD');
  lCmd.Add(Key);
  lCmd.Add(FormatFloat('0.000000', Latitude, FFormatSettings));
  lCmd.Add(FormatFloat('0.000000', Longitude, FFormatSettings));
  lCmd.Add(Member);
  Result := ExecuteWithIntegerResult(lCmd);
end;

function TRedisClient.GEODIST(const Key, Member1, Member2: string; const &Unit: TRedisGeoUnit): TRedisString;
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

function TRedisClient.GEOHASH(const Key: string; const Members: array of string): TRedisArray;
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

function TRedisClient.GEOPOS(const Key: string; const Members: array of string): TRedisMatrix;
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
  const &Unit: TRedisGeoUnit; const Sorting: TRedisSorting; const Count: Int64): TRedisArray;
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
  const Sorting: TRedisSorting = TRedisSorting.None; const Count: Int64 = -1): TRedisMatrix;
var
  lCmd: IRedisCommand;
begin
  lCmd := GetGEORADIUSCommand(Key, Longitude, Latitude, Radius, &Unit,
    Sorting, Count);
  lCmd.Add('WITHDIST');
  Result := ExecuteAndGetMatrix(lCmd);
end;

function TRedisClient.GEOSEARCH(const Key: string; const FromMember: string;
  const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
  const Sorting: TRedisSorting = TRedisSorting.None; const Count: Int64 = -1): TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEOSEARCH');
  lCmd.Add(Key);
  lCmd.Add('FROMMEMBER');
  lCmd.Add(FromMember);
  lCmd.Add('BYRADIUS');
  lCmd.Add(FormatFloat('0.0000000', Radius, FFormatSettings));
  lCmd.Add(REDIS_GEO_UNIT_STRING[&Unit]);
  if Count > -1 then
    lCmd.Add('COUNT').Add(Count);
  case Sorting of
    TRedisSorting.Asc:
      lCmd.Add('ASC');
    TRedisSorting.Desc:
      lCmd.Add('DESC');
  end;
  Result := ExecuteAndGetArrayNULL(lCmd);
end;

function TRedisClient.GEOSEARCH(const Key: string; const Longitude, Latitude: Extended;
  const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
  const Sorting: TRedisSorting = TRedisSorting.None; const Count: Int64 = -1): TRedisArray;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEOSEARCH');
  lCmd.Add(Key);
  lCmd.Add('FROMLONLAT');
  lCmd.Add(FormatFloat('0.0000000', Longitude, FFormatSettings));
  lCmd.Add(FormatFloat('0.0000000', Latitude, FFormatSettings));
  lCmd.Add('BYRADIUS');
  lCmd.Add(FormatFloat('0.0000000', Radius, FFormatSettings));
  lCmd.Add(REDIS_GEO_UNIT_STRING[&Unit]);
  if Count > -1 then
    lCmd.Add('COUNT').Add(Count);
  case Sorting of
    TRedisSorting.Asc:
      lCmd.Add('ASC');
    TRedisSorting.Desc:
      lCmd.Add('DESC');
  end;
  Result := ExecuteAndGetArrayNULL(lCmd);
end;

function TRedisClient.GEOSEARCHSTORE(const Destination, Source: string; const FromMember: string;
  const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
  const Sorting: TRedisSorting = TRedisSorting.None; const Count: Int64 = -1): Integer;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEOSEARCHSTORE');
  lCmd.Add(Destination);
  lCmd.Add(Source);
  lCmd.Add('FROMMEMBER');
  lCmd.Add(FromMember);
  lCmd.Add('BYRADIUS');
  lCmd.Add(FormatFloat('0.0000000', Radius, FFormatSettings));
  lCmd.Add(REDIS_GEO_UNIT_STRING[&Unit]);
  if Count > -1 then
    lCmd.Add('COUNT').Add(Count);
  case Sorting of
    TRedisSorting.Asc:
      lCmd.Add('ASC');
    TRedisSorting.Desc:
      lCmd.Add('DESC');
  end;
  Result := ExecuteWithIntegerResult(lCmd);
end;

function TRedisClient.GEOSEARCHSTORE(const Destination, Source: string; const Longitude, Latitude: Extended;
  const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
  const Sorting: TRedisSorting = TRedisSorting.None; const Count: Int64 = -1): Integer;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('GEOSEARCHSTORE');
  lCmd.Add(Destination);
  lCmd.Add(Source);
  lCmd.Add('FROMLONLAT');
  lCmd.Add(FormatFloat('0.0000000', Longitude, FFormatSettings));
  lCmd.Add(FormatFloat('0.0000000', Latitude, FFormatSettings));
  lCmd.Add('BYRADIUS');
  lCmd.Add(FormatFloat('0.0000000', Radius, FFormatSettings));
  lCmd.Add(REDIS_GEO_UNIT_STRING[&Unit]);
  if Count > -1 then
    lCmd.Add('COUNT').Add(Count);
  case Sorting of
    TRedisSorting.Asc:
      lCmd.Add('ASC');
    TRedisSorting.Desc:
      lCmd.Add('DESC');
  end;
  Result := ExecuteWithIntegerResult(lCmd);
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

// Redis 6.2+ commands implementation

function TRedisClient.GETEX(const aKey: string; aExpirationMs: UInt64): TRedisString;
var
  lCmd: IRedisCommand;
  lResp: TRedisBytes;
begin
  lCmd := NewRedisCommand('GETEX');
  lCmd.Add(aKey);
  lCmd.Add('EXAT');
  lCmd.Add(aExpirationMs);
  FTCPLibInstance.SendCmd(lCmd);
  lResp := ParseSimpleStringResponseAsByteNULL;
  if lResp.HasValue then
    Result := TRedisString.Create(StringOf(lResp.Value))
  else
    Result := TRedisString.Empty;
end;

function TRedisClient.GETEX(const aKey: string; aExpirationSec: UInt64; const UseSeconds: Boolean): TRedisString;
var
  lCmd: IRedisCommand;
  lResp: TRedisBytes;
begin
  lCmd := NewRedisCommand('GETEX');
  lCmd.Add(aKey);
  if UseSeconds then
  begin
    lCmd.Add('EX');
    lCmd.Add(aExpirationSec);
  end
  else
  begin
    lCmd.Add('PX');
    lCmd.Add(aExpirationSec);
  end;
  FTCPLibInstance.SendCmd(lCmd);
  lResp := ParseSimpleStringResponseAsByteNULL;
  if lResp.HasValue then
    Result := TRedisString.Create(StringOf(lResp.Value))
  else
    Result := TRedisString.Empty;
end;

function TRedisClient.GETDEL(const aKey: string): TRedisString;
var
  lCmd: IRedisCommand;
  lResp: TRedisBytes;
begin
  lCmd := NewRedisCommand('GETDEL');
  lCmd.Add(aKey);
  FTCPLibInstance.SendCmd(lCmd);
  lResp := ParseSimpleStringResponseAsByteNULL;
  if lResp.HasValue then
    Result := TRedisString.Create(StringOf(lResp.Value))
  else
    Result := TRedisString.Empty;
end;

function TRedisClient.COPY(const aSourceKey, aDestKey: string; const aReplace: Boolean): Boolean;
var
  lCmd: IRedisCommand;
begin
  lCmd := NewRedisCommand('COPY');
  lCmd.Add(aSourceKey);
  lCmd.Add(aDestKey);
  if aReplace then
    lCmd.Add('REPLACE');
  Result := ExecuteWithIntegerResult(lCmd) = 1;
end;

function TRedisClient.INFO(const ASection: string): string;
var
  LCmd: IRedisCommand;
begin
  LCmd := GetCmdList('INFO');
  if ASection <> '' then
    LCmd.Add(ASection);
  FTCPLibInstance.SendCmd(LCmd);
  Result := ParseSimpleStringResponseAsStringNULL;
end;

end.
