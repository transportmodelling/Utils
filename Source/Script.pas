unit Script;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, Classes, KeyVal;

Type
  TScriptFileReader = Class
  // Base class for script file readers, providing script commands one at a time.
  // Descendants implement the script file format (ReadFileCommand-method).
  //
  // Scripts can be parameterized: before commands are returned, parameter names
  // enclosed in the ParameterDelimiter (e.g. P%purp%Q) within the argument values
  // are replaced by the parameter values (P5Q when purp equals 5). Descendants can
  // push additional parameter scopes (e.g. for included script files); on name
  // clashes the parameters of the innermost scope take precedence.
  private
    FParameterDelimiter: Char;
    ParameterScopes: TArray<TKeyValuePairs>; // The first entry holds the script parameters, the last entry the innermost scope
  strict protected
    Function ReadFileCommand(out Command: String; out Arguments: TKeyValuePairs): Boolean; virtual; abstract;
    Procedure ApplyParameters(var Arguments: TKeyValuePairs);
    Procedure PushParameters(const [ref] Parameters: TKeyValuePairs);
    Procedure PopParameters;
  public
    Constructor Create(const [ref] Parameters: TKeyValuePairs; const ParameterDelimiter: Char = '%');
    Function ReadCommand(out Command: String; out Arguments: TKeyValuePairs): Boolean;
    Function LineNr: Integer; virtual;
    Function LineInfo: String; virtual;
  public
    Property ParameterDelimiter: Char read FParameterDelimiter write FParameterDelimiter;
  end;

  TTextScriptFileReader = Class(TScriptFileReader)
  // Reads script files in the text format.
  //
  // A script is a text file containing a series of commands. A command starts at
  // the first position of a line (without indentation), and takes its arguments
  // as key: value pairs on the subsequent lines, indented by at least one space
  // or tab. Alternatively (or additionally), arguments can be provided on the
  // command line itself, as a series of key=value pairs separated by semicolons.
  // When the same key is provided both ways, the value on the command line takes
  // precedence.
  //
  // Empty lines and lines starting with an asterisk or hash character (comments)
  // are skipped; they never terminate the argument lines of a command.
  //
  // The include-command, with a file-property specifying the script file to be
  // included, inserts the commands of another script file. Any other properties
  // of the include-command define additional parameters that apply to the
  // included script file only.
  private
    Type
      TScript = record
        FileName: String;
        LineNr: Integer;
        Buffered: Boolean;
        BufferedLine: String;
        Reader: TStreamReader;
      end;
    Var
      MainFileName: String;
      CommandLineNr: Integer;
      CommandFileName: String;
      Scripts: TArray<TScript>; // Stack of script files; the first entry is the main script file, the last entry the file being read
    Procedure OpenScript(const FileName: String);
    Procedure CloseScript;
    Function ReadLine(out Line: String): Boolean;
    Procedure UnreadLine(const Line: String);
    Function CurrentLineInfo: String;
    Function ReadCommandLine(out Command: String; out Arguments: TKeyValuePairs): Boolean;
    Procedure InterpretIncludeCommand(var Arguments: TKeyValuePairs);
  strict protected
    Function ReadFileCommand(out Command: String; out Arguments: TKeyValuePairs): Boolean; override;
  public
    Constructor Create(const FileName: String;
                       const [ref] Parameters: TKeyValuePairs;
                       const ParameterDelimiter: Char = '%');
    Function LineNr: Integer; override;
    Function LineInfo: String; override;
    Destructor Destroy; override;
  end;

  TScriptInterpreter = Class
  // Base class for script interpreters.
  //
  // A script consists of one or more sections, each starting with an init-command.
  // Whenever the next init-command is reached, the interpreted section is executed
  // before the interpretation of the next section starts.
  //
  // The parameters passed to the Execute-method are used by the script file reader
  // to replace the parameter placeholders within the argument values.
  //
  // All commands other than the init-command must be provided by descendant classes.
  private
    FScriptFileName: String;
    FInitialized: Boolean;
    FParameterDelimiter: Char;
    FParameters: TKeyValuePairs;
    ScriptReader: TScriptFileReader;
    PendingCommand: String;
    PendingArguments: TKeyValuePairs;
    Function InterpretCommands(UnhandledCommand: Boolean): Boolean;
  strict protected
    Property Initialized: Boolean read FInitialized;
    Property Parameters: TKeyValuePairs read FParameters;
    Function LineNr: Integer;
    Function CreateScriptReader: TScriptFileReader; virtual;
    // InitializeRun is called before the interpretation of each script section starts.
    // Descendants can override this method to reset the objects holding the section state.
    Procedure InitializeRun; virtual;
    Procedure InterpretInitCommand(const [ref] Arguments: TKeyValuePairs); virtual; abstract;
    Function InterpretCommand(const Command: String; const [ref] Arguments: TKeyValuePairs): Boolean; virtual; abstract;
    // RunCompleted is called when all commands of a run have been interpreted.
    // Interpreters that execute each command within the InterpretCommand-method
    // can leave this method as is; interpreters that convert commands into objects
    // can override this method to execute the interpreted run.
    Procedure RunCompleted; virtual;
    // FinalizeRun is called after the execution of each script section, including
    // sections that raised an exception. Descendants can override this method to
    // destroy the objects holding the section state.
    Procedure FinalizeRun; virtual;
    Procedure HandleException(const E: Exception); virtual;
  public
    Constructor Create;
    Procedure Execute(const ScriptFileName: String); overload;
    Procedure Execute(const ScriptFileName: String; const [ref] ScriptParameters: TKeyValuePairs); overload;
  public
    Property ScriptFileName: String read FScriptFileName;
    Property ParameterDelimiter: Char read FParameterDelimiter write FParameterDelimiter;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TScriptFileReader.Create(const [ref] Parameters: TKeyValuePairs; const ParameterDelimiter: Char = '%');
