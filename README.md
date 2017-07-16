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
    function &SET(const AKey, AValue: string): boolean; overload;
    function &SET(const AKey, AValue: TBytes): boolean; overload;
    function &SET(const AKey: string; AValue: TBytes): boolean; overload;
    function &SET(const AKey: string; AValue: TBytes; ASecsExpire: UInt64): boolean; overload;
    function &SET(const AKey: string; AValue: string; ASecsExpire: UInt64): boolean; overload;
    function SETNX(const AKey, AValue: string): boolean; overload;
    function SETNX(const AKey, AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: string): boolean; overload;
    function GET(const AKey: TBytes; out AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: TBytes): boolean; overload;
    function DEL(const AKeys: array of string): Integer;
    function TTL(const AKey: string): Integer;
    function EXISTS(const AKey: string): boolean;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TArray<string>;
    function INCR(const AKey: string): NativeInt;
    function DECR(const AKey: string): NativeInt;
    function EXPIRE(const AKey: string; AExpireInSecond: UInt32): boolean;

    // strings functions
    function APPEND(const AKey, AValue: TBytes): UInt64; overload;
    function APPEND(const AKey, AValue: string): UInt64; overload;
    function STRLEN(const AKey: string): UInt64;
    function GETRANGE(const AKey: string; const AStart, AEnd: NativeInt): string;
    function SETRANGE(const AKey: string; const AOffset: NativeInt; const AValue: string)
      : NativeInt;

    // hash
    function HSET(const AKey, aField: string; AValue: string): Integer; overload;
    procedure HMSET(const AKey: string; aFields: TArray<string>; AValues: TArray<string>);
    function HMGET(const AKey: string; aFields: TArray<string>): TArray<string>;
    function HSET(const AKey, aField: string; AValue: TBytes): Integer; overload;
    function HGET(const AKey, aField: string; out AValue: TBytes): boolean; overload;
    function HGET(const AKey, aField: string; out AValue: string): boolean; overload;
    function HDEL(const AKey: string; aFields: TArray<string>): Integer;

    // lists
    function RPUSH(const AListKey: string; AValues: array of string): Integer;
    function RPUSHX(const AListKey: string; AValues: array of string): Integer;
    function RPOP(const AListKey: string; var Value: string): boolean;
    function LPUSH(const AListKey: string; AValues: array of string): Integer;
    function LPUSHX(const AListKey: string; AValues: array of string): Integer;
    function LPOP(const AListKey: string; out Value: string): boolean;
    function LLEN(const AListKey: string): Integer;
    procedure LTRIM(const AListKey: string; const AIndexStart, AIndexStop: Integer);
    function LRANGE(const AListKey: string; IndexStart, IndexStop: Integer)
      : TArray<string>;
    function RPOPLPUSH(const ARightListKey, ALeftListKey: string;
      var APoppedAndPushedElement: string): boolean; overload;
    function BRPOPLPUSH(const ARightListKey, ALeftListKey: string;
      var APoppedAndPushedElement: string; ATimeout: Int32): boolean; overload;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32;
      out Value: TArray<string>): boolean;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32;
      out Value: TArray<string>): boolean;
    function LREM(const AListKey: string; const ACount: Integer;
      const AValue: string): Integer;

    // sets
    function SADD(const AKey, AValue: TBytes): Integer; overload;
    function SADD(const AKey, AValue: string): Integer; overload;
    function SREM(const AKey, AValue: TBytes): Integer; overload;
    function SREM(const AKey, AValue: string): Integer; overload;
    function SMEMBERS(const AKey: string): TArray<string>;
    function SCARD(const AKey: string): Integer;

    // ordered sets
    function ZADD(const AKey: string; const AScore: Int64; const AMember: string): Integer;
    function ZREM(const AKey: string; const AMember: string): Integer;
    function ZCARD(const AKey: string): Integer;
    function ZCOUNT(const AKey: string; const AMin, AMax: Int64): Integer;
    function ZRANK(const AKey: string; const AMember: string; out ARank: Int64): boolean;
    function ZRANGE(const AKey: string; const AStart, AStop: Int64): TArray<string>;
    function ZRANGEWithScore(const AKey: string; const AStart, AStop: Int64): TArray<string>;
    function ZINCRBY(const AKey: string; const AIncrement: Int64; const AMember: string): string;

    // lua scripts
    function EVAL(const AScript: string; AKeys: array of string; AValues: array of string): Integer;

    // system
    procedure FLUSHDB;
    procedure SELECT(const ADBIndex: Integer);
    procedure AUTH(const aPassword: string);

    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand)
      : TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string)
      : TArray<string>; overload;
    function ExecuteWithIntegerResult(const RedisCommand: IRedisCommand)
      : Int64; overload;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand): string;
    
    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string;
      ACallback: TProc<string, string>;
      ATimeoutCallback: TRedisTimeoutCallback = nil);
    function PUBLISH(const AChannel: string; AMessage: string): Integer;
    
    // transactions
    function MULTI(ARedisTansactionProc: TRedisTransactionProc): TArray<string>; overload;
    procedure MULTI; overload;
    function EXEC: TArray<string>;
    procedure WATCH(const AKeys: array of string);

    procedure DISCARD;
    // non sys
    function Tokenize(const ARedisCommand: string): TArray<string>;
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

