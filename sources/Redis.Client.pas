unit Redis.Client;

interface

uses
  Generics.Collections, System.SysUtils, Redis.Command, Redis.Commons;

function NewRedisClient(const AHostName: string = 'localhost';
  const APort: Word = 6379; const ALibName: string = 'indy'): IRedisClient;
function NewRedisCommand(const RedisCommandString: string): IRedisCommand;

implementation

uses Redis.NetLib.Factory, System.Generics.Collections;

type
  TRedisClient = class(TRedisClientBase, IRedisClient)
  private
    FTCPLibInstance: IRedisNetLibAdapter;
    FHostName: string;
    FPort: Word;
    FCommandTimeout: Int32;
    FRedisCmdParts: IRedisCommand;
    FNotExists: boolean;
    NextCMD: IRedisCommand;
    FValidResponse: boolean;
    IsValidResponse: boolean;
    FInTransaction: boolean;
    FIsTimeout: boolean;
    function ParseSimpleStringResponse(var AValidResponse: boolean): string;
    function ParseSimpleStringResponseAsByte(var AValidResponse
      : boolean): TBytes;
    function ParseIntegerResponse(var AValidResponse
      : boolean): Int64;
    function ParseArrayResponse(var AValidResponse: boolean): TArray<string>;
    procedure CheckResponseType(Expected, Actual: string);
  protected
    procedure Connect;
    function GetCmdList(const Cmd: string): IRedisCommand;
    procedure NextToken(out Msg: string);
    function NextBytes(const ACount: UInt32): TBytes;
    /// //
    function InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand;
      AKeys: array of string; ATimeout: Int32; var AIsValidResponse: boolean)
      : TArray<string>;

  public
    function Tokenize(const ARedisCommand: string): TArray<string>;
    constructor Create(TCPLibInstance: IRedisNetLibAdapter;
      const HostName: string; const Port: Word;
      const UseUnicodeString: boolean);
    destructor Destroy; override;
    /// SET key value [EX seconds] [PX milliseconds] [NX|XX]
    function &SET(const AKey, AValue: string): boolean; overload;
    function &SET(const AKey, AValue: TBytes): boolean; overload;
    function &SET(const AKey: string; AValue: TBytes): boolean; overload;
    function SETExpireInSec(const AKey: TBytes; AValue: TBytes; ASecsExpire: UInt64)
      : boolean; overload;
    function SETExpireInSec(const AKey: string; AValue: TBytes; ASecsExpire: UInt64)
      : boolean; overload;
    function SETExpireInSec(const AKey: string; AValue: string; ASecsExpire: UInt64)
      : boolean; overload;
    function SETNX(const AKey, AValue: string): boolean; overload;
    function SETNX(const AKey, AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: string): boolean; overload;
    function GET(const AKey: TBytes; out AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: TBytes): boolean; overload;
    function TTL(const AKey: string): Integer;
    function DEL(const AKeys: array of string): Integer;
    function EXISTS(const AKey: string): boolean;
    function INCR(const AKey: string): NativeInt;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TArray<string>;
    function EXPIRE(const AKey: string; AExpireInSecond: UInt32): boolean;

    // hash
    function HSET(const AKey, aField: string; AValue: string): Integer;
      overload;
    function HSET(const AKey, aField: string; AValue: TBytes): Integer;
      overload;
    procedure HMSET(const AKey: string; aFields: TArray<string>; AValues: TArray<string>);
    function HMGET(const AKey: string; aFields: TArray<string>): TArray<string>;
    function HGET(const AKey, aField: string; out AValue: TBytes)
      : boolean; overload;
    function HGET(const AKey, aField: string; out AValue: string)
      : boolean; overload;
    function HDEL(const AKey: string; aFields: TArray<string>): Integer;
    // lists
    function RPUSH(const AListKey: string; AValues: array of string): Integer;
    function RPUSHX(const AListKey: string; AValues: array of string): Integer;
    function RPOP(const AListKey: string; var Value: string): boolean;
    function LPUSH(const AListKey: string; AValues: array of string): Integer;
    function LPUSHX(const AListKey: string; AValues: array of string): Integer;
    function LPOP(const AListKey: string; out Value: string): boolean;
    function LRANGE(const AListKey: string; IndexStart, IndexStop: Integer)
      : TArray<string>;
    function LLEN(const AListKey: string): Integer;
    procedure LTRIM(const AListKey: string; const AIndexStart, AIndexStop: Integer);
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
    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string;
      ACallback: TProc<string, string>;
      ATimeoutCallback: TRedisTimeoutCallback);
    function PUBLISH(const AChannel: string; AMessage: string): Integer;
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
    function ZINCRBY(const AKey: string; const AIncrement: Int64; const AMember: string)
      : string;

    // geo
    // function GEOADD(const Key: string; const Latitude, Longitude: Extended; Member: string): Integer;
    // lua scripts
    function EVAL(const AScript: string; AKeys: array of string; AValues: array of string): Integer;
    // system
    procedure FLUSHDB;
    procedure SELECT(const ADBIndex: Integer);
    // transations
    function MULTI(ARedisTansactionProc: TRedisTransactionProc): TArray<string>;
    procedure DISCARD;
    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand)
      : TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string)
      : TArray<string>; overload;
    function ExecuteWithIntegerResult(const RedisCommand: IRedisCommand)
      : Int64; overload;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand): string;
    procedure Disconnect;
    procedure SetCommandTimeout(const Timeout: Int32);
    // client
    procedure ClientSetName(const ClientName: string);
  end;

  { TRedisClient }

