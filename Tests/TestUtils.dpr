program TestUtils;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.JUnit,
  DUnitX.TestFramework,
  TestUtils.ArrBld in 'TestUtils.ArrBld.pas',
  TestUtils.ArrHlp in 'TestUtils.ArrHlp.pas',
  TestUtils.ArrVal in 'TestUtils.ArrVal.pas';

begin
  try
    // Initialization
    TDUnitX.CheckCommandLine;
    TDUnitX.Options.XMLOutputFile := '.\TestUtils.xml';
    // Create the test Runner
    var Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;
    // Create loggers
    var ConsoleLogger := TDUnitXConsoleLogger.Create(false);
    var NunitLogger := TDUnitXXMLJUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(ConsoleLogger);
    Runner.AddLogger(NunitLogger);
    //Run tests
    var Results := Runner.Execute;
    if not Results.AllPassed then System.ExitCode := EXIT_ERRORS;
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
