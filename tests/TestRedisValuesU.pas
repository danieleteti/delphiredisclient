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


unit TestRedisValuesU;

interface

uses TestFramework, Redis.Values, Redis.Commons;

type
  // Test methods for Redis Values

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
