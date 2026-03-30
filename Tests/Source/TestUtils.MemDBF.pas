unit TestUtils.MemDBF;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, IOUtils, Variants,
  Data.DB, FireDac.Comp.Client,
  DUnitX.TestFramework, BaseDir, DBF, MemDBF;

Type
  [TestFixture]
  TMemDBFTests = class
  private
    FFixture: String;   // Tests\Data\sample.dbf
    FTempFile: String;  // unique temp file per test
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;
    // Construction
    [Test] procedure TestFileNotFoundRaises;
    [Test] procedure TestFileNameProperty;
    [Test] procedure TestTableNotNil;
    // Table contents after loading sample.dbf
    [Test] procedure TestFieldCount;
    [Test] procedure TestFieldNames;
    [Test] procedure TestRecordCount;
    [Test] procedure TestFieldValues_Row1;
    [Test] procedure TestFieldValues_Row2;
    // External-table overload
    [Test] procedure TestExternalTableOverload;
    // Persistence
    [Test] procedure TestSaveAs;
    [Test] procedure TestSave;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

procedure TMemDBFTests.Setup;
begin
  var BaseDirectory := TBaseDirectory.Create(true);
  FFixture := BaseDirectory.AbsolutePath('..\Data\sample.dbf');
  FTempFile := TPath.Combine(TPath.GetTempPath, 'TestMemDBF_' + TGUID.NewGuid.ToString + '.dbf');
end;

procedure TMemDBFTests.TearDown;
begin
  if TFile.Exists(FTempFile) then TFile.Delete(FTempFile);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TMemDBFTests.TestFileNotFoundRaises;
begin
  Assert.WillRaiseAny(procedure
  begin
    TMemDBF.Create('C:\does_not_exist_xyzzy.dbf').Free;
  end);
end;

procedure TMemDBFTests.TestFileNameProperty;
begin
  var M := TMemDBF.Create(FFixture);
  try
    Assert.AreEqual(FFixture, M.FileName);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestTableNotNil;
begin
  var M := TMemDBF.Create(FFixture);
  try
    Assert.IsNotNull(M.Table);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestFieldCount;
begin
  var M := TMemDBF.Create(FFixture);
  try
    Assert.AreEqual(4, M.Table.FieldCount);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestFieldNames;
begin
  var M := TMemDBF.Create(FFixture);
  try
    Assert.AreEqual('ID',     M.Table.Fields[0].FieldName);
    Assert.AreEqual('NAME',   M.Table.Fields[1].FieldName);
    Assert.AreEqual('ACTIVE', M.Table.Fields[2].FieldName);
    Assert.AreEqual('SCORE',  M.Table.Fields[3].FieldName);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestRecordCount;
begin
  var M := TMemDBF.Create(FFixture);
  try
    Assert.AreEqual(3, M.Table.RecordCount);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestFieldValues_Row1;
begin
  var M := TMemDBF.Create(FFixture);
  try
    M.Table.First;
    Assert.AreEqual(1,       Integer(M.Table.Fields[0].Value));
    Assert.AreEqual('Alice', String(M.Table.Fields[1].Value));
    Assert.IsTrue(Boolean(M.Table.Fields[2].Value), 'ACTIVE should be True');
    Assert.AreEqual(9.5,     Double(M.Table.Fields[3].Value), 0.001);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestFieldValues_Row2;
begin
  var M := TMemDBF.Create(FFixture);
  try
    M.Table.First;
    M.Table.Next;
    Assert.AreEqual(2,     Integer(M.Table.Fields[0].Value));
    Assert.AreEqual('Bob', String(M.Table.Fields[1].Value));
    Assert.IsFalse(Boolean(M.Table.Fields[2].Value), 'ACTIVE should be False');
    Assert.AreEqual(7.25,  Double(M.Table.Fields[3].Value), 0.001);
  finally
    M.Free;
  end;
end;

procedure TMemDBFTests.TestExternalTableOverload;
begin
  // Caller supplies the TFDMemTable; MemDBF should populate it but NOT free it
  var ExtTable := TFDMemTable.Create(nil);
  try
    var M := TMemDBF.Create(FFixture, ExtTable);
    M.Free; // must NOT free ExtTable (OwnsTable = false)
    Assert.AreEqual(3, ExtTable.RecordCount);
    Assert.AreEqual(4, ExtTable.FieldCount);
  finally
    ExtTable.Free;
  end;
end;

procedure TMemDBFTests.TestSaveAs;
begin
  // Load sample.dbf, save to a temp file, reload with TDBFReader and verify
  var M := TMemDBF.Create(FFixture);
  try
    M.SaveAs(FTempFile);
  finally
    M.Free;
  end;

  Assert.IsTrue(TFile.Exists(FTempFile), 'SaveAs should have created the file');

  var R := TDBFReader.Create(FTempFile);
  try
    Assert.AreEqual(4, R.FieldCount);
    Assert.AreEqual(3, R.RecordCount);
    R.NextRecord;
    Assert.AreEqual(1,       Integer(R[0]));
    Assert.AreEqual('Alice', String(R[1]));
  finally
    R.Free;
  end;
end;

procedure TMemDBFTests.TestSave;
begin
  // Copy sample.dbf to temp, load it, modify row 1, save, reload and verify
  TFile.Copy(FFixture, FTempFile);

  var M := TMemDBF.Create(FTempFile);
  try
    M.Table.First;
    M.Table.Edit;
    M.Table.Fields[1].Value := 'Modified';
    M.Table.Post;
    M.Save;
  finally
    M.Free;
  end;

  var R := TDBFReader.Create(FTempFile);
  try
    R.NextRecord;
    Assert.AreEqual('Modified', String(R[1]));
  finally
    R.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMemDBFTests);

end.
