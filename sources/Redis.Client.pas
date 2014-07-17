unit Redis.Client;

interface

uses
  Generics.Collections, System.SysUtils, Redis.Command, Redis.Commons;

function NewRedisClient(const AHostName: string; const APort: Word = 6379; const ALibName: string = 'indy')
  : IRedisClient;
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
    function ParseSimpleStringResponse(var AValidResponse: boolean): string;
    function ParseSimpleStringResponseAsByte(var AValidResponse: boolean): TBytes;
    function ParseIntegerResponse: NativeInt;
    function ParseArrayResponse(var AValidResponse: boolean): TArray<string>;
    procedure CheckResponseType(Expected, Actual: string);
  protected
    procedure Connect;
    function GetCmdList(const Cmd: string): IRedisCommand;
    function NextToken: string;
    function NextBytes(const ACount: UInt32): TBytes;
    /// //
    function InternalBlockingLeftOrRightPOP(NextCMD: IRedisCommand; AKeys: array of string; ATimeout: Int32;
      var AIsValidResponse: boolean): TArray<string>;

  public
    function Tokenize(const ARedisCommand: string): TArray<string>;
    constructor Create(TCPLibInstance: IRedisNetLibAdapter; const HostName: string; const Port: Word;
      const UseUnicodeString: boolean);
    destructor Destroy; override;
    /// SET key value [EX seconds] [PX milliseconds] [NX|XX]
    function &SET(const AKey, AValue: string): boolean; overload;
    function &SET(const AKey, AValue: TBytes): boolean; overload;
    function GET(const AKey: string; out AValue: string): boolean; overload;
    function GET(const AKey: TBytes; out AValue: TBytes): boolean; overload;
    function DEL(const AKeys: array of string): Integer;
    function INCR(const AKey: string): NativeInt;
    function MSET(const AKeysValues: array of string): boolean;
    function KEYS(const AKeyPattern: string): TArray<string>;
    function EXPIRE(const AKey: string; AExpireInSecond: UInt32): boolean;
    // lists
    function RPUSH(const AListKey: string; AValues: array of string): Integer;
    function RPUSHX(const AListKey: string; AValues: array of string): Integer;
    function RPOP(const AListKey: string; var Value: string): boolean;
    function LPUSH(const AListKey: string; AValues: array of string): Integer;
    function LPUSHX(const AListKey: string; AValues: array of string): Integer;
    function LPOP(const AListKey: string; out Value: string): boolean;
    function LRANGE(const AListKey: string; IndexStart, IndexStop: Integer): TArray<string>;
    function LLEN(const AListKey: string): Integer;
    function RPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string): boolean;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
    function LREM(const AListKey: string; const ACount: Integer; const AValue: string): Integer;
    // pubsub
    procedure SUBSCRIBE(const AChannels: array of string; ACallback: TProc<string, string>);
    // system
    procedure FLUSHDB;
    procedure SELECT(const ADBIndex: Integer);
    // raw execute
    function ExecuteAndGetArray(const RedisCommand: IRedisCommand): TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string): TArray<string>;
    function ExecuteWithStringResult(const RedisCommand: IRedisCommand): string;
    procedure Disconnect;
    procedure SetCommandTimeout(const Timeout: Int32);
  end;

  { TRedisClient }

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

function TRedisClient.BLPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
begin
  NextCMD := GetCmdList('BLPOP');
  Value := InternalBlockingLeftOrRightPOP(NextCMD, AKeys, ATimeout, IsValidResponse);
  Result := IsValidResponse;
end;

function TRedisClient.BRPOP(const AKeys: array of string; const ATimeout: Int32;
  out Value: TArray<string>): boolean;
begin
  NextCMD := GetCmdList('BRPOP');
  Value := InternalBlockingLeftOrRightPOP(NextCMD, AKeys, ATimeout, IsValidResponse);
  Result := IsValidResponse;
end;

procedure TRedisClient.CheckResponseType(Expected, Actual: string);
begin
  if Expected <> Actual then
  begin
    raise ERedisException.CreateFmt('Expected %s got %s', [Expected, Actual]);
  end;
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
end;

function TRedisClient.DEL(const AKeys: array of string): Integer;
var
  R: string;
begin
  NextCMD := GetCmdList('DEL');
  NextCMD.AddRange(AKeys);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse;
end;

destructor TRedisClient.Destroy;
begin
  inherited;
