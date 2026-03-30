program TestUtils;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.JUnit,
  DUnitX.TestFramework,
  TestUtils.ArrBld in 'TestUtils.ArrBld.pas',
  TestUtils.BaseDir in 'TestUtils.BaseDir.pas',
  TestUtils.ArrHlp in 'TestUtils.ArrHlp.pas',
  TestUtils.ArrVal in 'TestUtils.ArrVal.pas',
  TestUtils.DBF in 'TestUtils.DBF.pas',
  TestUtils.DynArr in 'TestUtils.DynArr.pas',
  TestUtils.FloatHlp in 'TestUtils.FloatHlp.pas',
  TestUtils.Json.ObjArr in 'TestUtils.Json.ObjArr.pas',
  TestUtils.ObjRef in 'TestUtils.ObjRef.pas',
  TestUtils.Ranges in 'TestUtils.Ranges.pas',
  TestUtils.TxtTab in 'TestUtils.TxtTab.pas',
  TestUtils.Polynom in 'TestUtils.Polynom.pas',
  TestUtils.Spline in 'TestUtils.Spline.pas',
  TestUtils.Parse in 'TestUtils.Parse.pas',
  TestUtils.MemDBF in 'TestUtils.MemDBF.pas',
  TestUtils.Float16 in 'TestUtils.Float16.pas';

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
