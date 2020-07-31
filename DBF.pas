unit DBF;

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
  System.Classes,System.SysUtils;

Type
  TDBFFile = Class
  private
    Type
      TDBFField = record
        FieldName: String;
        FieldType: Char;
        FieldLength,DecimalCount: Byte;
        FieldValue: Variant;
      end;
    Var
      FFileName: string;
      FFieldCount,FRecordCount,FRecordIndex: Integer;
      FFields: array of TDBFField;
      FileStream: TBufferedFileStream;
      FormatSettings: TFormatSettings;
    Function GetFieldNames(Field: Integer): String;
    Function GetFieldTypes(Field: Integer): Char;
    Function GetFieldValues(Field: Integer): Variant;
  public
    Function IndexOf(const FieldName: String): Integer;
  public
    Property FileName: String read FFileName;
    Property FieldCount: Integer read FFieldCount;
    Property RecordCount: Integer read FRecordCount;
    Property RecordIndex: Integer read FRecordIndex;
    Property FieldNames[Field: Integer]: String read GetFieldNames;
    Property FieldTypes[Field: Integer]: Char read GetFieldTypes;
    Property FieldValues[Field: Integer]: Variant read GetFieldValues; default;
  end;

  TDBFReader = Class(TDBFFile)
  private
    FileReader: TBinaryReader;
    Version: Byte;
    FormatSettings: TFormatSettings;
  public
    Constructor Create(const FileName: String);
    Function NextRecord: Boolean;
    Destructor Destroy; override;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Function TDBFFile.GetFieldNames(Field: Integer): String;
begin
  Result := FFields[Field].FieldName;
end;

Function TDBFFile.GetFieldTypes(Field: Integer): Char;
begin
  Result := FFields[Field].FieldType;
end;

Function TDBFFile.GetFieldValues(Field: Integer): variant;
begin
  Result := FFields[Field].FieldValue;
end;

Function TDBFFile.IndexOf(const FieldName: String): Integer;
begin
  Result := -1;
  for var Field := 0 to FFieldCount-1 do
  if SameText(FFields[Field].FieldName,FieldName) then
  begin
    Result := Field;
    Break;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TDBFReader.Create(const FileName: String);
begin
  inherited Create;
  FRecordIndex := -1;
  FormatSettings.DecimalSeparator := '.';
  FFileName := FileName;
  FileStream := TBufferedFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite,32768);
  FileReader := TBinaryReader.Create(FileStream,TEncoding.ANSI);
  // Read table file header
  Version := FileReader.ReadByte and 7;
  if Version = 4 then raise Exception.Create('dBase level 7 files not supported');
  for var Skip := 1 to 3 do FileReader.ReadByte; // Last update date
  FRecordCount := FileReader.ReadInteger;
  FFieldCount := (FileReader.ReadInt16 div 32)-1;
  for var Skip := 1 to 2 do FileReader.ReadByte; // Nr record bytes
  for var Skip := 1 to 2 do FileReader.ReadByte; // Reserved
  FileReader.ReadByte; // Incomplete dBase IV transaction
  FileReader.ReadByte; // dBase IV encryption flag
  for var Skip := 1 to 12 do FileReader.ReadByte; // Reserved
  FileReader.ReadByte; // Production MDX flag
  FileReader.ReadByte; // Language driver
  for var Skip := 1 to 2 do FileReader.ReadByte; // Reserved
  // Read field descriptor records
  SetLength(FFields,FFieldCount);
  for var Field := 0 to FFieldCount-1 do
  begin
    for var NameChar := 1 to 11 do
    begin
      var Chr := FileReader.ReadChar;
      if Chr <> #0 then FFields[Field].FieldName := FFields[Field].FieldName + Chr;
    end;
    FFields[Field].FieldType := FileReader.ReadChar;
    for var Skip := 1 to 4 do FileReader.ReadByte; // Reserved
    FFields[Field].FieldLength := FileReader.ReadByte;
    FFields[Field].DecimalCount := FileReader.ReadByte;
    for var Skip := 1 to 14 do FileReader.ReadByte;
  end;
  // Read header terminator
  FileReader.ReadByte;
end;

Function TDBFReader.NextRecord: Boolean;
Var
  DeletedRecord: Boolean;
begin
  if FRecordIndex < FRecordCount-1 then
  begin
    Result := true;
    Inc(FRecordIndex);
    repeat
      DeletedRecord := (FileReader.ReadChar = '*');
      for var Field := 0 to FFieldCount-1 do
      begin
        var FieldValue := '';
        for var FieldChar := 1 to FFields[Field].FieldLength do FieldValue := FieldValue + FileReader.ReadChar;
        case FFields[Field].FieldType of
          'C': FFields[Field].FieldValue := Trim(FieldValue);
          'D': begin
                 var Year := Copy(FieldValue,1,4).ToInteger;
                 var Month := Copy(FieldValue,5,2).ToInteger;
                 var Day := Copy(FieldValue,7,2).ToInteger;
                 FFields[Field].FieldValue := EncodeDate(Year,Month,Day);
               end;
          'L': if (FieldValue='T') or (FieldValue='t') or (FieldValue='Y') or (FieldValue='y') then
               begin
                 FFields[Field].FieldValue := true;
               end else
               if (FieldValue='F') or (FieldValue='f') or (FieldValue='N') or (FieldValue='n') then
               begin
                 FFields[Field].FieldValue := false;
               end else
               if FieldValue = '?' then VarClear(FFields[Field].FieldValue) else
                 raise Exception.Create('Invalid field value (' + FFields[Field].FieldName +')');
          'F','N':
               begin
                 FieldValue := Trim(FieldValue);
                 if FieldValue = '' then
                   VarClear(FFields[Field].FieldValue)
                 else
                   if FFields[Field].DecimalCount = 0 then
                     FFields[Field].FieldValue := StrToInt(FieldValue)
                   else
                     FFields[Field].FieldValue := StrToFloat(FieldValue,FormatSettings);
               end;
          else VarClear(FFields[Field].FieldValue);
        end;
      end;
    until not DeletedRecord;
  end else Result := false;
end;

Destructor TDBFReader.Destroy;
begin
  FileReader.Free;
  FileStream.Free;
  inherited Destroy;
end;

end.
