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
  // The dialect a file is written in. It decides the version byte in the
  // header, and the meaning of the field types whose letter differs in
  // meaning between dialects.
  TDBFDialect = (dbDBase3,dbDBase4,dbVisualFoxPro);

  // The field types this unit handles:
  //   C      text
  //   D      date, as 8 characters
  //   L      logical, as 1 character
  //   F,N    number, as characters
  //   I      32-bit integer, binary
  //   O      double, binary (dBase 7)
  //   B      double, binary (Visual FoxPro); a memo block reference, which
  //          this unit does not read, in dBase III and IV
  //   Y      currency, binary (Visual FoxPro)
  //   T      date and time, binary (Visual FoxPro)
  // A file holding any binary field is written as a Visual FoxPro one. Of the
  // two doubles, B is the one other tools are likeliest to read. Every type
  // can hold a null value: in a Visual FoxPro file every field has a bit of
  // its own in the hidden _NullFlags field to say so, and in a dBase III file
  // a text value says so with the bytes of the value itself.
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
    FDialect: TDBFDialect;
    // The bit each field has in the null flags of a record, or -1 for none,
    // the flags of the record at hand, and their length in bytes
    NullFlagBits: TArray<Integer>;
    NullFlags: TBytes;
    NullFlagsLength: Integer;
    Function BinaryFieldValue(const Field: Integer): Boolean;
    Function HasNullFlag(const Field: Integer): Boolean;
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
    // The dialect of the file: the one its version byte declares when reading,
    // and the one its field types ask for when writing
    Property Dialect: TDBFDialect read FDialect;
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
    // The number of fields read before the hidden field holding the null
    // flags, or -1 when the file has no such field
    NullFlagsIndex: Integer;
    // The number of fields read that have a bit in the null flags
    NullBitCount: Integer;
    FHeaderCodePage: Integer;
    FEncoding: TEncoding;
    OwnsEncoding: Boolean;
    Buffer: TBytes;
    Function LanguageDriverCodePage(const LanguageDriver: Byte): Integer;
    Function UTF8Length(const Bytes: TBytes; const Count: Integer; out DecodeCount: Integer): Boolean;
    Procedure SkipBytes(const Count: Integer);
    Function VersionDialect(const Version: Byte): TDBFDialect;
    Procedure ReadVersion;
    Procedure ReadTableHeader;
    Procedure InitEncoding(const Encoding: TEncoding);
    Procedure ReadFieldDescriptors;
    Procedure ReadFieldDescriptor(const First: Byte);
    Function  ReadFieldName(const First: Byte): String;
    Function  NullFlagsField(const FieldType: Char; const FieldName: String): Boolean;
    Procedure SetNullFlagsField(const FieldLength: Byte);
    Procedure AddField(const Field: TDBFField; const Nullable: Boolean);
    Procedure ReadNullFlags;
    Procedure ApplyNullFlags;
    Procedure ReadBuffer(const Count: Integer; const Offset: Integer = 0);
    Function  DecodeBuffer(const Count: Integer): String;
    Procedure ReadFieldValue(const Field: Integer);
    Function  ReadBinaryFieldValue(const Field: Integer): Variant;
    Function  ReadCurrencyFieldValue: Variant;
    Function  ReadDateTimeFieldValue: Variant;
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
    // Where in the record the field starts whose descriptor is written next
    Displacement: Word;
    Function FieldsDialect: TDBFDialect;
    Procedure AssignNullFlagBits;
    Function GetRecordSize(const Fields: array of TDBFField): Word;
    Procedure WriteHeader(const RecordSize: Word);
    Function VersionByte: Byte;
    Function HeaderSize: Word;
    Procedure WriteTableHeader(const RecordSize: Word);
    Procedure WriteFieldDescriptors;
    Procedure WriteFieldDescriptor(const Field: TDBFField; const FieldFlags: Byte);
    Procedure WriteNullFlagsDescriptor;
    Procedure WriteFieldValue(const Field: Integer);
    Procedure WriteFieldByType(const Field: Integer);
    Procedure WriteNullField(const Field: Integer);
    Procedure WriteCharacterField(const Field: Integer);
    Procedure WriteDateField(const Field: Integer);
    Procedure WriteLogicalField(const Field: Integer);
    Procedure WriteNumericField(const Field: Integer);
    Procedure WriteIntegerField(const Field: Integer);
    Procedure WriteDoubleField(const Field: Integer);
    Procedure WriteCurrencyField(const Field: Integer);
    Procedure WriteDateTimeField(const Field: Integer);
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

