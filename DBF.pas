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
  System.Classes,System.SysUtils,ArrayBld;

Type
  TDBFField = record
  private
    FFieldName: String;
    FFieldType: Char;
    FFieldLength,FDecimalCount: Byte;
    FieldValue: Variant;
    Procedure SetFieldName(Value: string);
    Procedure SetFieldType(Value: Char);
    Procedure SetFieldLength(Value: Byte);
    Procedure SetDecimalCount(Value: Byte);
    Procedure Validate;
  public
    Property FieldName: String read FFieldName write SetFieldName;
    Property FieldType: Char read FFieldType write SetFieldType;
    Property FieldLength: Byte read FFieldLength write SetFieldLength;
    Property DecimalCount: Byte read FDecimalCount write SetDecimalCount;
  end;

  TDBFFile = Class
  private
    FFileName: string;
    FFieldCount,FRecordCount: Integer;
    FFields: TArray<TDBFField>;
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
    Property FieldNames[Field: Integer]: String read GetFieldNames;
    Property FieldTypes[Field: Integer]: Char read GetFieldTypes;
    Property FieldValues[Field: Integer]: Variant read GetFieldValues; default;
  end;

  TDBFReader = Class(TDBFFile)
  private
    FRecordIndex: Integer;
    FileReader: TBinaryReader;
    Version: Byte;
    FormatSettings: TFormatSettings;
  public
    Constructor Create(const FileName: String);
    Function NextRecord: Boolean;
    Destructor Destroy; override;
  public
    Property RecordIndex: Integer read FRecordIndex;
  end;

  TDBFWriter = Class(TDBFFile)
  private
    Procedure SetFieldValues(Field: Integer; Value: Variant);
  public
    Constructor Create(const FileName: String; const Fields: array of TDBFField); overload;
    Constructor Create(const FileName: String; const DBFFile: TDBFFile); overload;
    Procedure AppendRecord;
    Destructor Destroy; override;
  public
    Property FieldValues[Field: Integer]: Variant read GetFieldValues write SetFieldValues; default;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TDBFField.SetFieldName(Value: string);
begin
  Value := Trim(Uppercase(Value));
  if (Value <> '') and (Length(Value) <= 10) then
  begin
    FFieldName := Value;
    for var Chr := 1 to Length(Value) do
    if Value[Chr] in ['A'..'Z'] then Continue else
    if Value[Chr] in ['0'..'9'] then Continue else
    if Value[Chr] <> '_' then raise Exception.Create('Invalid Field Name ' + Value);
  end else
    raise Exception.Create('Invalid Field Name ' + Value);
end;

Procedure TDBFField.SetFieldType(Value: Char);
begin
  if Value <> FFieldType then
  begin
    FFieldType := Value;
    case Value of
      'C': begin
             FFieldLength := 10;
             FDecimalCount := 0;
           end;
      'D': begin
             FFieldLength := 8;
             FDecimalCount := 0;
           end;
      'L': begin
             FFieldLength := 1;
             FDecimalCount := 0;
           end;
      'F','N':
           begin
             FFieldLength := 10;
             FDecimalCount := 0;
           end;
      else raise Exception.Create('Unsupported Field Type ' + Value);
    end;
  end;
end;

Procedure TDBFField.SetFieldLength(Value: Byte);
begin
  if Value <> FFieldLength then
  begin
    FFieldLength := Value;
    case FFieldType of
      'C': if Value > 254 then raise Exception.Create('Invalid Field Length');
      'D': if Value <> 8 then raise Exception.Create('Invalid Field Length');
      'L': if Value <> 1 then raise Exception.Create('Invalid Field Length');
      'F','N':
        if Value > 20 then raise Exception.Create('Invalid Field Length') else
        if Value < FDecimalCount+2 then raise Exception.Create('Field Length too small');
    end;
  end;
end;

Procedure TDBFField.SetDecimalCount(Value: Byte);
begin
  if Value <> FDecimalCount then
  begin
    FDecimalCount := Value;
    if FFieldType in ['F','N'] then
    begin
      if Value > FFieldlength-2 then raise Exception.Create('Field Length too small');
    end else
    begin
      if Value <> 0 then raise Exception.Create('Invalid Decimal Count');
    end;
  end;
end;

Procedure TDBFField.Validate;
begin
  if (FFieldName = '') or (FFieldType = #0) then raise Exception.Create('Uninitialized DBF Field');
end;

////////////////////////////////////////////////////////////////////////////////

Function TDBFFile.GetFieldNames(Field: Integer): String;
begin
  Result := FFields[Field].FFieldName;
end;

Function TDBFFile.GetFieldTypes(Field: Integer): Char;
begin
  Result := FFields[Field].FFieldType;
end;

Function TDBFFile.GetFieldValues(Field: Integer): variant;
begin
  Result := FFields[Field].FieldValue;
end;

Function TDBFFile.IndexOf(const FieldName: String): Integer;
begin
  Result := -1;
  for var Field := 0 to FFieldCount-1 do
  if SameText(FFields[Field].FFieldName,FieldName) then
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
      if Chr <> #0 then FFields[Field].FFieldName := FFields[Field].FFieldName + Chr;
    end;
    FFields[Field].FFieldType := FileReader.ReadChar;
    for var Skip := 1 to 4 do FileReader.ReadByte; // Reserved
    FFields[Field].FFieldLength := FileReader.ReadByte;
    FFields[Field].FDecimalCount := FileReader.ReadByte;
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
        for var FieldChar := 1 to FFields[Field].FFieldLength do FieldValue := FieldValue + FileReader.ReadChar;
        case FFields[Field].FFieldType of
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
                 raise Exception.Create('Invalid field value (' + FFields[Field].FFieldName +')');
          'F','N':
               begin
                 FieldValue := Trim(FieldValue);
                 if FieldValue = '' then
                   VarClear(FFields[Field].FieldValue)
                 else
                   if FFields[Field].FDecimalCount = 0 then
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

////////////////////////////////////////////////////////////////////////////////

Constructor TDBFWriter.Create(const FileName: String; const Fields: array of TDBFField);
begin
  inherited Create;
  FFieldCount := Length(Fields);
  FFields := TArrayBuilder<TDBFField>.Create(Fields);
  // Validate fields
  for var Field := low(FFields) to high(FFields) do
  if IndexOf(Fields[Field].FFieldName) = Field then
    Fields[Field].Validate
  else
    raise Exception.Create('Duplicate Field ' + Fields[field].FFieldName);
end;

Constructor TDBFWriter.Create(const FileName: String; const DBFFile: TDBFFile);
begin
  Create(FileName,DBFFile.FFields);
end;

Procedure TDBFWriter.SetFieldValues(Field: Integer; Value: Variant);
begin
  FFields[Field].FieldValue := Value;
end;

Procedure TDBFWriter.AppendRecord;
begin
  Inc(FRecordCount);
end;

Destructor TDBFWriter.Destroy;
begin
  // Update record count
  inherited Destroy;
end;

end.
