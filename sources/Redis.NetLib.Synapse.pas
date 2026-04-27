// *************************************************************************** }
//
// Delphi REDIS Client - Synapse Network Adapter
//
// Adapter implementing IRedisNetLibAdapter using Ararat Synapse TTCPBlockSocket.
// Drop-in replacement for Redis.NetLib.INDY with lower overhead and better
// Linux compatibility.
//
// ***************************************************************************

unit Redis.NetLib.Synapse;

interface

uses
  Redis.Client,
  Redis.NetLib.Factory,
  Redis.Command,
  Redis.Commons,
  blcksock,
  synsock;

type
  TRedisTCPLibSynapse = class(TRedisNetLibAdapter, IRedisNetLibAdapter)
  private
    FSocket: TTCPBlockSocket;
    FLastReadTimedOut: Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Connect(const HostName: string; const Port: Word); override;
    procedure Disconnect; override;
    function Receive(const Timeout: Int32): string; override;
    function ReceiveBytes(const ACount: Int64; const Timeout: Int32)
      : System.TArray<System.Byte>; override;
    procedure Send(const Value: string); override;
    procedure SendCmd(const Values: IRedisCommand); override;
    procedure Write(const Bytes: System.TArray<System.Byte>); override;
    procedure WriteCrLf(const Bytes: System.TArray<System.Byte>); override;
    function LastReadWasTimedOut: Boolean; override;
    function LibName: string; override;
    procedure TimeoutConnect(AValue: Integer); override;
  end;

implementation

uses
  System.SysUtils;

{ TRedisTCPLibSynapse }

constructor TRedisTCPLibSynapse.Create;
begin
  inherited;
  FSocket := TTCPBlockSocket.Create;
  // Redis RESP requires exact CRLF delimiters — do not convert
  FSocket.ConvertLineEnd := False;
  // Match INDY adapter's MaxLineLength * 1000
  FSocket.MaxLineLength := 10 * 1024 * 1024;
  FLastReadTimedOut := False;
end;

destructor TRedisTCPLibSynapse.Destroy;
begin
  FSocket.Free;
  inherited;
end;

procedure TRedisTCPLibSynapse.Connect(const HostName: string; const Port: Word);
begin
  FSocket.Connect(HostName, IntToStr(Port));
  if FSocket.LastError <> 0 then
    raise ERedisConnectionException.CreateFmt(
      'Cannot connect to Redis at %s:%d - %s',
      [HostName, Port, FSocket.LastErrorDesc]);
end;

procedure TRedisTCPLibSynapse.Disconnect;
begin
  try
    FSocket.CloseSocket;
  except
    // swallow — same pattern as INDY adapter
  end;
end;

function TRedisTCPLibSynapse.Receive(const Timeout: Int32): string;
var
  LAnsi: AnsiString;
begin
  // RecvString reads until CRLF and strips it — same semantics as Indy ReadLn(LF, Timeout)
  LAnsi := FSocket.RecvString(Timeout);
  FLastReadTimedOut := (FSocket.LastError = WSAETIMEDOUT);
  Result := string(LAnsi);
end;

function TRedisTCPLibSynapse.ReceiveBytes(const ACount: Int64;
  const Timeout: Int32): System.TArray<System.Byte>;
var
  LAnsi: AnsiString;
begin
  // RecvBufferStr reads exactly ACount bytes, blocking up to Timeout ms
  LAnsi := FSocket.RecvBufferStr(ACount, Timeout);
  FLastReadTimedOut := (FSocket.LastError = WSAETIMEDOUT);
  SetLength(Result, Length(LAnsi));
  if Length(LAnsi) > 0 then
    Move(LAnsi[1], Result[0], Length(LAnsi));
end;

procedure TRedisTCPLibSynapse.Send(const Value: string);
begin
  // Equivalent to Indy WriteLn: sends string + CRLF
  FSocket.SendString(AnsiString(Value + #13#10));
end;

procedure TRedisTCPLibSynapse.SendCmd(const Values: IRedisCommand);
begin
  inherited;
  Write(Values.ToRedisCommand);
end;

procedure TRedisTCPLibSynapse.Write(const Bytes: System.TArray<System.Byte>);
begin
  if Length(Bytes) > 0 then
    FSocket.SendBuffer(@Bytes[0], Length(Bytes));
end;

procedure TRedisTCPLibSynapse.WriteCrLf(const Bytes: System.TArray<System.Byte>);
var
  LBuf: TArray<Byte>;
begin
  // Write bytes + CRLF as a single send to avoid TCP fragmentation
  SetLength(LBuf, Length(Bytes) + 2);
  if Length(Bytes) > 0 then
    Move(Bytes[0], LBuf[0], Length(Bytes));
  LBuf[Length(Bytes)] := 13;
  LBuf[Length(Bytes) + 1] := 10;
  Write(LBuf);
end;

function TRedisTCPLibSynapse.LastReadWasTimedOut: Boolean;
begin
  Result := FLastReadTimedOut;
end;

function TRedisTCPLibSynapse.LibName: string;
begin
  Result := REDIS_NETLIB_SYNAPSE;
end;

procedure TRedisTCPLibSynapse.TimeoutConnect(AValue: Integer);
begin
  FSocket.ConnectionTimeout := AValue;
end;

initialization

TRedisNetLibFactory.RegisterRedisTCPLib(REDIS_NETLIB_SYNAPSE, TRedisTCPLibSynapse);

end.