function TRedisClient.SADD(const AKey, AValue: TBytes): Integer;
begin
  NextCMD := GetCmdList('SADD').Add(AKey).Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.SADD(const AKey, AValue: string): Integer;
begin
  Result := SADD(BytesOfUnicode(AKey), BytesOfUnicode(AValue));
end;

function TRedisClient.SCARD(const AKey: string): Integer;
begin
  NextCMD := GetCmdList('SCARD').Add(AKey);
  Result := ExecuteWithIntegerResult(NextCMD);
end;

procedure TRedisClient.SELECT(const ADBIndex: Integer);
begin
  NextCMD := GetCmdList('SELECT').Add(ADBIndex.ToString);
  ExecuteWithStringResult(NextCMD);
end;

function TRedisClient.&SET(const AKey, AValue: TBytes): boolean;
begin
  NextCMD := GetCmdList('SET');
  NextCMD.Add(AKey);
  NextCMD.Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  ParseSimpleStringResponseAsByte(FNotExists);
  Result := True;
end;

function TRedisClient.&SET(const AKey: string; AValue: TBytes): boolean;
begin
  Result := &SET(BytesOf(AKey), AValue);
end;

function TRedisClient.BLPOP(const AKeys: array of string; const ATimeout: Int32;
  out Value: TArray<string>): boolean;
begin
  NextCMD := GetCmdList('BLPOP');
  Value := InternalBlockingLeftOrRightPOP(NextCMD, AKeys, ATimeout,
    IsValidResponse);
  Result := IsValidResponse;
end;

function TRedisClient.BRPOP(const AKeys: array of string; const ATimeout: Int32;
  out Value: TArray<string>): boolean;
begin
  NextCMD := GetCmdList('BRPOP');
  Value := InternalBlockingLeftOrRightPOP(NextCMD, AKeys, ATimeout,
    IsValidResponse);
  Result := IsValidResponse;
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
  NextCMD := GetCmdList('CLIENT');
  NextCMD.Add('SETNAME');
  NextCMD.Add(ClientName);
  FTCPLibInstance.SendCmd(NextCMD);
  CheckResponseType('OK',
    StringOf(ParseSimpleStringResponseAsByte(FValidResponse)));
end;