Const
  // The Julian day number of December 30 1899, which is the zero of a TDateTime
  JulianDayOffset = 2415019;
  // The flags a Visual FoxPro field descriptor holds
  SystemFieldFlag = $01;
  NullableFieldFlag = $02;
  BinaryFieldFlag = $04;
  // The hidden field a Visual FoxPro file holds the null bits of a record in
  NullFlagsFieldName = '_NullFlags';
  NullFlagsFieldType = '0';

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
    'B','O','Y','T': ValidateExactFieldLength(Value,8);
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
      'D','B','O','Y','T': FFieldLength := 8;
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
  // A field read from a file carries the length the file gave it, which for a
  // binary type tells a double apart from a type of the same letter and
  // another meaning, such as a memo block reference in a dBase III or IV file
  case FFieldType of
    'I': ValidateExactFieldLength(FFieldLength,4);
    'B','O','Y','T': ValidateExactFieldLength(FFieldLength,8);
  end;
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

Function TDBFFile.BinaryFieldValue(const Field: Integer): Boolean;
// Whether the field holds its value as a binary number instead of as text.
// Type B is a double in Visual FoxPro, but a memo block reference in dBase
// III and IV, so what it is depends on the dialect.
begin
  case FFields[Field].FFieldType of
    'I','O','Y','T': Result := true;
    'B': Result := (FDialect = dbVisualFoxPro);
    else Result := false;
  end;
end;

Function TDBFFile.HasNullFlag(const Field: Integer): Boolean;
// Whether the field has a bit of its own to say its value holds nothing
begin
  Result := (Field < Length(NullFlagBits)) and (NullFlagBits[Field] >= 0)
            and (NullFlagBits[Field] div 8 < NullFlagsLength);
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
  NullFlagsIndex := -1;
  FileStream := TBufferedFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite,4096);
  FileReader := nil;
  // Only reads bytes; the text is decoded in DecodeBuffer
  FileReader := TBinaryReader.Create(FileStream);
  ReadTableHeader;
  InitEncoding(Encoding);
  ReadFieldDescriptors;
  // The backlink area a Visual FoxPro file has after the field descriptors
  if FDialect = dbVisualFoxPro then SkipBytes(263);
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

Function TDBFReader.VersionDialect(const Version: Byte): TDBFDialect;
// The dialect the version byte in the header declares. Anything not listed is
// taken for dBase III, in which the ambiguous field types are the older ones.
begin
  case Version of
    $30,$31,$32: Result := dbVisualFoxPro;
    $43,$63,$8B,$8C,$BB,$CB: Result := dbDBase4;
    else Result := dbDBase3;
  end;
end;

Procedure TDBFReader.ReadVersion;
begin
  Version := FileReader.ReadByte;
  if Version <> 4 then
    FDialect := VersionDialect(Version)
  else
    raise Exception.Create('dBase level 7 files not supported');
end;

Procedure TDBFReader.ReadTableHeader;
begin
  ReadVersion;
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
    ReadFieldDescriptor(First);
    First := FileReader.ReadByte;
  end;
end;

Procedure TDBFReader.ReadFieldDescriptor(const First: Byte);
// The descriptor whose first byte has been read: of a field of the table, or
// of the hidden field holding the null flags
begin
  var Field := Default(TDBFField);
  Field.FFieldName := ReadFieldName(First);
  Field.FFieldType := Char(FileReader.ReadByte);
  SkipBytes(4); // Reserved
  Field.FFieldLength := FileReader.ReadByte;
  Field.FDecimalCount := FileReader.ReadByte;
  var FieldFlags := FileReader.ReadByte;
  SkipBytes(13); // Reserved
  if NullFlagsField(Field.FFieldType,Field.FFieldName) then
    SetNullFlagsField(Field.FFieldLength)
  else
    AddField(Field,FieldFlags and NullableFieldFlag <> 0);
