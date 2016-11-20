program RedisClientTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}


uses
  DUnitTestRunner,
  TestRedisClientU in 'TestRedisClientU.pas',
  Redis.Client in '..\sources\Redis.Client.pas',
  Redis.NetLib.Factory in '..\sources\Redis.NetLib.Factory.pas',
  Redis.NetLib.INDY in '..\sources\Redis.NetLib.INDY.pas',
  Redis.Command in '..\sources\Redis.Command.pas',
  Redis.Commons in '..\sources\Redis.Commons.pas',
  TestRedisMQ in 'TestRedisMQ.pas',
  RedisMQ in '..\sources\RedisMQ.pas',
  Redis.Values in '..\sources\Redis.Values.pas',
  TestRedisValuesU in 'TestRedisValuesU.pas',
  RedisMQ.Commands in '..\sources\RedisMQ.Commands.pas';

{$R *.RES }


begin
  ReportMemoryLeaksOnShutdown := True;
  DUnitTestRunner.RunRegisteredTests;

end.