begin
  inherited Create;
  FParameterDelimiter := ParameterDelimiter;
  ParameterScopes := [Copy(Parameters)];
end;

Procedure TScriptFileReader.ApplyParameters(var Arguments: TKeyValuePairs);
// Replaces the parameter placeholders in the argument values by the parameter values.
// Scopes are applied from the innermost scope outwards, so on name clashes the
// parameters of the innermost scope take precedence.
begin
  for var Scope := high(ParameterScopes) downto low(ParameterScopes) do
  for var Parameter := low(ParameterScopes[Scope]) to high(ParameterScopes[Scope]) do
  begin
    var Placeholder := FParameterDelimiter + ParameterScopes[Scope][Parameter].Key + FParameterDelimiter;
    for var Argument := low(Arguments) to high(Arguments) do
    Arguments[Argument].Value := StringReplace(Arguments[Argument].Value,Placeholder,
                                               ParameterScopes[Scope][Parameter].Value,[rfReplaceAll,rfIgnoreCase]);
  end;
end;

Procedure TScriptFileReader.PushParameters(const [ref] Parameters: TKeyValuePairs);
begin
  ParameterScopes := ParameterScopes + [Copy(Parameters)];
end;

Procedure TScriptFileReader.PopParameters;
begin
  if Length(ParameterScopes) > 1 then SetLength(ParameterScopes,Length(ParameterScopes)-1);
end;

Function TScriptFileReader.ReadCommand(out Command: String; out Arguments: TKeyValuePairs): Boolean;
begin
  Result := ReadFileCommand(Command,Arguments);
  if Result then ApplyParameters(Arguments);
end;

Function TScriptFileReader.LineNr: Integer;
begin
  Result := 0;
end;

Function TScriptFileReader.LineInfo: String;
begin
  Result := '';
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TTextScriptFileReader.Create(const FileName: String;
                                         const [ref] Parameters: TKeyValuePairs;
                                         const ParameterDelimiter: Char = '%');
begin
  inherited Create(Parameters,ParameterDelimiter);
  MainFileName := ExpandFileName(FileName);
  OpenScript(MainFileName);
end;

Procedure TTextScriptFileReader.OpenScript(const FileName: String);
begin
  if FileExists(FileName) then
  begin
    var Script: TScript;
    Script.FileName := FileName;
    Script.LineNr := 0;
    Script.Buffered := false;
    Script.BufferedLine := '';
    Script.Reader := TStreamReader.Create(FileName);
    Scripts := Scripts + [Script];
  end else
    raise Exception.Create('Script file does not exist (' + FileName + ')');
end;

Procedure TTextScriptFileReader.CloseScript;
begin
  // Included script files carry their own parameter scope
  if Length(Scripts) > 1 then PopParameters;
  Scripts[high(Scripts)].Reader.Free;
  SetLength(Scripts,Length(Scripts)-1);
