unit ColData;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

// A columnar text file holds one row per line. A row class declares its
// columns once, as the sequence of Column calls in IterateColumns, each with
// its header and, for a real, its format. That one declaration serves two
// goals:
// - Consistent reading and writing: the reader and the writer both traverse
//   it, so a file reads back in the layout it is written in.
// - Metadata: the headers name the columns of the data, also of a file that
//   holds no header line, since they come from the declaration and not from
//   the file. The writer can put them in the file, the reader checks them or
//   finds the columns by them, and TColumnarDataHeaders gives them to any
//   other program that presents the data.

Uses
  SysUtils, Classes, Parse;

Type
  // hdNone: the file holds no header line and its columns follow the declared
  //         columns
  // hdFree: a header line names the columns, each declared column finds its
  //         place by name and the other columns of the file are passed over
  // hdStrict: a header line names exactly the declared columns, in their order
  TColumnarDataHeader = (hdNone,hdFree,hdStrict);

  TColumnarDataHandler = Class abstract
  // Receives the columns of a row in the order IterateColumns declares them
  protected
    Procedure Column(const Header: String; var Value: Integer); overload; virtual; abstract;
    Procedure Column(const Header: String; var Value: String); overload; virtual; abstract;
    Procedure Column(const Header: String; var Value: Float64); overload; virtual; abstract;
    Procedure Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                     const SkipTrailingZeroDecimals: Boolean); overload; virtual; abstract;
  end;

  TColumnarData = Class abstract
  private
    Handler: TColumnarDataHandler;
    Procedure Iterate(const ColumnHandler: TColumnarDataHandler);
  strict protected
    // The columns of the row, called by IterateColumns in file order. A real
    // without decimals is written as FloatToStr writes it, at 15 significant
    // digits. A real with decimals is rounded to them, and written without its
    // trailing zero decimals when asked; a value that rounds to zero is then
    // written as 0. A string is written as it is, and may hold no separator
    // of the delimiter and no line break; with a space delimiter, which also
    // splits on tabs and drops empty columns, it may not be empty either.
    Procedure Column(const Header: String; var Value: Integer); overload;
    Procedure Column(const Header: String; var Value: String); overload;
    Procedure Column(const Header: String; var Value: Float64); overload;
    Procedure Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                     const SkipTrailingZeroDecimals: Boolean = false); overload;
    Procedure IterateColumns; virtual; abstract;
  public
    // The separator of the columns, a tab unless a row class overrides it
    Function Delimiter: TDelimiter; virtual;
  end;

  TColumnarDataHeaders = Class(TColumnarDataHandler)
  // The headers of the columns a row class declares
  private
    FHeaders: TArray<String>;
    Function GetHeaders(Index: Integer): String; inline;
  protected
    Procedure Column(const Header: String; var Value: Integer); overload; override;
    Procedure Column(const Header: String; var Value: String); overload; override;
    Procedure Column(const Header: String; var Value: Float64); overload; override;
    Procedure Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                     const SkipTrailingZeroDecimals: Boolean); overload; override;
  public
    Constructor Create(const Data: TColumnarData);
    Function Count: Integer; inline;
    Function HeaderLine(const Separator: Char): String;
  public
    Property Headers[Index: Integer]: String read GetHeaders; default;
  end;

  TColumnarDataFile<DataType: TColumnarData, constructor> = Class(TColumnarDataHandler)
  private
    FData: DataType;
    FFileName: String;
    FLineCount: Integer;
  strict protected
    Headers: TColumnarDataHeaders;
    ColumnIndex: Integer;
    // Fetched once: TFormatSettings.Invariant fills a new record on every call
    Settings: TFormatSettings;
    Function LineError(const Message: String): Exception;
  public
    Constructor Create(const FileName: String);
    Destructor Destroy; override;
  public
    Property Data: DataType read FData;
    Property FileName: String read FFileName;
    Property LineCount: Integer read FLineCount;
  end;

  TColumnarDataReader<DataType: TColumnarData, constructor> = Class(TColumnarDataFile<DataType>)
  // Read fills Data with the next line; false at the end of the file
  private
    Reader: TStreamReader;
    Parser: TStringParser;
    NColumns: Integer;
    Positions: TArray<Integer>;
    Procedure ReadHeader(const Header: TColumnarDataHeader);
    Procedure MapByPosition;
    Procedure MapByName;
    Function IndexOfHeader(const Header: String): Integer;
    Function SameHeaders: Boolean;
    Function NextPosition: Integer; inline;
    Procedure ReadColumns;
  protected
    Procedure Column(const Header: String; var Value: Integer); overload; override;
    Procedure Column(const Header: String; var Value: String); overload; override;
    Procedure Column(const Header: String; var Value: Float64); overload; override;
    Procedure Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                     const SkipTrailingZeroDecimals: Boolean); overload; override;
  public
    Constructor Create(const FileName: String; const Header: TColumnarDataHeader);
    Function Read: Boolean;
    Destructor Destroy; override;
  end;

  TColumnarDataWriter<DataType: TColumnarData, constructor> = Class(TColumnarDataFile<DataType>)
  // Write writes Data as the next line
  private
    Writer: TStreamWriter;
    Line: TStringBuilder;
    Separator: Char;
    StringBreaks: TArray<Char>;
    DropsEmptyColumns: Boolean;
    Procedure TakeStringRules;
    Procedure Append(const Value: String);
    Function WithoutTrailingZeroDecimals(const Value: Float64; const NDecimals: Byte): String;
  protected
    Procedure Column(const Header: String; var Value: Integer); overload; override;
    Procedure Column(const Header: String; var Value: String); overload; override;
    Procedure Column(const Header: String; var Value: Float64); overload; override;
    Procedure Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                     const SkipTrailingZeroDecimals: Boolean); overload; override;
  public
    Constructor Create(const FileName: String; const Header: Boolean);
    Procedure Write;
    Destructor Destroy; override;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TColumnarData.Iterate(const ColumnHandler: TColumnarDataHandler);
