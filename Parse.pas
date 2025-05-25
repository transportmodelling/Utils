unit Parse;

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
  Classes, SysUtils, ArrayBld, VarPtr;

Type
  TToken = record
  private
    FValue: String;
  public
    Class Operator Implicit(Token: TToken): String;
    Class Operator Implicit(Token: TToken): Integer;
    Class Operator Implicit(Token: TToken): Int64;
    Class Operator Implicit(Token: TToken): Float32;
    Class Operator Implicit(Token: TToken): Float64;
    Class Operator Implicit(Token: TToken): Variant;
  public
    Function ToChar: Char; inline;
    Function ToInt: Integer; inline;
    Function ToFloat: Float64; inline;
    Function Round: Integer; inline;
  public
    Property Value: string read FValue;
  end;

  TDelimiter = (Comma,Tab,Semicolon,Space);

  TStringParser = record
  private
    FToken: Integer;
    FTokens: TArray<String>;
    FSeparators: TArray<Char>;
    SplitOptions: TStringSplitOptions;
    ParseMethod: Integer;
    Procedure SetToken(Token: Integer);
    Function GetExcludeEmpty: Boolean;
    Procedure SetExcludeEmpty(ExcludeEmpty: Boolean);
    Function GetTokens(Token: Integer): TToken; inline;
    Function GetChar(Token: Integer): Char; overload; inline;
    Function GetStr(Token: Integer): String; overload; inline;
    Function GetByte(Token: Integer): Byte; overload; inline;
    Function GetInt(Token: Integer): Integer; overload; inline;
    Function GetInt64(Token: Integer): Int64; overload; inline;
    Function GetFloat(Token: Integer): Float64; overload; inline;
  public
    Class Operator Initialize(out Tokenizer: TStringParser);
  public
    // Parse options
    Procedure SetSeparators(const Separators: array of Char);
    Function SeparatorCount: Integer;
    Function GetSeparators(Index: Integer): Char;
    Property ExcludeEmpty: Boolean read GetExcludeEmpty write SetExcludeEmpty;
    // Parse methods
    Procedure CSV;
    Procedure TabDelimited;
    Procedure SpaceDelimited;
    Procedure SemicolonDelimited;
    // Manage content
    Constructor Create(Delimiter: TDelimiter; const Line: String = ''); overload;
    Constructor Create(Delimiter: TDelimiter; const Line: String; const Quote: Char); overload;
    Procedure RemoveTrailingEmpties;
    Procedure TrimTokens;
    Function Extract(const Token: String): Integer; overload;
    Function Extract(Token: Integer): String; overload;
    Procedure Clear;
    Procedure Assign(const Line: String); overload;
    Procedure Assign(const Line: String; Quote: Char); overload;
    Procedure ReadLine(var TextFile: TextFile); overload;
    Procedure ReadLine(const TextReader: TTextReader); overload;
    Procedure ReadLine(const TextReader: TTextReader; Quote: Char); overload;
    // Query Tokens
    Function Count: Integer; inline;
    Function GetChar: Char; overload;
    Function GetStr: String; overload;
    Function GetByte: Byte; overload;
    Function GetInt: Integer; overload;
    Function GetInt64: Int64; overload;
    Function GetFloat: Float64; overload;
    Function IndexOf(const Token: String; Offset: Integer = 0): Integer;
    Procedure AssignTo(var Tokens: array of Integer; FromToken: Integer = 0); overload;
    Procedure AssignTo(var Tokens: array of Float64; FromToken: Integer = 0); overload;
    Procedure AssignToVar(const Tokens: array of TVarPointer; FromToken: Integer = 0);
    Function ToStrArray: TArray<String>; overload;
    Function ToStrArray(Offset,Count: Integer): TArray<String>; overload;
    Function ToIntArray: TArray<Int32>; overload;
    Function ToIntArray(Offset,Count: Integer): TArray<Int32>; overload;
    Function ToFloatArray: TArray<Float64>; overload;
    Function ToFloatArray(Offset,Count: Integer): TArray<Float64>; overload;
    Function ToFloatArray(const FormatSettings: TFormatSettings): TArray<Float64>; overload;
    Function ToFloatArray(const FormatSettings: TFormatSettings; Offset,Count: Integer): TArray<Float64>; overload;
    Function TryToInt(Token: Integer; out Value: Integer): Boolean;
    Function TryToFloat(Token: Integer; out Value: Float64): Boolean;
    Function TryToIntArray(out Values: TArray<Int32>): Boolean; overload;
    Function TryToIntArray(Offset,Count: Integer; out Values: TArray<Int32>): Boolean; overload;
    Function TryToFloatArray(out Values: TArray<Float64>): Boolean; overload;
    Function TryToFloatArray(Offset,Count: Integer; out Values: TArray<Float64>): Boolean; overload;
    Function TryToFloatArray(const FormatSettings: TFormatSettings; out Values: TArray<Float64>): Boolean; overload;
    Function TryToFloatArray(const FormatSettings: TFormatSettings; Offset,Count: Integer; out Values: TArray<Float64>): Boolean; overload;
    Function TrySum(out Sum: Float64): Boolean; overload;
    Function TrySum(Offset,Count: Integer; out Sum: Float64): Boolean; overload;
    Function TrySum(const FormatSettings: TFormatSettings; Offset,Count: Integer; out Sum: Float64): Boolean; overload;
  public
    Property Token: Integer read FToken write SetToken;
    Property Tokens[Token: Integer]: TToken read GetTokens; default;
    Property Char[Token: Integer]: Char read GetChar;
    Property Str[Token: Integer]: String read GetStr;
    Property Byte[Token: Integer]: Byte read GetByte;
    Property Int[Token: Integer]: Integer read GetInt;
    Property Int64[Token: Integer]: Int64 read GetInt64;
    Property Float[Token: Integer]: Float64 read GetFloat;
  end;

  TFixedWidthParser = record
  private
    FTokens: TArray<String>;
    Widths: TArray<Integer>;
    Function GetTokens(Token: Integer): TToken; inline;
    Function GetInt(Token: Integer): Integer; inline;
    Function GetFloat(Token: Integer): Float64; inline;
  public
    // Initialization
    Constructor Create(const FixedWidths: array of Integer);
    // Manage content
    Procedure Assign(Line: String); overload;
    Procedure ReadLine(var TextFile: TextFile); overload;
    Procedure ReadLine(const TextReader: TTextReader); overload;
    // Query Tokens
    Function Count: Integer; inline;
    Property Tokens[Token: Integer]: TToken read GetTokens; default;
    Property Int[Token: Integer]: Integer read GetInt;
    Property Float[Token: Integer]: Float64 read GetFloat;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TToken.Implicit(Token: TToken): String;
