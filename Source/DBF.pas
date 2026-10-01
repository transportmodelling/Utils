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
  Classes, SysUtils, Math, Variants, Generics.Collections, ArrBld;

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

  TDBFFieldBuilder = Class
  // Sizes a field to the values it is to hold: logical, date, numeric with or without decimals,
  // or text, whichever holds them all
  private
    Type
      TKind = (fkNone,fkLogical,fkDate,fkInteger,fkFloat,fkText);
    Const
      Decimals = 6;  // of a numeric field holding fractions
    Var
      FKind: TKind;
      FDigits: Integer;  // of a number before the decimal point, with its sign
      FWidth: Integer;   // of a value as text
    Function ValueKind(const Value: Variant): TKind;
  public
    // A null or empty value adds nothing
    Procedure Add(const Value: Variant);
    // The field holding the values added, under the name given. Text longer than the field and
    // decimals beyond those of the field are truncated when written.
    Function Field(const FieldName: String): TDBFField;
    // A valid field name for any text: upper case, letters, digits and underscores only, at
    // most ten characters, and not one of TakenNames
    Function ValidName(const Name: String; const TakenNames: array of String): String;
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
    FHeaderCodePage: Integer;
    FEncoding: TEncoding;
    OwnsEncoding: Boolean;
    Buffer: TBytes;
    Function LanguageDriverCodePage(const LanguageDriver: Byte): Integer;
    Function UTF8Length(const Bytes: TBytes; const Count: Integer; out DecodeCount: Integer): Boolean;
    Procedure SkipBytes(const Count: Integer);
    Procedure ReadTableHeader;
    Procedure InitEncoding(const Encoding: TEncoding);
    Procedure ReadFieldDescriptors;
    Procedure ReadBuffer(const Count: Integer; const Offset: Integer = 0);
    Function  DecodeBuffer(const Count: Integer): String;
    Procedure ReadFieldValue(const Field: Integer);
    Function  ReadTextFieldValue(const Field: Integer; out Asterisks,Nullify: Boolean): String;
    Function  ParseTextFieldValue(const Field: Integer; const FieldValue: String; const Asterisks,Nullify: Boolean): Variant;
    Function  ParseDateFieldValue(const FieldValue: String): Variant;
    Function  ParseLogicalFieldValue(const Field: Integer; const FieldValue: String): Variant;
    Function  ParseNumericFieldValue(const Field: Integer; const FieldValue: String): Variant;
  public
    // The text in the file is read in the Encoding passed in (which the
    // caller keeps owning), or else in the code page of the language driver
    // in the header. When neither gives one, each text value is read as UTF-8
    // when it is valid UTF-8, and in the system's ANSI code page otherwise.
    // A convention outside the file, such as a shapefile's .cpg, is for the
    // caller to turn into the Encoding.
    Constructor Create(const FileName: String; const Encoding: TEncoding = nil);
    Function NextRecord: Boolean; overload;
    Function NextRecord(var Values: array of Variant): Boolean; overload;
    Destructor Destroy; override;
  public
    Property RecordIndex: Integer read FRecordIndex;
    // The encoding the text is read in; nil when it is detected per value
    Property Encoding: TEncoding read FEncoding;
    // The code page the language driver in the header declares, whether or
    // not the text is read in it; 0 when there is none or it is not known.
    // Compare it with Encoding to see if an Encoding passed in disagrees.
    Property HeaderCodePage: Integer read FHeaderCodePage;
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

Function TDBFFieldBuilder.ValueKind(const Value: Variant): TKind;
begin
  case VarType(Value) and varTypeMask of
    varEmpty,varNull: Result := fkNone;
    varBoolean: Result := fkLogical;
    varDate: Result := fkDate;
    varSmallint,varInteger,varShortInt,varByte,varWord,varLongWord,varInt64,varUInt64: Result := fkInteger;
    varSingle,varDouble,varCurrency: Result := fkFloat;
    else Result := fkText;
  end;
end;