begin
  Handler := ColumnHandler;
  IterateColumns;
end;

Procedure TColumnarData.Column(const Header: String; var Value: Integer);
begin
  Handler.Column(Header,Value);
end;

Procedure TColumnarData.Column(const Header: String; var Value: String);
begin
  Handler.Column(Header,Value);
end;

Procedure TColumnarData.Column(const Header: String; var Value: Float64);
begin
  Handler.Column(Header,Value);
end;

Procedure TColumnarData.Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                               const SkipTrailingZeroDecimals: Boolean);
begin
  Handler.Column(Header,Value,NDecimals,SkipTrailingZeroDecimals);
end;

Function TColumnarData.Delimiter: TDelimiter;
begin
  Result := Tab;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TColumnarDataHeaders.Create(const Data: TColumnarData);
begin
  inherited Create;
  Data.Iterate(Self);
end;

Function TColumnarDataHeaders.GetHeaders(Index: Integer): String;
begin
  Result := FHeaders[Index];
end;

Procedure TColumnarDataHeaders.Column(const Header: String; var Value: Integer);
begin
  FHeaders := FHeaders + [Header];
end;

Procedure TColumnarDataHeaders.Column(const Header: String; var Value: String);
begin
  FHeaders := FHeaders + [Header];
end;

Procedure TColumnarDataHeaders.Column(const Header: String; var Value: Float64);
begin
  FHeaders := FHeaders + [Header];
end;

Procedure TColumnarDataHeaders.Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                                      const SkipTrailingZeroDecimals: Boolean);
begin
  FHeaders := FHeaders + [Header];
end;

Function TColumnarDataHeaders.Count: Integer;
begin
  Result := Length(FHeaders);
end;

Function TColumnarDataHeaders.HeaderLine(const Separator: Char): String;
begin
  Result := String.Join(Separator,FHeaders);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TColumnarDataFile<DataType>.Create(const FileName: String);
begin
  inherited Create;
  FFileName := FileName;
  FData := DataType.Create;
  Headers := TColumnarDataHeaders.Create(FData);
  Settings := TFormatSettings.Invariant;
end;

Function TColumnarDataFile<DataType>.LineError(const Message: String): Exception;
begin
  Result := Exception.Create(Message + ' at line ' + FLineCount.ToString +
                             ' of ' + ExtractFileName(FFileName));
end;

Destructor TColumnarDataFile<DataType>.Destroy;
begin
  Headers.Free;
  FData.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TColumnarDataReader<DataType>.Create(const FileName: String; const Header: TColumnarDataHeader);
begin
  inherited Create(FileName);
  Parser := TStringParser.Create(FData.Delimiter);
  Reader := TStreamReader.Create(FileName,TEncoding.ANSI,true,65536);
  ReadHeader(Header);
end;

Procedure TColumnarDataReader<DataType>.ReadHeader(const Header: TColumnarDataHeader);
begin
  if Header = hdNone then
    MapByPosition
  else
  begin
    Parser.ReadLine(Reader);
    Inc(FLineCount);
    if Header = hdFree then
      MapByName
    else if SameHeaders then
      MapByPosition
    else
      raise LineError('Invalid header');
  end;
end;

Procedure TColumnarDataReader<DataType>.MapByPosition;
begin
  NColumns := Headers.Count;
  SetLength(Positions,NColumns);
  for var Index := 0 to NColumns-1 do Positions[Index] := Index;
end;

Procedure TColumnarDataReader<DataType>.MapByName;
begin
  NColumns := Parser.Count;
  SetLength(Positions,Headers.Count);
  for var Index := 0 to Headers.Count-1 do
  begin
    var Position := IndexOfHeader(Headers[Index]);
    if Position >= 0 then
      Positions[Index] := Position
    else
      raise LineError('Missing column ' + Headers[Index]);
  end;
end;

Function TColumnarDataReader<DataType>.IndexOfHeader(const Header: String): Integer;
begin
  Result := -1;
  for var Position := 0 to Parser.Count-1 do
  if SameText(Parser.Str[Position],Header) then Exit(Position);
end;

Function TColumnarDataReader<DataType>.SameHeaders: Boolean;
begin
  var Index := 0;
  Result := Parser.Count = Headers.Count;
  while Result and (Index < Headers.Count) do
  begin
    Result := SameText(Parser.Str[Index],Headers[Index]);
    Inc(Index);
  end;
