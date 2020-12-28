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
    Constructor Create(const LogFileName: String; Echo: Boolean = true);
    Procedure Log(const Line: String = ''); overload;
    Procedure Log(const Error: Exception); overload;
    Procedure Log(const FileLabel,FileName: String); overload;
    Destructor Destroy; override;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TLogFile.Create(const LogFileName: String; Echo: Boolean = true);
begin
  inherited Create;
  ConsoleMessages := IsConsole and Echo;
  LogStream := TFileStream.Create(LogFileName,fmCreate or fmShareDenyWrite);
  LogWriter := TStreamWriter.Create(LogStream,TEncoding.ASCII,4096);
  Log('START ' + DateTimeToStr(Now));
  Log('Executable',ParamStr(0));
  Log('Running on: ' + GetEnvironmentVariable('COMPUTERNAME'));
 end;

Procedure TLogFile.Log(const Line: String = '');
begin
  if ConsoleMessages then writeln(Line);
  if LOGWriter <> nil then LOGWriter.WriteLine(Line)
end;

Procedure TLogFile.Log(const Error: Exception);
begin
  Log('ERROR ' + Error.Message);
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
