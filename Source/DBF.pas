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
  Classes, SysUtils, Variants, Generics.Collections, ArrBld;

Type
  TDBFField = record
  private
    FFieldName: String;
    FFieldType: Char;
    FFieldLength,FDecimalCount: Byte;
    FTruncate: Boolean;
    FieldValue: Variant;
    Procedure ValidateExactFieldLength(const Value,Expected: Byte);
    Procedure ValidateNumericFieldLength(const Value: Byte);
    Procedure ValidateFieldLength(const Value: Byte);
    Procedure SetFieldName(Value: string);
    Procedure SetFieldType(Value: Char);
    Procedure SetFieldLength(Value: Byte);
    Procedure SetDecimalCount(Value: Byte);
    Procedure Validate;
  public
    Constructor Create(const FieldName: String; const FieldType: Char;
                       const FieldLength,DecimalCount: Byte;
                       const Truncate: Boolean = false);
  public
    Property FieldName: String read FFieldName write SetFieldName;
    Property FieldType: Char read FFieldType write SetFieldType;
    Property FieldLength: Byte read FFieldLength write SetFieldLength;
    Property DecimalCount: Byte read FDecimalCount write SetDecimalCount;
    Property Truncate: Boolean read FTruncate;
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
    Function GetFieldLength(Field: Integer): Byte;
    Function GetDecimalCount(Field: Integer): Byte;
    Function GetPairs(Field: Integer): TPair<String,Variant>; overload;
    Function GetFieldValues(Field: Integer): Variant;
  public
    Constructor Create;
    Function IndexOf(const FieldName: String; const MustExist: Boolean = false): Integer;
    Function GetFields: TArray<TDBFField>; overload;
    Function GetFields(const FieldNames: array of String): TArray<TDBFField>; overload;
    Function GetValues: TArray<Variant>;
    Function GetPairs: TArray<TPair<String,Variant>>; overload;
  public
    Property FileName: String read FFileName;
    Property FieldCount: Integer read FFieldCount;
    Property RecordCount: Integer read FRecordCount;
    Property FieldNames[Field: Integer]: String read GetFieldNames;
    Property FieldTypes[Field: Integer]: Char read GetFieldTypes;
    Property FieldLength[Field: Integer]: Byte read GetFieldLength;
    Property DecimalCount[Field: Integer]: Byte read GetDecimalCount;
    Property Pairs[Field: Integer]: TPair<String,Variant> read GetPairs;
    Property FieldValues[Field: Integer]: Variant read GetFieldValues; default;
  end;

  TDBFReader = Class(TDBFFile)
  private
    FRecordIndex: Integer;
    FileReader: TBinaryReader;
    Version: Byte;
    Procedure SkipBytes(const Count: Integer);
    Procedure ReadTableHeader;
    Procedure ReadFieldDescriptors;
    Procedure ReadFieldValue(const Field: Integer);
    Function  ReadTextFieldValue(const Field: Integer; out Asterisks,Nullify: Boolean): String;
    Function  ParseTextFieldValue(const Field: Integer; const FieldValue: String; const Asterisks,Nullify: Boolean): Variant;
    Function  ParseDateFieldValue(const FieldValue: String): Variant;
    Function  ParseLogicalFieldValue(const Field: Integer; const FieldValue: String): Variant;
    Function  ParseNumericFieldValue(const Field: Integer; const FieldValue: String): Variant;
  public
    Constructor Create(const FileName: String);
    Function NextRecord: Boolean; overload;
    Function NextRecord(var Values: array of Variant): Boolean; overload;
    Destructor Destroy; override;
  public
    Property RecordIndex: Integer read FRecordIndex;
  end;

  TDBFWriter = Class(TDBFFile)
  private
    FileWriter: TBinaryWriter;
    Function GetRecordSize(const Fields: array of TDBFField): Word;
    Procedure WriteTableHeader(const RecordSize: Word);
    Procedure WriteFieldDescriptor(const Field: TDBFField);
    Procedure WriteFieldValue(const Field: Integer);
    Procedure WriteNullField(const Field: Integer);
    Procedure WriteCharacterField(const Field: Integer);
    Procedure WriteDateField(const Field: Integer);
    Procedure WriteLogicalField(const Field: Integer);
    Procedure WriteNumericField(const Field: Integer);
    Procedure WriteIntegerField(const Field: Integer);
    Procedure WriteDoubleField(const Field: Integer);
    Function NormalizeNumericText(const Field: Integer; const Value: Float64): String;
    Procedure SetFieldValues(Field: Integer; Value: Variant);
  public
    Constructor Create(const FileName: String; const Fields: array of TDBFField); overload;
    Constructor Create(const FileName: String; const DBFFile: TDBFFile); overload;
    Procedure AppendRecord; overload;
    Procedure AppendRecord(const Values: array of Variant); overload;
    Destructor Destroy; override;
  public
    Property FieldValues[Field: Integer]: Variant read GetFieldValues write SetFieldValues; default;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TDBFField.Create(const FieldName: String; const FieldType: Char;
                             const FieldLength,DecimalCount: Byte;
                             const Truncate: Boolean = false);
