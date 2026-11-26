unit TestUtils.ColData;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

// ColData tests: the reader maps the columns by position or by header, the
// writer writes the declared decimals, written rows read back unchanged, a row
// class sets the delimiter, a string reads back whole and the writer refuses
// one the reader would split or drop, and a malformed line names its line and
// file.

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

  TSemicolonZoneRow = Class(TZoneRow)
  public
    Function Delimiter: TDelimiter; override;
  end;

  TNamedZoneRow = Class(TZoneRow)
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
    Function ReadError(const Header: TColumnarDataHeader): String;
    Function LineOf(const Error: String; const Line: Integer): Boolean;
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
    [Test] Procedure RowClassSetsTheDelimiter;
    [Test] Procedure StringsReadBackWhole;
    [Test] Procedure StringWithTheDelimiterRaises;
    [Test] Procedure SpaceDelimitedStringWithATabRaises;
    [Test] Procedure SpaceDelimitedEmptyStringRaises;
    [Test] Procedure WrongColumnCountNamesTheLine;
    [Test] Procedure InvalidNumberNamesTheLine;
    [Test] Procedure EmptyLineInsideTheFileRaises;
    [Test] Procedure EmptyLastLineEndsTheFile;
    [Test] Procedure FreeHeaderMapsTheColumnsByName;
    [Test] Procedure FreeHeaderRequiresEveryColumn;
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

Function TSemicolonZoneRow.Delimiter: TDelimiter;
begin
  Result := Semicolon;
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

Function TColumnarDataTests.ReadError(const Header: TColumnarDataHeader): String;
begin
  Result := '';
  try
    var Reader := TColumnarDataReader<TZoneRow>.Create(FileName,Header);
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
  var Writer := TColumnarDataWriter<RowType>.Create(FileName,true);
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
  var Reader := TColumnarDataReader<TZoneRow>.Create(FileName,hdNone);
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
  var Writer := TColumnarDataWriter<TZoneRow>.Create(FileName,false);
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
  var Writer := TColumnarDataWriter<TFactorRow>.Create(FileName,false);
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
  var Writer := TColumnarDataWriter<TFactorRow>.Create(FileName,true);
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
  var Reader := TColumnarDataReader<TFactorRow>.Create(FileName,hdStrict);
  try
    for var Index := 0 to High(Factors) do
    begin
      Assert.AreEqual('0'#9+Expected[Index],Lines[Index+1],'Text of factor ' + Expected[Index]);
      Assert.IsTrue(Reader.Read,'Factor ' + Expected[Index] + ' reads');
      Assert.IsTrue(Reader.Data.Factor = Factors[Index],'Factor ' + Expected[Index] + ' reads back');
    end;
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.WriterWritesTheHeader;
begin
  var Writer := TColumnarDataWriter<TZoneRow>.Create(FileName,true);
  Writer.Free;
  var Lines := TFile.ReadAllLines(FileName);
  Assert.AreEqual<Integer>(1,Length(Lines),'The header line only');
  Assert.AreEqual('Zone'#9'Households'#9'Income',Lines[0],'The headers of the columns');
end;

Procedure TColumnarDataTests.WrittenRowsReadBack;
begin
  var Writer := TColumnarDataWriter<TZoneRow>.Create(FileName,true);
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
  var Reader := TColumnarDataReader<TZoneRow>.Create(FileName,hdStrict);
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

Procedure TColumnarDataTests.RowClassSetsTheDelimiter;
begin
  var Writer := TColumnarDataWriter<TSemicolonZoneRow>.Create(FileName,true);
  try
    Writer.Data.Zone := 7;
    Writer.Data.Income := 1.5;
    Writer.Write;
  finally
    Writer.Free;
  end;
  Assert.AreEqual('7;0;1.50',TFile.ReadAllLines(FileName)[1],'Semicolon separated');
  var Reader := TColumnarDataReader<TSemicolonZoneRow>.Create(FileName,hdStrict);
  try
    Assert.IsTrue(Reader.Read,'The line reads');
    Assert.AreEqual<Integer>(7,Reader.Data.Zone,'Zone');
  finally
    Reader.Free;
  end;
end;

Procedure TColumnarDataTests.StringsReadBackWhole;
begin
  var Writer := TColumnarDataWriter<TNamedZoneRow>.Create(FileName,true);
  try
    Writer.Data.Zone := 3;
    Writer.Data.Name := 'Den Haag Centraal';
    Writer.Write;
  finally
    Writer.Free;
  end;
  Assert.AreEqual('3'#9'0'#9'0.00'#9'Den Haag Centraal',TFile.ReadAllLines(FileName)[1],'The string as it is');
  var Reader := TColumnarDataReader<TNamedZoneRow>.Create(FileName,hdStrict);
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

Procedure TColumnarDataTests.WrongColumnCountNamesTheLine;
begin
  WriteLines(['3'#9'120'#9'2450.5','4'#9'80']);
  var Error := ReadError(hdNone);
  Assert.IsTrue(Error.StartsWith('3 columns expected, 2 found'),'The counts');
  Assert.IsTrue(LineOf(Error,2),'The line and file');
end;

Procedure TColumnarDataTests.InvalidNumberNamesTheLine;
begin
  WriteLines(['3'#9'120'#9'2450.5','4'#9'many'#9'1900']);
  Assert.IsTrue(LineOf(ReadError(hdNone),2),'The line and file');
end;

Procedure TColumnarDataTests.EmptyLineInsideTheFileRaises;
begin
  WriteLines(['3'#9'120'#9'2450.5','','4'#9'80'#9'1900']);
  var Error := ReadError(hdNone);
  Assert.IsTrue(Error.StartsWith('3 columns expected, 0 found'),'The empty line');
  Assert.IsTrue(LineOf(Error,2),'The line and file');
end;

Procedure TColumnarDataTests.EmptyLastLineEndsTheFile;
begin
  WriteLines(['3'#9'120'#9'2450.5','']);
  Assert.AreEqual('',ReadError(hdNone),'No error');
end;

Procedure TColumnarDataTests.FreeHeaderMapsTheColumnsByName;
begin
  WriteLines(['INCOME'#9'Name'#9'Zone'#9'Households','2450.5'#9'Centre'#9'3'#9'120']);
  var Reader := TColumnarDataReader<TZoneRow>.Create(FileName,hdFree);
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

Procedure TColumnarDataTests.FreeHeaderRequiresEveryColumn;
begin
  WriteLines(['Zone'#9'Income']);
  var Error := ReadError(hdFree);
  Assert.IsTrue(Error.StartsWith('Missing column Households'),'The missing column');
  Assert.IsTrue(LineOf(Error,1),'The header line and file');
end;

Procedure TColumnarDataTests.StrictHeaderRequiresTheColumnsInOrder;
begin
  WriteLines(['Zone'#9'Households'#9'Income','3'#9'120'#9'2450.5']);
  Assert.AreEqual('',ReadError(hdStrict),'The declared headers read');
  WriteLines(['Households'#9'Zone'#9'Income','3'#9'120'#9'2450.5']);
  var Error := ReadError(hdStrict);
  Assert.IsTrue(Error.StartsWith('Invalid header'),'Swapped headers');
  Assert.IsTrue(LineOf(Error,1),'The header line and file');
end;

initialization
  TDUnitX.RegisterTestFixture(TColumnarDataTests);
end.