Procedure TDBFFieldBuilder.Add(const Value: Variant);
begin
  var Kind := ValueKind(Value);
  if Kind = fkNone then Exit;
  // The kind holding this value and those before: a number can hold whole numbers, text anything
  if FKind = fkNone then FKind := Kind else
  if FKind <> Kind then
  if (FKind in [fkInteger,fkFloat]) and (Kind in [fkInteger,fkFloat]) then FKind := fkFloat else FKind := fkText;
  if Kind in [fkInteger,fkFloat] then
  begin
    var Number: Float64 := Value;
    var Digits := Length(IntToStr(Trunc(Abs(Number))));
    if Number < 0 then Inc(Digits);
    if Digits > FDigits then FDigits := Digits;
  end;
  var Width := Length(VarToStr(Value));
  if Width > FWidth then FWidth := Width;
end;

Function TDBFFieldBuilder.Field(const FieldName: String): TDBFField;
begin
  case FKind of
    fkLogical: Result := TDBFField.Create(FieldName,'L',1,0);
    fkDate: Result := TDBFField.Create(FieldName,'D',8,0);
    fkInteger: Result := TDBFField.Create(FieldName,'N',Min(Max(FDigits,1),20),0,true);
    fkFloat: Result := TDBFField.Create(FieldName,'N',Min(Max(FDigits,1)+1+Decimals,20),Decimals,true);
    else Result := TDBFField.Create(FieldName,'C',Min(Max(FWidth,1),254),0,true);
  end;
end;

Function TDBFFieldBuilder.ValidName(const Name: String; const TakenNames: array of String): String;
begin
  Result := '';
  for var Ch in UpperCase(Name) do
  if CharInSet(Ch,['A'..'Z','0'..'9','_']) then Result := Result + Ch else Result := Result + '_';
  if Result = '' then Result := 'FIELD';
  Result := Copy(Result,1,10);
  // A number tells names apart that the rules made the same
  var Base := Result;
  var Number := 1;
  repeat
    var Taken := false;
    for var TakenName in TakenNames do
    if SameText(TakenName,Result) then
    begin
      Taken := true;
      Break;
    end;
    if not Taken then Exit;
    Inc(Number);
    Result := Copy(Base,1,10-Length(Number.ToString)) + Number.ToString;
  until false;
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

Constructor TDBFReader.Create(const FileName: String; const Encoding: TEncoding = nil);
begin
  inherited Create;
  FRecordIndex := -1;
  FFileName := FileName;
  FileStream := TBufferedFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite,4096);
  FileReader := nil;
  // Only reads bytes; the text is decoded in DecodeBuffer
  FileReader := TBinaryReader.Create(FileStream);
  ReadTableHeader;
  InitEncoding(Encoding);
  ReadFieldDescriptors;
  if Version in [48,49,50] then SkipBytes(263); // Read Visual FoxPro header;
end;

Function TDBFReader.LanguageDriverCodePage(const LanguageDriver: Byte): Integer;
// The code page of the language driver ids in common use; 0 for none (0) or
// an id not listed
begin
  case LanguageDriver of
    $01: Result := 437;  // U.S. MS-DOS
    $02: Result := 850;  // International MS-DOS
    $03,$57,$58,$59: Result := 1252; // Windows ANSI
    $64: Result := 852;  // Eastern European MS-DOS
    $65: Result := 866;  // Russian MS-DOS
    $78: Result := 950;  // Chinese (Hong Kong SAR, Taiwan) Windows
    $79: Result := 949;  // Korean Windows
    $7A: Result := 936;  // Chinese (PRC, Singapore) Windows
    $7B: Result := 932;  // Japanese Windows
    $7C: Result := 874;  // Thai Windows
    $7D: Result := 1255; // Hebrew Windows
    $7E: Result := 1256; // Arabic Windows
    $C8: Result := 1250; // Eastern European Windows
    $C9: Result := 1251; // Russian Windows
    $CA: Result := 1254; // Turkish Windows
    $CB: Result := 1253; // Greek Windows
    $CC: Result := 1257; // Baltic Windows
    else Result := 0;
  end;
end;