end;

Function TDBFReader.ReadFieldName(const First: Byte): String;
// The name ends at the first #0
begin
  ReadBuffer(10,1);
  Buffer[0] := First;
  var NameLength := 0;
  while (NameLength < 11) and (Buffer[NameLength] <> 0) do Inc(NameLength);
  Result := DecodeBuffer(NameLength);
end;

Function TDBFReader.NullFlagsField(const FieldType: Char; const FieldName: String): Boolean;
// The hidden field a Visual FoxPro file holds the null bits of a record in
begin
  Result := (FDialect = dbVisualFoxPro) and (FieldType = NullFlagsFieldType)
            and SameText(FieldName,NullFlagsFieldName);
end;

Procedure TDBFReader.SetNullFlagsField(const FieldLength: Byte);
// The hidden field is no field of the table: the values whose bit it sets are
// read as null instead
begin
  NullFlagsIndex := FFieldCount;
  NullFlagsLength := FieldLength;
  SetLength(NullFlags,NullFlagsLength);
end;

Procedure TDBFReader.AddField(const Field: TDBFField; const Nullable: Boolean);
// The fields that can hold null take the bits of the null flags in the order
// they come
begin
  FFields := FFields + [Field];
  if Nullable then
  begin
    NullFlagBits := NullFlagBits + [NullBitCount];
    Inc(NullBitCount);
  end else
    NullFlagBits := NullFlagBits + [-1];
  Inc(FFieldCount);
end;

Procedure TDBFReader.ReadNullFlags;
begin
  if NullFlagsLength > 0 then
  begin
    ReadBuffer(NullFlagsLength);
    Move(Buffer[0],NullFlags[0],NullFlagsLength);
  end;
end;

Procedure TDBFReader.ApplyNullFlags;
begin
  for var Field := 0 to FFieldCount-1 do
  if HasNullFlag(Field) then
  begin
    var Bit := NullFlagBits[Field];
    if NullFlags[Bit div 8] and (1 shl (Bit mod 8)) <> 0 then
      FFields[Field].FieldValue := Null;
  end;
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
    if BinaryFieldValue(Field) then
      FFields[Field].FieldValue := ReadBinaryFieldValue(Field)
    else
    begin
      var FieldValue := ReadTextFieldValue(Field,Asterisks,Nullify);
      FFields[Field].FieldValue := ParseTextFieldValue(Field,FieldValue,Asterisks,Nullify);
    end;
  except
    raise Exception.Create('Error reading dbf-field ' + FFields[Field].FieldName);
  end;
end;

Function TDBFReader.ReadBinaryFieldValue(const Field: Integer): Variant;
begin
  case FFields[Field].FFieldType of
    'I': Result := FileReader.ReadInt32;
    'B','O': Result := FileReader.ReadDouble;
    'Y': Result := ReadCurrencyFieldValue;
    'T': Result := ReadDateTimeFieldValue;
    else raise Exception.Create('Unsupported field type');
  end;
end;

Function TDBFReader.ReadCurrencyFieldValue: Variant;
// A currency value is a 64-bit integer counting ten-thousandths, which is how
// a Currency holds its value too
begin
  var Value: Currency;
  PInt64(@Value)^ := FileReader.ReadInt64;
  Result := Value;
end;

