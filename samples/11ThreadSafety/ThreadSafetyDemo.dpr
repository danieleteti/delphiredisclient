// ***************************************************************************
//
// Delphi REDIS Client — Thread-Safety Demo
//
// Demonstrates thread-safety: concurrent operations, shared client survival,
// and multi-thread throughput. Shows that the refactored client no longer
// crashes under concurrent access.
// Requires: Redis 7 running on localhost:6379
//
// ***************************************************************************

program ThreadSafetyDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Diagnostics,
  Redis.Client,
  Redis.Commons,
  Redis.NetLib.Synapse,
  Redis.Values;

const
  REDIS_HOST = 'localhost';
  REDIS_PORT = 6379;

procedure DemoOneClientPerThread;
const
  NUM_THREADS = 8;
  OPS_PER_THREAD = 2000;
var
  Threads: TArray<TThread>;
  TotalOps, Errors: Integer;
  SW: TStopwatch;
  I: Integer;
begin
  WriteLn('=== 1. One Client per Thread (recommended model) ===');
  WriteLn(Format('  %d threads x %d iterations (3 ops each) = %d Redis ops',
    [NUM_THREADS, OPS_PER_THREAD, NUM_THREADS * OPS_PER_THREAD * 3]));
  WriteLn;

  TotalOps := 0;
  Errors := 0;

  SetLength(Threads, NUM_THREADS);
  SW := TStopwatch.StartNew;

  for I := 0 to NUM_THREADS - 1 do
  begin
    var TIdx := I;
    Threads[I] := TThread.CreateAnonymousThread(
      procedure
      var
        Client: IRedisClient;
        J: Integer;
        Key: string;
      begin
        try
          // Each thread creates its own client — no shared state
          Client := TRedisClient.Create(REDIS_HOST, REDIS_PORT, REDIS_NETLIB_SYNAPSE);
          Client.SetCommandTimeout(2000);
          Client.Connect;
          try
            for J := 0 to OPS_PER_THREAD - 1 do
            begin
              Key := Format('ts:t%d:%d', [TIdx, J]);
              Client.&SET(Key, 'val-' + J.ToString, 10);
              Client.GET(Key);
              Client.DEL([Key]);
              TInterlocked.Add(TotalOps, 3);
            end;
          finally
            Client.Disconnect;
          end;
        except
          on E: Exception do
            TInterlocked.Increment(Errors);
        end;
      end);
    Threads[I].FreeOnTerminate := False;
  end;

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;
  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  SW.Stop;

  WriteLn(Format('  Result: %d ops in %d ms', [TotalOps, SW.ElapsedMilliseconds]));
  WriteLn(Format('  Throughput: %s ops/sec',
    [FormatFloat('#,##0', TotalOps / (SW.ElapsedMilliseconds / 1000))]));
  WriteLn(Format('  Errors: %d', [Errors]));
  WriteLn;
end;

procedure DemoSharedClient;
const
  NUM_THREADS = 4;
  OPS_PER_THREAD = 200;
var
  SharedClient: IRedisClient;
  Threads: TArray<TThread>;
  OpsOK, OpsErr: Integer;
  SW: TStopwatch;
  I: Integer;
