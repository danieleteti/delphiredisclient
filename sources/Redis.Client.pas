unit Redis.Client;

interface

uses
  Generics.Collections, System.SysUtils;

type
  TRedisCmdParts = class(TList<string>)
  protected
    FBldr: TStringBuilder;
    function GetBuilder: TStringBuilder;
    procedure ClearBuilder;
  public
    function GetRedisToken(const Index: Integer): string;
    function GetBinaryRedisToken(const Index: Integer): TBytes;
    destructor Destroy; override;
  end;

  ERedisException = class(Exception)

  end;

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
    // raw execute
    function ExecuteWithStringArrayResult(const RedisCommand: string): TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string): TArray<string>;
    // non sys
    function Tokenize(const ARedisCommand: string): TArray<string>;
    procedure Disconnect;
  end;

  IRedisNetLibAdapter = interface
    ['{2DB21166-2E68-4DC4-9870-5DCCAAE877A3}']
    procedure Connect(const HostName: string; const Port: Word);
    procedure Send(const Value: string);
    procedure SendCmd(const Values: TRedisCmdParts);
    function Receive(const Timeout): string;
    procedure Disconnect;
  end;

const
  REDIS_NULL_BULK_STRING = '$-1';

function NewRedisClient(const HostName: string; const Port: Word = 6379; const LibName: string = 'indy'): IRedisClient;

implementation

uses Redis.NetLib.Factory, System.Generics.Collections;

type
  TRedisClient = class(TInterfacedObject, IRedisClient)
  private
    FTCPLibInstance: IRedisNetLibAdapter;
    FHostName: string;
    FPort: Word;
    FCommandTimeout: Int32;
    FRedisCmdParts: TRedisCmdParts;
    FNotExists: boolean;
    NextCMD: TRedisCmdParts;
    FValidResponse: boolean;
    IsValidResponse: boolean;
    function ParseSimpleStringResponse(var AValidResponse: boolean): string;
    function ParseIntegerResponse: Integer;
    function ParseArrayResponse(var AValidResponse: boolean): TArray<string>;
    procedure CheckResponseType(Expected, Actual: string);
  protected
    procedure Connect;
    function GetCmdList(const Cmd: string): TRedisCmdParts;
    function NextToken: string;
    /// //
    function InternalBlockingLeftOrRightPOP(NextCMD: TRedisCmdParts; AKeys: array of string; ATimeout: Int32;
      var AIsValidResponse: boolean): TArray<string>;

  public
    function Tokenize(const ARedisCommand: string): TArray<string>;
    constructor Create(TCPLibInstance: IRedisNetLibAdapter; const HostName: string; const Port: Word);
    destructor Destroy; override;
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
    function LRANGE(const AListKey: string; IndexStart, IndexStop: Integer): TArray<string>;
    function LLEN(const AListKey: string): Integer;
    function RPOPLPUSH(const ARightListKey, ALeftListKey: string; var APoppedAndPushedElement: string): boolean;
    function BLPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
    function BRPOP(const AKeys: array of string; const ATimeout: Int32; out Value: TArray<string>): boolean;
    function LREM(const AListKey: string; const ACount: Integer; const AValue: string): Integer;
    // system
    function FLUSHDB: boolean;
    // raw execute
    function ExecuteWithStringArrayResult(const RedisCommand: string): TArray<string>;
    function ExecuteWithIntegerResult(const RedisCommand: string): TArray<string>;
    procedure Disconnect;
    procedure SetCommandTimeout(const Timeout: Int32);
  end;

  { TRedisClient }

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
  const HostName: string; const Port: Word);
begin
  inherited Create;
  FTCPLibInstance := TCPLibInstance;
  FHostName := HostName;
  FPort := Port;
  FRedisCmdParts := TRedisCmdParts.Create;
end;

function TRedisClient.DEL(const AKeys: array of string): Integer;
var
  R: string;
  Cmd: TRedisCmdParts;
begin
  Cmd := GetCmdList('DEL');
  Cmd.AddRange(AKeys);
  FTCPLibInstance.SendCmd(Cmd);
  Result := ParseIntegerResponse;
end;

destructor TRedisClient.Destroy;
begin
  FRedisCmdParts.Free;
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

function TRedisClient.ExecuteWithStringArrayResult(
  const RedisCommand: string): TArray<string>;
begin

end;

function TRedisClient.FLUSHDB: boolean;
var
  Cmd: TRedisCmdParts;
begin
  FTCPLibInstance.SendCmd(GetCmdList('FLUSHDB'));
  Result := ParseSimpleStringResponse(FNotExists) = 'OK';
end;

function TRedisClient.GET(const AKey: string; out AValue: string): boolean;
var
  R: string;
  Pieces: TRedisCmdParts;
  HowMany: Integer;
begin
  Pieces := GetCmdList('GET');
  Pieces.Add(AKey);
  FTCPLibInstance.SendCmd(Pieces);
  AValue := ParseSimpleStringResponse(FValidResponse);
  Result := FValidResponse;
end;

function TRedisClient.GetCmdList(const Cmd: string): TRedisCmdParts;
begin
  FRedisCmdParts.Clear;
  Result := FRedisCmdParts;
  Result.Add(Cmd);
end;

function TRedisClient.InternalBlockingLeftOrRightPOP(
  NextCMD: TRedisCmdParts;
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
  NextCMD.Add(AKeyPattern);
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
    Result[I] := ParseSimpleStringResponse(FNotExists);
    inc(I);
    if I >= ArrLength then
      break;
  end;
end;

function TRedisClient.ParseIntegerResponse: Integer;
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
begin
  AValidResponse := True;
  R := NextToken;
  case R.Chars[0] of
    '+':
      Result := R.Substring(1);
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
  NextCMD := GetCmdList('SET');
  NextCMD.Add(AKey);
  NextCMD.Add(AValue);
  FTCPLibInstance.SendCmd(NextCMD);
  Result := ParseSimpleStringResponse(FNotExists) = 'OK';
end;

procedure TRedisClient.SetCommandTimeout(const Timeout: Int32);
begin
  FCommandTimeout := Timeout;
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

function NewRedisClient(const HostName: string; const Port: Word; const LibName: string): IRedisClient;
var
  TCPLibInstance: IRedisNetLibAdapter;
begin
  TCPLibInstance := TLibFactory.GET(LibName);
  Result := TRedisClient.Create(TCPLibInstance, HostName, Port);
  try
    TRedisClient(Result).Connect;
  except
    Result := nil;
    raise;
  end;
end;

{ TRedisCmdParts }

procedure TRedisCmdParts.ClearBuilder;
begin
  if assigned(FBldr) then
    FBldr.Clear;
end;

destructor TRedisCmdParts.Destroy;
begin
  FBldr.Free;
  inherited;
end;

function TRedisCmdParts.GetBinaryRedisToken(const Index: Integer): TBytes;
begin
end;

function TRedisCmdParts.GetBuilder: TStringBuilder;
begin
  if not assigned(FBldr) then
    FBldr := TStringBuilder.Create;
  Result := FBldr;
end;

function TRedisCmdParts.GetRedisToken(const Index: Integer): string;
var
  // I: Integer;
  itm: string;
  // bldr: TStringBuilder;
  // C: Char;
  // AnsiC: AnsiChar;
begin
  if index = 0 then
    Exit(Items[0]); // this is always the command
  Result := '"' + Items[index].Replace('"', '\"', [rfReplaceAll]) + '"';
end;

end.
