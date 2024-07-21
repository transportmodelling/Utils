unit Log;

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
  SysUtils, Classes, Windows, Math, IOUtils, DateUtils, Parse;

Type
  TLogEvent = Procedure(Sender: TObject; const Line: String) of Object;

  TLogFile = Class
  private
    Type
      TFileInfo = record
        FileLabel,FileInfo: String;
      end;
    Const
      MaxPathLevels = 4;
    Var
      LogEvent: TLogEvent;
      StartTime: TDateTime;
      Console: Boolean;
      ConsoleWidth: Integer;
      LogStream: TFileStream;
      LogWriter: TStreamWriter;
      InputFiles,OutputFiles: array of TFileInfo;
    Function ShortenPath(const Path: string): string;
    Function FileProperties(const FileName: string): string;
    Function FileInfo(const FileName: string; NameOnly: Boolean): string;
    Function VarRecToStr(VarRec: TVarRec; Decimals: Integer): String;
  public
    Constructor Create(const OnLog: TLogEvent = nil); overload;
    Constructor Create(const LogFileName: String;
                       const Echo: Boolean = false;
                       const Append: Boolean = false;
                       const OnAppend: TNotifyEvent = nil;
                       const OnLog: TLogEvent = nil); overload;
    Procedure Log(const Line: String = ''); overload;
    Procedure Log(const Columns: array of String; const ColumnWidths: Integer); overload;
    Procedure Log(const Columns: array of Const; const ColumnWidths, Decimals: Integer); overload;
    Procedure Log(const Columns: array of String; const ColumnWidths: array of Integer); overload;
    Procedure Log(const Columns: array of Const; const ColumnWidths: array of Integer; Decimals: Integer); overload;
    Procedure Log(const Error: Exception); overload;
    Procedure Log(const FileLabel,FileName: String); overload;
    Procedure LogFileContent(const FileName: String);
    Procedure InputFile(const FileLabel,FileName: String);
    Procedure OutputFile(const FileLabel,FileName: String);
    Procedure Flush;
    Destructor Destroy; override;
  end;

Var
  LogFile: TLogFile = nil;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TLogFile.Create(const OnLog: TLogEvent = nil);
var
  CBI: TConsoleScreenBufferInfo;
begin
  LogEvent := OnLog;
  Console := IsConsole;
  if Console then
  begin
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),CBI);
    ConsoleWidth := CBI.dwSize.X;
  end;
  StartTime := Now;
  Log('START ' + DateTimeToStr(StartTime));
  Log('Executable: ' + FileInfo(ParamStr(0),true));
  Log('Computer: ' + GetEnvironmentVariable('COMPUTERNAME'));
end;

Constructor TLogFile.Create(const LogFileName: String;
                            const Echo: Boolean = false;
                            const Append: Boolean = false;
                            const OnAppend: TNotifyEvent = nil;
                            const OnLog: TLogEvent = nil);
var
  CBI: TConsoleScreenBufferInfo;
begin
  inherited Create;
  LogEvent := OnLog;
  Console := IsConsole and Echo;
  if Console then
  begin
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),CBI);
    ConsoleWidth := CBI.dwSize.X;
  end;
  if FileExists(LogFileName) and Append then
  begin
    LogStream := TFileStream.Create(LogFileName,fmOpenWrite or fmShareDenyWrite);
    LogStream.Seek(0,soEnd);
    LogWriter := TStreamWriter.Create(LogStream,TEncoding.ASCII,4096);
    if Assigned(OnAppend) then OnAppend(Self);
  end else
  begin
    LogStream := TFileStream.Create(LogFileName,fmCreate or fmShareDenyWrite);
    LogWriter := TStreamWriter.Create(LogStream,TEncoding.ASCII,4096);
  end;
  StartTime := Now;
  Log('START ' + DateTimeToStr(StartTime));
  Log('Executable: ' + FileInfo(ParamStr(0),true));
  Log('Computer: ' + GetEnvironmentVariable('COMPUTERNAME'));
 end;

Function TLogFile.ShortenPath(const Path: string): string;
Var
  Parser: TStringParser;
begin
   var RootPath := TPath.GetPathRoot(Path);
   Parser.SetSeparators([PathDelim]);
   Parser.ExcludeEmpty := false;
   Parser.Assign(Copy(Path,Length(RootPath)+1,MaxInt));
   if Parser.Count <= MaxPathLevels+1 then
     Result := Path
   else
     begin
       Result := RootPath + '...';
       for var Level  := MaxPathLevels downto 1 do
       Result := Result + PathDelim + Parser[Parser.Count-Level];
     end;
end;

Function TlogFile.FileProperties(const FileName: string): string;
begin
  Result := DateTimeToStr(TFile.GetLastWriteTime(FileName)) + '; ' +
            TFile.GetSize(FileName).ToString + ' bytes';
end;

Function TLogFile.FileInfo(const FileName: string; NameOnly: Boolean): string;
begin
  if NameOnly then
    Result := ExtractFileName(FileName)
  else
    Result := ShortenPath(FileName);
  Result := Result + '; ' +  FileProperties(FileName);
end;

