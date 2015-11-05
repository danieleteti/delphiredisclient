unit Redis.Commons;

interface

uses
  System.SysUtils;

var
  RedisDefaultSubscribeTimeout: UInt32 = 1000;

type
  ERedisException = class(Exception)

  end;

  TRedisConsts = class sealed
  const
    TTL_KEY_DOES_NOT_EXIST = -2;
    TTL_KEY_IS_NOT_VOLATILE = -1;
  end;

  TRedisClientBase = class abstract(TInterfacedObject)
  protected
    FUnicode: boolean;
    function BytesOfUnicode(const AUnicodeString: string): TBytes;
    function StringOfUnicode(const ABytes: TBytes): string;
  end;

  IRedisCommand = interface;
  IRedisClient = interface;

  TRedisTransactionProc = reference to procedure(Redis: IRedisClient);
  TRedisTimeoutCallback = reference to function: Boolean;

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
      var APoppedAndPushedElement: string): boolean;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32;
      out Value: TArray<string>): boolean;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32;
      out Value: TArray<string>): boolean;
    function LREM(const AListKey: string; const ACount: Integer;
      const AValue: string): Integer;
    // sets
    function SADD(const AKey, AValue: TBytes): Integer;
    function SREM(const AKey, AValue: TBytes): Integer;
    function SMEMBERS(const AKey: string): TArray<string>;
    // system
    procedure FLUSHDB;
    procedure SELECT(const ADBIndex: Integer);

    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand)
      : TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string)
      : TArray<string>;

    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string;
      ACallback: TProc<string, string>;
      ATimeoutCallback: TRedisTimeoutCallback);
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

  IRedisCommand = interface
    ['{79C43B91-604F-49BC-8EB8-35F092258833}']
    function GetToken(const Index: Integer): TBytes;
    procedure Clear;
    function Count: Integer;
    function Add(ABytes: TBytes): IRedisCommand; overload;
    function Add(AString: string): IRedisCommand; overload;
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
    function Receive(const Timeout: UInt32): string;
    function ReceiveBytes(const ACount: Int64; const Timeout: UInt32)
      : System.TArray<System.Byte>;
    procedure Disconnect;
    function LastReadWasTimedOut: boolean;
  end;

const
  REDIS_NULL_BULK_STRING = '$-1';

implementation

{ TRedisClientBase }

function TRedisClientBase.BytesOfUnicode(const AUnicodeString: string): TBytes;
begin
  // if FUnicode then
  // Result := TEncoding.Unicode.GetBytes(AUnicodeString)
  // else
  Result := BytesOf(AUnicodeString);
end;

function TRedisClientBase.StringOfUnicode(const ABytes: TBytes): string;
begin
  // if FUnicode then
  // Result := TEncoding.Unicode.GetString(ABytes)
  // else
  Result := StringOf(ABytes);
end;

end.
