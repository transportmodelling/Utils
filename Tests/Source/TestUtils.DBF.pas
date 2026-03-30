unit TestUtils.DBF;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, IOUtils, Variants, DUnitX.TestFramework, DBF;

Type
  [TestFixture]
  TDBFFieldTests = class
  public
    // Field name validation
    [Test] Procedure TestFieldNameEmpty;
    [Test] Procedure TestFieldNameTooLong;
    [Test] Procedure TestFieldNameInvalidChar;
    [Test] Procedure TestFieldNameValid;
    // Field type validation
    [Test] Procedure TestFieldTypeUnsupported;
    // Field length validation
    [Test] Procedure TestFieldLengthZero;
    [Test] Procedure TestFieldLengthCharTooLong;
    [Test] Procedure TestFieldLengthDateWrong;
    // Decimal count validation
    [Test] Procedure TestDecimalCountOnCharField;
    [Test] Procedure TestDecimalCountExceedsLength;
  end;

  [TestFixture]
  TDBFWriterTests = class
  private
    FTempFile: String;
  public
    [Setup]    Procedure Setup;
    [TearDown] Procedure TearDown;
    // Writer basic behaviour
    [Test] Procedure TestWriterCreatesFile;
    [Test] Procedure TestWriterAppendRecordByIndex;
    [Test] Procedure TestWriterAppendRecordByValues;
    [Test] Procedure TestWriterFieldCountMismatch;
    [Test] Procedure TestWriterDuplicateField;
    [Test] Procedure TestWriterTruncateAllowed;
    [Test] Procedure TestWriterTruncateDisallowed;
  end;

  [TestFixture]
  TDBFReaderTests = class
  private
    FFixture: String;
  public
    [Setup] Procedure Setup;
    // Static-fixture reader tests
    [Test] Procedure TestReaderFieldCount;
    [Test] Procedure TestReaderFieldNames;
    [Test] Procedure TestReaderFieldTypes;
    [Test] Procedure TestReaderRecordCount;
    [Test] Procedure TestReaderReadAllRecords;
    [Test] Procedure TestReaderFieldValues;
    // IndexOf / helpers
    [Test] Procedure TestIndexOfFound;
    [Test] Procedure TestIndexOfNotFound;
    [Test] Procedure TestIndexOfMustExistRaises;
    [Test] Procedure TestGetValues;
    [Test] Procedure TestGetPairs;
  end;

  [TestFixture]
  TDBFRoundTripTests = class
  private
    FTempFile: String;
    Procedure WriteAndRead(const Fields: array of TDBFField;
                           const Values: array of Variant;
                           out ReadValues: TArray<Variant>);
  public
    [Setup]    Procedure Setup;
    [TearDown] Procedure TearDown;
    // Round-trip per field type
    [Test] Procedure TestRoundTripCharField;
    [Test] Procedure TestRoundTripNumericIntField;
    [Test] Procedure TestRoundTripNumericFloatField;
    [Test] Procedure TestRoundTripLogicalField;
    [Test] Procedure TestRoundTripNullField;
    [Test] Procedure TestRoundTripMultipleRecords;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

{ TDBFFieldTests }

Procedure TDBFFieldTests.TestFieldNameEmpty;
begin
  Assert.WillRaiseAny(procedure begin TDBFField.Create('', 'C', 10, 0) end);
end;

Procedure TDBFFieldTests.TestFieldNameTooLong;
begin
  Assert.WillRaiseAny(procedure begin TDBFField.Create('TOOLONGNAME1', 'C', 10, 0) end);
end;

Procedure TDBFFieldTests.TestFieldNameInvalidChar;
begin
  Assert.WillRaiseAny(procedure begin TDBFField.Create('BAD NAME', 'C', 10, 0) end);
end;

Procedure TDBFFieldTests.TestFieldNameValid;
begin
  // Underscore and digits are allowed; no exception expected
  var F := TDBFField.Create('MY_FIELD1', 'C', 10, 0);
  Assert.AreEqual('MY_FIELD1', F.FieldName);