begin
  FTruncate := Truncate;
  SetFieldName(FieldName);
  SetFieldType(FieldType);
  SetFieldLength(FieldLength);
  SetDecimalCount(DecimalCount);
end;

Procedure TDBFField.ValidateExactFieldLength(const Value,Expected: Byte);
begin
  if Value <> Expected then raise Exception.Create('Invalid Field Length');
end;

Procedure TDBFField.ValidateNumericFieldLength(const Value: Byte);
begin
  if Value > 20 then raise Exception.Create('Invalid Field Length');
  if (FDecimalCount > 0) and (Value < FDecimalCount+2) then raise Exception.Create('Invalid Field Length');
end;

Procedure TDBFField.ValidateFieldLength(const Value: Byte);
begin
  case FFieldType of
    'C': if Value > 254 then raise Exception.Create('Invalid Field Length');
    'D': ValidateExactFieldLength(Value,8);
    'L': ValidateExactFieldLength(Value,1);
    'F','N': ValidateNumericFieldLength(Value);
    'I': ValidateExactFieldLength(Value,4);
    'O': ValidateExactFieldLength(Value,8);
  end;
end;

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
    FDecimalCount := 0;
    case Value of
      'C','F','N': FFieldLength := 10;
      'D','O': FFieldLength := 8;
      'L': FFieldLength := 1;
      'I': FFieldLength := 4;
      else raise Exception.Create('Unsupported Field Type ' + Value);
    end;
  end;
end;

Procedure TDBFField.SetFieldLength(Value: Byte);
begin
  if Value <> FFieldLength then
  if Value > 0 then
  begin
    ValidateFieldLength(Value);
    FFieldLength := Value;
  end else
    raise Exception.Create('Invalid Field Length');
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

Constructor TDBFFile.Create;
begin
  inherited Create;
  FormatSettings.DecimalSeparator := '.';
end;

Function TDBFFile.GetFieldNames(Field: Integer): String;
begin
  Result := FFields[Field].FFieldName;
end;

Function TDBFFile.GetFieldTypes(Field: Integer): Char;
begin
  Result := FFields[Field].FFieldType;
end;

Function TDBFFile.GetFieldLength(Field: Integer): Byte;
begin
  Result := FFields[Field].FieldLength;
end;

Function TDBFFile.GetDecimalCount(Field: Integer): Byte;
begin
  Result := FFields[Field].DecimalCount;
end;

Function TDBFFile.GetFieldValues(Field: Integer): variant;
begin
  Result := FFields[Field].FieldValue;
end;

Function TDBFFile.GetPairs(Field: Integer): TPair<String,Variant>;
begin
  Result.Key := FFields[Field].FFieldName;
  Result.Value := FFields[Field].FieldValue;
end;

Function TDBFFile.IndexOf(const FieldName: String; const MustExist: Boolean = false): Integer;
begin
  Result := -1;
  for var Field := 0 to FFieldCount-1 do
  if SameText(FFields[Field].FFieldName,FieldName) then Exit(Field);
  if MustExist then raise Exception.Create('Field ' + FieldName + ' not found in ' + FFileName);
end;

Function TDBFFile.GetFields: TArray<TDBFField>;
begin
  Result := Copy(FFields);
end;

Function TDBFFile.GetFields(const FieldNames: array of String): TArray<TDBFField>;
begin
  SetLength(Result,Length(FieldNames));
  for var Field := low(Result) to high(Result) do
  Result[Field] := FFields[IndexOf(FieldNames[Field],true)];
end;

Function TDBFFile.GetValues: TArray<Variant>;
begin
  SetLength(Result,FFieldCount);
  for var Field := 0 to FFieldCount-1 do Result[Field] := FFields[Field].FieldValue;
end;

Function TDBFFile.GetPairs: TArray<TPair<String,Variant>>;
begin
  SetLength(Result,FFieldCount);
  for var Field := 0 to FFieldCount-1 do Result[Field] := GetPairs(Field);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TDBFReader.Create(const FileName: String);
