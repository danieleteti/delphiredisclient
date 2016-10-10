Delphi Redis client
=================

Redis client for Delphi 10.1 Berlin, Delphi 10 Seattle, XE8, XE7, XE6 and XE5 (should works also with older versions)


This client is able to send all Redis commands and read the response using an internal parser. 

Some commands have a specialized dedicated method.

This is the  interface used to send command to the Redis server. Each method is a Redis command. Hi level methods implementing some integration design pattern are planned (e.g. Push a JSONObject, Pop a Stream and so on).

```Delphi
  IRedisClient = interface
    ['{566C20FF-7D9F-4DAC-9B0E-A8AA7D29B0B4}']
    function &SET(const AKey, AValue: string): boolean; overload;
    function &SET(const AKey, AValue: TBytes): boolean; overload;
    function &SET(const AKey: String; AValue: TBytes): boolean; overload;
    function SETNX(const AKey, AValue: string): boolean; overload;
    function SETNX(const AKey, AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: string): boolean; overload;
    function GET(const AKey: TBytes; out AValue: TBytes): boolean; overload;
    function GET(const AKey: String; out AValue: TBytes): boolean; overload;
    function DEL(const AKeys: array of string): Integer;
    function TTL(const AKey: string): Integer;
    function EXISTS(const AKey: string): boolean;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TArray<string>;
    function INCR(const AKey: string): NativeInt;
    function EXPIRE(const AKey: string; AExpireInSecond: UInt32): boolean;

    // hash
    function HSET(const AKey, aField: String; AValue: string): Integer; overload;
    procedure HMSET(const AKey: String; aFields: TArray<String>; AValues: TArray<String>);
    function HMGET(const AKey: String; aFields: TArray<String>): TArray<String>;
    function HSET(const AKey, aField: String; AValue: TBytes): Integer; overload;
    function HGET(const AKey, aField: String; out AValue: TBytes): boolean; overload;
    function HGET(const AKey, aField: String; out AValue: string): boolean; overload;

    // lists
    function RPUSH(const AListKey: string; AValues: array of string): Integer;
    function RPUSHX(const AListKey: string; AValues: array of string): Integer;
    function RPOP(const AListKey: string; var Value: string): boolean;
    function LPUSH(const AListKey: string; AValues: array of string): Integer;
    function LPUSHX(const AListKey: string; AValues: array of string): Integer;
    function LPOP(const AListKey: string; out Value: string): boolean;
    function LLEN(const AListKey: string): Integer;
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
    function SADD(const AKey, AValue: String): Integer; overload;
    function SREM(const AKey, AValue: TBytes): Integer; overload;
    function SREM(const AKey, AValue: String): Integer; overload;
    function SMEMBERS(const AKey: string): TArray<string>;

    // lua scripts
    function EVAL(const AScript: String; AKeys: array of string; AValues: array of string): Integer;

    // system
    procedure FLUSHDB;
    procedure SELECT(const ADBIndex: Integer);

    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand): TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string): TArray<string>; overload;
    function ExecuteWithIntegerResult(const RedisCommand: IRedisCommand): Int64; overload;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand): string;
    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string; ACallback: TProc<string, string>; ATimeoutCallback: TRedisTimeoutCallback);
    function PUBLISH(const AChannel: string; AMessage: string): Integer;
    // transactions
    function MULTI(ARedisTansactionProc: TRedisTransactionProc): TArray<String>;
    procedure DISCARD;
    // non sys
    function Tokenize(const ARedisCommand: string): TArray<string>;
    procedure Disconnect;
    // client
    procedure ClientSetName(const ClientName: String);
    procedure SetCommandTimeout(const Timeout: Int32);
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
program SetGet;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Redis.Client, Redis.NetLib.INDY;

var
  Redis: IRedisClient;
  Value: string;

begin
  try
    Redis := NewRedisClient('localhost');
    Redis.&SET('firstname', 'Daniele');
    Redis.GET('firstname', Value);
    WriteLn('key firstname, value ', Value);
    WriteLn('DEL firstname');
    Redis.DEL(['firstname']);
    if Redis.GET('firstname', Value) then
      write(Value)
    else
      write('Key firstname not exists');
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;

end.
```


Each feature is unit tested.

This project is related to [DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework) project and is currently used by it.

To discuss about [DelphiMVCProject](https://github.com/danieleteti/delphimvcframework) or [DelphiRedisClient](https://github.com/danieleteti/delphiredisclient), use the [facebook group](https://www.facebook.com/groups/delphimvcframework/)