begin
  Result := Token.Value;
end;

Class Operator TToken.Implicit(Token: TToken): Integer;
begin
  Result := Token.Value.ToInteger;
end;

Class Operator TToken.Implicit(Token: TToken): Int64;
begin
  Result := Token.Value.ToInt64;
end;

Class Operator TToken.Implicit(Token: TToken): Float32;
begin
  Result := Token.Value.ToSingle;
end;

Class Operator TToken.Implicit(Token: TToken): Float64;
begin
  Result := Token.Value.ToDouble;
end;

Class Operator TToken.Implicit(Token: TToken): Variant;
begin
  Result := Token.Value;
end;

Function TToken.ToChar: Char;
begin
  if Value.Length = 1 then
    Result := Value[1]
  else
    raise Exception.Create('Invalid token length');
end;

Function TToken.ToInt: Integer;
begin
  Result := Value.ToInteger;
end;

Function TToken.ToFloat: Float64;
begin
  Result := Value.ToDouble;
end;

Function TToken.Round: Integer;
begin
  Result := System.Round(ToFloat);
end;

////////////////////////////////////////////////////////////////////////////////

Class Operator TStringParser.Initialize(out Tokenizer: TStringParser);
begin
  Tokenizer.ParseMethod := -1;
  Tokenizer.SpaceDelimited;
end;

Procedure TStringParser.SetToken(Token: Integer);
begin
  if (Token >= 0) and (Token < Count) then
    FToken := Token
  else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.GetExcludeEmpty: Boolean;
begin
  Result := (SplitOptions = TStringSplitOptions.ExcludeEmpty);
end;

Procedure TStringParser.SetExcludeEmpty(ExcludeEmpty: Boolean);
begin
  if ExcludeEmpty <> GetExcludeEmpty then
  begin
    FTokens := nil;
    ParseMethod := -1;
    if ExcludeEmpty then
      SplitOptions := TStringSplitOptions.ExcludeEmpty
    else
      SplitOptions := TStringSplitOptions.None;
  end;