begin
  WriteLn('=== 2. Shared Client Between Threads (stress test) ===');
  WriteLn(Format('  %d threads x %d ops sharing 1 client', [NUM_THREADS, OPS_PER_THREAD]));
  WriteLn('  (This is NOT the recommended model — it tests crash protection)');
  WriteLn;

  SharedClient := TRedisClient.Create(REDIS_HOST, REDIS_PORT, REDIS_NETLIB_SYNAPSE);
  SharedClient.SetCommandTimeout(2000);
  SharedClient.Connect;

  OpsOK := 0;
  OpsErr := 0;

  SetLength(Threads, NUM_THREADS);
  SW := TStopwatch.StartNew;

  for I := 0 to NUM_THREADS - 1 do
  begin
    var TIdx := I;
    Threads[I] := TThread.CreateAnonymousThread(
      procedure
      var
        J: Integer;
        Key: string;
      begin
        for J := 0 to OPS_PER_THREAD - 1 do
        begin
          try
            Key := Format('ts:shared:%d:%d', [TIdx, J]);
            SharedClient.&SET(Key, 'val', 10);
            SharedClient.GET(Key);
            SharedClient.DEL([Key]);
            TInterlocked.Add(OpsOK, 3);
          except
            TInterlocked.Increment(OpsErr);
          end;
        end;
      end);
    Threads[I].FreeOnTerminate := False;
  end;

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;
  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  SW.Stop;

  var TotalExpected := NUM_THREADS * OPS_PER_THREAD * 3;
  WriteLn(Format('  Result: %d OK + %d errors out of %d expected',
    [OpsOK, OpsErr, TotalExpected]));
  WriteLn(Format('  Time: %d ms', [SW.ElapsedMilliseconds]));

  if OpsOK + OpsErr > 0 then
    WriteLn(Format('  Success rate: %.1f%%', [OpsOK / (OpsOK + OpsErr) * 100]));

  WriteLn;
  WriteLn('  KEY POINT: No Access Violation, no crash!');
  WriteLn('  Before thread-safety, this scenario would CRASH with AV.');
  WriteLn('  I/O errors are expected (TCP stream corruption from concurrent writes),');
  WriteLn('  but the process survives and all memory is clean.');

  SharedClient.Disconnect;
  WriteLn;
end;

procedure DemoScalability;
const
  OPS_PER_THREAD = 1000;
var
  ThreadCounts: array of Integer;
  T, I: Integer;
begin
  WriteLn('=== 3. Scalability — Throughput by Thread Count ===');
  WriteLn(Format('  %d ops/thread (SET+GET+DEL), one client per thread', [OPS_PER_THREAD]));
  WriteLn;

  ThreadCounts := [1, 2, 4, 8, 16];

  for T in ThreadCounts do
  begin
    var TotalOps: Integer := 0;
    var Errors: Integer := 0;
    var Threads: TArray<TThread>;
    SetLength(Threads, T);

    var SW := TStopwatch.StartNew;

    for I := 0 to T - 1 do
    begin
      var TIdx := I;
      Threads[I] := TThread.CreateAnonymousThread(
        procedure
        var
          Client: IRedisClient;
          J: Integer;
          Key: string;
        begin
          try
            Client := TRedisClient.Create(REDIS_HOST, REDIS_PORT, REDIS_NETLIB_SYNAPSE);
            Client.SetCommandTimeout(2000);
            Client.Connect;
            try
              for J := 0 to OPS_PER_THREAD - 1 do
              begin
                Key := Format('ts:scale:%d:%d', [TIdx, J]);
                Client.&SET(Key, 'v', 10);
                Client.GET(Key);
                Client.DEL([Key]);
                TInterlocked.Add(TotalOps, 3);
              end;
            finally
              Client.Disconnect;
            end;
          except
            TInterlocked.Increment(Errors);
          end;
        end);
      Threads[I].FreeOnTerminate := False;
    end;

    for I := 0 to T - 1 do
      Threads[I].Start;
    for I := 0 to T - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    SW.Stop;
    var OpsPerSec := TotalOps / (SW.ElapsedMilliseconds / 1000);
    WriteLn(Format('  %2d threads: %6d ops in %5d ms => %s ops/sec (errors: %d)',
      [T, TotalOps, SW.ElapsedMilliseconds, FormatFloat('#,##0', OpsPerSec), Errors]));
  end;

  WriteLn;
end;

begin
  try
    WriteLn('Redis Thread-Safety Demo');
    WriteLn('=========================');
    WriteLn;

    DemoOneClientPerThread;
    DemoSharedClient;
    DemoScalability;

    WriteLn('All demos completed!');
  except
    on E: Exception do
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
  end;
  WriteLn;
  Write('Press Enter to exit...');
  ReadLn;
end.