Function TDBFReader.ReadDateTimeFieldValue: Variant;
// A date and time value is the Julian day number followed by the number of
// milliseconds since midnight, each a 32-bit integer. Both zero is no value.
begin
  var Days := FileReader.ReadInt32;
  var MSecs := FileReader.ReadInt32;
  if (Days = 0) and (MSecs = 0) then Result := Null else
  begin
    var Value: TDateTime := (Days-JulianDayOffset) + MSecs/MSecsPerDay;
    Result := Value;
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
      for var Field := 0 to FFieldCount-1 do
      begin
        // The hidden field holding the null flags sits in the record where
        // its descriptor says, which is behind the other fields as a rule
        if Field = NullFlagsIndex then ReadNullFlags;
        ReadFieldValue(Field);
      end;
      if NullFlagsIndex = FFieldCount then ReadNullFlags;
      if NullFlagsIndex >= 0 then ApplyNullFlags;
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
begin
  inherited Create;
  FFieldCount := Length(Fields);
  FFields := TArrayBuilder<TDBFField>.Create(Fields);
  FDialect := FieldsDialect;
  AssignNullFlagBits;
  var RecordSize := GetRecordSize(Fields);
  FileStream := TBufferedFileStream.Create(FileName,fmCreate or fmShareDenyWrite,4096);
  FileWriter := TBinaryWriter.Create(FileStream,TEncoding.ANSI);
  WriteHeader(RecordSize);
end;

Function TDBFWriter.FieldsDialect: TDBFDialect;
// A binary field type is a Visual FoxPro one, and the header must say so for
// other tools to read the file as one
begin
  Result := dbDBase3;
  for var Field := 0 to FFieldCount-1 do
  if CharInSet(FFields[Field].FFieldType,['B','I','O','Y','T']) then Exit(dbVisualFoxPro);
end;

Procedure TDBFWriter.AssignNullFlagBits;
// In a Visual FoxPro file every field gets a bit of its own in the hidden
// _NullFlags field to say its value holds nothing, which is how such a file
// tells, for a text value as much as for a binary one. A dBase III file has
// no such field, and a text value says it there with its own bytes.
begin
  SetLength(NullFlagBits,FFieldCount);
  if FDialect = dbVisualFoxPro then
  begin
    for var Field := 0 to FFieldCount-1 do NullFlagBits[Field] := Field;
    NullFlagsLength := (FFieldCount+7) div 8;
  end else
  begin
    for var Field := 0 to FFieldCount-1 do NullFlagBits[Field] := -1;
    NullFlagsLength := 0;
  end;
  SetLength(NullFlags,NullFlagsLength);
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
  // The hidden field holding the null bits is part of the record too
  Inc(Result,NullFlagsLength);
end;