end;

Procedure TDBFFieldTests.TestFieldTypeUnsupported;
begin
  Assert.WillRaiseAny(procedure begin TDBFField.Create('FLD', 'X', 10, 0) end);
end;

Procedure TDBFFieldTests.TestFieldLengthZero;
begin
  Assert.WillRaiseAny(
    procedure
    begin
      var F := TDBFField.Create('FLD', 'C', 10, 0);
      F.FieldLength := 0;
    end);
end;

Procedure TDBFFieldTests.TestFieldLengthCharTooLong;
begin
  Assert.WillRaiseAny(
    procedure
    begin
      var F := TDBFField.Create('FLD', 'C', 10, 0);
      F.FieldLength := 255;
    end);
end;

Procedure TDBFFieldTests.TestFieldLengthDateWrong;
begin
  Assert.WillRaiseAny(
    procedure
    begin
      var F := TDBFField.Create('DT', 'D', 8, 0);
      F.FieldLength := 10;
    end);
end;

Procedure TDBFFieldTests.TestDecimalCountOnCharField;
begin
  Assert.WillRaiseAny(
    procedure
    begin
      var F := TDBFField.Create('FLD', 'C', 10, 0);
      F.DecimalCount := 2;
    end);
end;

Procedure TDBFFieldTests.TestDecimalCountExceedsLength;
begin
  Assert.WillRaiseAny(
    procedure
    begin
      // N,6,0 is valid; then try to set DecimalCount=5 -> needs length>=7
      var F := TDBFField.Create('FLD', 'N', 6, 0);
      F.DecimalCount := 5;
    end);
end;

////////////////////////////////////////////////////////////////////////////////

{ TDBFWriterTests }

Procedure TDBFWriterTests.Setup;
begin
  FTempFile := TPath.GetTempFileName;
end;

Procedure TDBFWriterTests.TearDown;
begin
  if FileExists(FTempFile) then DeleteFile(FTempFile);
end;

Procedure TDBFWriterTests.TestWriterCreatesFile;
begin
  var W := TDBFWriter.Create(FTempFile, [TDBFField.Create('ID','N',4,0)]);
  W.Free;
  Assert.IsTrue(FileExists(FTempFile), 'File should exist after writer is freed');
end;

Procedure TDBFWriterTests.TestWriterAppendRecordByIndex;
begin
  var W := TDBFWriter.Create(FTempFile, [TDBFField.Create('ID','N',4,0)]);
  try
    W[0] := 42;
    W.AppendRecord;
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    Assert.AreEqual(1, R.RecordCount);
    R.NextRecord;
    Assert.AreEqual(42, Integer(R[0]));
  finally
    R.Free;
  end;
end;

Procedure TDBFWriterTests.TestWriterAppendRecordByValues;
begin
  var W := TDBFWriter.Create(FTempFile, [TDBFField.Create('ID','N',4,0)]);
  try
    W.AppendRecord([Variant(7)]);
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    Assert.AreEqual(7, Integer(R[0]));
  finally
    R.Free;
  end;
end;

Procedure TDBFWriterTests.TestWriterFieldCountMismatch;
begin
  var W := TDBFWriter.Create(FTempFile, [TDBFField.Create('ID','N',4,0)]);
  try
    Assert.WillRaiseAny(
      procedure begin W.AppendRecord([Variant(1), Variant(2)]) end);
  finally
    W.Free;
  end;
end;

Procedure TDBFWriterTests.TestWriterDuplicateField;
begin
  Assert.WillRaiseAny(
    procedure
    begin
      var W := TDBFWriter.Create(FTempFile,
        [TDBFField.Create('ID','N',4,0), TDBFField.Create('ID','C',10,0)]);
      W.Free;
    end);
end;

