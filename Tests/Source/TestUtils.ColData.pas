unit TestUtils.ColData;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

// ColData tests: the reader passes a free header line over and maps the
// columns by position, or maps them by the names of a header line, as the
// row class states, the writer writes the declared decimals, written rows read
// back unchanged, a row class sets the delimiter and describes its file when
// created from its class, a string reads back whole and the writer refuses
// one the reader would split or drop, the reader and the writer refuse a row
// its row class does not validate, a malformed line names its line and file,
// and floats take the decimal separator of the format settings, or the one
// their row class states.

Uses
  SysUtils, Classes, IOUtils, DUnitX.TestFramework, Parse, ColData;

Type
  TZoneRow = Class(TColumnarData)
  strict protected
    Procedure IterateColumns; override;
  public
    Zone,Households: Integer;
    Income: Float64;
  end;

  TStrictZoneRow = Class(TZoneRow)
  public
    Function Header: TColumnarDataHeader; override;
  end;

  THeaderNamedZoneRow = Class(TZoneRow)
  public
    Function Header: TColumnarDataHeader; override;
  end;

  TFreeZoneRow = Class(TZoneRow)
  public
    Function Header: TColumnarDataHeader; override;
  end;

  TSemicolonZoneRow = Class(TStrictZoneRow)
  public
    Function Delimiter: TDelimiter; override;
  end;

  TCommaZoneRow = Class(TZoneRow)
  public
    Function DecimalSeparator: Char; override;
  end;

  TInhabitedZoneRow = Class(TZoneRow)
  // A zone with households has an income
  protected
    Procedure Validate; override;
  end;

  TNamedZoneRow = Class(TStrictZoneRow)
  strict protected
    Procedure IterateColumns; override;
  public
    Name: String;
  end;

  TSpaceNamedZoneRow = Class(TNamedZoneRow)
  public
    Function Delimiter: TDelimiter; override;
  end;

  TFactorRow = Class(TColumnarData)
  strict protected
    Procedure IterateColumns; override;
  public
    Count,Factor: Float64;
  end;

  [TestFixture]
  TColumnarDataTests = Class
  private
    FileName: String;
    Procedure WriteLines(const Lines: TArray<String>);
    Function ReadError<RowType: TColumnarData, constructor>: String;
    Function LineOf(const Error: String; const Line: Integer): Boolean;
    Procedure CheckIncomeWithAComma<RowType: TZoneRow, constructor>;
    Function NameWriteError<RowType: TNamedZoneRow, constructor>(const Name: String): String;
  public
    [Setup] Procedure Setup;
    [TearDown] Procedure TearDown;
    [Test] Procedure ReaderMapsTheColumnsByPosition;
    [Test] Procedure WriterWritesTheDeclaredDecimals;
    [Test] Procedure WriterSkipsTrailingZeroDecimals;
    [Test] Procedure WriterWritesRealsWithoutDecimalsInFull;
    [Test] Procedure WriterWritesTheHeader;
    [Test] Procedure WrittenRowsReadBack;
    [Test] Procedure FloatsFollowTheFormatSettings;
    [Test] Procedure RowClassSetsTheDecimalSeparator;
    [Test] Procedure RowClassSetsTheDelimiter;
    [Test] Procedure RowClassDescribesItsFile;
    [Test] Procedure StringsReadBackWhole;
    [Test] Procedure StringWithTheDelimiterRaises;
    [Test] Procedure SpaceDelimitedStringWithATabRaises;
    [Test] Procedure SpaceDelimitedEmptyStringRaises;
    [Test] Procedure ReaderRaisesForAnInvalidRow;
    [Test] Procedure WriterRaisesForAnInvalidRow;
    [Test] Procedure WrongColumnCountNamesTheLine;
    [Test] Procedure InvalidNumberNamesTheLine;
    [Test] Procedure EmptyLineInsideTheFileRaises;
    [Test] Procedure EmptyLastLineEndsTheFile;
    [Test] Procedure FreeHeaderIsPassedOver;
    [Test] Procedure NamedHeaderMapsTheColumnsByName;
    [Test] Procedure NamedHeaderRequiresEveryColumn;
    [Test] Procedure StrictHeaderRequiresTheColumnsInOrder;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TZoneRow.IterateColumns;
