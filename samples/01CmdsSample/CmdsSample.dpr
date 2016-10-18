program CmdsSample1;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  Redis.Commons, // Interfaces and types
  Redis.Client, // The client itself
  Redis.NetLib.INDY, // The tcp library used
  Redis.Values; // nullable types for redis commands

var
  lRedis: IRedisClient;
  lValue: TRedisString;

begin
  try
    lRedis := TRedisClient.Create;
    lRedis.Connect;
    lRedis.&SET('firstname', 'Daniele');
    lValue := lRedis.GET('firstname');
    if not lValue.IsNull then
      WriteLn('KEY FOUND! key "firstname" => ', lValue.Value);
    WriteLn('DEL firstname');
    lRedis.DEL(['firstname']); // remove the key
    lValue := lRedis.GET('firstname');
    if lValue.IsNull then
      WriteLn('Key "firstname" doesn''t exist (it''s correct!)')
    else
      WriteLn(lValue.Value); // never printed

  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
  readln; // just to keep the command prompt open

end.
