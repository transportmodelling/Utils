unit Ctl;

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
  SysUtils, IOUtils, PropSet, Log;

Type
  TControlFile = Type TPropertySet;

  TCtlFileHelper = record helper for TControlFile
  public
    Constructor Create(ControlFilename: String);
    Function Read(ControlFilename: String): Boolean;
    Function InpFileName(const Name: string; Optional: Boolean = false): String;
    Function InpProperties(const Name: string; Optional: Boolean = false): TPropertySet;
    Function OutpFileName(const Name: string; Optional: Boolean = false): String;
    Function OutpProperties(const Name: string; Optional: Boolean = false): TPropertySet;
  end;

Var
  CtlFile: TControlFile;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TCtlFileHelper.Create(ControlFilename: String);
begin
  Read(ControlFilename);
end;

Function TCtlFileHelper.Read(ControlFilename: String): Boolean;
begin
  ControlFileName := ExpandFileName(ControlFileName);
  if FileExists(ControlFileName) then
  begin
    Result := true;
    Self.NameValueSeparator := ':';
    Self.PropertiesSeparator := ';';
    Self.BaseDirectory := ExtractFileDir(ControlFileName);
    Self.AsStrings := TFile.ReadAllLines(ControlFileName);
    Self.Lock;
  end else
  begin
    Result := false;
    writeln('Control file does not exist');
  end;
end;

Function TCtlFileHelper.InpFileName(const Name: string; Optional: Boolean = false): String;
begin
  Result := ToFileName(Name);
  if Result <> '' then
    if FileExists(Result) then
    begin
      if LogFile <> nil then LogFile.InputFile(Name,Result);
    end else
      raise Exception.Create('File does not exist (' + Name + ')')
  else
    if not Optional then
      raise Exception.Create('Missing file name (' + Name + ')')
end;

Function TCtlFileHelper.InpProperties(const Name: string; Optional: Boolean = false): TPropertySet;
Var
  Value: String;
begin
  if Contains(Name,Value) and (Value <> '') then
  begin
    Result := TPropertySet.Create('=',';',true);
    Result.AsString := Value;
    if Result.Contains('file',Value) then
    begin
      Value := TPropertySet.BaseDirectory.AbsolutePath(Value);
      if FileExists(Value) then
      begin
        if LogFile <> nil then LogFile.InputFile(Name,Value);
      end else
        raise Exception.Create('File does not exist (' + Name + ')')
    end else
      raise Exception.Create('Missing file property (' + Name + ')')
  end else
  begin
    if not Optional then
      raise Exception.Create('Missing properties (' + Name + ')')
  end;
end;

Function TCtlFileHelper.OutpFileName(const Name: string; Optional: Boolean = false): String;
begin
  Result := ToFileName(Name);
  if Result <> '' then
  begin
    if LogFile <> nil then LogFile.OutputFile(Name,Result);
  end else
    if not Optional then
      raise Exception.Create('Missing file name (' + Name + ')')
end;

Function TCtlFileHelper.OutpProperties(const Name: string; Optional: Boolean = false): TPropertySet;
Var
  Value: String;
begin
  if Contains(Name,Value) and (Value <> '') then
  begin
    Result := TPropertySet.Create('=',';',true);
    Result.AsString := Value;
    if Result.Contains('file',Value) then
    begin
      Value := TPropertySet.BaseDirectory.AbsolutePath(Value);
      if LogFile <> nil then LogFile.OutputFile(Name,Value);
    end else
      raise Exception.Create('Missing file property (' + Name + ')')
  end else
  begin
    if not Optional then
      raise Exception.Create('Missing properties (' + Name + ')')
  end;
end;

end.