begin
  Column('Zone',Zone);
  Column('Households',Households);
  Column('Income',Income,2);
end;

////////////////////////////////////////////////////////////////////////////////

Function TStrictZoneRow.Header: TColumnarDataHeader;
begin
  Result := hdStrict;
end;

////////////////////////////////////////////////////////////////////////////////

Function THeaderNamedZoneRow.Header: TColumnarDataHeader;
begin
  Result := hdNamed;
end;

////////////////////////////////////////////////////////////////////////////////

Function TFreeZoneRow.Header: TColumnarDataHeader;
begin
  Result := hdFree;
end;

////////////////////////////////////////////////////////////////////////////////

Function TSemicolonZoneRow.Delimiter: TDelimiter;
begin
  Result := Semicolon;
end;

////////////////////////////////////////////////////////////////////////////////

Function TCommaZoneRow.DecimalSeparator: Char;
begin
  Result := ',';
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TInhabitedZoneRow.Validate;
begin
  if (Households = 0) or (Income > 0) then
    inherited Validate
  else
    raise EInvalidColumnarData.Create('Zone ' + Zone.ToString + ' has households but no income');
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TNamedZoneRow.IterateColumns;
begin
  inherited IterateColumns;
  Column('Name',Name);
end;

////////////////////////////////////////////////////////////////////////////////

Function TSpaceNamedZoneRow.Delimiter: TDelimiter;
begin
  Result := Space;
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TFactorRow.IterateColumns;
begin
  Column('Count',Count,1,true);
  Column('Factor',Factor);
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TColumnarDataTests.WriteLines(const Lines: TArray<String>);
begin
  TFile.WriteAllLines(FileName,Lines,TEncoding.ANSI);
end;

Function TColumnarDataTests.ReadError<RowType>: String;
begin
  Result := '';
  try
    var Reader := TColumnarDataReader<RowType>.Create(FileName);
    try
      while Reader.Read do;
    finally
      Reader.Free;
    end;
  except
    on E: Exception do Result := E.Message;
  end;
end;

Function TColumnarDataTests.LineOf(const Error: String; const Line: Integer): Boolean;
begin
  Result := Error.EndsWith(' at line ' + Line.ToString + ' of ' + ExtractFileName(FileName));
end;

Function TColumnarDataTests.NameWriteError<RowType>(const Name: String): String;
begin
  Result := '';
  var Writer := TColumnarDataWriter<RowType>.Create(FileName);
  try
    Writer.Data.Name := Name;
    try
      Writer.Write;
    except
      on E: Exception do Result := E.Message;
    end;
  finally
    Writer.Free;
  end;
end;

Procedure TColumnarDataTests.Setup;
begin
  FileName := TPath.GetTempFileName;
end;

Procedure TColumnarDataTests.TearDown;
begin
  TFile.Delete(FileName);
end;

