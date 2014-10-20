unit Redis.NetLib.INDY;

interface

uses Redis.Client, IdTCPClient, Redis.NetLib.Factory, Redis.Command,
  Redis.Commons;

type
  TRedisTCPLibINDY = class(TRedisNetLibAdapter, IRedisNetLibAdapter)
  private
    FTCPClient: TIdTCPClient;
  public
    constructor Create; override;
    destructor Destroy; override;
    { ===IRedisTCPLib=== }
    procedure Connect(const HostName: string; const Port: Word); override;
    procedure Disconnect; override;
    function Receive(const Timeout: UInt32): string; override;
    function ReceiveBytes(const ACount: Int64; const Timeout: UInt32): System.TArray<System.Byte>; override;
    procedure Send(const Value: string); override;
    procedure SendCmd(const Values: IRedisCommand); override;
    procedure Write(const Bytes: System.TArray<System.Byte>); override;
    procedure WriteCrLf(const Bytes: System.TArray<System.Byte>); override;
  end;

implementation

uses
  System.SysUtils, idGlobal, IdIOHandler;

{ TRedisTCPLibINDY }

procedure TRedisTCPLibINDY.Connect(const HostName: string; const Port: Word);
begin
  FTCPClient.Connect(HostName, Port);
  FTCPClient.IOHandler.MaxLineLength := IdMaxLineLengthDefault * 1000;
end;

constructor TRedisTCPLibINDY.Create;
begin
  inherited;
  FTCPClient := TIdTCPClient.Create;
end;

destructor TRedisTCPLibINDY.Destroy;
begin
  FTCPClient.Free;
  inherited;
end;

procedure TRedisTCPLibINDY.Disconnect;
begin
  try
    FTCPClient.Disconnect;
  except
  end;
end;

function TRedisTCPLibINDY.Receive(const Timeout: UInt32): string;
begin
  // FTCPClient.ReadTimeout := Timeout;
  Result := FTCPClient.IOHandler.ReadLn(IndyTextEncoding_Default);
end;

function TRedisTCPLibINDY.ReceiveBytes(
  const ACount: Int64; const Timeout: UInt32): System.TArray<System.Byte>;
begin
  FTCPClient.IOHandler.ReadBytes(TIdBytes(Result), ACount);
end;

procedure TRedisTCPLibINDY.Send(
  const
  Value:
  string);
begin
  FTCPClient.IOHandler.WriteLn(AnsiString(Value)); // , IndyTextEncoding_Default);
end;

procedure TRedisTCPLibINDY.SendCmd(
  const Values: IRedisCommand);
begin
  inherited;
  write(Values.ToRedisCommand);
end;

procedure TRedisTCPLibINDY.Write(
  const
  Bytes:
  System.TArray<System.Byte>);
begin
  FTCPClient.IOHandler.Write(TIdBytes(Bytes));
end;

procedure TRedisTCPLibINDY.WriteCrLf(
  const
  Bytes:
  System.TArray<System.Byte>);
begin
  write(Bytes);
  FTCPClient.IOHandler.Write(#13);
  FTCPClient.IOHandler.Write(#10);
end;

initialization

TLibFactory.RegisterRedisTCPLib('indy', TRedisTCPLibINDY);

end.
