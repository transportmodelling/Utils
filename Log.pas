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
  SysUtils,IOUtils,Classes,Parse;

Type
  TLogFile = Class
  private
    Type
      TFileInfo = record
        FileLabel,FileInfo: String;
      end;
    Const
      MaxPathLevels = 4;
    Var
      ConsoleMessages: Boolean;
      LogStream: TFileStream;
      LogWriter: TStreamWriter;
      InputFiles,OutputFiles: array of TFileInfo;
    Function ShortenPath(const Path: string): string;
    Function FileProperties(const FileName: string): string;
    Function FileInfo(const FileName: string; NameOnly: Boolean): string;
  public
    Constructor Create(const LogFileName: String; Echo: Boolean = true; Append: Boolean = false);
    Procedure Log(const Line: String = ''); overload;
    Procedure Log(const Columns: array of String; const ColumnWidths: Integer); overload;
    Procedure Log(const Columns: array of String; const ColumnWidths: array of Integer); overload;
    Procedure Log(const Error: Exception); overload;
    Procedure Log(const FileLabel,FileName: String); overload;
    Procedure InputFile(const FileLabel,FileName: String);
    Procedure OutputFile(const FileLabel,FileName: String);
    Destructor Destroy; override;
  end;

Var
  LogFile: TLogFile = nil;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TLogFile.Create(const LogFileName: String; Echo: Boolean = true; Append: Boolean = false);
begin
  inherited Create;
  ConsoleMessages := IsConsole and Echo;
  if Append then
  begin
    LogStream := TFileStream.Create(LogFileName,fmOpenWrite or fmShareDenyWrite);
    LogStream.Seek(0,soEnd);
  end else
    LogStream := TFileStream.Create(LogFileName,fmCreate or fmShareDenyWrite);
  LogWriter := TStreamWriter.Create(LogStream,TEncoding.ASCII,4096);
  if Append and (LogStream.Size > 0) then LOGWriter.WriteLine;
  Log('START ' + DateTimeToStr(Now));
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

Procedure TLogFile.Log(const Line: String = '');
begin
  if ConsoleMessages then writeln(Line);
  if LogWriter <> nil then LogWriter.WriteLine(Line)
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

Procedure TLogFile.Log(const Error: Exception);
begin
  Log('ERROR: ' + Error.Message);
end;

Procedure TLogFile.Log(const FileLabel,FileName: String);
begin
  Log(FileLabel + ': ' + FileInfo(FileName,false));
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
  Log;
  Log('STOP ' + DateTimeToStr(Now));
  LogWriter.Free;
  LogStream.Free;
  inherited Destroy;
end;

end.