procedure TRedisClient.Connect;
begin
  FTCPLibInstance.Connect(FHostName, FPort);
end;

constructor TRedisClient.Create(TCPLibInstance: IRedisNetLibAdapter;
  const HostName: string; const Port: Word; const UseUnicodeString: boolean);
begin
  inherited Create;
  FTCPLibInstance := TCPLibInstance;
  FHostName := HostName;
  FPort := Port;
  FRedisCmdParts := TRedisCommand.Create(UseUnicodeString);
  FUnicode := UseUnicodeString;
  FCommandTimeout := -1;
end;

function TRedisClient.DEL(const AKeys: array of string): Integer;
begin
  NextCMD := GetCmdList('DEL');
  NextCMD.AddRange(AKeys);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

destructor TRedisClient.Destroy;
begin
  inherited;
end;

procedure TRedisClient.DISCARD;
begin
  NextCMD := GetCmdList('DISCARD');
  FTCPLibInstance.SendCmd(NextCMD);
  ParseSimpleStringResponseAsByte(FValidResponse); // always OK
end;

procedure TRedisClient.Disconnect;
begin
  try
    FTCPLibInstance.Disconnect;
  except
  end;
end;

function TRedisClient.ExecuteWithIntegerResult(const RedisCommand: string)
  : TArray<string>;
var
  Pieces: TArray<string>;
  I: Integer;
begin
  Pieces := Tokenize(RedisCommand);
  NextCMD := GetCmdList(Pieces[0]);
  for I := 1 to Length(Pieces) - 1 do
    NextCMD.Add(Pieces[I]);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponse(IsValidResponse);
end;

function TRedisClient.ExecuteWithIntegerResult(const RedisCommand
  : IRedisCommand): Int64;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.ExecuteWithStringResult(const RedisCommand
  : IRedisCommand): string;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseSimpleStringResponse(FValidResponse);
  if not FValidResponse then
    raise ERedisException.Create('Not valid response');
end;

function TRedisClient.EXISTS(const AKey: string): boolean;
begin
  NextCMD := GetCmdList('EXISTS');
  NextCMD.Add(AKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse) = 1;
end;

function TRedisClient.EXPIRE(const AKey: string;
  AExpireInSecond: UInt32): boolean;
begin
  FTCPLibInstance.Write(GetCmdList('EXPIRE').Add(AKey)
    .Add(AExpireInSecond.ToString).ToRedisCommand);

  {
    1 if the timeout was set.
    0 if key does not exist or the timeout could not be set.
  }
  Result := ParseIntegerResponse(FValidResponse) = 1;
end;

function TRedisClient.EVAL(const AScript: string; AKeys,
  AValues: array of string): Integer;
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
    for lPar in AValues do
    begin
      lCmd.Add(lPar);
    end;
  end;

  Result := ExecuteWithIntegerResult(lCmd);
end;

function TRedisClient.ExecuteAndGetArray(const RedisCommand: IRedisCommand)
  : TArray<string>;
begin
  SetLength(Result, 0);
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseArrayResponse(FValidResponse);
  if FTCPLibInstance.LastReadWasTimedOut then
    Exit;
  if not FValidResponse then
    raise ERedisException.Create('Not valid response');
end;

procedure TRedisClient.FLUSHDB;
begin
  FTCPLibInstance.SendCmd(GetCmdList('FLUSHDB'));
  ParseSimpleStringResponse(FNotExists);
end;

function TRedisClient.GET(const AKey: string; out AValue: string): boolean;
var
  Resp: TBytes;
begin
  Result := GET(BytesOfUnicode(AKey), Resp);
  AValue := StringOfUnicode(Resp);
end;

function TRedisClient.GET(const AKey: TBytes; out AValue: TBytes): boolean;
var
  Pieces: IRedisCommand;