end;

Function TStringParser.GetTokens(Token: Integer): TToken;
begin
  Result.FValue := FTokens[Token];
end;

Function TStringParser.GetChar(Token: Integer): Char;
begin
  if FTokens[Token].Length = 1 then
    Result := FTokens[Token][1]
  else
    raise Exception.Create('Invalid token length');
end;

Function TStringParser.GetStr(Token: Integer): String;
begin
  Result := FTokens[Token];
end;

Function TStringParser.GetByte(Token: Integer): Byte;
begin
  Result := FTokens[Token].ToInteger;
end;

Function TStringParser.GetInt(Token: Integer): Integer;
begin
  Result := FTokens[Token].ToInteger;
end;

Function TStringParser.GetInt64(Token: Integer): Int64;
begin
  Result := FTokens[Token].ToInt64;
end;

Function TStringParser.GetFloat(Token: Integer): Float64;
begin
  Result := FTokens[Token].ToDouble;
end;

Procedure TStringParser.SetSeparators(const Separators: array of Char);
begin
  FTokens := nil;
  ParseMethod := -1;
  FSeparators := TCharArrayBuilder.Create(Separators);
end;

Function TStringParser.SeparatorCount: Integer;
begin
  Result := Length(FSeparators);
end;

Function TStringParser.GetSeparators(Index: Integer): Char;
begin
  Result := FSeparators[Index];
end;

