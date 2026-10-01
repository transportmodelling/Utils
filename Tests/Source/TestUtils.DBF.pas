unit TestUtils.DBF;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  Classes, SysUtils, IOUtils, Variants, DUnitX.TestFramework, DBF;

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
    [Test] Procedure TestWriterNumericTruncateDecimals;
    [Test] Procedure TestWriterNumericTruncateDecimalPoint;
    [Test] Procedure TestWriterNumericTruncateIntegerPart;
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

  [TestFixture]
  TDBFEncodingTests = class
  private
    FTempFile: String;
    Function Bytes(const Values: array of Byte): TBytes;
    // Writes a file with one record of character fields F1, F2, ..., each
    // value padded with spaces (or cut off) to its field length
    Procedure WriteFile(const LanguageDriver: Byte;
                        const FieldLengths: array of Byte;
                        const Values: array of TBytes);
    Function ReadFirstValue(const Encoding: TEncoding = nil): String;
  public
    [Setup]    Procedure Setup;
    [TearDown] Procedure TearDown;
    // Undeclared encoding: detected per value
    [Test] Procedure TestUndeclaredUTF8;
    [Test] Procedure TestUndeclaredAnsi;
    [Test] Procedure TestUndeclaredUTF8CutOff;
    [Test] Procedure TestUndeclaredHighByteAtEndIsAnsi;
    [Test] Procedure TestUndeclaredEncodingIsNil;
    // Declared encoding
    [Test] Procedure TestLanguageDriver;
    [Test] Procedure TestLanguageDriverOtherCodePage;
    [Test] Procedure TestEncodingParameterOverridesLanguageDriver;
    [Test] Procedure TestEncodingParameterStaysCallers;
    // What the header declares
    [Test] Procedure TestHeaderCodePage;
    [Test] Procedure TestHeaderCodePageNoneOrUnknown;
    [Test] Procedure TestHeaderCodePageWithEncodingPassed;
    // Multi-byte values keep the following fields in place
    [Test] Procedure TestMultiByteValueKeepsNextField;
  end;

  [TestFixture]
  TDBFFieldBuilderTests = class
  private
    FBuilder: TDBFFieldBuilder;
    FTempFile: String;
    // The field the builder gives the values, under the name given
    Function FieldFor(const Values: array of Variant; const FieldName: String = 'F'): TDBFField;
  public
    [Setup]    Procedure Setup;
    [TearDown] Procedure TearDown;
    [Test] Procedure Nothing_IsOneCharacterOfText;
    [Test] Procedure Null_AddsNothing;
    [Test] Procedure Booleans_AreLogical;
    [Test] Procedure Dates_AreDates;
    [Test] Procedure Integers_AreNumericWithoutDecimals_SizedToTheLongest;
    [Test] Procedure IntegersAndFloats_AreNumericWithDecimals;
    [Test] Procedure Strings_AreText_SizedToTheLongest;
    [Test] Procedure NumbersAndStrings_AreText;
    [Test] Procedure Field_WritesAndReadsTheValuesBack;
    [Test] Procedure ValidName_UpperCasesAndReplacesOtherCharacters;
    [Test] Procedure ValidName_IsAtMostTenCharacters;
    [Test] Procedure ValidName_EmptyGetsAName;
    [Test] Procedure ValidName_TakenGetsANumber;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

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

Procedure TDBFWriterTests.TestWriterNumericTruncateDecimals;
begin
  var W := TDBFWriter.Create(FTempFile,
    [TDBFField.Create('VAL','N',5,3,{Truncate=}true)]);
  try
    W.AppendRecord([Variant(12.3456)]);  // 12.346 -> 12.35
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    Assert.AreEqual(12.35, Double(R[0]), 1E-9);
  finally
    R.Free;
  end;
end;

Procedure TDBFWriterTests.TestWriterNumericTruncateDecimalPoint;
begin
  var W := TDBFWriter.Create(FTempFile,
    [TDBFField.Create('VAL','N',5,2,{Truncate=}true)]);
  try
    W.AppendRecord([Variant(12345.6)]);  // 12345.60 -> 12346
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    Assert.AreEqual(12346.0, Double(R[0]), 1E-9);
  finally
    R.Free;
  end;
end;

Procedure TDBFWriterTests.TestWriterNumericTruncateIntegerPart;
begin
  var W := TDBFWriter.Create(FTempFile,
    [TDBFField.Create('VAL','N',5,2,{Truncate=}true)]);
  try
    Assert.WillRaiseAny(
      Procedure begin W.AppendRecord([Variant(123456.7)]) end);
  finally
    W.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

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

