// ***************************************************************************
//
// Delphi REDIS Client — Synapse Adapter Demo
//
// Demonstrates the Synapse network adapter: connection, all data types,
// side-by-side comparison with Indy, and INFO command.
// Requires: Redis 7 running on localhost:6379
//
// ***************************************************************************

program SynapseDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Diagnostics,
  Redis.Client,
  Redis.Commons,
  Redis.NetLib.Synapse,
  Redis.NetLib.INDY,
  Redis.Values;

const
  REDIS_HOST = 'localhost';
  REDIS_PORT = 6379;
  NUM_OPS = 3000;

procedure DemoSynapseConnection;
var
  Client: IRedisClient;
  Val: TRedisString;
begin
  WriteLn('=== 1. Synapse Adapter — Basic Connection ===');
  WriteLn;

  Client := TRedisClient.Create(REDIS_HOST, REDIS_PORT, REDIS_NETLIB_SYNAPSE);
  Client.SetCommandTimeout(2000);
  Client.Adapter.TimeoutConnect(2000);
  Client.Connect;

  WriteLn('  Adapter: ', Client.Adapter.LibName);
  WriteLn('  PING:    ', Client.PING);

  // String ops
  Client.&SET('syn:hello', 'world', 30);
  Val := Client.GET('syn:hello');
  WriteLn('  SET/GET:  syn:hello => ', Val.Value);

  // Numeric ops
  Client.DEL(['syn:counter']);
  Client.INCR('syn:counter');
  Client.INCR('syn:counter');
  Client.INCR('syn:counter');
  WriteLn('  INCR x3: syn:counter => ', string(Client.GET('syn:counter')));

  // Hash ops
  Client.HSET('syn:user', 'name', TEncoding.UTF8.GetBytes('Delphi'));
  Client.HSET('syn:user', 'year', TEncoding.UTF8.GetBytes('2026'));
  WriteLn('  HGET:    syn:user.name => ', string(Client.HGET('syn:user', 'name')));
  WriteLn('  HGET:    syn:user.year => ', string(Client.HGET('syn:user', 'year')));

  // List ops
  Client.DEL(['syn:list']);
  Client.LPUSH('syn:list', ['a', 'b', 'c']);
  WriteLn('  LLEN:    syn:list => ', Client.LLEN('syn:list'));
  WriteLn('  LRANGE:  ', Client.LRANGE('syn:list', 0, -1).ToArray[0], ', ',
                          Client.LRANGE('syn:list', 0, -1).ToArray[1], ', ',
                          Client.LRANGE('syn:list', 0, -1).ToArray[2]);

  // Set ops
  Client.DEL(['syn:tags']);
  Client.SADD('syn:tags', 'redis');
  Client.SADD('syn:tags', 'delphi');
  Client.SADD('syn:tags', 'synapse');
  WriteLn('  SCARD:   syn:tags => ', Client.SCARD('syn:tags'));

  // Cleanup
  Client.DEL(['syn:hello', 'syn:counter', 'syn:user', 'syn:list', 'syn:tags']);
  Client.Disconnect;
  WriteLn;
end;

procedure DemoINFOCommand;
var
  Client: TRedisClient;
  Intf: IRedisClient;
  Info: string;
  Lines: TArray<string>;
  I: Integer;
begin
  WriteLn('=== 2. INFO Command ===');
  WriteLn;

  Client := TRedisClient.Create(REDIS_HOST, REDIS_PORT, REDIS_NETLIB_SYNAPSE);
  Intf := Client; // prevent leak
  Client.SetCommandTimeout(2000);
  Client.Connect;

  Info := Client.INFO('server');
  Lines := Info.Split([#13#10, #10]);

  WriteLn('  INFO server (first 10 lines):');
  for I := 0 to High(Lines) do
  begin
    if I >= 10 then
    begin
      WriteLn(Format('  ... (%d more lines)', [Length(Lines) - 10]));
      Break;
    end;
    if Lines[I].Trim <> '' then
      WriteLn('    ', Lines[I].Trim);
  end;

  WriteLn;
  WriteLn('  Available sections: server, clients, memory, stats, replication,');
  WriteLn('    cpu, commandstats, latencystats, cluster, keyspace');

  Intf.Disconnect;
  WriteLn;
end;

procedure RunBench(const ALibName: string; out AOpsPerSec: Double);
var
  Client: IRedisClient;
  SW: TStopwatch;
  I: Integer;
begin
  Client := TRedisClient.Create(REDIS_HOST, REDIS_PORT, ALibName);
  Client.SetCommandTimeout(2000);
  Client.Connect;

  SW := TStopwatch.StartNew;
  for I := 0 to NUM_OPS - 1 do
  begin
    Client.&SET('bench:' + ALibName + ':' + I.ToString, 'v', 30);
    Client.GET('bench:' + ALibName + ':' + I.ToString);
    Client.DEL(['bench:' + ALibName + ':' + I.ToString]);
  end;
  SW.Stop;

  AOpsPerSec := (NUM_OPS * 3) / (SW.ElapsedMilliseconds / 1000);
  Client.Disconnect;
end;

procedure DemoSynapseVsIndy;
var
  SynOps, IndyOps: Double;
begin
  WriteLn('=== 3. Synapse vs Indy — Throughput Comparison ===');
  WriteLn(Format('  %d iterations x 3 ops (SET+GET+DEL) = %d total', [NUM_OPS, NUM_OPS * 3]));
  WriteLn;

  Write('  Running Synapse... ');
  RunBench(REDIS_NETLIB_SYNAPSE, SynOps);
  WriteLn(Format('%s ops/sec', [FormatFloat('#,##0', SynOps)]));

  Write('  Running Indy...    ');
  RunBench(REDIS_NETLIB_INDY, IndyOps);
  WriteLn(Format('%s ops/sec', [FormatFloat('#,##0', IndyOps)]));

  WriteLn;
  if SynOps > IndyOps then
    WriteLn(Format('  Winner: Synapse (+%.1f%%)', [(SynOps - IndyOps) / IndyOps * 100]))
  else
    WriteLn(Format('  Winner: Indy (+%.1f%%)', [(IndyOps - SynOps) / SynOps * 100]));

  WriteLn;
  WriteLn('  Note: Synapse has no global state, lower overhead, and native Linux support.');
  WriteLn;
end;

begin
  try
    WriteLn('Redis Synapse Adapter Demo');
    WriteLn('===========================');
    WriteLn;

    DemoSynapseConnection;
    DemoINFOCommand;
    DemoSynapseVsIndy;

    WriteLn('All demos completed!');
  except
    on E: Exception do
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
  end;
  WriteLn;
  Write('Press Enter to exit...');
  ReadLn;
end.