Function TDBFReader.UTF8Length(const Bytes: TBytes; const Count: Integer; out DecodeCount: Integer): Boolean;
// Whether the bytes are UTF-8, and if so how many of them to decode. A value
// the writer cut off in the middle of a character still counts as UTF-8, less
// the partial character, provided the rest holds a multi-byte character: a
// lone high byte at the end is more likely ANSI.
begin
  var Index := 0;
  var MultiByte := false;
  while Index < Count do
  begin
    var Lead := Bytes[Index];
    var CharLength: Integer;
    if Lead < $80 then CharLength := 1 else
    if (Lead >= $C2) and (Lead <= $DF) then CharLength := 2 else
    if (Lead >= $E0) and (Lead <= $EF) then CharLength := 3 else
    if (Lead >= $F0) and (Lead <= $F4) then CharLength := 4 else
      Exit(false);
    for var Next := Index+1 to Index+CharLength-1 do
    begin
      if Next >= Count then
      begin
        // Cut off at the end
        DecodeCount := Index;
        Exit(MultiByte);
      end;
      if Bytes[Next] and $C0 <> $80 then Exit(false);
    end;
    if CharLength > 1 then MultiByte := true;
    Inc(Index,CharLength);
  end;
  DecodeCount := Count;
  Result := true;
end;

Procedure TDBFReader.InitEncoding(const Encoding: TEncoding);
begin
  if Encoding <> nil then
    FEncoding := Encoding
  else
    if FHeaderCodePage <> 0 then
    try
      FEncoding := TEncoding.GetEncoding(FHeaderCodePage);
      OwnsEncoding := true;
    except
      // A code page this system does not have: detect the encoding per value
      on EEncodingError do FEncoding := nil;
    end;
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
  FHeaderCodePage := LanguageDriverCodePage(FileReader.ReadByte); // Language driver
  SkipBytes(2); // Reserved
end;

Procedure TDBFReader.ReadFieldDescriptors;
Const
  HeaderTerminator = 13;
begin
  // The first byte of a descriptor is the first of the field name
  var First := FileReader.ReadByte;
  while First <> HeaderTerminator do
  begin
    if Length(FFields) <= FFieldCount then SetLength(FFields,FFieldCount+16);
    ReadBuffer(10,1);
    Buffer[0] := First;
    // The name ends at the first #0
    var NameLength := 0;
    while (NameLength < 11) and (Buffer[NameLength] <> 0) do Inc(NameLength);
    FFields[FFieldCount].FFieldName := DecodeBuffer(NameLength);
    FFields[FFieldCount].FFieldType := Char(FileReader.ReadByte);
    SkipBytes(4); // Reserved
    FFields[FFieldCount].FFieldLength := FileReader.ReadByte;
    FFields[FFieldCount].FDecimalCount := FileReader.ReadByte;
    SkipBytes(14); // Reserved
    Inc(FFieldCount);
    First := FileReader.ReadByte;
  end;
  SetLength(FFields,FFieldCount);
end;

Procedure TDBFReader.ReadBuffer(const Count: Integer; const Offset: Integer = 0);
begin
  if Length(Buffer) < Offset+Count then SetLength(Buffer,Offset+Count);
  if FileReader.Read(Buffer,Offset,Count) < Count then raise Exception.Create('Unexpected end of file');
end;

Function TDBFReader.DecodeBuffer(const Count: Integer): String;
begin
  if FEncoding <> nil then
    Result := FEncoding.GetString(Buffer,0,Count)
  else
  begin
    var DecodeCount: Integer;
    if UTF8Length(Buffer,Count,DecodeCount) then
      Result := TEncoding.UTF8.GetString(Buffer,0,DecodeCount)
    else
      Result := TEncoding.ANSI.GetString(Buffer,0,Count);
  end;
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
  // The field length is in bytes, which in a multi-byte encoding need not be
  // the number of characters. So read the bytes, then decode them together.
  var Count := FFields[Field].FFieldLength;
  ReadBuffer(Count);
  Asterisks := true;
  Nullify := true;
  for var Index := 0 to Count-1 do
  begin
    Asterisks := Asterisks and (Buffer[Index] = Ord('*'));
    Nullify := Nullify and (Buffer[Index] = 0);
  end;
  Result := DecodeBuffer(Count);
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
      DeletedRecord := (FileReader.ReadByte = Ord('*'));
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
  if OwnsEncoding then FEncoding.Free;
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
  var NDecimals: Integer := FFields[Field].FDecimalCount;
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
