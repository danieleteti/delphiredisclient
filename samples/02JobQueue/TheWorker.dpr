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

program TheWorker;

{$APPTYPE CONSOLE}
{$R *.res}


uses
  System.SysUtils,
  Rest.json,
  System.json,
  Redis.Client,
  Redis.netlib.INDY,
  Redis.Commons,
  System.Bindings.ExpressionDefaults,
  System.Bindings.Expression,
  System.Classes,
  System.Bindings.EvalProtocol,
  JobU in '..\Commons\JobU.pas',
  RandomUtilsU in '..\Commons\RandomUtilsU.pas',
  Redis.Values,
  ConstantsU in '..\Commons\ConstantsU.pas';

function IValueToString(Value: IValue): string;
var
  StrOutput: string;
begin
  case Value.GetType.Kind of
    tkUString, tkString:
      StrOutput := Value.GetValue.AsString;
    tkInteger, tkInt64:
      StrOutput := IntToStr(Value.GetValue.AsInt64);
    tkFloat:
      StrOutput := FloatToStr(Value.GetValue.AsExtended);
    tkClass:
      StrOutput := Value.GetValue.AsObject.ToString;
    tkEnumeration:
      StrOutput := BoolToStr(Value.GetValue.AsBoolean, true);
  else
    raise Exception.Create('Invalid type');
  end;
  Result := StrOutput;
end;

function GetExpressionResult(EvalJob: TEvalJob): Extended;
var
  lExpr: TBindingExpression;
begin
  TThread.Sleep(4000); // just to mimic some work load
  lExpr := TBindingExpressionDefault.Create;
  try
    lExpr.Source := EvalJob.Expression;
    lExpr.Recompile;
    Result := lExpr.Evaluate.GetValue.AsExtended;
  finally
    lExpr.Free;
  end;
end;

procedure Main;
var
  lRedis: IRedisClient;
  lQName: string;
  lJObj: TJSONObject;
  lEvalJob: TEvalJob;
  lResp: Extended;
  lJRespObj: TJSONObject;
  lArrResp: TRedisArray;
  lMsg: String;
begin
  lRedis := TRedisClient.Create(REDIS_HOSTNAME);
  lRedis.Connect;
  while true do
  begin
    Writeln(slinebreak + '>>WAITING FOR MESSAGES ON QUEUE "jobs"');
    // Wait for a message in the queue. Timeout 10 secs.
    lArrResp := lRedis.BRPOP(['jobs'], 10);
    if lArrResp.HasValue then
    begin
      Writeln('** NEW MESSAGE **');
      lQName := lArrResp.Items[0];
      lMsg := lArrResp.Items[1];
      lJObj := TJSONObject.ParseJSONValue(lMsg) as TJSONObject;
      try
        Writeln('Just got the message ', lJObj.ToString);
        lEvalJob := TJson.JsonToObject<TEvalJob>(lJObj);
        try
          write('I''m working on it...');
          lResp := GetExpressionResult(lEvalJob);
          lJRespObj := TJSONObject.Create;
          try
            lJRespObj.AddPair('expression', lEvalJob.Expression);
            lJRespObj.AddPair('result', TJSONNumber.Create(lResp));
            lRedis.LPUSH(lEvalJob.ReplyTo, [lJRespObj.ToJSON]);
            Writeln('DONE!');
            Writeln('RESPONSE: ', lJRespObj.ToJSON);
          finally
            lJRespObj.Free;
          end;

          Writeln('RESPONSE SENT TO:', lEvalJob.ReplyTo);
          Writeln('Ready for another message!');
          Writeln;
        finally
          lEvalJob.Free;
        end;
      finally
        lJObj.Free;
      end;
    end;
  end;
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
