program CmdsSample1;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils, Redis.Client, Redis.NetLib.INDY, Redis.Commons;

var
  Redis: IRedisClient;
  Value: string;

begin
  try
    Redis := TRedisClient.Create;
    Redis.Connect;
    Redis.&SET('firstname', 'Daniele');
    Redis.GET('firstname', Value);
    WriteLn('key firstname, value ', Value);
    WriteLn('DEL firstname');
    Redis.DEL(['firstname']);
    if Redis.GET('firstname', Value) then
      write(Value)
    else
      write('Key "firstname" doesn''t exist (it''s correct!)');

  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
  readln;

end.
