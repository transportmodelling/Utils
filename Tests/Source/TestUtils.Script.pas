unit TestUtils.Script;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, IOUtils, DUnitX.TestFramework, KeyVal, Script;

Type
  TTestScriptInterpreter = Class(TScriptInterpreter)
  // Minimal script interpreter recording the interpreted and executed commands.
  // The init-command and set-command both take an optional value-property.
  public
    InitValues: TArray<String>; // Value-property of each interpreted init-command
    Runs: TArray<String>;       // Comma-separated set-values of each executed script section
  private
    Values: TArray<String>;     // Set-values of the current script section
  strict protected
    Procedure InitializeRun; override;
    Procedure InterpretInitCommand(const [ref] Arguments: TKeyValuePairs); override;
    Function InterpretCommand(const Command: String; const [ref] Arguments: TKeyValuePairs): Boolean; override;
    Procedure RunCompleted; override;
  end;

  [TestFixture]
  TScriptTests = class
  private
    Interpreter: TTestScriptInterpreter;
    ScriptFiles: TArray<String>;
    Function WriteScript(const Lines: array of String): String;
  public
    [Setup]
    Procedure Setup;
    [TearDown]
    Procedure TearDown;

    // Init
    [Test] Procedure Execute_InitAndCommands_ExecutesSingleRun;
    [Test] Procedure Execute_CommandBeforeInit_RaisesException;
    [Test] Procedure Execute_Reinit_ExecutesMultipleRuns;

    // Include
    [Test] Procedure Execute_Include_InsertsLines;
    [Test] Procedure Execute_NestedInclude_InsertsLines;
    [Test] Procedure Execute_CircularInclude_RaisesException;
    [Test] Procedure Execute_MissingIncludeFile_RaisesException;
    [Test] Procedure Execute_ErrorInInclude_ReportsIncludeFile;

    // Lines
    [Test] Procedure Execute_InvalidCommand_RaisesException;
    [Test] Procedure Execute_CommentsAndEmptyLines_Skipped;
    [Test] Procedure Execute_HashComment_Skipped;

    // Indented arguments
    [Test] Procedure Execute_IndentedArguments;
    [Test] Procedure Execute_MixedArguments;
    [Test] Procedure Execute_MixedArguments_CommandLineTakesPrecedence;
    [Test] Procedure Execute_IndentedArguments_CommentsAndEmptyLinesSkipped;
    [Test] Procedure Execute_IndentedArgument_ColonInValue;
    [Test] Procedure Execute_IndentedArgument_WithoutColon_RaisesException;
    [Test] Procedure Execute_ArgumentLineWithoutCommand_RaisesException;
    [Test] Procedure Execute_Include_IndentedArguments;

    // Parameters
    [Test] Procedure Execute_Parameter_ReplacedInValue;
    [Test] Procedure Execute_Parameter_CaseInsensitive;
    [Test] Procedure Execute_Parameter_ReplacedInInitArguments;
    [Test] Procedure Execute_Parameter_ReplacedInInclude;
    [Test] Procedure Execute_Parameter_CustomDelimiter;
    [Test] Procedure Execute_Parameter_DelimiterFromInitCommand;
    [Test] Procedure Execute_Parameter_DelimiterRestoredOnReinit;
    [Test] Procedure Execute_Parameter_InvalidDelimiter_RaisesException;
    [Test] Procedure Execute_NoParameters_PlaceholderUnchanged;
    [Test] Procedure Execute_Parameter_ReplacedInIncludeFileName;

    // Include parameters
    [Test] Procedure Execute_IncludeParameter_ReplacedInInclude;
    [Test] Procedure Execute_IncludeParameter_OutOfScopeAfterInclude;
    [Test] Procedure Execute_IncludeParameter_OverridesScriptParameter;
    [Test] Procedure Execute_IncludeParameter_PassedOnToNestedInclude;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TTestScriptInterpreter.InitializeRun;
begin
  Values := nil;
end;

Procedure TTestScriptInterpreter.InterpretInitCommand(const [ref] Arguments: TKeyValuePairs);
begin
  InitValues := InitValues + [Arguments.ToStr('value','')];
end;

Function TTestScriptInterpreter.InterpretCommand(const Command: String; const [ref] Arguments: TKeyValuePairs): Boolean;
begin
  Result := SameText(Command,'set');
  if Result then Values := Values + [Arguments.ToStr('value','')];
end;

Procedure TTestScriptInterpreter.RunCompleted;
begin
  Runs := Runs + [String.Join(',',Values)];
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TScriptTests.Setup;
begin
  Interpreter := TTestScriptInterpreter.Create;
end;

Procedure TScriptTests.TearDown;
begin
  Interpreter.Free;
  for var ScriptFile in ScriptFiles do TFile.Delete(ScriptFile);
  ScriptFiles := nil;
end;

