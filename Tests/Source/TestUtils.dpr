program TestUtils;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.JUnit,
  DUnitX.TestFramework,
  TestUtils.ArrBld in 'TestUtils.ArrBld.pas',
  TestUtils.ArrHlp in 'TestUtils.ArrHlp.pas',
  TestUtils.ArrVal in 'TestUtils.ArrVal.pas',
  TestUtils.BaseDir in 'TestUtils.BaseDir.pas',
  TestUtils.DBF in 'TestUtils.DBF.pas',
  TestUtils.DynArr in 'TestUtils.DynArr.pas',
  TestUtils.FloatHlp in 'TestUtils.FloatHlp.pas',
  TestUtils.FP16 in 'TestUtils.FP16.pas',
  TestUtils.Json.Eval in 'TestUtils.Json.Eval.pas',
  TestUtils.Json.ObjArr in 'TestUtils.Json.ObjArr.pas',
  TestUtils.KeyVal in 'TestUtils.KeyVal.pas',
  TestUtils.MemDBF in 'TestUtils.MemDBF.pas',
  TestUtils.ObjRef in 'TestUtils.ObjRef.pas',
  TestUtils.Parse in 'TestUtils.Parse.pas',
  TestUtils.Polynom in 'TestUtils.Polynom.pas',
  TestUtils.Ranges in 'TestUtils.Ranges.pas',
  TestUtils.Spline in 'TestUtils.Spline.pas',
  TestUtils.TxtTab in 'TestUtils.TxtTab.pas',
  TestUtils.Yaml in 'TestUtils.Yaml.pas';

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