Procedure TDBFWriterTests.TestWriterTruncateAllowed;
begin
  var W := TDBFWriter.Create(FTempFile,
    [TDBFField.Create('NAME','C',5,0,{Truncate=}true)]);
  try
    W.AppendRecord([Variant('Hello World')]);  // 11 chars -> truncated to 5
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    Assert.AreEqual('Hello', String(R[0]));
  finally
    R.Free;
  end;
end;

Procedure TDBFWriterTests.TestWriterTruncateDisallowed;
begin
  var W := TDBFWriter.Create(FTempFile,
    [TDBFField.Create('NAME','C',5,0,{Truncate=}false)]);
  try
    Assert.WillRaiseAny(
      procedure begin W.AppendRecord([Variant('Hello World')]) end);
  finally
    W.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

{ TDBFReaderTests }

Procedure TDBFReaderTests.Setup;
begin
  // Fixture lives at Tests\Data\sample.dbf; exe is in Tests\Source\
  FFixture := TPath.Combine(
    TPath.Combine(ExtractFileDir(ParamStr(0)), '..\Data'), 'sample.dbf');
  FFixture := TPath.GetFullPath(FFixture);
end;

Procedure TDBFReaderTests.TestReaderFieldCount;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.AreEqual(4, R.FieldCount);
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestReaderFieldNames;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.AreEqual('ID',     R.FieldNames[0]);
    Assert.AreEqual('NAME',   R.FieldNames[1]);
    Assert.AreEqual('ACTIVE', R.FieldNames[2]);
    Assert.AreEqual('SCORE',  R.FieldNames[3]);
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestReaderFieldTypes;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.AreEqual('N', R.FieldTypes[0]);
    Assert.AreEqual('C', R.FieldTypes[1]);
    Assert.AreEqual('L', R.FieldTypes[2]);
    Assert.AreEqual('N', R.FieldTypes[3]);
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestReaderRecordCount;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.AreEqual(3, R.RecordCount);
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestReaderReadAllRecords;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.IsTrue(R.NextRecord,  'Record 1 should exist');
    Assert.IsTrue(R.NextRecord,  'Record 2 should exist');
    Assert.IsTrue(R.NextRecord,  'Record 3 should exist');
    Assert.IsFalse(R.NextRecord, 'No record 4');
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestReaderFieldValues;
begin
  var R := TDBFReader.Create(FFixture);
  try
    // Record 1: ID=1, NAME='Alice', ACTIVE=True, SCORE=9.50
    R.NextRecord;
    Assert.AreEqual(1,       Integer(R[0]));
    Assert.AreEqual('Alice', String(R[1]));
    Assert.IsTrue(Boolean(R[2]), 'ACTIVE should be True for record 1');
    Assert.AreEqual(9.50,    Double(R[3]), 0.001);
    // Record 2: ID=2, NAME='Bob', ACTIVE=False, SCORE=7.25
    R.NextRecord;
    Assert.AreEqual(2,       Integer(R[0]));
    Assert.AreEqual('Bob',   String(R[1]));
    Assert.IsFalse(Boolean(R[2]), 'ACTIVE should be False for record 2');
    Assert.AreEqual(7.25,    Double(R[3]), 0.001);
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestIndexOfFound;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.AreEqual(1, R.IndexOf('NAME'));
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestIndexOfNotFound;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.AreEqual(-1, R.IndexOf('MISSING'));
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestIndexOfMustExistRaises;
begin
  var R := TDBFReader.Create(FFixture);
  try
    Assert.WillRaiseAny(procedure begin R.IndexOf('MISSING', true) end);
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestGetValues;
begin
  var R := TDBFReader.Create(FFixture);
  try
    R.NextRecord;
    var V := R.GetValues;
    Assert.AreEqual(4,       Integer(Length(V)));
    Assert.AreEqual(1,       Integer(V[0]));
    Assert.AreEqual('Alice', String(V[1]));
  finally
    R.Free;
  end;
end;