Procedure TColumnarDataTests.ReaderMapsTheColumnsByPosition;
begin
  WriteLines(['3'#9'120'#9'2450.5','4'#9'80'#9'1900']);
  var Reader := TColumnarDataReader<TZoneRow>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'The first line reads');
    Assert.AreEqual<Integer>(3,Reader.Data.Zone,'Zone');
    Assert.AreEqual<Integer>(120,Reader.Data.Households,'Households');
    Assert.AreEqual(2450.5,Reader.Data.Income,1E-12,'Income');
    Assert.IsTrue(Reader.Read,'The second line reads');
    Assert.AreEqual(1900.0,Reader.Data.Income,1E-12,'An integral real');
    Assert.IsFalse(Reader.Read,'No further lines');
    Assert.AreEqual<Integer>(2,Reader.LineCount,'Lines read');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.WriterWritesTheDeclaredDecimals;
begin
  var Writer := TColumnarDataWriter<TZoneRow>.Create(FileName);
  try
    Writer.Data.Zone := 3;
    Writer.Data.Households := 120;
    Writer.Data.Income := 2450.456;
    Writer.Write;
  finally
    Writer.Free;
  end;
  var Lines := TFile.ReadAllLines(FileName);
  Assert.AreEqual<Integer>(1,Length(Lines),'One line');
  Assert.AreEqual('3'#9'120'#9'2450.46',Lines[0],'Integers as they are, reals rounded');
end;

Procedure TColumnarDataTests.WriterSkipsTrailingZeroDecimals;
Const
  Counts: array[0..5] of Float64 = (437.0,436.96,12.34,0.25,-0.04,0.0);
  Expected: array[0..5] of String = ('437','437','12.3','0.3','0','0');
begin
  var Writer := TColumnarDataWriter<TFactorRow>.Create(FileName);
  try
    for var Index := 0 to High(Counts) do
    begin
      Writer.Data.Count := Counts[Index];
      Writer.Write;
    end;
  finally
    Writer.Free;
  end;
  var Lines := TFile.ReadAllLines(FileName);
  for var Index := 0 to High(Counts) do
  Assert.AreEqual(Expected[Index]+#9'0',Lines[Index],'Count ' + Expected[Index]);
end;

Procedure TColumnarDataTests.WriterWritesRealsWithoutDecimalsInFull;
Const
  Factors: array[0..2] of Float64 = (0.209376618194576,-0.000149736735588604,3.0);
  Expected: array[0..2] of String = ('0.209376618194576','-0.000149736735588604','3');
begin
  var Writer := TColumnarDataWriter<TFactorRow>.Create(FileName);
  try
    for var Index := 0 to High(Factors) do
    begin
      Writer.Data.Factor := Factors[Index];
      Writer.Write;
    end;
  finally
    Writer.Free;
  end;
  var Lines := TFile.ReadAllLines(FileName);
  var Reader := TColumnarDataReader<TFactorRow>.Create(FileName);
  try
    for var Index := 0 to High(Factors) do
    begin
      Assert.AreEqual('0'#9+Expected[Index],Lines[Index],'Text of factor ' + Expected[Index]);
      Assert.IsTrue(Reader.Read,'Factor ' + Expected[Index] + ' reads');
      Assert.IsTrue(Reader.Data.Factor = Factors[Index],'Factor ' + Expected[Index] + ' reads back');
    end;
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.WriterWritesTheHeader;
begin
  var Writer := TColumnarDataWriter<TStrictZoneRow>.Create(FileName);
  Writer.Free;
  var Lines := TFile.ReadAllLines(FileName);
  Assert.AreEqual<Integer>(1,Length(Lines),'The header line only');
  Assert.AreEqual('Zone'#9'Households'#9'Income',Lines[0],'The headers of the columns');
end;

Procedure TColumnarDataTests.WrittenRowsReadBack;
begin
  var Writer := TColumnarDataWriter<TStrictZoneRow>.Create(FileName);
  try
    for var Zone := 1 to 3 do
    begin
      Writer.Data.Zone := Zone;
      Writer.Data.Households := 10*Zone;
      Writer.Data.Income := 0.25*Zone;
      Writer.Write;
    end;
  finally
    Writer.Free;
  end;
  var Reader := TColumnarDataReader<TStrictZoneRow>.Create(FileName);
  try
    for var Zone := 1 to 3 do
    begin
      Assert.IsTrue(Reader.Read,'Row ' + Zone.ToString + ' reads');
      Assert.AreEqual<Integer>(Zone,Reader.Data.Zone,'Zone');
      Assert.AreEqual<Integer>(10*Zone,Reader.Data.Households,'Households');
      Assert.AreEqual(0.25*Zone,Reader.Data.Income,1E-12,'Income');
    end;
    Assert.IsFalse(Reader.Read,'Three rows');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.CheckIncomeWithAComma<RowType>;
// Writes an income and reads it back, both with a comma as decimal separator
begin
  var Writer := TColumnarDataWriter<RowType>.Create(FileName);
  try
    Writer.Data.Income := 2450.456;
    Writer.Write;
  finally
    Writer.Free;
  end;
  Assert.AreEqual('0'#9'0'#9'2450,46',TFile.ReadAllLines(FileName)[0],'Written with a comma');
  var Reader := TColumnarDataReader<RowType>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'The line reads');
    Assert.AreEqual(2450.46,Reader.Data.Income,1E-12,'Read with a comma');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.FloatsFollowTheFormatSettings;
begin
  var Separator := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := ',';
  try
    CheckIncomeWithAComma<TZoneRow>;
  finally
    FormatSettings.DecimalSeparator := Separator;
  end;
end;

Procedure TColumnarDataTests.RowClassSetsTheDecimalSeparator;
begin
  Assert.IsTrue(FormatSettings.DecimalSeparator = '.','The format settings hold a point');
  CheckIncomeWithAComma<TCommaZoneRow>;
  Assert.IsTrue(FormatSettings.DecimalSeparator = '.','The format settings are unchanged');
end;

Procedure TColumnarDataTests.RowClassSetsTheDelimiter;
begin
  var Writer := TColumnarDataWriter<TSemicolonZoneRow>.Create(FileName);
  try
    Writer.Data.Zone := 7;
    Writer.Data.Income := 1.5;
    Writer.Write;
  finally
    Writer.Free;
  end;
  Assert.AreEqual('7;0;1.50',TFile.ReadAllLines(FileName)[1],'Semicolon separated');
  var Reader := TColumnarDataReader<TSemicolonZoneRow>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'The line reads');
    Assert.AreEqual<Integer>(7,Reader.Data.Zone,'Zone');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.RowClassDescribesItsFile;
begin
  var RowClass: TColumnarDataClass := TSemicolonZoneRow;
  var Row := RowClass.Create;
  var Headers := TColumnarDataHeaders.Create(Row);
  try
    Assert.AreEqual('Zone,Households,Income',Headers.HeaderLine(','),'The headers');
    Assert.IsTrue(Row.Header = hdStrict,'The header line');
    Assert.IsTrue(Row.Delimiter = Semicolon,'The delimiter');
  finally
    Headers.Free;
    Row.Free;
  end;
end;

Procedure TColumnarDataTests.StringsReadBackWhole;
begin
  var Writer := TColumnarDataWriter<TNamedZoneRow>.Create(FileName);
  try
    Writer.Data.Zone := 3;
    Writer.Data.Name := 'Den Haag Centraal';
    Writer.Write;
  finally
    Writer.Free;
  end;
  Assert.AreEqual('3'#9'0'#9'0.00'#9'Den Haag Centraal',TFile.ReadAllLines(FileName)[1],'The string as it is');
  var Reader := TColumnarDataReader<TNamedZoneRow>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'The line reads');
    Assert.AreEqual('Den Haag Centraal',Reader.Data.Name,'With its spaces');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.StringWithTheDelimiterRaises;
begin
  var Error := NameWriteError<TNamedZoneRow>('Den Haag'#9'Centraal');
  Assert.IsTrue(Error.StartsWith('Column Name holds a separator'),'The column');
  Assert.IsTrue(LineOf(Error,2),'The line being written and the file');
end;

Procedure TColumnarDataTests.SpaceDelimitedStringWithATabRaises;
begin
  var Error := NameWriteError<TSpaceNamedZoneRow>('Den'#9'Haag');
  Assert.IsTrue(Error.StartsWith('Column Name holds a separator'),'The space delimiter also splits on tabs');
end;

Procedure TColumnarDataTests.SpaceDelimitedEmptyStringRaises;
begin
  Assert.IsTrue(NameWriteError<TSpaceNamedZoneRow>('').StartsWith('Column Name is empty'),'The space delimiter drops empty columns');
  Assert.AreEqual('',NameWriteError<TNamedZoneRow>(''),'The tab delimiter keeps them');
end;

Procedure TColumnarDataTests.ReaderRaisesForAnInvalidRow;
begin
  WriteLines(['3'#9'120'#9'2450.5','4'#9'0'#9'0','5'#9'80'#9'0']);
  var Error := '';
  var Reader := TColumnarDataReader<TInhabitedZoneRow>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'A zone with households and income');
    Assert.IsTrue(Reader.Read,'A zone without households or income');
    try
      Reader.Read;
    except
      on E: Exception do Error := E.Message;
    end;
  finally
    Reader.Free;
  end;
  Assert.IsTrue(Error.StartsWith('Zone 5 has households but no income'),'The message of the row class');
  Assert.IsTrue(LineOf(Error,3),'The line and file');
end;

Procedure TColumnarDataTests.WriterRaisesForAnInvalidRow;
begin
  var Error := '';
  var Writer := TColumnarDataWriter<TInhabitedZoneRow>.Create(FileName);
  try
    Writer.Data.Zone := 5;
    Writer.Data.Households := 80;
    try
      Writer.Write;
    except
      on E: Exception do Error := E.Message;
    end;
  finally
    Writer.Free;
  end;
  Assert.IsTrue(LineOf(Error,1),'The line being written and the file');
  Assert.AreEqual<Integer>(0,Length(TFile.ReadAllLines(FileName)),'Nothing is written');
end;

Procedure TColumnarDataTests.WrongColumnCountNamesTheLine;
begin
  WriteLines(['3'#9'120'#9'2450.5','4'#9'80']);
  var Error := ReadError<TZoneRow>;
  Assert.IsTrue(Error.StartsWith('3 columns expected, 2 found'),'The counts');
  Assert.IsTrue(LineOf(Error,2),'The line and file');
end;

Procedure TColumnarDataTests.InvalidNumberNamesTheLine;
begin
  WriteLines(['3'#9'120'#9'2450.5','4'#9'many'#9'1900']);
  Assert.IsTrue(LineOf(ReadError<TZoneRow>,2),'The line and file');
end;

Procedure TColumnarDataTests.EmptyLineInsideTheFileRaises;
begin
  WriteLines(['3'#9'120'#9'2450.5','','4'#9'80'#9'1900']);
  var Error := ReadError<TZoneRow>;
  Assert.IsTrue(Error.StartsWith('3 columns expected, 0 found'),'The empty line');
  Assert.IsTrue(LineOf(Error,2),'The line and file');
end;

Procedure TColumnarDataTests.EmptyLastLineEndsTheFile;
begin
  WriteLines(['3'#9'120'#9'2450.5','']);
  Assert.AreEqual('',ReadError<TZoneRow>,'No error');
end;

Procedure TColumnarDataTests.FreeHeaderIsPassedOver;
begin
  WriteLines(['Area'#9'Dwellings','3'#9'120'#9'2450.5','4'#9'80'#9'1900']);
  var Reader := TColumnarDataReader<TFreeZoneRow>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'The line after the header reads');
    Assert.AreEqual<Integer>(3,Reader.Data.Zone,'The first declared column');
    Assert.AreEqual<Integer>(120,Reader.Data.Households,'The second, under another name');
    Assert.AreEqual(2450.5,Reader.Data.Income,1E-12,'The third, without a name');
    Assert.IsTrue(Reader.Read,'The next line reads');
    Assert.IsFalse(Reader.Read,'Two rows');
    Assert.AreEqual<Integer>(3,Reader.LineCount,'The header counts as a line');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.NamedHeaderMapsTheColumnsByName;
begin
  WriteLines(['INCOME'#9'Name'#9'Zone'#9'Households','2450.5'#9'Centre'#9'3'#9'120']);
  var Reader := TColumnarDataReader<THeaderNamedZoneRow>.Create(FileName);
  try
    Assert.IsTrue(Reader.Read,'The line reads');
    Assert.AreEqual<Integer>(3,Reader.Data.Zone,'Past the extra column');
    Assert.AreEqual<Integer>(120,Reader.Data.Households,'Households');
    Assert.AreEqual(2450.5,Reader.Data.Income,1E-12,'Headers compare without case');
    Assert.AreEqual<Integer>(2,Reader.LineCount,'The header counts as a line');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.NamedHeaderRequiresEveryColumn;
begin
  WriteLines(['Zone'#9'Income']);
  var Error := ReadError<THeaderNamedZoneRow>;
  Assert.IsTrue(Error.StartsWith('Missing column Households'),'The missing column');
  Assert.IsTrue(LineOf(Error,1),'The header line and file');
end;

Procedure TColumnarDataTests.StrictHeaderRequiresTheColumnsInOrder;
begin
  WriteLines(['Zone'#9'Households'#9'Income','3'#9'120'#9'2450.5']);
  Assert.AreEqual('',ReadError<TStrictZoneRow>,'The declared headers read');
  WriteLines(['Households'#9'Zone'#9'Income','3'#9'120'#9'2450.5']);
  var Error := ReadError<TStrictZoneRow>;
  Assert.IsTrue(Error.StartsWith('Invalid header'),'Swapped headers');
  Assert.IsTrue(LineOf(Error,1),'The header line and file');
end;

initialization
  TDUnitX.RegisterTestFixture(TColumnarDataTests);
end.