end;

procedure TRedisClient.Disconnect;
begin
  try
    FTCPLibInstance.Disconnect;
  except
  end;
end;

function TRedisClient.ExecuteWithIntegerResult(
  const RedisCommand: string): TArray<string>;
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

function TRedisClient.ExecuteWithStringResult(
  const RedisCommand: IRedisCommand): string;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseSimpleStringResponse(FValidResponse);
  if not FValidResponse then
    raise ERedisException.Create('Not valid response');
end;

function TRedisClient.EXPIRE(const AKey: string;
  AExpireInSecond: UInt32): boolean;
begin
  FTCPLibInstance.Write(GetCmdList('EXPIRE')
    .Add(AKey)
    .Add(AExpireInSecond.ToString)
    .ToRedisCommand);

  {
    1 if the timeout was set.
    0 if key does not exist or the timeout could not be set.
  }
  Result := ParseIntegerResponse = 1;
end;

function TRedisClient.ExecuteAndGetArray(
  const RedisCommand: IRedisCommand): TArray<string>;
begin
  FTCPLibInstance.Write(RedisCommand.ToRedisCommand);
  Result := ParseArrayResponse(FValidResponse);
  if not FValidResponse then
    raise ERedisException.Create('Not valid response');
end;

procedure TRedisClient.FLUSHDB;
var
  Cmd: TRedisCommand;
begin
  FTCPLibInstance.SendCmd(GetCmdList('FLUSHDB'));
  ParseSimpleStringResponse(FNotExists);
end;

function TRedisClient.GET(const AKey: string; out AValue: string): boolean;
var
  R: string;
  Pieces: TRedisCommand;
  HowMany: Integer;
  Resp: TBytes;
begin
  Result := GET(BytesOfUnicode(AKey), Resp);
  AValue := StringOfUnicode(Resp);
end;

function TRedisClient.GET(const AKey: TBytes; out AValue: TBytes): boolean;
var
  R: string;
  Pieces: IRedisCommand;
  HowMany: Integer;
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

function TRedisClient.INCR(const AKey: string): NativeInt;
begin
  FTCPLibInstance.Write(GetCmdList('INCR').Add(AKey).ToRedisCommand);
  Result := ParseIntegerResponse;
end;

function TRedisClient.InternalBlockingLeftOrRightPOP(
  NextCMD: IRedisCommand;
  AKeys: array of string;
  ATimeout: Int32;
  var AIsValidResponse: boolean): TArray<string>;
begin
  NextCMD.AddRange(AKeys);
  NextCMD.Add(ATimeout.ToString);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseArrayResponse(AIsValidResponse);
end;

function TRedisClient.KEYS(const AKeyPattern: string): TArray<string>;
var
  R: string;
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
  Result := ParseIntegerResponse;
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
  Result := ParseIntegerResponse;
end;

