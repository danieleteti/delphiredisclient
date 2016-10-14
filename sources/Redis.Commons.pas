unit Redis.Commons;

interface

uses
  System.SysUtils;

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
  end;

  TRedisClientBase = class abstract(TInterfacedObject)
  protected
    function BytesOfUnicode(const AUnicodeString: string): TBytes;
    function StringOfUnicode(const ABytes: TBytes): string;
  end;

  IRedisCommand = interface;
  IRedisClient = interface;

  TRedisTransactionProc = reference to procedure(const Redis: IRedisClient);
  TRedisTimeoutCallback = reference to function: boolean;

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

    // geo
    // function GEOADD(const Key: string; const Latitude, Longitude: Extended; Member: string)
    // : Integer;

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
    function GetToken(const Index: Integer): TBytes;
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
    function ReceiveBytes(const ACount: Int64; const Timeout: Int32)
      : System.TArray<System.Byte>;
    procedure Disconnect;
    function LastReadWasTimedOut: boolean;
    function LibName: string;
  end;

function ByteToHex(InByte: byte): string;

implementation

function ByteToHex(InByte: byte): string;
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
