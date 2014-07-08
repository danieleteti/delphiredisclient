Delphi Redis client
=================

Redis client for Delphi XE6 and XE5


This client is able to send all Redis commands and read the response using an internal parser. 

Some commands have a specialized dedicated method.

This is the  interface used to send command to the Redis server. Each method is a Redis command. Hi level methods implementing some integration design pattern are planned (e.g. Push a JSONObject, Pop a Stream and so on).

```Delphi
  IRedisClient = interface
    ['{566C20FF-7D9F-4DAC-9B0E-A8AA7D29B0B4}']
    function &SET(const AKey, AValue: string): boolean;
    function GET(const AKey: string; out AValue: string): boolean;
    function DEL(const AKeys: array of string): Integer;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TArray<string>;
    // lists
    function RPUSH(const AListKey: string; AValues: array of string): Integer;
    function RPUSHX(const AListKey: string; AValues: array of string): Integer;
    function RPOP(const AListKey: string; var Value: string): boolean;
    function LPUSH(const AListKey: string; AValues: array of string): Integer;
    function LPUSHX(const AListKey: string; AValues: array of string): Integer;
    function LPOP(const AListKey: string; out Value: string): boolean;
    function LLEN(const AListKey: string): Integer;
    function LRANGE(const AListKey: string; IndexStart, IndexStop: Integer): TArray<string>;
    function RPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string): boolean;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
    function LREM(const AListKey: string; const ACount: Integer; const AValue: string): Integer;

    // system
    function FLUSHDB: boolean;
    // non sys
    function Tokenize(const ARedisCommand: string): TArray<string>;
    procedure Disconnect;
  end;
```

Delphi Redis Client is not tied to a specific TCP/IP library. Currently it uses INDY but you can implement the IRedisNetLibAdapter and wrap whatever library you like.


```Delphi
  IRedisNetLibAdapter = interface
    ['{2DB21166-2E68-4DC4-9870-5DCCAAE877A3}']
    procedure Connect(const HostName: string; const Port: Word);
    procedure Send(const Value: string);
    procedure SendCmd(const Values: TRedisCmdParts);
    function Receive(const Timeout): string;
    procedure Disconnect;
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

This project is related to the DelphiMVCFramework project and will be used by it (https://code.google.com/p/delphimvcframework/)

To discuss about DelphiMVCProject or DelphiRedisClient, use the facebook group https://www.facebook.com/groups/delphimvcframework/