function TRedisClient.LPUSHX(const AListKey: string;
  AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('LPUSHX');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse;
end;

function TRedisClient.LRANGE(const AListKey: string; IndexStart,
  IndexStop: Integer): TArray<string>;
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
  Result := ParseIntegerResponse;
end;

function TRedisClient.MSET(const AKeysValues: array of string): boolean;
begin
  NextCMD := GetCmdList('MSET');
  NextCMD.AddRange(AKeysValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseSimpleStringResponse(FNotExists) = 'OK';
end;

function TRedisClient.NextToken: string;
begin
  Result := FTCPLibInstance.Receive(FCommandTimeout);
end;

function TRedisClient.NextBytes(const ACount: UInt32): TBytes;
begin
  FTCPLibInstance.ReceiveBytes(ACount, FCommandTimeout);
end;

function TRedisClient.ParseArrayResponse(var AValidResponse: boolean): TArray<string>;
var
  R: string;
  ArrLength: Integer;
  I: Integer;
begin
  AValidResponse := True;
  R := NextToken;
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
    raise ERedisException.Create('Invalid response length');
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

function TRedisClient.ParseIntegerResponse: NativeInt;
var
  R: string;
  I: Integer;
begin
  R := NextToken;
  case R.Chars[0] of
    ':':
      begin
        if not TryStrToInt(R.Substring(1), I) then
          raise ERedisException.CreateFmt('Expected Integer got [%s]', [R]);
        Result := I;
      end
  else
    raise ERedisException.Create('ParseIntegerResponse Error');
  end;
end;

function TRedisClient.ParseSimpleStringResponse(var AValidResponse: boolean): string;
var
  R: string;
  HowMany: Integer;
  B: TArray<Byte>;
begin
  AValidResponse := True;
  R := NextToken;
  case R.Chars[0] of
    '+':
      Result := R.Substring(1);
    '-':
      raise ERedisException.Create(R.Substring(1));
    '$':
      begin
        HowMany := R.Substring(1).ToInteger;
        if HowMany > 0 then
        begin
          R := NextToken;
          // if R.Length <> HowMany then
          // raise ERedisException.CreateFmt('Invalid string len Expected [%d] got [%d]', [HowMany, R.Length]);
          Result := R;
        end
        else if HowMany = -1 then // "$-1\r\n" --> This is called a Null Bulk String.
        begin
          AValidResponse := False;
          Result := '';
        end;
      end;
  else
    raise ERedisException.Create('ParseStringResponse Error');
  end;
end;

function TRedisClient.ParseSimpleStringResponseAsByte(
  var AValidResponse: boolean): TBytes;
var
  R: string;
  HowMany: Integer;
begin
  SetLength(Result, 0);
  AValidResponse := True;
  R := NextToken;
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
        if HowMany > 0 then
        begin
          Result := FTCPLibInstance.ReceiveBytes(HowMany, FCommandTimeout);
          // eat crlf
          FTCPLibInstance.ReceiveBytes(2, FCommandTimeout);
        end
        else if HowMany = -1 then // "$-1\r\n" --> This is called a Null Bulk String.
        begin
          AValidResponse := False;
          SetLength(Result, 0);
        end;
      end;
  else
    raise ERedisException.Create('ParseStringResponse Error');
  end;
end;

function TRedisClient.RPOP(const AListKey: string; var Value: string): boolean;
begin
  NextCMD := GetCmdList('RPOP');
  NextCMD.Add(AListKey);
  FTCPLibInstance.SendCmd(NextCMD);
  Value := ParseSimpleStringResponse(Result);
end;

function TRedisClient.RPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string)
  : boolean;
begin
  NextCMD := GetCmdList('RPOPLPUSH');
  NextCMD.Add(ARightListKey);
  NextCMD.Add(ALeftListKey);
  FTCPLibInstance.SendCmd(NextCMD);
  APoppedAndPushedElement := ParseSimpleStringResponse(FValidResponse);
  Result := FValidResponse;
end;

function TRedisClient.RPUSH(const AListKey: string; AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('RPUSH');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse;
end;

function TRedisClient.RPUSHX(const AListKey: string;
  AValues: array of string): Integer;
begin
  NextCMD := GetCmdList('RPUSHX');
  NextCMD.Add(AListKey);
  NextCMD.AddRange(AValues);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseIntegerResponse;
end;

function TRedisClient.&SET(const AKey, AValue: string): boolean;
var
  R: string;
begin
  Result := &SET(BytesOfUnicode(AKey), BytesOfUnicode(AValue));
end;

procedure TRedisClient.SetCommandTimeout(const Timeout: Int32);
begin
  FCommandTimeout := Timeout;
end;

procedure TRedisClient.SUBSCRIBE(const AChannels: array of string; ACallback: TProc<string, string>);
var
  I: Integer;
  Channel, Value: string;
  Arr: TArray<string>;
begin
  NextCMD := GetCmdList('SUBSCRIBE');
  NextCMD.AddRange(AChannels);
  FTCPLibInstance.SendCmd(NextCMD);
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
    if (not FValidResponse) or (Arr[0] <> 'message') then
      raise ERedisException.CreateFmt('Invalid reply: %s', [string.Join('-', Arr)]);
    Channel := Arr[1];
    Value := Arr[2];
    ACallback(Channel, Value);
  end;
end;

function TRedisClient.Tokenize(const ARedisCommand: string): TArray<string>;
var
  I: Integer;
  C: Char;
  List: TList<string>;
  CurState: Integer;
  Piece: string;
  Command: string;
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

function NewRedisClient(const AHostName: string; const APort: Word; const ALibName: string): IRedisClient;
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  TCPLibInstance := TLibFactory.GET(ALibName);
  Result := TRedisClient.Create(TCPLibInstance, AHostName, APort, False { AUseUnicodeString } );
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

end.