end;

Function TTextScriptFileReader.ReadLine(out Line: String): Boolean;
// Reads the next script line, without trimming, as the indentation of a line
// is significant. On reaching the end of an included script file, reading
// continues in the including script file. The result indicates whether a line
// has been read.
begin
  Result := false;
  while Length(Scripts) > 0 do
  if Scripts[high(Scripts)].Buffered then
  begin
    Scripts[high(Scripts)].Buffered := false;
    Line := Scripts[high(Scripts)].BufferedLine;
    Exit(true);
  end else
  if Scripts[high(Scripts)].Reader.EndOfStream then
    if Length(Scripts) > 1 then
      CloseScript
    else
      Exit
  else
    begin
      Inc(Scripts[high(Scripts)].LineNr);
      Line := Scripts[high(Scripts)].Reader.ReadLine;
      Exit(true);
    end;
end;

Procedure TTextScriptFileReader.UnreadLine(const Line: String);
// Buffers a line that has been read ahead, so the next ReadLine-call returns it again
begin
  Scripts[high(Scripts)].Buffered := true;
  Scripts[high(Scripts)].BufferedLine := Line;
end;

Function TTextScriptFileReader.CurrentLineInfo: String;
// Returns the position of the line being read, used for reader errors.
// The LineInfo-method returns the position of the current command instead.
begin
  Result := ' at line ' + Scripts[high(Scripts)].LineNr.ToString;
  if high(Scripts) > 0 then Result := Result + ' in ' + Scripts[high(Scripts)].FileName;
end;

Function TTextScriptFileReader.ReadCommandLine(out Command: String; out Arguments: TKeyValuePairs): Boolean;
// Reads the next command line, together with its indented argument lines.
// The result indicates whether a command has been read.
Var
  Line: String;
