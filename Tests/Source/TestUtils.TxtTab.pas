unit TestUtils.TxtTab;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, BaseDir, Parse, TxtTab;

Type
  [TestFixture]
  TTextTableReaderTests = class
  private
    function DataFile: TFileName;
  public
    // Header parsing
    [Test] procedure TestFieldCount;
    [Test] procedure TestFieldNames;
    // IndexOf
    [Test] procedure TestIndexOfFound;
    [Test] procedure TestIndexOfNotFound;
    [Test] procedure TestIndexOfCaseInsensitive;
    [Test] procedure TestIndexOfCaseSensitiveHit;
    [Test] procedure TestIndexOfCaseSensitiveMiss;
    [Test] procedure TestIndexOfMustExistRaises;
    // Data rows
    [Test] procedure TestReadLineReturnsTrueWhileRows;
    [Test] procedure TestReadLineReturnsFalseAtEnd;
    [Test] procedure TestLineCount;
    [Test] procedure TestValuesByIndex;
    [Test] procedure TestValuesAsString;
    [Test] procedure TestValuesAsInteger;
    [Test] procedure TestValuesAsFloat;
    // FileName property
    [Test] procedure TestFileNameProperty;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

function TTextTableReaderTests.DataFile: TFileName;
begin
  var BaseDirectory: TBaseDirectory;
  BaseDirectory.SetExeDir;
  Result := BaseDirectory.AbsolutePath('..\Data\sample.txt');
end;

procedure TTextTableReaderTests.TestFieldCount;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual(3, R.FieldCount);
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestFieldNames;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual('Name',  R.Names[0]);
    Assert.AreEqual('Age',   R.Names[1]);
    Assert.AreEqual('Score', R.Names[2]);
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestIndexOfFound;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual(1, R.IndexOf('Age'));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestIndexOfNotFound;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual(-1, R.IndexOf('Missing'));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestIndexOfCaseInsensitive;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual(0, R.IndexOf('name'));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestIndexOfCaseSensitiveHit;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual(2, R.IndexOf('Score', false, true));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestIndexOfCaseSensitiveMiss;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.AreEqual(-1, R.IndexOf('score', false, true));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestIndexOfMustExistRaises;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.WillRaiseAny(procedure begin R.IndexOf('Missing', true); end);
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestReadLineReturnsTrueWhileRows;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    Assert.IsTrue(R.ReadLine, 'First data row should return True');
    Assert.IsTrue(R.ReadLine, 'Second data row should return True');
    Assert.IsTrue(R.ReadLine, 'Third data row should return True');
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestReadLineReturnsFalseAtEnd;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    R.ReadLine; R.ReadLine; R.ReadLine;
    Assert.IsFalse(R.ReadLine, 'Should return False after last row');
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestLineCount;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    while R.ReadLine do;
    Assert.AreEqual(3, R.LineCount);
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestValuesByIndex;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    R.ReadLine;
    Assert.AreEqual('Alice', string(R[0]));
    Assert.AreEqual('30',    string(R[1]));
    Assert.AreEqual('8.5',   string(R[2]));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestValuesAsString;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    R.ReadLine; R.ReadLine; // skip to Bob
    Assert.AreEqual('Bob', string(R[0]));
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestValuesAsInteger;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    R.ReadLine;
    var Age: Integer := R[1];
    Assert.AreEqual(30, Age);
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestValuesAsFloat;
begin
  var R := TTextTableReader.Create(DataFile);
  try
    R.ReadLine;
    var Score: Float64 := R[2];
    Assert.AreEqual(8.5, Score, 1e-9);
  finally
    R.Free;
  end;
end;

procedure TTextTableReaderTests.TestFileNameProperty;
begin
  var FileName := DataFile;
  var R := TTextTableReader.Create(FileName);
  try
    Assert.AreEqual(string(FileName), R.FileName);
  finally
    R.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTextTableReaderTests);

end.
