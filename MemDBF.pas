unit MemDBF;

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
  SysUtils,Data.DB,FireDac.Comp.Client,DBF;

Type
  TDBFMemDataSet = record
    Class Procedure Read(const DBFFileName: String; const MemDataSet: TFDMemTable); static;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Procedure TDBFMemDataSet.Read(const DBFFileName: String; const MemDataSet: TFDMemTable);
begin
  var DBFReader := TDBFReader.Create(DBFFileName);
  try
    // Read fields
    MemDataSet.FieldDefs.Clear;
    for var Field := 0 to DBFReader.FieldCount-1 do
    case DBFReader.FieldTypes[Field] of
      'C': MemDataSet.FieldDefs.Add(DBFReader.FieldNames[Field],ftString,DBFReader.FieldLength[Field]);
      'D': MemDataSet.FieldDefs.Add(DBFReader.FieldNames[Field],ftDate);
      'L': MemDataSet.FieldDefs.Add(DBFReader.FieldNames[Field],ftBoolean);
      'F','N':
           if DBFReader.DecimalCount[Field] = 0 then
             MemDataSet.FieldDefs.Add(DBFReader.FieldNames[Field],ftInteger)
           else
             MemDataSet.FieldDefs.Add(DBFReader.FieldNames[Field],ftFloat)
    end;
    MemDataSet.CreateDataSet;
    // Read data
    for var Rec := 0 to DBFReader.RecordCount-1 do
    if DBFReader.NextRecord then
    begin
      MemDataSet.Append;
      for var Field := 0 to DBFReader.FieldCount-1 do MemDataSet.Fields[Field].Value := DBFReader[Field];
    end else
      raise exception.Create('Error reading DBF-file');
    MemDataSet.First;
  finally
    DBFReader.Free;
  end;
end;

end.