Procedure TDBFReaderTests.TestGetPairs;
begin
  var R := TDBFReader.Create(FFixture);
  try
    R.NextRecord;
    var P := R.GetPairs;
    Assert.AreEqual(4,    Integer(Length(P)));
    Assert.AreEqual('ID', P[0].Key);
    Assert.AreEqual(1,    Integer(P[0].Value));
  finally
    R.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

{ TDBFRoundTripTests }

Procedure TDBFRoundTripTests.Setup;
begin
  FTempFile := TPath.GetTempFileName;
end;

Procedure TDBFRoundTripTests.TearDown;
begin
  if FileExists(FTempFile) then DeleteFile(FTempFile);
end;

Procedure TDBFRoundTripTests.WriteAndRead(const Fields: array of TDBFField;
                                           const Values: array of Variant;
                                           out ReadValues: TArray<Variant>);
begin
  var W := TDBFWriter.Create(FTempFile, Fields);
  try
    W.AppendRecord(Values);
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    ReadValues := R.GetValues;
  finally
    R.Free;
  end;
end;

Procedure TDBFRoundTripTests.TestRoundTripCharField;
begin
  var V: TArray<Variant>;
  WriteAndRead([TDBFField.Create('S','C',10,0)], [Variant('Hello')], V);
  Assert.AreEqual('Hello', String(V[0]));
end;

Procedure TDBFRoundTripTests.TestRoundTripNumericIntField;
begin
  var V: TArray<Variant>;
  WriteAndRead([TDBFField.Create('N','N',6,0)], [Variant(12345)], V);
  Assert.AreEqual(12345, Integer(V[0]));
end;

Procedure TDBFRoundTripTests.TestRoundTripNumericFloatField;
begin
  var V: TArray<Variant>;
  WriteAndRead([TDBFField.Create('F','N',10,3)], [Variant(3.125)], V);
  Assert.AreEqual(3.125, Double(V[0]), 0.0001);
end;

Procedure TDBFRoundTripTests.TestRoundTripLogicalField;
begin
  var V: TArray<Variant>;
  WriteAndRead([TDBFField.Create('L','L',1,0)], [Variant(True)], V);
  Assert.IsTrue(Boolean(V[0]), 'Logical True should round-trip');
end;

Procedure TDBFRoundTripTests.TestRoundTripNullField;
begin
  var V: TArray<Variant>;
  WriteAndRead([TDBFField.Create('N','N',6,0)], [Null], V);
  Assert.IsTrue(VarIsNull(V[0]), 'Null field should read back as Null');
end;

Procedure TDBFRoundTripTests.TestRoundTripMultipleRecords;
begin
  var Fields: TArray<TDBFField>;
  SetLength(Fields, 2);
  Fields[0] := TDBFField.Create('ID','N',4,0);
  Fields[1] := TDBFField.Create('VAL','C',8,0);

  var W := TDBFWriter.Create(FTempFile, Fields);
  try
    W.AppendRecord([Variant(1), Variant('one')]);
    W.AppendRecord([Variant(2), Variant('two')]);
    W.AppendRecord([Variant(3), Variant('three')]);
  finally
    W.Free;
  end;

  var R := TDBFReader.Create(FTempFile);
  try
    Assert.AreEqual(3, R.RecordCount);
    R.NextRecord; Assert.AreEqual(1,       Integer(R[0])); Assert.AreEqual('one',   String(R[1]));
    R.NextRecord; Assert.AreEqual(2,       Integer(R[0])); Assert.AreEqual('two',   String(R[1]));
    R.NextRecord; Assert.AreEqual(3,       Integer(R[0])); Assert.AreEqual('three', String(R[1]));
  finally
    R.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

initialization
  TDUnitX.RegisterTestFixture(TDBFFieldTests);
  TDUnitX.RegisterTestFixture(TDBFWriterTests);
  TDUnitX.RegisterTestFixture(TDBFReaderTests);
  TDUnitX.RegisterTestFixture(TDBFRoundTripTests);

end.
