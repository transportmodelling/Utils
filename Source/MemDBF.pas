unit MemDBF;

////////////////////////////////////////////////////////////////////////////////
//
// Class to manipulate a dbf file. Data are read into a FireDac memory table to be
// manipulated. The manipulated table can be saved to file again.
//
////////////////////////////////////////////////////////////////////////////////

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
  SysUtils, Data.DB, FireDac.Comp.Client, DBF;

Type
  TMemDBF = Class
  private
    FFileName: String;
    FTable: TFDMemTable;
    Fields: TArray<TDBFField>;
    OwnsTable: Boolean;
    Procedure ReadTable;
    Procedure DefineFields(const DBFReader: TDBFReader);
    Function TableFieldType(const Field: TDBFField; const Dialect: TDBFDialect): TFieldType;
    Function UnsupportedFieldType(const Field: TDBFField): Exception;
    Procedure ReadRecords(const DBFReader: TDBFReader);
  public
    Constructor Create(const FileName: String); overload;
    Constructor Create(const FileName: String; const Table: TFDMemTable); overload;
    Procedure Save;
    Procedure SaveAs(const FileName: String);
    Destructor Destroy; override;
  public
    Property FileName: String read FFileName;
    Property Table: TFDMemTable read FTable;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TMemDBF.Create(const FileName: String);
begin
  OwnsTable := true;
  Create(FileName,TFDMemTable.Create(nil));
end;

Constructor TMemDBF.Create(const FileName: String; const Table: TFDMemTable);
begin
  inherited Create;
  FTable := Table;
  if FileExists(FileName) then
  begin
    FFileName := FileName;
    ReadTable;
  end else
    raise Exception.Create('DBF-file does not exist');
end;

Procedure TMemDBF.ReadTable;
begin
  var DBFReader := TDBFReader.Create(FFileName);
  try
    Fields := DBFReader.GetFields;
    DefineFields(DBFReader);
    ReadRecords(DBFReader);
    FTable.First;
  finally
    DBFReader.Free;
  end;
end;

Procedure TMemDBF.DefineFields(const DBFReader: TDBFReader);
// Every field needs a definition, because the values are read into the table
// by their position
begin
  FTable.FieldDefs.Clear;
  for var Field := low(Fields) to high(Fields) do
  begin
    var FieldType := TableFieldType(Fields[Field],DBFReader.Dialect);
    if FieldType = ftString then
      FTable.FieldDefs.Add(Fields[Field].FieldName,FieldType,Fields[Field].FieldLength)
    else
      FTable.FieldDefs.Add(Fields[Field].FieldName,FieldType);
  end;
  FTable.CreateDataSet;
end;

Function TMemDBF.TableFieldType(const Field: TDBFField; const Dialect: TDBFDialect): TFieldType;
// Type B is a double in Visual FoxPro, but a memo block reference, which the
// reader does not read, in dBase III and IV
begin
  case Field.FieldType of
    'C': Result := ftString;
    'D': Result := ftDate;
    'L': Result := ftBoolean;
    'F','N': if Field.DecimalCount = 0 then Result := ftInteger else Result := ftFloat;
    'I': Result := ftInteger;
    'O': Result := ftFloat;
    'Y': Result := ftCurrency;
    'T': Result := ftDateTime;
    'B': if Dialect = dbVisualFoxPro then Result := ftFloat else raise UnsupportedFieldType(Field);
    else raise UnsupportedFieldType(Field);
  end;
end;

Function TMemDBF.UnsupportedFieldType(const Field: TDBFField): Exception;
begin
  Result := Exception.Create('Unsupported field type ' + Field.FieldType +
                             ' (field=' + Field.FieldName + ')');
end;

Procedure TMemDBF.ReadRecords(const DBFReader: TDBFReader);
begin
  for var Rec := 1 to DBFReader.RecordCount do
  try
    if DBFReader.NextRecord then
    begin
      FTable.Append;
      for var Field := 0 to DBFReader.FieldCount-1 do
      FTable.Fields[Field].Value := DBFReader[Field];
    end else
      raise Exception.Create('Error reading DBF-file');
  except
    on E: Exception do raise Exception.Create(E.Message + ' record ' + Rec.ToString);
  end;
end;

Procedure TMemDBF.Save;
begin
  SaveAs(FFileName);
end;

Procedure TMemDBF.SaveAs(const FileName: String);
begin
  // Set property value
  FFileName := FileName;
  // Write dbf-file
  var DBFWriter := TDBFWriter.Create(FFileName,Fields);
  try
    FTable.DisableControls;
    try
      // Save data
      FTable.First;
      while not FTable.Eof do
      begin
        for var Field := low(Fields) to high(Fields) do
        DBFWriter.FieldValues[Field] := FTable.Fields[Field].Value;
        DBFWriter.AppendRecord;
        FTable.Next;
      end;
    finally
      FTable.EnableControls;
    end;
  finally
    DBFWriter.Free;
  end;
end;

Destructor TMemDBF.Destroy;
begin
  if OwnsTable then FTable.Free;
  inherited Destroy;
end;

end.
