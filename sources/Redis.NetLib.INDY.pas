unit Redis.NetLib.INDY;

interface

uses Redis.Client, IdTCPClient, Redis.NetLib.Factory;

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
    function Receive(const Timeout): string; override;
    procedure Send(const Value: string); override;
    procedure SendCmd(const Values: TRedisCmdParts); override;
  end;

implementation

uses
  System.SysUtils, idGlobal;

{ TRedisTCPLibINDY }

procedure TRedisTCPLibINDY.Connect(const HostName: string; const Port: Word);
begin
  FTCPClient.Connect(HostName, Port);
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

function TRedisTCPLibINDY.Receive(const Timeout): string;
begin
  Result := FTCPClient.IOHandler.ReadLn(IndyTextEncoding_Default);
end;

procedure TRedisTCPLibINDY.Send(const Value: string);
begin
  FTCPClient.IOHandler.WriteLn(AnsiString(Value)); // , IndyTextEncoding_Default);
end;

procedure TRedisTCPLibINDY.SendCmd(const Values: TRedisCmdParts);
var
  Value: TStringBuilder;
  I: Integer;
begin
  inherited;
  Value := TStringBuilder.Create;
  try
    Value.Append(Values[0]);
    for I := 1 to Values.Count - 1 do
    begin
      Value.Append(' ' + Values.GetRedisToken(I));
    end;
    Send(Value.ToString);
  finally
    Value.Free;
  end;
end;

initialization

TLibFactory.RegisterRedisTCPLib('indy', TRedisTCPLibINDY);

end.