Const
  // Frysl-a-circumflex-n in UTF-8, with the a-circumflex as the two bytes C3 A2
  FryslanUTF8: array[0..7] of Byte = ($46,$72,$79,$73,$6C,$C3,$A2,$6E);
  // The same in Windows-1252, with the a-circumflex as the byte E2
  Fryslan1252: array[0..6] of Byte = ($46,$72,$79,$73,$6C,$E2,$6E);

Procedure TDBFEncodingTests.Setup;
begin
  FTempFile := TPath.GetTempFileName;
end;

Procedure TDBFEncodingTests.TearDown;
begin
  if FileExists(FTempFile) then DeleteFile(FTempFile);
end;

Function TDBFEncodingTests.Bytes(const Values: array of Byte): TBytes;
begin
  SetLength(Result,Length(Values));
  for var Index := 0 to High(Values) do Result[Index] := Values[Index];
end;

Procedure TDBFEncodingTests.WriteFile(const LanguageDriver: Byte;
                                      const FieldLengths: array of Byte;
                                      const Values: array of TBytes);
begin
  var Stream := TFileStream.Create(FTempFile,fmCreate);
  var Writer := TBinaryWriter.Create(Stream);
  try
    var RecordSize: Word := 1;
    for var FieldLength in FieldLengths do Inc(RecordSize,FieldLength);
    // Table header: 32 bytes, with the language driver at offset 29
    Writer.Write(Byte(3));
    Writer.Write(Bytes([126,1,1])); // Last update
    Writer.Write(Integer(1));       // Record count
    Writer.Write(Word(32*(Length(FieldLengths)+1)+1));
    Writer.Write(RecordSize);
    for var Offset := 12 to 28 do Writer.Write(Byte(0));
    Writer.Write(LanguageDriver);
    Writer.Write(Bytes([0,0]));
    // Field descriptors: 32 bytes each
    for var Field := 0 to High(FieldLengths) do
    begin
      var Name := TEncoding.ASCII.GetBytes('F' + IntToStr(Field+1));
      SetLength(Name,11);
      Writer.Write(Name);
      Writer.Write(Byte(Ord('C')));
      Writer.Write(Bytes([0,0,0,0]));
      Writer.Write(FieldLengths[Field]);
      Writer.Write(Byte(0));
      for var Reserved := 1 to 14 do Writer.Write(Byte(0));
    end;
    Writer.Write(Byte(13)); // Header terminator
    // The record
    Writer.Write(Byte(Ord(' ')));
    for var Field := 0 to High(FieldLengths) do
    begin
      var Value := Copy(Values[Field]);
      var ValueLength := Length(Value);
      SetLength(Value,FieldLengths[Field]);
      for var Index := ValueLength to FieldLengths[Field]-1 do Value[Index] := Ord(' ');
      Writer.Write(Value);
    end;
    Writer.Write(Byte(26));
  finally
    Writer.Free;
    Stream.Free;
  end;
end;

Function TDBFEncodingTests.ReadFirstValue(const Encoding: TEncoding = nil): String;
begin
  var R := TDBFReader.Create(FTempFile,Encoding);
  try
    Assert.IsTrue(R.NextRecord,'Record should exist');
    Result := R[0];
  finally
    R.Free;
  end;
end;

