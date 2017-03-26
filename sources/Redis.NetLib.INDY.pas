// *************************************************************************** }
//
// Delphi REDIS Client
//
// Copyright (c) 2015-2017 Daniele Teti
//
// https://github.com/danieleteti/delphiredisclient
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************


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
    function Receive(const Timeout: Int32): string; override;
    function ReceiveBytes(const ACount: Int64; const Timeout: Int32)
      : System.TArray<System.Byte>; override;
    procedure Send(const Value: string); override;
    procedure SendCmd(const Values: IRedisCommand); override;
    procedure Write(const Bytes: System.TArray<System.Byte>); override;
    procedure WriteCrLf(const Bytes: System.TArray<System.Byte>); override;
    function LastReadWasTimedOut: boolean; override;
    function LibName: string; override;
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

function TRedisTCPLibINDY.LastReadWasTimedOut: boolean;
begin
  Result := FTCPClient.IOHandler.ReadLnTimedout;
end;

function TRedisTCPLibINDY.LibName: string;
begin
  Result := 'indy';
end;

function TRedisTCPLibINDY.Receive(const Timeout: Int32): string;
begin
  Result := FTCPClient.IOHandler.ReadLn(LF, Timeout, -1,
    IndyTextEncoding_Default);
end;

function TRedisTCPLibINDY.ReceiveBytes(const ACount: Int64;
  const Timeout: Int32): System.TArray<System.Byte>;
begin
  FTCPClient.IOHandler.ReadBytes(TIdBytes(Result), ACount);
end;

procedure TRedisTCPLibINDY.Send(const Value: string);
begin
  FTCPClient.IOHandler.WriteLn(Value);
  // , IndyTextEncoding_Default);
end;

procedure TRedisTCPLibINDY.SendCmd(const Values: IRedisCommand);
begin
  inherited;
  write(Values.ToRedisCommand);
end;

procedure TRedisTCPLibINDY.Write(const Bytes: System.TArray<System.Byte>);
begin
  FTCPClient.IOHandler.WriteDirect(TIdBytes(Bytes));
end;

procedure TRedisTCPLibINDY.WriteCrLf(const Bytes: System.TArray<System.Byte>);
begin
  write(Bytes);
  FTCPClient.IOHandler.Write(#13);
  FTCPClient.IOHandler.Write(#10);
end;

initialization

TRedisNetLibFactory.RegisterRedisTCPLib(REDIS_NETLIB_INDY, TRedisTCPLibINDY);

end.
