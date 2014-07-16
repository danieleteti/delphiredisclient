unit Redis.Commons;

interface

uses
  System.SysUtils;

type
  ERedisException = class(Exception)

  end;

  TRedisClientBase = class abstract(TInterfacedObject)
  protected
    FUnicode: boolean;
    function BytesOfUnicode(const AUnicodeString: string): TBytes;
    function StringOfUnicode(const ABytes: TBytes): string;
  end;

  IRedisClient = interface
    ['{566C20FF-7D9F-4DAC-9B0E-A8AA7D29B0B4}']
    function &SET(const AKey, AValue: string): boolean; overload;
    function &SET(const AKey, AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: string): boolean; overload;
    function GET(const AKey: TBytes; out AValue: TBytes): boolean; overload;
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
    // raw execute
    function ExecuteWithStringArrayResult(const RedisCommand: string): TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string): TArray<string>;
    // non sys
    function Tokenize(const ARedisCommand: string): TArray<string>;
    procedure Disconnect;
  end;

  IRedisCommand = interface
    ['{79C43B91-604F-49BC-8EB8-35F092258833}']
    function GetRedisToken(const Index: Integer): string;
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
    function ReceiveBytes(const ACount: Int64; const Timeout: UInt32): System.TArray<System.Byte>;
    procedure Disconnect;
  end;

const
  REDIS_NULL_BULK_STRING = '$-1';

implementation

{ TRedisClientBase }

function TRedisClientBase.BytesOfUnicode(const AUnicodeString: string): TBytes;
begin
  if FUnicode then
    Result := TEncoding.Unicode.GetBytes(AUnicodeString)
  else
    Result := BytesOf(AUnicodeString);
end;

function TRedisClientBase.StringOfUnicode(const ABytes: TBytes): string;
begin
  if FUnicode then
    Result := TEncoding.Unicode.GetString(ABytes)
  else
    Result := StringOf(ABytes);
end;

end.
