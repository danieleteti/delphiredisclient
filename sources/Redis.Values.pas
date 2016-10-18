unit Redis.Values;

interface

uses
  SysUtils;

type
  TRedisNullable<T> = record
  private
    FValue: T;
    FSentinel: string;
    function GetValue: T;
    procedure SetValue(const Value: T);
  public
    class function Create(AValue: T): TRedisNullable<T>; overload; static;
    class function Create(AValue: TRedisNullable<T>): TRedisNullable<T>; overload; static;
    class function Empty: TRedisNullable<T>; static;
    function HasValue: Boolean;
    procedure SetNull;
    class operator Implicit(a: TRedisNullable<T>): T; overload; inline;
    class operator Implicit(a: T): TRedisNullable<T>; overload; inline;
    class operator Implicit(a: Pointer): TRedisNullable<T>; overload; inline;
    property Value: T read GetValue write SetValue;
  end;

  TRedisInteger = TRedisNullable<Integer>;

  TRedisString = TRedisNullable<string>;

  TRedisBytes = TRedisNullable<TBytes>;

const
  VALUE_IS_NULL = 'Value is null';

implementation

uses
  Redis.Commons;

function CheckValue(a, b: TRedisInteger): Boolean; overload; inline;
begin
  Result := a.HasValue and b.HasValue;
end;

function CheckValue(a: TRedisInteger): Boolean; overload; inline;
begin
  Result := a.HasValue;
end;

{ TRedisNullable<T> }

class function TRedisNullable<T>.Create(AValue: T): TRedisNullable<T>;
begin
  Result.Value := AValue;
end;

class function TRedisNullable<T>.Create(
  AValue: TRedisNullable<T>): TRedisNullable<T>;
begin
  if AValue.HasValue then
    Result.Value := AValue.Value
  else
    Result := nil;
end;

class function TRedisNullable<T>.Empty: TRedisNullable<T>;
begin
  Result := nil;
end;

function TRedisNullable<T>.GetValue: T;
begin
  if HasValue then
    Result := FValue
  else
    raise ERedisException.Create(VALUE_IS_NULL);
end;

function TRedisNullable<T>.HasValue: Boolean;
begin
  Result := FSentinel <> '';
end;

class operator TRedisNullable<T>.Implicit(a: TRedisNullable<T>): T;
begin
  Result := a.Value;
end;

class operator TRedisNullable<T>.Implicit(a: T): TRedisNullable<T>;
begin
  Result.Value := a;
end;

class operator TRedisNullable<T>.Implicit(a: Pointer): TRedisNullable<T>;
begin
  Result.SetNull;
end;

procedure TRedisNullable<T>.SetNull;
begin
  FSentinel := '';
  FValue := default (T);
end;

procedure TRedisNullable<T>.SetValue(const Value: T);
begin
  FSentinel := 'x';
  FValue := Value;
end;

end.