end;

Function TColumnarDataReader<DataType>.NextPosition: Integer;
begin
  Result := Positions[ColumnIndex];
  Inc(ColumnIndex);
end;

Procedure TColumnarDataReader<DataType>.ReadColumns;
begin
  ColumnIndex := 0;
  try
    FData.Iterate(Self);
  except
    on E: EConvertError do raise LineError(E.Message);
  end;
end;

Procedure TColumnarDataReader<DataType>.Column(const Header: String; var Value: Integer);
begin
  Value := Parser.Int[NextPosition];
end;

Procedure TColumnarDataReader<DataType>.Column(const Header: String; var Value: String);
begin
  Value := Parser.Str[NextPosition];
end;

Procedure TColumnarDataReader<DataType>.Column(const Header: String; var Value: Float64);
begin
  Value := StrToFloat(Parser.Str[NextPosition],Settings);
end;

Procedure TColumnarDataReader<DataType>.Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                                               const SkipTrailingZeroDecimals: Boolean);
begin
  Value := StrToFloat(Parser.Str[NextPosition],Settings);
end;

Function TColumnarDataReader<DataType>.Read: Boolean;
begin
  Result := not Reader.EndOfStream;
  if Result then
  begin
    Parser.ReadLine(Reader);
    Inc(FLineCount);
    if Parser.Count = NColumns then
      ReadColumns
    else if (Parser.Count = 0) and Reader.EndOfStream then
      Result := false
    else
      raise LineError(NColumns.ToString + ' columns expected, ' +
                      Parser.Count.ToString + ' found');
  end;
end;

Destructor TColumnarDataReader<DataType>.Destroy;
begin
  Reader.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TColumnarDataWriter<DataType>.Create(const FileName: String; const Header: Boolean);
begin
  inherited Create(FileName);
  Separator := FData.Delimiter.Delimiter;
  TakeStringRules;
  Line := TStringBuilder.Create;
  Writer := TStreamWriter.Create(FileName,false,TEncoding.ANSI,65536);
  Writer.AutoFlush := false;
  if Header then
  begin
    Writer.WriteLine(Headers.HeaderLine(Separator));
    Inc(FLineCount);
  end;
end;

Procedure TColumnarDataWriter<DataType>.TakeStringRules;
// A string column ends at any separator of the parser that reads the line back
// and at a line break, and that parser may drop an empty column
begin
  var Parser := TStringParser.Create(FData.Delimiter);
  StringBreaks := [#13,#10];
  for var Index := 0 to Parser.SeparatorCount-1 do StringBreaks := StringBreaks + [Parser.GetSeparators(Index)];
  DropsEmptyColumns := Parser.ExcludeEmpty;
end;

Procedure TColumnarDataWriter<DataType>.Append(const Value: String);
begin
  if ColumnIndex > 0 then Line.Append(Separator);
  Line.Append(Value);
  Inc(ColumnIndex);
end;

Function TColumnarDataWriter<DataType>.WithoutTrailingZeroDecimals(const Value: Float64; const NDecimals: Byte): String;
// FormatFloat with the mask '0.###...', except for a nonzero value that rounds
// to zero: FormatFloat writes it as '0.0...', this as '0'
begin
  var Mask: String := '0';
  if NDecimals > 0 then Mask := Mask + '.' + StringOfChar('#',NDecimals);
  Result := FormatFloat(Mask,Value,Settings);
  if StrToFloat(Result,Settings) = 0 then Result := '0';
end;

Procedure TColumnarDataWriter<DataType>.Column(const Header: String; var Value: Integer);
begin
  Append(Value.ToString);
end;

Procedure TColumnarDataWriter<DataType>.Column(const Header: String; var Value: String);
// A string the reader would split or drop would shift the columns of the line
begin
  if Value.IndexOfAny(StringBreaks) < 0 then
    if (Value <> '') or not DropsEmptyColumns then
      Append(Value)
    else
      raise LineError('Column ' + Header + ' is empty, which the delimiter does not allow')
  else
    raise LineError('Column ' + Header + ' holds a separator or a line break');
end;

Procedure TColumnarDataWriter<DataType>.Column(const Header: String; var Value: Float64);
begin
  Append(FloatToStr(Value,Settings));
end;

Procedure TColumnarDataWriter<DataType>.Column(const Header: String; var Value: Float64; const NDecimals: Byte;
                                               const SkipTrailingZeroDecimals: Boolean);
begin
  if SkipTrailingZeroDecimals then
    Append(WithoutTrailingZeroDecimals(Value,NDecimals))
  else
    Append(FloatToStrF(Value,ffFixed,15,NDecimals,Settings));
end;

Procedure TColumnarDataWriter<DataType>.Write;
begin
  Inc(FLineCount);
  ColumnIndex := 0;
  Line.Clear;
  FData.Iterate(Self);
  Writer.WriteLine(Line.ToString);
end;

Destructor TColumnarDataWriter<DataType>.Destroy;
begin
  Writer.Free;
  Line.Free;
  inherited Destroy;
end;

end.
