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
  SysUtils,IOUtils,Classes;

Type
  TLogFile = Class
  private
    ConsoleMessages: Boolean;
    LogStream: TFileStream;
    LogWriter: TStreamWriter;
  public
    Constructor Create(const LogFileName: String; Echo: Boolean = true; Append: Boolean = false);
    Procedure Log(const Line: String = ''); overload;
    Procedure Log(const Columns: array of String; const ColumnWidths: Integer); overload;
    Procedure Log(const Columns: array of String; const ColumnWidths: array of Integer); overload;
    Procedure Log(const Error: Exception); overload;
    Procedure Log(const FileLabel,FileName: String); overload;
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
  Log('Executable',ParamStr(0));
  Log('Computer: ' + GetEnvironmentVariable('COMPUTERNAME'));
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
  Log(FileLabel + ': ' + ExtractFileName(FileName) + '; ' + DateTimeToStr(TFile.GetLastWriteTime(FileName)));
end;

Destructor TLogFile.Destroy;
begin
  Log('STOP ' + DateTimeToStr(Now));
  LogWriter.Free;
  LogStream.Free;
  inherited Destroy;
end;

end.