Procedure TDBFEncodingTests.TestUndeclaredUTF8;
begin
  WriteFile(0,[10],[Bytes(FryslanUTF8)]);
  Assert.AreEqual('Frysl'#$E2'n',ReadFirstValue);
end;

Procedure TDBFEncodingTests.TestUndeclaredAnsi;
begin
  // Not valid UTF-8, so read in the system's ANSI code page
  WriteFile(0,[10],[Bytes(Fryslan1252)]);
  Assert.AreEqual(TEncoding.ANSI.GetString(Bytes(Fryslan1252)),ReadFirstValue);
end;

Procedure TDBFEncodingTests.TestUndeclaredUTF8CutOff;
begin
  // a-circumflex, x, a-circumflex (C3 A2 78 C3 A2) cut off at 4 bytes, in the second a-circumflex
  WriteFile(0,[4],[Bytes([$C3,$A2,$78,$C3,$A2])]);
  Assert.AreEqual(#$E2'x',ReadFirstValue);
end;

Procedure TDBFEncodingTests.TestUndeclaredHighByteAtEndIsAnsi;
begin
  // 'Cafe' with e-acute (E9) in Windows-1252 filling the field: the E9 at the end looks like
  // the start of a UTF-8 character, but nothing before it is UTF-8
  var Cafe := Bytes([$43,$61,$66,$E9]);
  WriteFile(0,[4],[Cafe]);
  Assert.AreEqual(TEncoding.ANSI.GetString(Cafe),ReadFirstValue);
end;

Procedure TDBFEncodingTests.TestLanguageDriver;
begin
  // Language driver $57 is Windows-1252: the UTF-8 bytes are read as 1252
  WriteFile($57,[10],[Bytes(FryslanUTF8)]);
  var R := TDBFReader.Create(FTempFile);
  try
    Assert.AreEqual(1252,Integer(R.Encoding.CodePage));
    R.NextRecord;
    Assert.AreEqual('Frysl'#$C3#$A2'n',String(R[0]));
  finally
    R.Free;
  end;
end;

Procedure TDBFEncodingTests.TestUndeclaredEncodingIsNil;
begin
  WriteFile(0,[10],[Bytes(FryslanUTF8)]);
  var R := TDBFReader.Create(FTempFile);
  try
    Assert.IsNull(R.Encoding,'Encoding should be detected per value');
  finally
    R.Free;
  end;
end;

Procedure TDBFEncodingTests.TestLanguageDriverOtherCodePage;
begin
  // Language driver $C9 is Windows-1251, in which C0 is the Cyrillic capital A
  WriteFile($C9,[4],[Bytes([$C0])]);
  Assert.AreEqual(#$0410,ReadFirstValue);
end;

Procedure TDBFEncodingTests.TestEncodingParameterOverridesLanguageDriver;
begin
  WriteFile($57,[10],[Bytes(FryslanUTF8)]);
  Assert.AreEqual('Frysl'#$E2'n',ReadFirstValue(TEncoding.UTF8));
end;

Procedure TDBFEncodingTests.TestEncodingParameterStaysCallers;
begin
  // The caller keeps owning the encoding, so freeing it after the reader must
  // not free it twice
  WriteFile(0,[10],[Bytes(FryslanUTF8)]);
  var Encoding := TEncoding.GetEncoding(1252);
  try
    Assert.AreEqual('Frysl'#$C3#$A2'n',ReadFirstValue(Encoding));
  finally
    Encoding.Free;
  end;
end;

Procedure TDBFEncodingTests.TestHeaderCodePage;
begin
  WriteFile($57,[10],[Bytes(FryslanUTF8)]);
  var R := TDBFReader.Create(FTempFile);
  try
    Assert.AreEqual(1252,R.HeaderCodePage);
  finally
    R.Free;
  end;
end;

Procedure TDBFEncodingTests.TestHeaderCodePageNoneOrUnknown;
begin
  for var LanguageDriver in [$00,$FF] do
  begin
    WriteFile(LanguageDriver,[10],[Bytes(FryslanUTF8)]);
    var R := TDBFReader.Create(FTempFile);
    try
      Assert.AreEqual(0,R.HeaderCodePage,Format('Language driver $%.2x',[LanguageDriver]));
    finally
      R.Free;
    end;
  end;
end;

Procedure TDBFEncodingTests.TestHeaderCodePageWithEncodingPassed;
begin
  // The header declares Windows-1252 while UTF-8 is passed in: both show,
  // so the caller can tell they disagree
  WriteFile($57,[10],[Bytes(FryslanUTF8)]);
  var R := TDBFReader.Create(FTempFile,TEncoding.UTF8);
  try
    Assert.AreEqual(1252,R.HeaderCodePage);
    Assert.AreEqual(65001,Integer(R.Encoding.CodePage));
  finally
    R.Free;
  end;
end;

Procedure TDBFEncodingTests.TestMultiByteValueKeepsNextField;
begin
  // Two a-circumflexes take all 4 bytes of the first field, but only 2 characters
  WriteFile(0,[4,3],[Bytes([$C3,$A2,$C3,$A2]),Bytes([$61,$62,$63])]);
  var R := TDBFReader.Create(FTempFile,TEncoding.UTF8);
  try
    R.NextRecord;
    Assert.AreEqual(#$E2#$E2,String(R[0]));
    Assert.AreEqual('abc',String(R[1]));
  finally
    R.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

Procedure TDBFFieldBuilderTests.Setup;
begin
  FBuilder := TDBFFieldBuilder.Create;
  FTempFile := TPath.GetTempFileName;
end;

Procedure TDBFFieldBuilderTests.TearDown;
begin
  FBuilder.Free;
  if FileExists(FTempFile) then TFile.Delete(FTempFile);
end;

Function TDBFFieldBuilderTests.FieldFor(const Values: array of Variant; const FieldName: String = 'F'): TDBFField;
begin
  for var Value in Values do FBuilder.Add(Value);
  Result := FBuilder.Field(FieldName);
end;

Procedure TDBFFieldBuilderTests.Nothing_IsOneCharacterOfText;
begin
  var F := FieldFor([]);
  Assert.AreEqual('C', String(F.FieldType));
  Assert.AreEqual(1, Integer(F.FieldLength));
end;

Procedure TDBFFieldBuilderTests.Null_AddsNothing;
begin
  var F := FieldFor([Null, True, Unassigned]);
  Assert.AreEqual('L', String(F.FieldType));
end;

Procedure TDBFFieldBuilderTests.Booleans_AreLogical;
begin
  var F := FieldFor([True, False]);
  Assert.AreEqual('L', String(F.FieldType));
  Assert.AreEqual(1, Integer(F.FieldLength));
end;

Procedure TDBFFieldBuilderTests.Dates_AreDates;
begin
  var F := FieldFor([EncodeDate(2026, 10, 1)]);
  Assert.AreEqual('D', String(F.FieldType));
  Assert.AreEqual(8, Integer(F.FieldLength));
end;

Procedure TDBFFieldBuilderTests.Integers_AreNumericWithoutDecimals_SizedToTheLongest;
// Minus 1234 takes five characters
begin
  var F := FieldFor([3, -1234]);
  Assert.AreEqual('N', String(F.FieldType));
  Assert.AreEqual(5, Integer(F.FieldLength));
  Assert.AreEqual(0, Integer(F.DecimalCount));
end;

Procedure TDBFFieldBuilderTests.IntegersAndFloats_AreNumericWithDecimals;
// Two digits, the point, and six decimals
begin
  var F := FieldFor([3, 52.2]);
  Assert.AreEqual('N', String(F.FieldType));
  Assert.AreEqual(9, Integer(F.FieldLength));
  Assert.AreEqual(6, Integer(F.DecimalCount));
end;

Procedure TDBFFieldBuilderTests.Strings_AreText_SizedToTheLongest;
begin
  var F := FieldFor(['Ede', 'Amersfoort']);
  Assert.AreEqual('C', String(F.FieldType));
  Assert.AreEqual(10, Integer(F.FieldLength));
end;

Procedure TDBFFieldBuilderTests.NumbersAndStrings_AreText;
begin
  var F := FieldFor([1234567, 'Amersfoort']);
  Assert.AreEqual('C', String(F.FieldType));
  Assert.AreEqual(10, Integer(F.FieldLength));
end;

Procedure TDBFFieldBuilderTests.Field_WritesAndReadsTheValuesBack;
// The number with the most decimals keeps six of them
var
  V: TArray<Variant>;
begin
  var F := FieldFor([52.2, -1234567.891]);
  var W := TDBFWriter.Create(FTempFile, [F]);
  try
    W.AppendRecord([Variant(52.2)]);
    W.AppendRecord([Variant(-1234567.891)]);
  finally
    W.Free;
  end;
  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    V := R.GetValues;
    Assert.AreEqual(52.2, Double(V[0]), 1e-9);
    R.NextRecord;
    V := R.GetValues;
    Assert.AreEqual(-1234567.891, Double(V[0]), 1e-9);
  finally
    R.Free;
  end;
end;

Procedure TDBFFieldBuilderTests.ValidName_UpperCasesAndReplacesOtherCharacters;
begin
  Assert.AreEqual('ROAD_NAME', FBuilder.ValidName('road name', []));
  Assert.AreEqual('ORDER', FBuilder.ValidName('order', []));
end;

Procedure TDBFFieldBuilderTests.ValidName_IsAtMostTenCharacters;
begin
  Assert.AreEqual('A_VERY_LON', FBuilder.ValidName('a very long field name', []));
end;

Procedure TDBFFieldBuilderTests.ValidName_EmptyGetsAName;
begin
  Assert.AreEqual('FIELD', FBuilder.ValidName('', []));
end;

Procedure TDBFFieldBuilderTests.ValidName_TakenGetsANumber;
// The number replaces the end of a name that is already ten characters long
begin
  Assert.AreEqual('ROAD_NAME2', FBuilder.ValidName('road name', ['ROAD_NAME']));
  Assert.AreEqual('ROAD_NAME3', FBuilder.ValidName('road name', ['ROAD_NAME', 'ROAD_NAME2']));
  Assert.AreEqual('A_VERY_LO2', FBuilder.ValidName('a very long field name', ['A_VERY_LON']));
end;

initialization
  TDUnitX.RegisterTestFixture(TDBFFieldTests);
  TDUnitX.RegisterTestFixture(TDBFWriterTests);
  TDUnitX.RegisterTestFixture(TDBFReaderTests);
  TDUnitX.RegisterTestFixture(TDBFRoundTripTests);
  TDUnitX.RegisterTestFixture(TDBFEncodingTests);
  TDUnitX.RegisterTestFixture(TDBFFieldBuilderTests);

end.
