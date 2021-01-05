![](https://github.com/danieleteti/delphiredisclient/blob/master/docs/redisclientlogo.png)
=================
Delphi Redis Client version 2 (this branch) is compatible with Delphi 10.1 Berlin and better.
WARNING!
If you use an older Delphi version you have to use [Delphi Redis Client Version 1](https://github.com/danieleteti/delphiredisclient/tree/DELPHI_REDIS_CLIENT_VERSION_1) wich works for Delphi 10 Seattle, XE8, XE7, XE6 and XE5 (should works also with older versions).

Delphi REDIS Client works on mobile since the first version (or so) and since Delphi 10.2 Tokyo it works on Linux too (tested Ubuntu 16.x LTS).

Delphi Redis Client is able to send all Redis commands and read the response using an internal parser. Moreover, many popular commands have a specialized dedicated methods which simplifies utilization.

This is the Redis Client interface used to connect, send commands and manager the Redis server. Many methods are 1-1 mapping to the Redis command with the same name (eg. SET is a map to the Redis SET command). Hi level methods implementing some integration design pattern are planned (e.g. Push a JSONObject, Pop a Stream and so on).

```Delphi
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
    function INCR(const aKey: string): Int64;
    function DECR(const aKey: string): Int64;
    function EXPIRE(const aKey: string; aExpireInSecond: UInt32): boolean;
    function PERSIST(const aKey: string): boolean;
    function RANDOMKEY: TRedisString;
    function RENAME(const aKey, aNewKey: string): boolean;
    function RENAMENX(const aKey, aNewKey: string): boolean;	

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
    function HKEYS(const aKey: string): TRedisArray;
    function HVALS(const aKey: string): TRedisArray;
    function HEXISTS(const aKey, aField: string): Boolean;
    function HLEN(const aKey: string): Integer;
    function HINCRBY(const aKey, aField: string; const AIncrement: NativeInt): Integer;
    function HINCRBYFLOAT(const aKey, aField: string; const AIncrement: Double): Double;

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
    function SDIFF(const aKeys: array of string): TRedisArray;
    function SREM(const aKey, aValue: TBytes): Integer; overload;
    function SREM(const aKey, aValue: string): Integer; overload;
    function SISMEMBER(const aKey, aValue: TBytes): Integer; overload;
    function SISMEMBER(const aKey, aValue: string): Integer; overload;
    function SMEMBERS(const aKey: string): TRedisArray;
    function SCARD(const aKey: string): Integer;
    function SUNION(const aKeys: array of string): TRedisArray;
    function SUNIONSTORE(const aDestination: String; const aKeys: array of string): Integer;

    // ordered sets
    function ZADD(const aKey: string; const AScore: Int64;
      const AMember: string): Integer;
    function ZREM(const aKey: string; const AMember: string): Integer;
    function ZCARD(const aKey: string): Integer;
    function ZCOUNT(const aKey: string; const AMin, AMax: Int64): Integer;
    function ZRANK(const aKey: string; const AMember: string;
      out ARank: Int64): boolean;
    function ZRANGE(const aKey: string; const aStart, AStop: Int64;
      const aScores: TRedisScoreMode = TRedisScoreMode.WithoutScores): TRedisArray;
    function ZREVRANGE(const aKey: string; const aStart, AStop: Int64;
      const aScoreMode: TRedisScoreMode = TRedisScoreMode.WithoutScores): TRedisArray;
//    function ZRANGEWithScore(const aKey: string; const aStart, AStop: Int64)
//      : TRedisArray;
    function ZINCRBY(const aKey: string; const AIncrement: Int64;
      const AMember: string): string;
    function ZUNIONSTORE(const aDestination: string;
      const aNumKeys: NativeInt; const aKeys: array of string): Int64; overload;
    function ZUNIONSTORE(const aDestination: string;
      const aNumKeys: NativeInt; const aKeys: array of string; const aWeights: array of Integer): Int64; overload;
    function ZUNIONSTORE(const aDestination: string;
      const aNumKeys: NativeInt; const aKeys: array of string; const aWeights: array of Integer; const aAggregate: TRedisAggregate): Int64; overload;

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
    procedure FLUSHALL;
    procedure SELECT(const aDBIndex: Integer);
    procedure AUTH(const aPassword: string);
    function MOVE(const aKey: string; const aDB: Byte): boolean;

    // raw execute
    function ExecuteAndGetRESPArray(const RedisCommand: IRedisCommand): TRedisRESPArray;
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

    {$REGION STREAMS}
      function XADD(const aStreamName: String; const MaxLength: UInt64;
        const MaxLengthType: TRedisMaxLengthType; const Keys,
        Values: array of string; const ID: UInt64 = 0): String; overload;
      function XADD(const aStreamName: String; const Keys,
        Values: array of string; const ID: UInt64 = 0): String; overload;
    {$ENDREGION}

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
  ```

Delphi Redis Client is not tied to a specific TCP/IP library. Currently it uses INDY but you can implement the IRedisNetLibAdapter and wrap whatever library you like.


```Delphi
  IRedisNetLibAdapter = interface
    ['{2DB21166-2E68-4DC4-9870-5DCCAAE877A3}']
    procedure Connect(const HostName: string; const Port: Word);
    procedure Send(const Value: string);
    procedure Write(const Bytes: TBytes);
    procedure WriteCrLf(const Bytes: TBytes);
    procedure SendCmd(const Values: IRedisCommand);
    function Receive(const Timeout: Int32): string;
    function ReceiveBytes(const ACount: Int64; const Timeout: Int32): System.TArray<System.Byte>;
    procedure Disconnect;
    function LastReadWasTimedOut: boolean;
  end;
```


This is a simple demo showing the utilization pattern (using the builtin INDY library support).

```Delphi
program CmdsSample1;

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
  readln; //just to keep the command prompt open

end.
```


Each feature is unit tested.

This project is related to [DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework) project and is currently used by it.

To discuss about [DelphiMVCProject](https://github.com/danieleteti/delphimvcframework) or [DelphiRedisClient](https://github.com/danieleteti/delphiredisclient), use the [facebook group](https://www.facebook.com/groups/delphimvcframework/)