Function TScriptTests.WriteScript(const Lines: array of String): String;
begin
  Result := TPath.Combine(TPath.GetTempPath,'TestScriptIntp'+Length(ScriptFiles).ToString+'.script');
  var ScriptLines: TArray<String>;
  SetLength(ScriptLines,Length(Lines));
  for var Line := low(Lines) to high(Lines) do ScriptLines[Line] := Lines[Line];
  TFile.WriteAllLines(Result,ScriptLines);
  ScriptFiles := ScriptFiles + [Result];
end;

// Init
Procedure TScriptTests.Execute_InitAndCommands_ExecutesSingleRun;
begin
  var ScriptFile := WriteScript(['init value=A','set value=1','set value=2']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual(1,Integer(Length(Interpreter.InitValues)));
  Assert.AreEqual('A',Interpreter.InitValues[0]);
  Assert.AreEqual(1,Integer(Length(Interpreter.Runs)));
  Assert.AreEqual('1,2',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_CommandBeforeInit_RaisesException;
begin
  var ScriptFile := WriteScript(['set value=1']);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.AreEqual('Initialization required at line 1',Msg);
end;

Procedure TScriptTests.Execute_Reinit_ExecutesMultipleRuns;
begin
  var ScriptFile := WriteScript(['init value=A','set value=1','init value=B','set value=2']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual(2,Integer(Length(Interpreter.InitValues)));
  Assert.AreEqual('A',Interpreter.InitValues[0]);
  Assert.AreEqual('B',Interpreter.InitValues[1]);
  Assert.AreEqual(2,Integer(Length(Interpreter.Runs)));
  Assert.AreEqual('1',Interpreter.Runs[0]);
  Assert.AreEqual('2',Interpreter.Runs[1]);
end;

// Include

Procedure TScriptTests.Execute_Include_InsertsLines;
begin
  var IncludeFile := WriteScript(['set value=1','set value=2']);
  var ScriptFile := WriteScript(['init','include file='+IncludeFile,'set value=3']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual(1,Integer(Length(Interpreter.Runs)));
  Assert.AreEqual('1,2,3',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_NestedInclude_InsertsLines;
begin
  var InnerFile := WriteScript(['set value=2']);
  var OuterFile := WriteScript(['set value=1','include file='+InnerFile,'set value=3']);
  var ScriptFile := WriteScript(['init','include file='+OuterFile,'set value=4']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual(1,Integer(Length(Interpreter.Runs)));
  Assert.AreEqual('1,2,3,4',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_CircularInclude_RaisesException;
begin
  var IncludeFile := WriteScript([]);
  TFile.WriteAllLines(IncludeFile,['include file='+IncludeFile]);
  var ScriptFile := WriteScript(['init','include file='+IncludeFile]);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.IsTrue(Msg.StartsWith('Circular include'),'Unexpected message: '+Msg);
end;

Procedure TScriptTests.Execute_MissingIncludeFile_RaisesException;
begin
  var MissingFile := TPath.Combine(TPath.GetTempPath,'TestScriptIntpMissing.script');
  var ScriptFile := WriteScript(['init','include file='+MissingFile]);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.IsTrue(Msg.StartsWith('Script file does not exist'),'Unexpected message: '+Msg);
end;

Procedure TScriptTests.Execute_ErrorInInclude_ReportsIncludeFile;
begin
  var IncludeFile := WriteScript(['unknown value=1']);
  var ScriptFile := WriteScript(['init','include file='+IncludeFile]);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.AreEqual('Invalid command at line 1 in '+IncludeFile,Msg);
end;

// Lines

Procedure TScriptTests.Execute_InvalidCommand_RaisesException;
begin
  var ScriptFile := WriteScript(['init','unknown value=1']);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.AreEqual('Invalid command at line 2',Msg);
end;

Procedure TScriptTests.Execute_CommentsAndEmptyLines_Skipped;
begin
  var ScriptFile := WriteScript(['* comment','','init','* another comment','set value=1']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual(1,Integer(Length(Interpreter.Runs)));
  Assert.AreEqual('1',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_HashComment_Skipped;
begin
  var ScriptFile := WriteScript(['# comment','init','set value=1']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('1',Interpreter.Runs[0]);
end;

// Indented arguments

Procedure TScriptTests.Execute_IndentedArguments;
begin
  var ScriptFile := WriteScript(['init','  value: A','set','  value: 1','set','  value: 2']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('A',Interpreter.InitValues[0]);
  Assert.AreEqual('1,2',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_MixedArguments;
begin
  var ScriptFile := WriteScript(['init','set tag=x','  value: 1']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('1',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_MixedArguments_CommandLineTakesPrecedence;
begin
  var ScriptFile := WriteScript(['init','set value=1','  value: 2']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('1',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_IndentedArguments_CommentsAndEmptyLinesSkipped;
begin
  var ScriptFile := WriteScript(['init','set','* comment','','  value: 1','set','  value: 2']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('1,2',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_IndentedArgument_ColonInValue;
begin
  var ScriptFile := WriteScript(['init','set','  value: C:\data']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('C:\data',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_IndentedArgument_WithoutColon_RaisesException;
begin
  var ScriptFile := WriteScript(['init','set','  value']);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.AreEqual('Invalid argument line at line 3',Msg);
end;

Procedure TScriptTests.Execute_ArgumentLineWithoutCommand_RaisesException;
begin
  var ScriptFile := WriteScript(['  value: 1']);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.AreEqual('Argument line without command at line 1',Msg);
end;

Procedure TScriptTests.Execute_Include_IndentedArguments;
begin
  var IncludeFile := WriteScript(['set','  value: %purp%']);
  var ScriptFile := WriteScript(['init','include','  file: '+IncludeFile,'  purp: 5']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('5',Interpreter.Runs[0]);
end;

// Parameters

Procedure TScriptTests.Execute_Parameter_ReplacedInValue;
begin
  var ScriptFile := WriteScript(['init','set value=P%purp%Q']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('P5Q',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_Parameter_CaseInsensitive;
begin
  var ScriptFile := WriteScript(['init','set value=P%PURP%Q']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('P5Q',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_Parameter_ReplacedInInitArguments;
begin
  var ScriptFile := WriteScript(['init value=%purp%','set value=1']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('5',Interpreter.InitValues[0]);
end;

Procedure TScriptTests.Execute_Parameter_ReplacedInInclude;
begin
  var IncludeFile := WriteScript(['set value=P%purp%Q']);
  var ScriptFile := WriteScript(['init','include file='+IncludeFile]);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('P5Q',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_Parameter_CustomDelimiter;
begin
  var ScriptFile := WriteScript(['init','set value=P$purp$Q%purp%']);
  Interpreter.ParameterDelimiter := '$';
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('P5Q%purp%',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_Parameter_DelimiterFromInitCommand;
begin
  var ScriptFile := WriteScript(['init delim=$','set value=P$purp$Q%purp%']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('P5Q%purp%',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_Parameter_DelimiterRestoredOnReinit;
begin
  var ScriptFile := WriteScript(['init delim=$','set value=$purp$','init','set value=%purp%']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','5')]));
  Assert.AreEqual('5',Interpreter.Runs[0]);
  Assert.AreEqual('5',Interpreter.Runs[1]);
end;

Procedure TScriptTests.Execute_Parameter_InvalidDelimiter_RaisesException;
begin
  var ScriptFile := WriteScript(['init delim=ab']);
  var Msg := '';
  try
    Interpreter.Execute(ScriptFile);
  except
    on E: Exception do Msg := E.Message;
  end;
  Assert.AreEqual('Invalid delim value (ab) at line 1',Msg);
end;

Procedure TScriptTests.Execute_NoParameters_PlaceholderUnchanged;
begin
  var ScriptFile := WriteScript(['init','set value=P%purp%Q']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('P%purp%Q',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_Parameter_ReplacedInIncludeFileName;
begin
  var IncludeFile := WriteScript(['set value=1']);
  var ScriptFile := WriteScript(['init','include file=%inc%']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('inc',IncludeFile)]));
  Assert.AreEqual('1',Interpreter.Runs[0]);
end;

// Include parameters

Procedure TScriptTests.Execute_IncludeParameter_ReplacedInInclude;
begin
  var IncludeFile := WriteScript(['set value=P%purp%Q']);
  var ScriptFile := WriteScript(['init','include file='+IncludeFile+'; purp=5']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('P5Q',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_IncludeParameter_OutOfScopeAfterInclude;
begin
  var IncludeFile := WriteScript(['set value=%purp%']);
  var ScriptFile := WriteScript(['init','include file='+IncludeFile+'; purp=5','set value=%purp%']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('5,%purp%',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_IncludeParameter_OverridesScriptParameter;
begin
  var IncludeFile := WriteScript(['set value=%purp%']);
  var ScriptFile := WriteScript(['init','set value=%purp%','include file='+IncludeFile+'; purp=5']);
  Interpreter.Execute(ScriptFile,TKeyValuePairs.Create([TKeyValuePair.Create('purp','1')]));
  Assert.AreEqual('1,5',Interpreter.Runs[0]);
end;

Procedure TScriptTests.Execute_IncludeParameter_PassedOnToNestedInclude;
begin
  var InnerFile := WriteScript(['set value=%q%']);
  var OuterFile := WriteScript(['include file='+InnerFile+'; q=%p%2']);
  var ScriptFile := WriteScript(['init','include file='+OuterFile+'; p=5']);
  Interpreter.Execute(ScriptFile);
  Assert.AreEqual('52',Interpreter.Runs[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TScriptTests);
end.