begin
  Result := false;
  // Read the command line
  repeat
    if not ReadLine(Line) then Exit;
    var Content := Trim(Line);
    if (Content <> '') and (Content[1] <> '*') and (Content[1] <> '#') then
    if (Line[1] = ' ') or (Line[1] = #9) then
      raise Exception.Create('Argument line without command' + CurrentLineInfo)
    else
      begin
        var SpacePos := Pos(' ',Content);
        if SpacePos > 0 then
        begin
          Command := Copy(Content,1,SpacePos-1);
          Arguments := TKeyValuePairs.Create(Copy(Content,SpacePos+1,MaxInt),'=',';');
        end else
        begin
          Command := Content;
          Arguments := nil;
        end;
        CommandLineNr := Scripts[high(Scripts)].LineNr;
        CommandFileName := Scripts[high(Scripts)].FileName;
        Result := true;
      end;
  until Result;
  // Append the indented argument lines. The arguments of a command must reside
  // within the same script file as the command line, so reading stops at the
  // end of the file.
  while not Scripts[high(Scripts)].Reader.EndOfStream do
  begin
    ReadLine(Line);
    var Content := Trim(Line);
    if (Content <> '') and (Content[1] <> '*') and (Content[1] <> '#') then
    if (Line[1] = ' ') or (Line[1] = #9) then
    begin
      var SeparatorPos := Pos(':',Content);
      if SeparatorPos > 0 then
        Arguments.Append(Trim(Copy(Content,1,SeparatorPos-1)),Trim(Copy(Content,SeparatorPos+1,MaxInt)))
      else
        raise Exception.Create('Invalid argument line' + CurrentLineInfo);
    end else
    begin
      UnreadLine(Line);
      break;
    end;
  end;
end;

Procedure TTextScriptFileReader.InterpretIncludeCommand(var Arguments: TKeyValuePairs);
begin
  try
    // Substitute parameters using the scope of the including script file
    ApplyParameters(Arguments);
    var IncludeFileName := ExpandFileName(Arguments.Path('file'));
    for var Script := low(Scripts) to high(Scripts) do
    if SameFileName(Scripts[Script].FileName,IncludeFileName) then
    raise Exception.Create('Circular include (' + IncludeFileName + ')');
    OpenScript(IncludeFileName);
    // The remaining properties define the parameter scope of the included script file
    Arguments.Delete('file');
    PushParameters(Arguments);
  except
    on E: Exception do raise Exception.Create(E.Message + LineInfo);
  end;
end;

Function TTextScriptFileReader.ReadFileCommand(out Command: String; out Arguments: TKeyValuePairs): Boolean;
begin
  Result := false;
  while ReadCommandLine(Command,Arguments) do
  if SameText(Command,'include') then
    InterpretIncludeCommand(Arguments)
  else
    Exit(true);
end;

Function TTextScriptFileReader.LineNr: Integer;
begin
  Result := CommandLineNr;
end;

Function TTextScriptFileReader.LineInfo: String;
begin
  if CommandLineNr > 0 then
  begin
    Result := ' at line ' + CommandLineNr.ToString;
    if not SameFileName(CommandFileName,MainFileName) then Result := Result + ' in ' + CommandFileName;
  end else
    Result := '';
end;

Destructor TTextScriptFileReader.Destroy;
begin
  while Length(Scripts) > 0 do CloseScript;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TScriptInterpreter.Create;
begin
  inherited Create;
  FParameterDelimiter := '%';
end;

Function TScriptInterpreter.CreateScriptReader: TScriptFileReader;
// Descendants can override this method to read script files in another format
begin
  Result := TTextScriptFileReader.Create(ScriptFileName,Parameters,ParameterDelimiter);
end;

Function TScriptInterpreter.LineNr: Integer;
begin
  Result := ScriptReader.LineNr;
end;

Procedure TScriptInterpreter.InitializeRun;
begin
end;

Procedure TScriptInterpreter.RunCompleted;
begin
end;

Procedure TScriptInterpreter.FinalizeRun;
begin
end;

Procedure TScriptInterpreter.HandleException(const E: Exception);
// Called for exceptions raised while interpreting or executing a script section.
// The base class re-raises the exception; descendants can override this method
// to log the exception and continue with the next script section.
begin
  raise ExceptClass(E.ClassType).Create(E.Message);
end;

Function TScriptInterpreter.InterpretCommands(UnhandledCommand: Boolean): Boolean;
// Interpret commands until the end of the script file, or the script is re-initialized.
// The result indicates whether all commands have been handled.
// The UnhandledCommand-argument indicates whether an unhandled command is left from a previous call.
Var
  Command: String;
  Arguments: TKeyValuePairs;
begin
  FInitialized := false;
  while UnhandledCommand or ScriptReader.ReadCommand(Command,Arguments) do
  begin
    if UnhandledCommand then
    begin
      UnhandledCommand := false;
      Command := PendingCommand;
      Arguments := PendingArguments;
    end;
    try
      if SameText(Command,'init') then
      begin
        if FInitialized then
        begin
          // Script is re-initialized; save the init-command for the next section
          PendingCommand := Command;
          PendingArguments := Arguments;
          Exit(false);
        end else
        begin
          FInitialized := true;
          // The delim-argument changes the parameter delimiter from the
          // next command onwards; when absent the default delimiter is restored
          var Delimiter := Arguments.ToStr('delim',FParameterDelimiter);
          if Length(Delimiter) = 1 then
            ScriptReader.ParameterDelimiter := Delimiter[1]
          else
            raise Exception.Create('Invalid delim value (' + Delimiter + ')');
          InterpretInitCommand(Arguments);
        end
      end else
        if FInitialized then
        begin
          if not InterpretCommand(Command,Arguments) then raise Exception.Create('Invalid command');
        end else
          raise Exception.Create('Initialization required');
    except
      on E: Exception do raise Exception.Create(E.Message + ScriptReader.LineInfo);
    end;
  end;
  Result := true;
end;

Procedure TScriptInterpreter.Execute(const ScriptFileName: String);
Var
  ScriptParameters: TKeyValuePairs;
begin
  Execute(ScriptFileName,ScriptParameters);
end;

Procedure TScriptInterpreter.Execute(const ScriptFileName: String; const [ref] ScriptParameters: TKeyValuePairs);
begin
  FParameters := Copy(ScriptParameters);
  FScriptFileName := ExpandFileName(ScriptFileName);
  ScriptReader := CreateScriptReader;
  try
    var UnhandledCommand := false;
    repeat
      try
        try
          InitializeRun;
          UnhandledCommand := not InterpretCommands(UnhandledCommand);
          RunCompleted;
        except
          on E: Exception do HandleException(E);
        end;
      finally
        FinalizeRun;
      end;
    until not UnhandledCommand;
  finally
    FreeAndNil(ScriptReader);
  end;
end;

end.
