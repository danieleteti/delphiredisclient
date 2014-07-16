unit Redis.NetLib.Factory;

interface

uses Redis.Client, System.Generics.Collections, System.SysUtils, Redis.Command,
  Redis.Commons;

type
  // this class introduce the virtual constructor
  TRedisNetLibAdapter = class abstract(TInterfacedObject, IRedisNetLibAdapter)
    constructor Create; virtual;
  protected
    procedure Connect(const HostName: string; const Port: Word); virtual; abstract;
    procedure Send(const Value: string); virtual; abstract;
    procedure SendCmd(const Values: IRedisCommand); virtual; abstract;
    procedure Write(const Bytes: TBytes); virtual; abstract;
    procedure WriteCrLf(const Bytes: TBytes); virtual; abstract;
    function Receive(const Timeout: UInt32): string; virtual; abstract;
    function ReceiveBytes(const ACount: Int64; const Timeout: UInt32): System.TArray<System.Byte>; virtual; abstract;
    procedure Disconnect; virtual; abstract;
  end;

  TRedisTCPLibClass = class of TRedisNetLibAdapter;

  TLibFactory = class sealed
    class function Get(const LibName: string): IRedisNetLibAdapter;
    class procedure RegisterRedisTCPLib(const LibName: string; Clazz: TRedisTCPLibClass);
  end;

implementation

var
  RedisTCPLibraryRegistry: TDictionary<string, TRedisTCPLibClass>;

  { TLibFactory }

class function TLibFactory.Get(const LibName: string): IRedisNetLibAdapter;
var
  Clazz: TRedisTCPLibClass;
begin
  if not RedisTCPLibraryRegistry.TryGetValue(LibName, Clazz) then
    raise Exception.Createfmt('Cannot instantiate %s TCP lib', [LibName]);
  Result := Clazz.Create;
end;

class procedure TLibFactory.RegisterRedisTCPLib(const LibName: string;
  Clazz: TRedisTCPLibClass);
begin
  RedisTCPLibraryRegistry.Add(LibName, Clazz);
end;

{ TRedisTCPLib }

constructor TRedisNetLibAdapter.Create;
begin
  inherited Create;
end;

initialization

RedisTCPLibraryRegistry := TDictionary<string, TRedisTCPLibClass>.Create;

finalization

RedisTCPLibraryRegistry.Free;

end.