Procedure TStringParser.CSV;
begin
  if ParseMethod <> Ord(Comma) then
  begin
    SetSeparators([#44]);
    ExcludeEmpty := false;
    ParseMethod := Ord(Comma);
  end;
end;

Procedure TStringParser.TabDelimited;
begin
  if ParseMethod <> Ord(Tab) then
  begin
    SetSeparators([#9]);
    ExcludeEmpty := false;
    ParseMethod := Ord(Tab);
  end;
end;

Procedure TStringParser.SpaceDelimited;
begin
  if ParseMethod <> Ord(Space) then
  begin
    SetSeparators([#9,#32]);
    ExcludeEmpty := true;
    ParseMethod := Ord(Space);
  end;
end;

Procedure TStringParser.SemicolonDelimited;
begin
  if ParseMethod <> Ord(Semicolon) then
  begin
    SetSeparators([#59]);
    ExcludeEmpty := false;
    ParseMethod := Ord(Semicolon);
  end;
end;

Constructor TStringParser.Create(Delimiter: TDelimiter; const Line: String = '');
begin
  // Initialize
  case Delimiter of
    Comma: CSV;
    Tab: TabDelimited;
    SemiColon: SemicolonDelimited;
    Space: SpaceDelimited;
  end;
  // Assign content
  Assign(Line);
end;

Constructor TStringParser.Create(Delimiter: TDelimiter; const Line: String; const Quote: Char);
begin
  // Initialize
  case Delimiter of
    Comma: CSV;
    Tab: TabDelimited;
    SemiColon: SemicolonDelimited;
    Space: SpaceDelimited;
  end;
  // Assign content
  Assign(Line,Quote);
end;

Procedure TStringParser.RemoveTrailingEmpties;
begin
  var Index := Count-1;
  while (Index >= 0) and (FTokens[Index] = '') do Dec(Index);
  SetLength(FTokens,Index+1);
end;

Procedure TStringParser.TrimTokens;
begin
  for var Token := 0 to Count-1 do FTokens[Token] := Trim(FTokens[Token]);
end;

Function TStringParser.Extract(const Token: String): Integer;
begin
  Result := IndexOf(Token);
  Extract(Result);
end;

Function TStringParser.Extract(Token: Integer): String;
begin
  Result := '';
  if Token >= 0 then
  begin
    Result := FTokens[Token];
    if Token < FToken then Dec(FToken);
    for var Index := Token to Count-2 do FTokens[Index] := FTokens[Index+1];
    SetLength(FTokens,Count-1);
  end;
end;

Procedure TStringParser.Clear;
begin
  FTokens := nil;
end;

Procedure TStringParser.Assign(const Line: String);
begin
  FTokens := Line.Split(FSeparators,SplitOptions);
  if Count > 0 then FToken := 0 else FToken := -1;
end;

Procedure TStringParser.Assign(const Line: String; Quote: Char);
begin
  FTokens := Line.Split(FSeparators,Quote,Quote,SplitOptions);
  if Count > 0 then FToken := 0 else FToken := -1;
end;

Procedure TStringParser.ReadLine(var TextFile: TextFile);
var
  Line: String;
begin
  readln(TextFile,Line);
  Assign(Line);
end;

Procedure TStringParser.ReadLine(const TextReader: TTextReader);
begin
  Assign(TextReader.ReadLine);
end;

Procedure TStringParser.ReadLine(const TextReader: TTextReader; Quote: Char);
begin
  Assign(TextReader.ReadLine,Quote);
end;

Function TStringParser.Count: Integer;
begin
  Result := Length(FTokens);
end;

Function TStringParser.GetChar: Char;
begin
  if FToken < Count then
  begin
    Result := GetChar(FToken);
    Inc(FToken);
  end else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.GetStr: String;
begin
  if FToken < Count then
  begin
    Result := GetStr(FToken);
    Inc(FToken);
  end else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.GetByte: Byte;
begin
  if FToken < Count then
  begin
    Result := GetByte(FToken);
    Inc(FToken);
  end else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.GetInt: Integer;
begin
  if FToken < Count then
  begin
    Result := GetInt(FToken);
    Inc(FToken);
  end else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.GetInt64: Int64;
begin
  if FToken < Count then
  begin
    Result := GetInt64(FToken);
    Inc(FToken);
  end else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.GetFloat: Float64;
begin
  if FToken < Count then
  begin
    Result := GetFloat(FToken);
    Inc(FToken);
  end else
    raise Exception.Create('Token out of range');
end;

Function TStringParser.IndexOf(const Token: String; Offset: Integer = 0): Integer;
begin
  Result := -1;
  for var Index := Offset to Count-1 do
  if SameText(FTokens[Index],Token) then Exit(Index);
end;

Procedure TStringParser.AssignTo(var Tokens: array of Integer; FromToken: Integer = 0);
begin
  for var Token := low(Tokens) to high(Tokens) do
  begin
    Tokens[Token] := Int[FromToken];
    Inc(FromToken);
  end;
end;

Procedure TStringParser.AssignTo(var Tokens: array of Float64; FromToken: Integer = 0);
begin
  for var Token := low(Tokens) to high(Tokens) do
  begin
    Tokens[Token] := Float[FromToken];
    Inc(FromToken);
  end;
end;

Procedure TStringParser.AssignToVar(const Tokens: array of TVarPointer; FromToken: Integer = 0);
begin
  for var Token := low(Tokens) to high(Tokens) do
  begin
    case Tokens[Token].VarType of
      vtByte: Tokens[Token].AsByte := Int[FromToken];
      vtInt16: Tokens[Token].AsInt16 := Int[FromToken];
      vtInt32: Tokens[Token].AsInt32 := Int[FromToken];
      vtInt64: Tokens[Token].AsInt64 := Int64[FromToken];
      vtFloat32: Tokens[Token].AsFloat32 := Float[FromToken];
      vtFloat64: Tokens[Token].AsFloat64 := Float[FromToken];
      else raise Exception.Create('Unsupported var-tyep');
    end;
    Inc(FromToken);
  end;
end;

Function TStringParser.ToStrArray: TArray<String>;
begin
  Result := ToStrArray(0,Count);
end;

Function TStringParser.ToStrArray(Offset,Count: Integer): TArray<String>;
begin
  SetLength(Result,Count);
  for var Token := 0 to Count-1 do Result[Token] := FTokens[Token+Offset];
end;

Function TStringParser.ToIntArray: TArray<Int32>;
begin
  Result := ToIntArray(0,Count);
end;

Function TStringParser.ToIntArray(Offset,Count: Integer): TArray<Int32>;
begin
  SetLength(Result,Count);
  for var Token := 0 to Count-1 do Result[Token] := StrToInt(FTokens[Token+Offset]);
end;

Function TStringParser.ToFloatArray: TArray<Float64>;
begin
  Result := ToFloatArray(FormatSettings,0,Count);
end;

Function TStringParser.ToFloatArray(Offset,Count: Integer): TArray<Float64>;
begin
  Result := ToFloatArray(FormatSettings,Offset,Count);
end;

Function TStringParser.ToFloatArray(const FormatSettings: TFormatSettings): TArray<Float64>;
begin
  Result := ToFloatArray(FormatSettings,0,Count);
end;

Function TStringParser.ToFloatArray(const FormatSettings: TFormatSettings; Offset,Count: Integer): TArray<Float64>;
begin
  SetLength(Result,Count);
  for var Token := 0 to Count-1 do Result[Token] := StrToFloat(FTokens[Token+Offset],FormatSettings);
end;

Function TStringParser.TryToInt(Token: Integer; out Value: Integer): Boolean;
begin
  Result := TryStrToInt(FTokens[Token],Value);
end;

Function TStringParser.TryToFloat(Token: Integer; out Value: Float64): Boolean;
begin
  Result := TryStrToFloat(FTokens[Token],Value);
end;

Function TStringParser.TryToIntArray(out Values: TArray<Int32>): Boolean;
begin
  Result := TryToIntArray(0,Count,Values);
end;

Function TStringParser.TryToIntArray(Offset,Count: Integer; out Values: TArray<Int32>): Boolean;
begin
  Result := true;
  SetLength(Values,Count);
  for var Token := 0 to Count-1 do
  if not TryStrToInt(FTokens[Token+Offset],Values[Token]) then Exit(false);
end;

Function TStringParser.TryToFloatArray(out Values: TArray<Float64>): Boolean;
begin
  Result := TryToFloatArray(FormatSettings,0,Count,Values);
end;

Function TStringParser.TryToFloatArray(Offset,Count: Integer; out Values: TArray<Float64>): Boolean;
begin
  Result := TryToFloatArray(FormatSettings,Offset,Count,Values);
end;

Function TStringParser.TryToFloatArray(const FormatSettings: TFormatSettings; out Values: TArray<Float64>): Boolean;
begin
  Result := TryToFloatArray(FormatSettings,0,Count,Values);
end;

Function TStringParser.TryToFloatArray(const FormatSettings: TFormatSettings; Offset,Count: Integer; out Values: TArray<Float64>): Boolean;
begin
  Result := true;
  SetLength(Values,Count);
  for var Token := 0 to Count-1 do
  if not TryStrToFloat(FTokens[Token+Offset],Values[Token],FormatSettings) then Exit(false);
end;

Function TStringParser.TrySum(out Sum: Float64): Boolean;
begin
  Result := TrySum(0,Count,Sum);
end;

Function TStringParser.TrySum(Offset,Count: Integer; out Sum: Float64): Boolean;
begin
  Result := TrySum(FormatSettings,Offset,Count,Sum);
end;

Function TStringParser.TrySum(const FormatSettings: TFormatSettings; Offset,Count: Integer; out Sum: Float64): Boolean;
Var
  Value: Float64;
begin
  Sum := 0;
  Result := true;
  for var Token := 0 to Count-1 do
  if TryStrToFloat(FTokens[Token+Offset],Value,FormatSettings) then
    Sum := Sum + Value
  else
    Exit(false);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TFixedWidthParser.Create(const FixedWidths: array of Integer);
begin
  Finalize(FTokens);
  Widths := TArrayBuilder<Integer>.Create(FixedWidths);
end;

Function TFixedWidthParser.GetTokens(Token: Integer): TToken;
begin
  Result.FValue := FTokens[Token];
end;

Function TFixedWidthParser.GetInt(Token: Integer): Integer;
begin
  Result := Trim(FTokens[Token]).ToInteger;
end;

Function TFixedWidthParser.GetFloat(Token: Integer): Float64;
begin
  Result := Trim(FTokens[Token]).ToDouble;
end;

Procedure TFixedWidthParser.Assign(Line: String);
begin
  var Pos := 1;
  SetLength(FTokens,Length(Widths));
  for var Token := 0 to Count-1 do
  begin
    FTokens[Token] := Copy(Line,Pos,Widths[Token]);
    Inc(Pos,Widths[Token]);
  end;
end;

Procedure TFixedWidthParser.ReadLine(var TextFile: TextFile);
var
  Line: String;
begin
  readln(TextFile,Line);
  Assign(Line);
end;

Procedure TFixedWidthParser.ReadLine(const TextReader: TTextReader);
begin
  Assign(TextReader.ReadLine);
end;

Function TFixedWidthParser.Count: Integer;
begin
  Result := Length(FTokens);
end;

end.