begin
  inherited Create;
  FRecordIndex := -1;
  FFileName := FileName;
  FileStream := TBufferedFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite,4096);
  FileReader := nil;
  FileReader := TBinaryReader.Create(FileStream,TEncoding.ANSI);
  ReadTableHeader;
  ReadFieldDescriptors;
  if Version in [48,49,50] then SkipBytes(263); // Read Visual FoxPro header;
end;

Procedure TDBFReader.SkipBytes(const Count: Integer);
begin
  for var i := 1 to Count do FileReader.ReadByte;
end;

Procedure TDBFReader.ReadTableHeader;
begin
  Version := FileReader.ReadByte;
  if Version = 4 then raise Exception.Create('dBase level 7 files not supported');
  SkipBytes(3); // Last update date
  FRecordCount := FileReader.ReadInteger;
  SkipBytes(2); // Position of first data record
  SkipBytes(2); // Nr record bytes
  SkipBytes(2); // Reserved
  SkipBytes(1); // Incomplete dBase IV transaction
  SkipBytes(1); // dBase IV encryption flag
  SkipBytes(12); // Reserved
  SkipBytes(1); // Production MDX flag
  SkipBytes(1); // Language driver
  SkipBytes(2); // Reserved
end;

Procedure TDBFReader.ReadFieldDescriptors;
begin
  while FileReader.PeekChar <> 13 do
  begin
    if Length(FFields) <= FFieldCount then SetLength(FFields,FFieldCount+16);
    for var NameChar := 1 to 11 do
    begin
      var Chr := FileReader.ReadChar;
      if Chr <> #0 then FFields[FFieldCount].FFieldName := FFields[FFieldCount].FFieldName + Chr;
    end;
    FFields[FFieldCount].FFieldType := FileReader.ReadChar;
    SkipBytes(4); // Reserved
    FFields[FFieldCount].FFieldLength := FileReader.ReadByte;
    FFields[FFieldCount].FDecimalCount := FileReader.ReadByte;
    SkipBytes(14); // Reserved
    Inc(FFieldCount);
  end;
  SetLength(FFields,FFieldCount);
  FileReader.ReadByte; // Header terminator
end;

Procedure TDBFReader.ReadFieldValue(const Field: Integer);
Var
  Asterisks,Nullify: Boolean;
begin
  try
    case FFields[Field].FFieldType of
      'I': FFields[Field].FieldValue := FileReader.ReadInt32;
      'O': FFields[Field].FieldValue := FileReader.ReadDouble;
      else
        begin
          var FieldValue := ReadTextFieldValue(Field,Asterisks,Nullify);
          FFields[Field].FieldValue := ParseTextFieldValue(Field,FieldValue,Asterisks,Nullify);
        end;
    end;
  except
    raise Exception.Create('Error reading dbf-field ' + FFields[Field].FieldName);
  end;
end;

