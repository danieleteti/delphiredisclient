delphiredisclient
=================

Redis client for Delphi XE6 and XE5


    program SetGet;

    {$APPTYPE CONSOLE}

    {$R *.res}

    uses
      System.SysUtils, Redis.Client, Redis.NetLib.INDY;
    
    var
      Redis: IRedisClient;
      Value: string;
    
    begin
      try
        Redis := NewRedisClient('localhost');
        Redis.&SET('firstname', 'Daniele');
        Redis.GET('firstname', Value);
        WriteLn('key firstname, value ', Value);
        WriteLn('DEL firstname');
        Redis.DEL(['firstname']);
        if Redis.GET('firstname', Value) then
          write(Value)
        else
          write('Key firstname not exists');
      except
        on E: Exception do
          WriteLn(E.ClassName, ': ', E.Message);
      end;
    
    end.

