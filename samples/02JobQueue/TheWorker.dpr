program TheWorker;

{$APPTYPE CONSOLE}
{$R *.res}


uses
  System.SysUtils,
  Rest.json,
  System.json,
  {These are the required units for delphiredisclient}
  Redis.Client,
  Redis.netlib.INDY,
  Redis.Commons,
  {///}
  System.Bindings.ExpressionDefaults,
  System.Bindings.Expression,
  System.Classes,
  System.Bindings.EvalProtocol,
  JobU in '..\Commons\JobU.pas',
  RandomUtilsU in '..\Commons\RandomUtilsU.pas';

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
  TThread.Sleep(5000); // just to mimic some work load
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
  lMsgs: TArray<string>;
  lQName: string;
  lMsg: string;
  lJObj: TJSONObject;
  lEvalJob: TEvalJob;
  lResp: Extended;
  lJRespObj: TJSONObject;
begin
  lRedis := TRedisClient.Create;
  lRedis.Connect;
  while true do
  begin
    Writeln(slinebreak + '>>WAITING FOR MESSAGES ON QUEUE "jobs"');
    // Wait for a message in the queue. Timeout 10 secs.
    if lRedis.BRPOP(['jobs'], 10, lMsgs) then
    begin
      Writeln('** NEW MESSAGE **');
      lQName := lMsgs[0];
      lMsg := lMsgs[1];
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
