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

unit Redis.Commons;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils, Redis.Values;

var
  RedisDefaultSubscribeTimeout: UInt32 = 1000;

const
  REDIS_NETLIB_INDY = 'indy';

type
  ERedisException = class(Exception)

  end;

  TRedisConsts = class sealed
  const
    TTL_KEY_DOES_NOT_EXIST = -2;
    TTL_KEY_IS_NOT_VOLATILE = -1;
    NULL_ARRAY = '*-1';
    NULL_BULK_STRING = '$-1';
    ERR_NOT_A_VALID_RESPONSE = 'Not a valid response';
    ERR_NOT_A_VALID_STRING_RESPONSE = 'Not a valid string response';
    ERR_NOT_A_VALID_ARRAY_RESPONSE = 'Not a valid array response';
    ERR_NOT_A_VALID_INTEGER_RESPONSE = 'Not a valid integer response';
    ERR_NOT_A_VALID_COMMAND = 'Not a valid Redis command';
  end;

  TRedisGeoUnit = (Meters, Kilometers, Miles, Feet);
  TRedisSorting = (None, Asc, Desc);

  TRedisClientBase = class abstract(TInterfacedObject)
  protected
    function BytesOfUnicode(const AUnicodeString: string): TBytes;
    function StringOfUnicode(const ABytes: TBytes): string;
  end;

  IRedisCommand = interface;
  IRedisClient = interface;

  TRedisTransactionProc = reference to procedure(const Redis: IRedisClient);
  TRedisTimeoutCallback = reference to function: boolean;
  TRedisAction = TProc;

  IRedisClient = interface
    ['{566C20FF-7D9F-4DAC-9B0E-A8AA7D29B0B4}']

    function &SET(const aKey, aValue: string): boolean; overload;

    function &SET(const aKey, aValue: TBytes): boolean; overload;
    function &SET(const aKey: string; aValue: TBytes): boolean; overload;
    function &SET(const aKey: string; aValue: TBytes; aSecsExpire: UInt64)
      : boolean; overload;
    function &SET(const aKey: string; aValue: string; aSecsExpire: UInt64)
      : boolean; overload;
    function SETNX(const aKey, aValue: string): boolean; overload;
    function SETNX(const aKey, aValue: TBytes): boolean; overload;
    function GET(const aKey: string; out aValue: string): boolean; overload;
      deprecated 'Use GET(aKey: string): TRedisString';
    function GET(const aKey: string): TRedisString; overload;
    function GET_AsBytes(const aKey: string): TRedisBytes;
    function GET(const aKey: TBytes; out aValue: TBytes): boolean; overload;
      deprecated 'Use GET(aKey: string): TRedisString';
    function GET(const aKey: string; out aValue: TBytes): boolean; overload;
      deprecated 'Use GET(aKey: string): TRedisString';
    function DEL(const aKeys: array of string): Integer;
    function TTL(const aKey: string): Integer;
    function EXISTS(const aKey: string): boolean;
    function MSET(const aKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TRedisArray;
    function INCR(const aKey: string): NativeInt;
    function DECR(const aKey: string): NativeInt;
    function EXPIRE(const aKey: string; aExpireInSecond: UInt32): boolean;
    function PERSIST(const aKey: string): boolean;
    function RANDOMKEY: TRedisString;

    // strings functions
    function APPEND(const aKey, aValue: TBytes): UInt64; overload;
    function APPEND(const aKey, aValue: string): UInt64; overload;
    function STRLEN(const aKey: string): UInt64;
    function GETRANGE(const aKey: string;
      const aStart, aEnd: NativeInt): string;
    function SETRANGE(const aKey: string; const aOffset: NativeInt;
      const aValue: string): NativeInt;

    // hash
    function HSET(const aKey, aField: string; aValue: string): Integer;
      overload;
    procedure HMSET(const aKey: string; aFields: TArray<string>;
      aValues: TArray<string>); overload;
    procedure HMSET(const aKey: string; aFields: TArray<string>;
      aValues: TArray<TBytes>); overload;
    function HSET(const aKey, aField: string; aValue: TBytes): Integer;
      overload;
    function HGET(const aKey, aField: string; out aValue: TBytes)
      : boolean; overload;
    function HGET(const aKey, aField: string; out aValue: string)
      : boolean; overload;
    function HGET_AsBytes(const aKey, aField: string): TRedisBytes;
    function HGET(const aKey, aField: string): TRedisString; overload;
    function HMGET(const aKey: string; aFields: TArray<string>)
      : TRedisArray; overload;
    function HDEL(const aKey: string; aFields: TArray<string>): Integer;

    // lists
    function RPUSH(const aListKey: string; aValues: array of string): Integer;
    function RPUSHX(const aListKey: string; aValues: array of string): Integer;
    function RPOP(const aListKey: string; var Value: string): boolean; overload;
    function RPOP(const aListKey: string): TRedisString; overload;
    function LPUSH(const aListKey: string; aValues: array of string): Integer;
    function LPUSHX(const aListKey: string; aValues: array of string): Integer;
    function LPOP(const aListKey: string; out Value: string): boolean; overload;
    function LPOP(const aListKey: string): TRedisString; overload;
    function LLEN(const aListKey: string): Integer;
    procedure LTRIM(const aListKey: string;
      const aIndexStart, aIndexStop: Integer);
    function LRANGE(const aListKey: string; aIndexStart, aIndexStop: Integer)
      : TRedisArray;
    function RPOPLPUSH(const aRightListKey, aLeftListKey: string;
      var aPoppedAndPushedElement: string): boolean; overload;
    function BRPOPLPUSH(const aRightListKey, aLeftListKey: string;
      var aPoppedAndPushedElement: string; aTimeout: Int32): boolean; overload;
    function BLPOP(const aKeys: array of string; const aTimeout: Int32;
      out Value: TArray<string>): boolean; overload;
      deprecated 'Use BLPOP: TRedisArray';
    function BLPOP(const aKeys: array of string; const aTimeout: Int32)
      : TRedisArray; overload;
    function BRPOP(const aKeys: array of string; const aTimeout: Int32;
      out Value: TArray<string>): boolean; overload;
      deprecated 'Use BRPOP: TRedisArray';
    function BRPOP(const aKeys: array of string; const aTimeout: Int32)
      : TRedisArray; overload;
    function LREM(const aListKey: string; const aCount: Integer;
      const aValue: string): Integer;

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
    function ZRANGE(const aKey: string; const aStart, AStop: Int64)
      : TRedisArray;
    function ZRANGEWithScore(const aKey: string; const aStart, AStop: Int64)
      : TRedisArray;
    function ZINCRBY(const aKey: string; const AIncrement: Int64;
      const AMember: string): string;

    // geo
    /// <summary>
    /// GEOADD (Redis 3.2+)
    /// </summary>
    function GEOADD(const Key: string; const Latitude, Longitude: Extended;
      Member: string): Integer;
    /// <summary>
    /// GEODIST (Redis 3.2+)
    /// </summary>
    function GEODIST(const Key: string; const Member1, Member2: string;
      const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters): TRedisString;

    /// <summary>
    /// GEOHASH (Redis 3.2+)
    /// </summary>
    function GEOHASH(const Key: string; const Members: array of string)
      : TRedisArray;

    /// <summary>
    /// GEOPOS (Redis 3.2+)
    /// </summary>
    function GEOPOS(const Key: string; const Members: array of string)
      : TRedisMatrix;

    /// <summary>
    /// GEORADIUS (Redis 3.2+)
    /// </summary>
    function GEORADIUS(const Key: string; const Longitude, Latitude: Extended;
      const Radius: Extended; const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisArray;

    /// <summary>
    /// GEORADIUS (Redis 3.2+)
    /// </summary>
    function GEORADIUS_WITHDIST(const Key: string;
      const Longitude, Latitude: Extended; const Radius: Extended;
      const &Unit: TRedisGeoUnit = TRedisGeoUnit.Meters;
      const Sorting: TRedisSorting = TRedisSorting.None;
      const Count: Int64 = -1): TRedisMatrix;

    // lua scripts
    function EVAL(const aScript: string; aKeys: array of string;
      aValues: array of string): Integer;

    // system
    procedure FLUSHDB;
    procedure SELECT(const aDBIndex: Integer);
    procedure AUTH(const aPassword: string);
    function MOVE(const aKey: string; const aDB: Byte): boolean;

    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand): TRedisArray;
    function ExecuteWithIntegerResult(const RedisCommand: IRedisCommand)
      : Int64; overload;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand)
      : TRedisString;
    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string;
      aCallback: TProc<string, string>;
      aContinueOnTimeoutCallback: TRedisTimeoutCallback = nil;
      aAfterSubscribe: TRedisAction = nil);
    function PUBLISH(const aChannel: string; aMessage: string): Integer;
    // transactions
    function MULTI(aRedisTansactionProc: TRedisTransactionProc)
      : TRedisArray; overload;
    procedure MULTI; overload;
    function EXEC: TRedisArray;
    procedure WATCH(const aKeys: array of string);

    procedure DISCARD;
    // non sys
    function Tokenize(const aRedisCommand: string): TArray<string>;
    procedure Connect;
    procedure Disconnect;
    function InTransaction: boolean;
    // client
    procedure ClientSetName(const ClientName: string);
    procedure SetCommandTimeout(const Timeout: Int32);
    function Clone: IRedisClient;
  end;

  IRedisCommand = interface
    ['{79C43B91-604F-49BC-8EB8-35F092258833}']
    function GetToken(const index: Integer): TBytes;
    procedure Clear;
    function Count: Integer;
    function Add(ABytes: TBytes): IRedisCommand; overload;
    function Add(AString: string): IRedisCommand; overload;
    function Add(AInteger: NativeInt): IRedisCommand; overload;
    function SetCommand(AString: string): IRedisCommand;
    function AddRange(AStrings: array of string): IRedisCommand;
    function ToRedisCommand: TBytes;
  end;

  IRedisNetLibAdapter = interface
    ['{2DB21166-2E68-4DC4-9870-5DCCAAE877A3}']
    procedure Connect(const HostName: string; const Port: Word);
    procedure Send(const Value: string);
    procedure Write(const Bytes: TBytes);
    procedure WriteCrLf(const Bytes: TBytes);
    procedure SendCmd(const Values: IRedisCommand);
    function Receive(const Timeout: Int32): string;
    function ReceiveBytes(const aCount: Int64; const Timeout: Int32)
      : System.TArray<System.Byte>;
    procedure Disconnect;
    function LastReadWasTimedOut: boolean;
    function LibName: string;
  end;

function ByteToHex(InByte: Byte): string;

implementation

function ByteToHex(InByte: Byte): string;
const
  HexDigits: array [0 .. 15] of char = '0123456789ABCDEF';
begin
  Result := HexDigits[InByte shr 4] + HexDigits[InByte and $0F];
end;

{ TRedisClientBase }

function TRedisClientBase.BytesOfUnicode(const AUnicodeString: string): TBytes;
begin
  Result := BytesOf(AUnicodeString);
end;

function TRedisClientBase.StringOfUnicode(const ABytes: TBytes): string;
begin
  Result := StringOf(ABytes);
end;

end.