Function TLogFile.VarRecToStr(VarRec: TVarRec; Decimals: Integer): String;
begin
  case VarRec.VType of
    vtInteger:       Result := VarRec.VInteger.ToString;
    vtInt64:         Result := VarRec.VInt64^.ToString;
    vtChar:          Result := VarRec.VChar;
    vtExtended:      Result := FloatToStrF(VarRec.vExtended^,ffFixed,15,Decimals);
    vtString:        Result := VarRec.VString^;
    vtUnicodeString: Result := String(VarRec.VUnicodeString);
    vtPChar:         Result := VarRec.VPChar;
    vtAnsiString:    Result := String(VarRec.VAnsiString);
    vtCurrency:      Result := VarRec.VCurrency^.ToString;
    vtVariant:       Result := String(VarRec.VVariant^);
    else raise Exception.Create('Unsupported type in Log');
  end;
end;

Procedure TLogFile.Log(const Line: String = '');
begin
  if Console then
  if Line.Length <= ConsoleWidth then
    writeln(Line)
  else
    write(Copy(Line,1,ConsoleWidth));
  if LogWriter <> nil then LogWriter.WriteLine(Line);
  if Assigned(LogEvent) then TThread.Synchronize(nil,Procedure
                                                     begin
                                                       LogEvent(Self,Line)
                                                     end);
end;

Procedure TLogFile.Log(const Columns: array of String; const ColumnWidths:Integer);
begin
  var Line := '';
  for var Column := low(Columns) to high(Columns) do
  begin
    var Text := Columns[Column];
    while Length(Text) < ColumnWidths do Text := ' ' + Text;
    Line := Line + Text;
  end;
  Log(Line);
end;

Procedure TLogFile.Log(const Columns: array of Const; const ColumnWidths, Decimals: Integer);
Var
  StringColumns: array of String;
begin
  SetLength(StringColumns,Length(Columns));
  for var Column := low(Columns) to high(Columns) do StringColumns[Column] := VarRecToStr(Columns[Column],Decimals);
  Log(StringColumns,ColumnWidths);
end;

Procedure TLogFile.Log(const Columns: array of String; const ColumnWidths: array of Integer);
begin
  if Length(Columns) = Length(ColumnWidths) then
  begin
    var Line := '';
    for var Column := low(Columns) to high(Columns) do
    begin
      var Text := Columns[Column];
      var Width := ColumnWidths[Column];
      while Length(Text) < Width do Text := ' ' + Text;
      Line := Line + Text;
    end;
    Log(Line);
  end else
    raise Exception.Create('Inconsistent method arguments');
end;

Procedure TLogFile.Log(const Columns: array of Const; const ColumnWidths: array of Integer; Decimals: Integer);
Var
  StringColumns: array of String;
begin
  SetLength(StringColumns,Length(Columns));
  for var Column := low(Columns) to high(Columns) do StringColumns[Column] := VarRecToStr(Columns[Column],Decimals);
  Log(StringColumns,ColumnWidths);
end;

Procedure TLogFile.Log(const Error: Exception);
begin
  Log('ERROR: ' + Error.Message);
end;

Procedure TLogFile.Log(const FileLabel,FileName: String);
begin
  Log(FileLabel + ': ' + FileInfo(FileName,false));
end;

Procedure TLogFile.LogFileContent(const FileName: String);
begin
  var Reader := TStreamReader.Create(FileName);
  try
    while not Reader.EndOfStream do Log(Reader.ReadLine);
  finally
    Reader.Free;
  end;
end;

Procedure TLogFile.InputFile(const FileLabel,FileName: String);
Var
  InputFile: TFileInfo;
begin
  InputFile.FileLabel := FileLabel;
  InputFile.FileInfo := FileInfo(FileName,false);
  InputFiles := InputFiles + [InputFile];
end;

Procedure TLogFile.OutputFile(const FileLabel,FileName: String);
Var
  OutputFile: TFileInfo;
begin
  OutputFile.FileLabel := FileLabel;
  OutputFile.FileInfo := FileName;
  OutputFiles := OutputFiles + [OutputFile];
end;

Procedure TLogFile.Flush;
begin
  LogWriter.Flush;
end;

Destructor TLogFile.Destroy;
begin
  // Log input files
  if Length(InputFiles) > 0 then
  begin
    Log;
    Log('Input files:');
    for var InpFile := low(InputFiles) to high(InputFiles) do
    Log(InputFiles[InpFile].FileLabel + ': ' + InputFiles[InpFile].FileInfo);
  end;
  // Log output files
  if Length(OutputFiles) > 0 then
  begin
    Log;
    Log('Output files:');
    for var OutpFile := low(OutputFiles) to high(OutputFiles) do
    Log(OutputFiles[OutpFile].FileLabel + ': ' + FileInfo(OutputFiles[OutpFile].FileInfo,false));
  end;
  // Log stop time
  var StopTime := Now;
  Log;
  if DaysBetween(StartTime,StopTime) = 0 then
    Log('STOP ' + DateTimeToStr(StopTime) + ' (Run time: ' + FormatDateTime('hh:nn:ss',StopTime-StartTime)+ ')')
  else
    Log('STOP ' + DateTimeToStr(StopTime) + ' (Run time: ' + FormatDateTime('dd:hh:nn:ss',StopTime-StartTime)+ ')');
  LogWriter.Free;
  LogStream.Free;
  inherited Destroy;
end;

end.