begin
  Pieces := GetCmdList('GET');
  Pieces.Add(AKey);
  FTCPLibInstance.SendCmd(Pieces);
  AValue := ParseSimpleStringResponseAsByte(FValidResponse);
  Result := FValidResponse;
end;

function TRedisClient.GetCmdList(const Cmd: string): IRedisCommand;
begin
  FRedisCmdParts.Clear;
  Result := FRedisCmdParts;
  Result.SetCommand(Cmd);
end;

function TRedisClient.HSET(const AKey, aField: string; AValue: string): Integer;
begin
  Result := HSET(AKey, aField, BytesOfUnicode(AValue));
end;

function TRedisClient.HGET(const AKey, aField: string;
  out AValue: TBytes): boolean;
var
  Pieces: IRedisCommand;
begin
  Pieces := GetCmdList('HGET');
  Pieces.Add(AKey);
  Pieces.Add(aField);
  FTCPLibInstance.SendCmd(Pieces);
  AValue := ParseSimpleStringResponseAsByte(FValidResponse);
  Result := FValidResponse;
end;

function TRedisClient.HDEL(const AKey: string;
  aFields: TArray<string>): Integer;
var
  lCommand: IRedisCommand;
begin
  lCommand := GetCmdList('HDEL');
  lCommand.Add(AKey);
  lCommand.AddRange(aFields);
  FTCPLibInstance.SendCmd(lCommand);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.HGET(const AKey, aField: string;
  out AValue: string): boolean;
var
  Resp: TBytes;
begin
  Result := HGET(AKey, aField, Resp);
  AValue := StringOfUnicode(Resp);
end;

function TRedisClient.HMGET(const AKey: string;
  aFields: TArray<string>): TArray<string>;
var
  Pieces: IRedisCommand;
  I: Integer;
begin
  Pieces := GetCmdList('HMGET');
  Pieces.Add(AKey);
  for I := low(aFields) to high(aFields) do
  begin
    Pieces.Add(aFields[I]);
  end;
  FTCPLibInstance.SendCmd(Pieces);
  Result := ParseArrayResponse(FValidResponse)
end;

procedure TRedisClient.HMSET(const AKey: string; aFields: TArray<string>; AValues: TArray<string>);
var
  I: Integer;
begin
  if Length(aFields) <> Length(AValues) then
    raise ERedisException.Create('Fields count and values count are different');

  NextCMD := GetCmdList('HMSET');
  NextCMD.Add(AKey);
  for I := low(aFields) to high(aFields) do
  begin
    NextCMD.Add(aFields[I]);
    NextCMD.Add(AValues[I]);
  end;
  FTCPLibInstance.SendCmd(NextCMD);
  if FInTransaction then
    CheckResponseType('QUEUED',
      StringOf(ParseSimpleStringResponseAsByte(FValidResponse)))
  else
    CheckResponseType('OK',
      StringOf(ParseSimpleStringResponseAsByte(FValidResponse)));
end;

function TRedisClient.HSET(const AKey, aField: string; AValue: TBytes): Integer;
begin
  NextCMD := GetCmdList('HSET');
  NextCMD.Add(AKey);
  NextCMD.Add(aField);
  NextCMD.Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.INCR(const AKey: string): NativeInt;
begin
  FTCPLibInstance.Write(GetCmdList('INCR').Add(AKey).ToRedisCommand);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand;
  AKeys: array of string; ATimeout: Int32; var AIsValidResponse: boolean)
  : TArray<string>;
begin
  NextCMD.AddRange(AKeys);
  NextCMD.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponse(AIsValidResponse);
end;

function TRedisClient.KEYS(const AKeyPattern: string): TArray<string>;
begin
  NextCMD := GetCmdList('KEYS');
  NextCMD.Add(BytesOfUnicode(AKeyPattern));
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponse(IsValidResponse);
end;