Function TDBFReader.ReadTextFieldValue(const Field: Integer; out Asterisks,Nullify: Boolean): String;
begin
  Result := '';
  Asterisks := true;
  Nullify := true;
  for var FieldChar := 1 to FFields[Field].FFieldLength do
  begin
    var Chr := FileReader.ReadChar;
    Asterisks := Asterisks and (Chr = '*');
    Nullify := Nullify and (Chr = #0);
    Result := Result + Chr;
  end;
end;

Function TDBFReader.ParseTextFieldValue(const Field: Integer; const FieldValue: String;
                                        const Asterisks,Nullify: Boolean): Variant;
begin
  if Nullify then Result := Null else
  if Asterisks then
    if FFields[Field].FFieldType = 'C' then Result := FieldValue else Result := Null
  else
    case FFields[Field].FFieldType of
      'C': Result := Trim(FieldValue);
      'D': Result := ParseDateFieldValue(FieldValue);
      'L': Result := ParseLogicalFieldValue(Field,FieldValue);
      'F','N': Result := ParseNumericFieldValue(Field,FieldValue);
      else Result := Null;
    end;
end;

Function TDBFReader.ParseDateFieldValue(const FieldValue: String): Variant;
begin
  if Trim(FieldValue) <> '' then
  begin
    var Year := Copy(FieldValue,1,4).ToInteger;
    var Month := Copy(FieldValue,5,2).ToInteger;
    var Day := Copy(FieldValue,7,2).ToInteger;
    Result := EncodeDate(Year,Month,Day);
  end else
    Result := Unassigned;
end;

Function TDBFReader.ParseLogicalFieldValue(const Field: Integer; const FieldValue: String): Variant;
begin
  if FieldValue.Length = 1 then
    case FieldValue[1] of
      'T','t','Y','y': Result := true;
      'F','f','N','n': Result := false;
      '?': Result := Null;
      else raise Exception.Create('Invalid field value (' + FFields[Field].FFieldName +')');
    end
  else
    raise Exception.Create('Invalid field value (' + FFields[Field].FFieldName +')');
end;

Function TDBFReader.ParseNumericFieldValue(const Field: Integer; const FieldValue: String): Variant;
begin
  var Value := Trim(FieldValue);
  if Value = '' then Result := Null else
  if FFields[Field].FDecimalCount = 0 then
    Result := StrToInt(Value)
  else
    Result := StrToFloat(Value,FormatSettings);
end;

Function TDBFReader.NextRecord: Boolean;
Var
  DeletedRecord: Boolean;
begin
  if FRecordIndex < FRecordCount-1 then
  begin
    Result := true;
    repeat
      DeletedRecord := (FileReader.ReadChar = '*');
      for var Field := 0 to FFieldCount-1 do ReadFieldValue(Field);
    until not DeletedRecord;
    Inc(FRecordIndex);
  end else
    Result := false;
end;

Function TDBFReader.NextRecord(var Values: array of Variant): Boolean;
begin
  if Length(Values) = FFieldCount then
    if NextRecord then
    begin
      Result := true;
      for var Field := 0 to FFieldCount-1 do Values[Field] := GetFieldValues(Field);
    end else
      Result := false
  else
    raise Exception.Create('Invalid number of fields');
end;

Destructor TDBFReader.Destroy;
begin
  FileReader.Free;
  FileStream.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TDBFWriter.Create(const FileName: String; const Fields: array of TDBFField);
Var
  RecordSize: Word;
  Completed: Boolean;
begin
  inherited Create;
  Completed := false;
  FFieldCount := Length(Fields);
  FFields := TArrayBuilder<TDBFField>.Create(Fields);
  RecordSize := GetRecordSize(Fields);
  FileStream := TBufferedFileStream.Create(FileName,fmCreate or fmShareDenyWrite,4096);
  FileWriter := TBinaryWriter.Create(FileStream,TEncoding.ANSI);
  WriteTableHeader(RecordSize);
  for var Field := 0 to FFieldCount-1 do WriteFieldDescriptor(FFields[Field]);
  FileWriter.Write(#13); // Header terminator
end;

Constructor TDBFWriter.Create(const FileName: String; const DBFFile: TDBFFile);
begin
  Create(FileName,DBFFile.FFields);
end;

Function TDBFWriter.GetRecordSize(const Fields: array of TDBFField): Word;
begin
  Result := 1; // Deletion marker
  for var Field := low(FFields) to high(FFields) do
  if IndexOf(Fields[Field].FFieldName) = Field then
  begin
    Fields[Field].Validate;
    Inc(Result,Fields[Field].FFieldLength);
  end else
    raise Exception.Create('Duplicate Field ' + Fields[field].FFieldName);
end;

Procedure TDBFWriter.WriteTableHeader(const RecordSize: Word);
Var
  B: Byte;
  HeaderSize: Word;
  Year,Month,Day: Word;
begin
  FileWriter.Write(#3); // Version
  DecodeDate(Now,Year,Month,Day);
  B := Year-1900; // Year
  FileWriter.Write(B);
  B := Month; // Month
  FileWriter.Write(B);
  B := Day; // Day
  FileWriter.Write(B);
  FileWriter.Write(RecordCount);
  HeaderSize := (FFieldCount+1)*32 + 1;
  FileWriter.Write(HeaderSize);
  FileWriter.Write(RecordSize);
  for var Skip := 1 to 20 do FileWriter.Write(#0);
end;

Procedure TDBFWriter.WriteFieldDescriptor(const Field: TDBFField);
begin
  var Name := Field.FFieldName;
  while Length(Name) < 11 do Name := Name + #0;
  FileWriter.Write(Name.ToCharArray);
  FileWriter.Write(Field.FFieldType);
  for var Skip := 1 to 4 do FileWriter.Write(#0); // Reserved
  FileWriter.Write(Field.FFieldLength);
  FileWriter.Write(Field.FDecimalCount);
  for var Skip := 1 to 14 do FileWriter.Write(#0); // Reserved
end;

Procedure TDBFWriter.WriteFieldValue(const Field: Integer);
begin
  if VarIsNull(FFields[Field].FieldValue) then WriteNullField(Field) else
  try
    case FFields[Field].FFieldType of
      'C': WriteCharacterField(Field);
      'D': WriteDateField(Field);
      'L': WriteLogicalField(Field);
      'F','N': WriteNumericField(Field);
      'I': WriteIntegerField(Field);
      'O': WriteDoubleField(Field);
      else raise Exception.Create('Unsupported field type');
    end;
  except
    on E: Exception do
      raise Exception.Create(E.Message + ' (field=' + FFields[Field].FFieldName +
                             '; value=' + VarToStr(FFields[Field].FieldValue) + ')');
  end;
end;

Procedure TDBFWriter.WriteNullField(const Field: Integer);
begin
  for var Chr := 1 to FFields[Field].FieldLength do FileWriter.Write(#0);
end;

Procedure TDBFWriter.WriteCharacterField(const Field: Integer);
begin
  var Value: String := FFields[Field].FieldValue;
  if Value.Length > FFields[Field].FieldLength then
    if FFields[Field].FTruncate then
      Value := Copy(Value,1,FFields[Field].FieldLength)
    else
      raise Exception.Create('Field value exceeds field length')
  else
    while Length(Value) < FFields[Field].FieldLength do Value := Value + #0;
  FileWriter.Write(Value.ToCharArray);
end;

Procedure TDBFWriter.WriteDateField(const Field: Integer);
begin
  var Year,Month,Day: Word;
  var Value: TDateTime := FFields[Field].FieldValue;
  DecodeDate(Value,Year,Month,Day);
  FileWriter.Write(IntToStr(Year).ToCharArray);
  if Month < 10 then
    FileWriter.Write(('0'+IntToStr(Month)).ToCharArray)
  else
    FileWriter.Write(IntToStr(Month).ToCharArray);
  if Day < 10 then
    FileWriter.Write(('0'+IntToStr(Day)).ToCharArray)
  else
    FileWriter.Write(IntToStr(Day).ToCharArray);
end;

Procedure TDBFWriter.WriteLogicalField(const Field: Integer);
begin
  var Value: Boolean := FFields[Field].FieldValue;
  if Value then
    FileWriter.Write('T')
  else
    FileWriter.Write('F');
end;

Procedure TDBFWriter.WriteNumericField(const Field: Integer);
begin
  var Value: Float64 := FFields[Field].FieldValue;
  var Text := NormalizeNumericText(Field,Value);
  FileWriter.Write(Text.ToCharArray);
end;

Procedure TDBFWriter.WriteIntegerField(const Field: Integer);
begin
  var Value: Integer := FFields[Field].FieldValue;
  FileWriter.Write(Value);
end;

Procedure TDBFWriter.WriteDoubleField(const Field: Integer);
begin
  var Value: Float64 := FFields[Field].FieldValue;
  FileWriter.Write(Value);
end;

Function TDBFWriter.NormalizeNumericText(const Field: Integer; const Value: Float64): String;
begin
  var NDecimals := FFields[Field].FDecimalCount;
  repeat
    Result := Format('%.*f',[NDecimals,Value]);
    // Remove excess decimals
    if Result.Length > FFields[Field].FFieldLength then
    if FFields[Field].FTruncate then
      if NDecimals > 0 then
      begin
        NDecimals := NDecimals-(Result.Length-FFields[Field].FFieldLength);
        if NDecimals = -1 then NDecimals := 0 else
        if NDecimals < 0 then raise Exception.Create('Field value exceeds field length');
      end else
        raise Exception.Create('Field value exceeds field length')
    else
      raise Exception.Create('Field value exceeds field length');
  until Result.Length <= FFields[Field].FFieldLength;
  // Align the string
  while Result.Length < FFields[Field].FFieldLength do Result := ' ' + Result;
end;

Procedure TDBFWriter.SetFieldValues(Field: Integer; Value: Variant);
begin
  FFields[Field].FieldValue := Value;
end;

Procedure TDBFWriter.AppendRecord;
begin
  FileWriter.Write(' '); // Undeleted record
  for var Field := 0 to FFieldCount-1 do
  begin
    WriteFieldValue(Field);
    FFields[Field].FieldValue := Null;
  end;
  Inc(FRecordCount);
end;

Procedure TDBFWriter.AppendRecord(const Values: array of Variant);
begin
  if Length(Values) = FFieldCount then
  begin
    for var Field := 0 to FFieldCount-1 do SetFieldValues(Field,Values[Field]);
    AppendRecord;
  end else
    raise Exception.Create('Invalid number of fields');
end;

Destructor TDBFWriter.Destroy;
begin
  // Write eof marker
  var EOF: Byte := 26;
  if FileWriter <> nil then FileWriter.Write(EOF);
  // Update record count
  if FileStream <> nil then
  begin
    FileStream.FlushBuffer;
    FileStream.Position := 4;
    FileWriter.Write(RecordCount);
  end;
  // Close file
  FileWriter.Free;
  FileStream.Free;
  inherited Destroy;
end;

end.