Procedure TDBFWriter.WriteHeader(const RecordSize: Word);
begin
  WriteTableHeader(RecordSize);
  WriteFieldDescriptors;
  FileWriter.Write(#13); // Header terminator
  // The backlink area of a Visual FoxPro file, which names the database
  // container the table belongs to; it belongs to none, so it stays empty
  if FDialect = dbVisualFoxPro then
  for var Skip := 1 to 263 do FileWriter.Write(#0);
end;

Function TDBFWriter.VersionByte: Byte;
// The version the header declares for the dialect of the file
begin
  if FDialect = dbVisualFoxPro then Result := $30 else Result := $03;
end;

Function TDBFWriter.HeaderSize: Word;
// The table header, the field descriptors, the header terminator and, for a
// Visual FoxPro file, the backlink area that follows them
begin
  Result := (FFieldCount+1)*32 + 1;
  if NullFlagsLength > 0 then Inc(Result,32);
  if FDialect = dbVisualFoxPro then Inc(Result,263);
end;

Procedure TDBFWriter.WriteTableHeader(const RecordSize: Word);
Var
  Year,Month,Day: Word;
begin
  FileWriter.Write(VersionByte);
  DecodeDate(Now,Year,Month,Day);
  FileWriter.Write(Byte(Year-1900));
  FileWriter.Write(Byte(Month));
  FileWriter.Write(Byte(Day));
  FileWriter.Write(RecordCount);
  FileWriter.Write(HeaderSize);
  FileWriter.Write(RecordSize);
  for var Skip := 1 to 20 do FileWriter.Write(#0);
end;

Procedure TDBFWriter.WriteFieldDescriptors;
// The hidden field holding the null bits comes behind the fields themselves
begin
  Displacement := 1; // The deletion marker comes before the fields
  for var Field := 0 to FFieldCount-1 do
  if HasNullFlag(Field) then
    WriteFieldDescriptor(FFields[Field],NullableFieldFlag)
  else
    WriteFieldDescriptor(FFields[Field],0);
  if NullFlagsLength > 0 then WriteNullFlagsDescriptor;
end;

Procedure TDBFWriter.WriteFieldDescriptor(const Field: TDBFField; const FieldFlags: Byte);
begin
  FileWriter.Write(Field.FFieldName.PadRight(11,#0).ToCharArray);
  FileWriter.Write(Field.FFieldType);
  if FDialect = dbVisualFoxPro then
    // Where the field starts in the record, which Visual FoxPro reads here
    FileWriter.Write(Cardinal(Displacement))
  else
    for var Skip := 1 to 4 do FileWriter.Write(#0); // Reserved
  FileWriter.Write(Field.FFieldLength);
  FileWriter.Write(Field.FDecimalCount);
  FileWriter.Write(FieldFlags);
  for var Skip := 1 to 13 do FileWriter.Write(#0); // Reserved
  Inc(Displacement,Field.FFieldLength);
end;

Procedure TDBFWriter.WriteNullFlagsDescriptor;
begin
  var Field := Default(TDBFField);
  Field.FFieldName := NullFlagsFieldName;
  Field.FFieldType := NullFlagsFieldType;
  Field.FFieldLength := NullFlagsLength;
  WriteFieldDescriptor(Field,SystemFieldFlag or BinaryFieldFlag);
end;

Procedure TDBFWriter.WriteFieldValue(const Field: Integer);
begin
  if VarIsNull(FFields[Field].FieldValue) then WriteNullField(Field) else
  try
    WriteFieldByType(Field);
  except
    on E: Exception do
      raise Exception.Create(E.Message + ' (field=' + FFields[Field].FFieldName +
                             '; value=' + VarToStr(FFields[Field].FieldValue) + ')');
  end;
end;

Procedure TDBFWriter.WriteFieldByType(const Field: Integer);
begin
  case FFields[Field].FFieldType of
    'C': WriteCharacterField(Field);
    'D': WriteDateField(Field);
    'L': WriteLogicalField(Field);
    'F','N': WriteNumericField(Field);
    'I': WriteIntegerField(Field);
    'B','O': WriteDoubleField(Field);
    'Y': WriteCurrencyField(Field);
    'T': WriteDateTimeField(Field);
    else raise Exception.Create('Unsupported field type');
  end;
end;

Procedure TDBFWriter.WriteNullField(const Field: Integer);
begin
  // The bit of the field in the null flags of the record says its value holds
  // nothing, in a file that has them. A text field reads back as null anyway
  // when it holds nothing but zero bytes, which is what is written here.
  if HasNullFlag(Field) then
  begin
    var Bit := NullFlagBits[Field];
    NullFlags[Bit div 8] := Byte(NullFlags[Bit div 8] or (1 shl (Bit mod 8)));
  end;
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

Procedure TDBFWriter.WriteCurrencyField(const Field: Integer);
begin
  var Value: Currency := FFields[Field].FieldValue;
  FileWriter.Write(PInt64(@Value)^);
end;

Procedure TDBFWriter.WriteDateTimeField(const Field: Integer);
begin
  var Value: TDateTime := FFields[Field].FieldValue;
  var Days: Integer := Floor(Value);
  var MSecs: Integer := Round((Value-Days)*MSecsPerDay);
  if MSecs = MSecsPerDay then
  begin
    Inc(Days);
    MSecs := 0;
  end;
  FileWriter.Write(Days+JulianDayOffset);
  FileWriter.Write(MSecs);
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
  if NullFlagsLength > 0 then FillChar(NullFlags[0],NullFlagsLength,0);
  for var Field := 0 to FFieldCount-1 do
  begin
    WriteFieldValue(Field);
    FFields[Field].FieldValue := Null;
  end;
  // The null bits of the values just written come behind them, where the
  // descriptor of the hidden field says they are
  if NullFlagsLength > 0 then FileWriter.Write(NullFlags);
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