function TRedisClient.LLEN(const AListKey: string): Integer;
begin
  NextCMD := GetCmdList('LLEN');
  NextCMD.Add(AListKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.LPOP(const AListKey: string; out Value: string): boolean;
begin
  NextCMD := GetCmdList('LPOP');
  NextCMD.Add(AListKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.LPUSH(const AListKey: string;
  AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('LPUSH');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.LPUSHX(const AListKey: string;
  AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('LPUSHX');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.LRANGE(const AListKey: string;
  IndexStart, IndexStop: Integer): TArray<string>;
begin
  NextCMD := GetCmdList('LRANGE');
  NextCMD.Add(AListKey);
  NextCMD.Add(IndexStart.ToString);
  NextCMD.Add(IndexStop.ToString);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponse(IsValidResponse);
end;

function TRedisClient.LREM(const AListKey: string; const ACount: Integer;
  const AValue: string): Integer;
begin
  NextCMD := GetCmdList('LREM');
  NextCMD.Add(AListKey);
  NextCMD.Add(ACount.ToString);
  NextCMD.Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

procedure TRedisClient.LTRIM(const AListKey: string; const AIndexStart,
  AIndexStop: Integer);
var
  lResult: string;
begin
  NextCMD := GetCmdList('LTRIM')
    .Add(AListKey)
    .Add(AIndexStart.ToString)
    .Add(AIndexStop.ToString);
  lResult := ExecuteWithStringResult(NextCMD);
  if lResult <> 'OK' then
    raise ERedisException.Create(lResult);
end;

function TRedisClient.MSET(const AKeysValues: array of string): boolean;
begin
  NextCMD := GetCmdList('MSET');
  NextCMD.AddRange(AKeysValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseSimpleStringResponse(FNotExists) = 'OK';
end;

function TRedisClient.MULTI(ARedisTansactionProc: TRedisTransactionProc)
  : TArray<string>;
begin
  NextCMD := GetCmdList('MULTI');
  try
    FTCPLibInstance.SendCmd(NextCMD);
    ParseSimpleStringResponse(FValidResponse);
    FInTransaction := True;
    try
      ARedisTansactionProc(self);
    except
      DISCARD;
      raise;
    end;
    NextCMD := GetCmdList('EXEC');
    FTCPLibInstance.SendCmd(NextCMD);
    Result := ParseArrayResponse(FValidResponse);
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

function TRedisClient.ParseArrayResponse(var AValidResponse: boolean)
  : TArray<string>;
var
  R: string;
  ArrLength: Integer;
  I: Integer;
begin
  SetLength(Result, 0);
  AValidResponse := True;
  NextToken(R);
  if FIsTimeout then
    Exit;

  if R.Chars[0] = '*' then
  begin
    ArrLength := R.Substring(1).ToInteger;
    if ArrLength = -1 then // REDIS_NULL_BULK_STRING
    begin
      AValidResponse := False;
      Exit;
    end;
  end
  else if R.Chars[0] = '-' then
    raise ERedisException.Create(R.Substring(1))
  else
    raise ERedisException.Create('Invalid response length, invalid array response');
  SetLength(Result, ArrLength);
  if ArrLength = 0 then
    Exit;
  I := 0;
  while True do
  begin
    Result[I] := StringOfUnicode(ParseSimpleStringResponseAsByte(FNotExists));
    inc(I);
    if I >= ArrLength then
      break;
  end;
end;

function TRedisClient.ParseIntegerResponse(var AValidResponse
  : boolean): Int64;
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

  case R.Chars[0] of
    ':':
      begin
        if not TryStrToInt(R.Substring(1), I) then
          raise ERedisException.CreateFmt('Expected Integer got [%s]', [R]);
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
          raise ERedisException.Create('Not an Integer response');
      end
  else
    raise ERedisException.Create('Not an Integer response');
  end;
end;

function TRedisClient.ParseSimpleStringResponse(var AValidResponse
  : boolean): string;
var
  R: string;
  HowMany: Integer;
begin
  AValidResponse := True;
  NextToken(R);
  if FIsTimeout then
  begin
    AValidResponse := False;
    Exit;
  end;

  if R = TRedisConsts.NULL_ARRAY then
  begin
    AValidResponse := True;
    Exit(TRedisConsts.NULL_ARRAY);
  end;

  case R.Chars[0] of
    '+':
      Result := R.Substring(1);
    '-':
      raise ERedisException.Create(R.Substring(1));
    '$':
      begin
        HowMany := R.Substring(1).ToInteger;
        if HowMany >= 0 then
        begin
          NextToken(R);
          if FIsTimeout then
            Exit;

          // if R.Length <> HowMany then
          // raise ERedisException.CreateFmt('Invalid string len Expected [%d] got [%d]', [HowMany, R.Length]);
          Result := R;
        end
        else if HowMany = -1 then
        // "$-1\r\n" --> This is called a Null Bulk String.
        begin
          AValidResponse := False;
          Result := '';
        end;
      end;
  else
    raise ERedisException.Create('Not a String response');
  end;
end;

function TRedisClient.ParseSimpleStringResponseAsByte(var AValidResponse
  : boolean): TBytes;
var
  R: string;
  HowMany: Integer;
begin
  SetLength(Result, 0);
  AValidResponse := True;
  NextToken(R);
  if FIsTimeout then
    Exit;

  case R.Chars[0] of
    '+':
      Result := BytesOf(R.Substring(1));
    '-':
      raise ERedisException.Create(R.Substring(1));
    ':':
      Result := BytesOf(R.Substring(1));
    '$':
      begin
        HowMany := R.Substring(1).ToInteger;
        if HowMany >= 0 then
        begin
          Result := FTCPLibInstance.ReceiveBytes(HowMany, FCommandTimeout);
          // eat crlf
          FTCPLibInstance.ReceiveBytes(2, FCommandTimeout);
        end
        else if HowMany = -1 then
        // "$-1\r\n" --> This is called a Null Bulk String.
        begin
          AValidResponse := False;
          SetLength(Result, 0);
        end;
      end;
  else
    raise ERedisException.Create('Not a String response');
  end;
end;

function TRedisClient.PUBLISH(const AChannel: string; AMessage: string)
  : Integer;
begin
  NextCMD := GetCmdList('PUBLISH');
  NextCMD.Add(AChannel);
  NextCMD.Add(AMessage);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.RPOP(const AListKey: string; var Value: string): boolean;
begin
  NextCMD := GetCmdList('RPOP');
  NextCMD.Add(AListKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.BRPOPLPUSH(const ARightListKey, ALeftListKey: string;
  var APoppedAndPushedElement: string; ATimeout: Int32): boolean;
var
  lValue: string;
begin
  APoppedAndPushedElement := '';
  NextCMD := GetCmdList('BRPOPLPUSH');
  NextCMD.Add(ARightListKey);
  NextCMD.Add(ALeftListKey);
  NextCMD.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(NextCMD);
  lValue := ParseSimpleStringResponse(FValidResponse);
  Result := not(lValue = TRedisConsts.NULL_ARRAY);
  if Result then
  begin
    APoppedAndPushedElement := lValue;
    // Result := FValidResponse;
  end;
end;

function TRedisClient.RPOPLPUSH(const ARightListKey, ALeftListKey: string;
  var APoppedAndPushedElement: string): boolean;
begin
  NextCMD := GetCmdList('RPOPLPUSH');
  NextCMD.Add(ARightListKey);
  NextCMD.Add(ALeftListKey);
  FTCPLibInstance.SendCmd(NextCMD);
  APoppedAndPushedElement := ParseSimpleStringResponse(FValidResponse);
  Result := FValidResponse;
end;

function TRedisClient.RPUSH(const AListKey: string;
  AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('RPUSH');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.RPUSHX(const AListKey: string;
  AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('RPUSHX');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.&SET(const AKey, AValue: string): boolean;
begin
  Result := &SET(BytesOfUnicode(AKey), BytesOfUnicode(AValue));
end;

procedure TRedisClient.SetCommandTimeout(const Timeout: Int32);
begin
  FCommandTimeout := Timeout;
end;

function TRedisClient.SETNX(const AKey, AValue: string): boolean;
begin
  Result := SETNX(BytesOfUnicode(AKey), BytesOfUnicode(AValue));
end;

function TRedisClient.SETExpireInSec(const AKey: string; AValue: TBytes;
  ASecsExpire: UInt64): boolean;
begin
  Result := SETExpireInSec(BytesOfUnicode(AKey), AValue, ASecsExpire);
end;

function TRedisClient.SETExpireInSec(const AKey: TBytes; AValue: TBytes;
  ASecsExpire: UInt64): boolean;
begin
  NextCMD := GetCmdList('SET');
  NextCMD.Add(AKey);
  NextCMD.Add(AValue);
  NextCMD.Add('EX');
  NextCMD.Add(IntToStr(ASecsExpire));
  FTCPLibInstance.SendCmd(NextCMD);
  ParseSimpleStringResponseAsByte(FNotExists);
  Result := True;
end;

function TRedisClient.SETExpireInSec(const AKey: string; AValue: string;
  ASecsExpire: UInt64): boolean;
begin
  Result := SETExpireInSec(BytesOfUnicode(AKey), BytesOfUnicode(AValue), ASecsExpire);
end;

function TRedisClient.SETNX(const AKey, AValue: TBytes): boolean;
begin
  NextCMD := GetCmdList('SETNX');
  NextCMD.Add(AKey);
  NextCMD.Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse) = 1;
end;

function TRedisClient.SMEMBERS(const AKey: string): TArray<string>;
begin
  NextCMD := GetCmdList('SMEMBERS').Add(AKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponse(FValidResponse);
end;

function TRedisClient.SREM(const AKey, AValue: string): Integer;
begin
  Result := SREM(BytesOfUnicode(AKey), BytesOfUnicode(AValue));
end;

function TRedisClient.SREM(const AKey, AValue: TBytes): Integer;
begin
  NextCMD := GetCmdList('SREM').Add(AKey).Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

procedure TRedisClient.SUBSCRIBE(const AChannels: array of string;
  ACallback: TProc<string, string>; ATimeoutCallback: TRedisTimeoutCallback);
var
  I: Integer;
  Channel, Value: string;
  Arr: TArray<string>;
  BContinue: boolean;
begin
  NextCMD := GetCmdList('SUBSCRIBE');
  NextCMD.AddRange(AChannels);
  FTCPLibInstance.SendCmd(NextCMD);
  // just to implement a sort of non blockign subscribe
  SetCommandTimeout(RedisDefaultSubscribeTimeout);

  for I := 0 to Length(AChannels) - 1 do
  begin
    Arr := ParseArrayResponse(FValidResponse);
    if (Arr[0].ToLower <> 'subscribe') or (Arr[1] <> AChannels[I]) then
      raise ERedisException.Create('Invalid response: ' + string.Join('-', Arr))
  end;
  // all is fine, now read the callbacks message
  while True do
  begin
    Arr := ParseArrayResponse(FValidResponse);
    if FTCPLibInstance.LastReadWasTimedOut then
    begin
      if Assigned(ATimeoutCallback) then
      begin
        BContinue := ATimeoutCallback();
        if not BContinue then
          break;
      end;
    end
    else
    begin
      if (not FValidResponse) or (Arr[0] <> 'message') then
        raise ERedisException.CreateFmt('Invalid reply: %s',
          [string.Join('-', Arr)]);
      Channel := Arr[1];
      Value := Arr[2];
      ACallback(Channel, Value);
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
      raise ERedisException.Create('Invalid end of command');

    if not Piece.IsEmpty then
      List.Add(Piece);

    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TRedisClient.TTL(const AKey: string): Integer;
begin
  NextCMD := GetCmdList('TTL');
  NextCMD.Add(AKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse(FValidResponse);
end;

function TRedisClient.ZADD(const AKey: string; const AScore: Int64;
  const AMember: string): Integer;
begin
  NextCMD := GetCmdList('ZADD');
  NextCMD.Add(AKey).Add(AScore.ToString).Add(AMember);
  Result := ExecuteWithIntegerResult(NextCMD);
end;

function TRedisClient.ZCARD(const AKey: string): Integer;
begin
  NextCMD := GetCmdList('ZCARD').Add(AKey);
  Result := ExecuteWithIntegerResult(NextCMD);
end;

function TRedisClient.ZCOUNT(const AKey: string; const AMin,
  AMax: Int64): Integer;
begin
  NextCMD := GetCmdList('ZCOUNT');
  NextCMD.Add(AKey).Add(AMin.ToString).Add(AMax.ToString);
  Result := ExecuteWithIntegerResult(NextCMD);
end;

function TRedisClient.ZINCRBY(const AKey: string; const AIncrement: Int64;
  const AMember: string): string;
begin
  NextCMD := GetCmdList('ZINCRBY');
  NextCMD.Add(AKey).Add(AIncrement.ToString).Add(AMember);
  Result := ExecuteWithStringResult(NextCMD);
end;

function TRedisClient.ZRANGE(const AKey: string; const AStart,
  AStop: Int64): TArray<string>;
begin
  NextCMD := GetCmdList('ZRANGE');
  NextCMD.Add(AKey).Add(AStart.ToString).Add(AStop.ToString);
  Result := ExecuteAndGetArray(NextCMD);
end;

function TRedisClient.ZRANGEWithScore(const AKey: string; const AStart,
  AStop: Int64): TArray<string>;
begin
  NextCMD := GetCmdList('ZRANGE');
  NextCMD.Add(AKey).Add(AStart.ToString).Add(AStop.ToString).Add('WITHSCORES');
  Result := ExecuteAndGetArray(NextCMD);
end;

function TRedisClient.ZRANK(const AKey: string; const AMember: string; out ARank: Int64): boolean;
begin
  NextCMD := GetCmdList('ZRANK');
  NextCMD.Add(AKey).Add(AMember);
  ARank := ExecuteWithIntegerResult(NextCMD);
  Result := ARank <> -1;
end;

function TRedisClient.ZREM(const AKey, AMember: string): Integer;
begin
  NextCMD := GetCmdList('ZREM');
  NextCMD.Add(AKey).Add(AMember);
  Result := ExecuteWithIntegerResult(NextCMD);
end;

function NewRedisClient(const AHostName: string; const APort: Word;
  const ALibName: string): IRedisClient;
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  TCPLibInstance := TLibFactory.GET(ALibName);
  Result := TRedisClient.Create(TCPLibInstance, AHostName, APort,
    False { AUseUnicodeString } );
  try
    TRedisClient(Result).Connect;
  except
    Result := nil;
    raise;
  end;
end;

function NewRedisCommand(const RedisCommandString: string): IRedisCommand;
begin
  Result := TRedisCommand.Create(False);
  TRedisCommand(Result).SetCommand(RedisCommandString);
end;

// function TRedisClient.GEOADD(const Key: string; const Latitude,
// Longitude: Extended; Member: string): Integer;
// var
// lCmd: IRedisCommand;
// begin
// lCmd := NewRedisCommand('GEOADD');
// lCmd.Add(Key);
// lCmd.Add(FormatFloat('0.0000000', Latitude));
// lCmd.Add(FormatFloat('0.0000000', Longitude));
// lCmd.Add(Member);
// Result := ExecuteWithIntegerResult(lCmd);
// end;

function TRedisClient.GET(const AKey: string; out AValue: TBytes): boolean;
begin
  Result := GET(BytesOf(AKey), AValue);
end;

end.
