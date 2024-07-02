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
  Create(FileName,TFDMemTable.Create(nil));
  OwnsTable := true;
end;

Constructor TMemDBF.Create(const FileName: String; const Table: TFDMemTable);
begin
  inherited Create;
  if FileExists(FileName) then
  begin
    // Set property values
    FFileName := FileName;
    FTable := Table;
    // Read table
    var DBFReader := TDBFReader.Create(FileName);
    try
      // Read fields
      Fields := DBFReader.GetFields;
      FTable.FieldDefs.Clear;
      for var Field in Fields do
      case Field.FieldType of
        'C': FTable.FieldDefs.Add(Field.FieldName,ftString,Field.FieldLength);
        'D': FTable.FieldDefs.Add(Field.FieldName,ftDate);
        'L': FTable.FieldDefs.Add(Field.FieldName,ftBoolean);
        'F','N':
             if Field.DecimalCount = 0 then
               FTable.FieldDefs.Add(Field.FieldName,ftInteger)
             else
               FTable.FieldDefs.Add(Field.FieldName,ftFloat)
      end;
      FTable.CreateDataSet;
      // Read data
      for var Rec := 0 to DBFReader.RecordCount-1 do
      if DBFReader.NextRecord then
      begin
        FTable.Append;
        for var Field := 0 to DBFReader.FieldCount-1 do FTable.Fields[Field].Value := DBFReader[Field];
      end else
        raise exception.Create('Error reading DBF-file');
      FTable.First;
    finally
      DBFReader.Free;
    end;
  end else
    raise Exception.Create('DBF-file does not exist');
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
