unit TxtTab;

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
  SysUtils,Classes,Parse;

Type
  TTextTableReader = Class
  private
    FFieldCount,FLineCount: Integer;
    FNames: TArray<String>;
    FFileName: String;
    Parser: TStringParser;
    Reader: TStreamReader;
    Function GetNames(Field: Integer): String; inline;
    Function GetValues(Field: Integer): TToken; inline;
  public
    Constructor Create(const FileName: String; const Delimiter: TDelimiter = Tab); overload;
    Constructor Create(const FileName: String; const Encoding: TEncoding; const Delimiter: TDelimiter = Tab); overload;
    Function IndexOf(const FieldName: String; MustExist: Boolean = false; CaseSensitive: Boolean = false): Integer;
    Function ReadLine: Boolean;
    Destructor Destroy; override;
  public
    Property FieldCount: Integer read FFieldCount;
    Property LineCount: Integer read FLineCount;
    Property Names[Field: Integer]: String read GetNames;
    Property Values[Field: Integer]: TToken read GetValues; default;
    Property FileName: String read FFileName;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TTextTableReader.Create(const FileName: String; const Delimiter: TDelimiter= Tab);
begin
  Create(FileName,Tencoding.ASCII,Delimiter);
end;

Constructor TTextTableReader.Create(const FileName: String; const Encoding: TEncoding; const Delimiter: TDelimiter= Tab);
begin
  inherited Create;
  FFileName := FileName;
  Reader := TStreamReader.Create(FileName,Encoding);
  Parser := TStringParser.Create(Delimiter);
  // Read field names
  Parser.ReadLine(Reader);
  FFieldCount := Parser.Count;
  FNames := Parser.ToStrArray;
end;

Function TTextTableReader.GetNames(Field: Integer): String;
begin
  Result := FNames[Field];
end;

Function TTextTableReader.GetValues(Field: Integer): TToken;
begin
  Result := Parser[Field];
end;

Function TTextTableReader.IndexOf(const FieldName: String; MustExist: Boolean = false; CaseSensitive: Boolean = false): Integer;
begin
  Result := -1;
  if CaseSensitive then
  begin
    for var Field := 0 to FFieldCount-1 do
    if FNames[Field] = FieldName then Exit(Field)
  end else
  begin
    for var Field := 0 to FFieldCount-1 do
    if SameText(FNames[Field],FieldName) then Exit(Field)
  end;
  if MustExist then raise Exception.Create('Unknown field ' + FieldName + ' in ' + FFileName);
end;

Function TTextTableReader.ReadLine: Boolean;
begin
  if not Reader.EndOfStream then
  begin
    Inc(FLineCount);
    Parser.ReadLine(Reader);
    if Parser.Count = 0 then
      if Reader.EndOfStream then
        Result := false // Empty line at end of file
      else
        raise Exception.Create('Invalid number of columns at line ' + FLineCount.ToString)
    else
      if Parser.Count = FFieldCount then
        Result := true
      else
        raise Exception.Create('Invalid number of columns at line ' + FLineCount.ToString)
  end else
    Result := false;
end;

Destructor TTextTableReader.Destroy;
begin
  Reader.Free;
  inherited Destroy;
end;

end.
