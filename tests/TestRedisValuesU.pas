unit TestRedisValuesU;

interface

uses TestFramework, Redis.Values, Redis.Commons;

type
  // Test methods for Resis Values

  TestRedisValues = class(TTestCase)
  private
    FIntValue: TRedisInteger;
    FStrValue: TRedisString;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestIntegerHasValue10;
    procedure TestIntegerHasValue20;
    procedure TestIntegerEquals;
    procedure TestIntegerAssignToInteger;
    procedure TestIntegerAssignFromInteger;
    procedure TestStringHasValue10;
    procedure TestStringHasValue20;
    procedure TestStringAssignToString;
    procedure TestStringAssignFromString;

  end;

implementation

uses
  System.SysUtils;

procedure TestRedisValues.SetUp;
begin
  inherited;
  FIntValue.SetNull;
  FStrValue.SetNull;
end;

procedure TestRedisValues.TearDown;
begin
  inherited;

end;

procedure TestRedisValues.TestIntegerAssignFromInteger;
var
  i: Integer;
begin
  i := 123;
  FIntValue := i;
  CheckEquals(123, FIntValue);
end;

procedure TestRedisValues.TestIntegerAssignToInteger;
var
  i: Integer;
begin
  FIntValue := 123;
  i := FIntValue;
  CheckEquals(123, i);
end;

procedure TestRedisValues.TestIntegerEquals;
var
  a, b: TRedisInteger;
begin
  a := 123;
  b := 123;
  CheckTrue(a.Value = b.Value, 'Equals doesn''t work');
  CheckFalse(a.Value <> b.Value, 'Equals doesn''t work');
end;

procedure TestRedisValues.TestIntegerHasValue10;
begin
  CheckFalse(FIntValue.HasValue);
  FIntValue := nil;
  CheckFalse(FIntValue.HasValue);
  FIntValue := 123;
  CheckTrue(FIntValue.HasValue);
  CheckEquals(123, FIntValue.Value);
end;

procedure TestRedisValues.TestIntegerHasValue20;
var
  lValue: TRedisInteger;
begin
  CheckFalse(lValue.HasValue);
end;

procedure TestRedisValues.TestStringAssignFromString;
var
  s: string;
begin
  s := 'abc';
  FStrValue := s;
  CheckEquals('abc', FStrValue);
end;

procedure TestRedisValues.TestStringAssignToString;
var
  s: string;
begin
  FStrValue := 'abc';
  s := FStrValue;
  CheckEquals('abc', s);
end;

procedure TestRedisValues.TestStringHasValue10;
begin
  CheckFalse(FStrValue.HasValue);
  FStrValue := 'abc';
  CheckTrue(FStrValue.HasValue);
  CheckEquals('abc', FStrValue.Value);
end;

procedure TestRedisValues.TestStringHasValue20;
var
  lValue: TRedisString;
begin
  CheckFalse(lValue.HasValue);
end;

initialization

RegisterTest(TestRedisValues.Suite);

end.
