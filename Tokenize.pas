unit Tokenize;

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
  Classes,SysUtils,ArrayBld;

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
  public
    Function ToInt: Integer; inline;
    Function ToFloat: Float64; inline;
    Function Round: Integer; inline;
  public
    Property Value: string read FValue;
  end;

  TDelimiter = (Comma,Tab,Semicolon,Space);

  TTokenizer = record
  private
    FTokens: TArray<String>;
    FSeparators: TArray<Char>;
    SplitOptions: TStringSplitOptions;
    ParseMethod: Integer;
    Function GetExcludeEmpty: Boolean;
    Procedure SetExcludeEmpty(ExcludeEmpty: Boolean);
    Function GetTokens(Token: Integer): TToken; inline;
    Function GetInt(Token: Integer): Integer; inline;
    Function GetInt64(Token: Integer): Int64; inline;
    Function GetFloat(Token: Integer): Float64; inline;
  public
    Class Operator Initialize(out Tokenizer: TTokenizer);
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
    Constructor Create(Delimiter: TDelimiter; const Line: String = '');
    Procedure Clear;
    Procedure Assign(const Line: String); overload;
    Procedure Assign(const Line: String; Quote: Char); overload;
    Procedure ReadLine(var TextFile: TextFile); overload;
    Procedure ReadLine(const TextReader: TTextReader); overload;
    // Query Tokens
    Function Count: Integer; inline;
    Property Tokens[Token: Integer]: TToken read GetTokens; default;
    Property Int[Token: Integer]: Integer read GetInt;
    Property Int64[Token: Integer]: Int64 read GetInt64;
    Property Float[Token: Integer]: Float64 read GetFloat;
    Function ToStrArray: TArray<String>; overload;
    Function ToStrArray(Offset,Count: Integer): TArray<String>; overload;
    Function ToIntArray: TArray<Int32>; overload;
    Function ToIntArray(Offset,Count: Integer): TArray<Int32>; overload;
    Function ToFloatArray: TArray<Float64>; overload;
    Function ToFloatArray(Offset,Count: Integer): TArray<Float64>; overload;
    Function ToFloatArray(const FormatSettings: TFormatSettings): TArray<Float64>; overload;
    Function ToFloatArray(const FormatSettings: TFormatSettings; Offset,Count: Integer): TArray<Float64>; overload;
  end;

  TFixedWidthParser = record
  private
    FTokens: TArray<String>;
    Widths: TArray<Integer>;
    Function GetTokens(Token: Integer): TToken; inline;
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

Class Operator TTokenizer.Initialize(out Tokenizer: TTokenizer);
begin
  Tokenizer.ParseMethod := -1;
  Tokenizer.SpaceDelimited;
end;

Function TTokenizer.GetExcludeEmpty: Boolean;
begin
  Result := (SplitOptions = TStringSplitOptions.ExcludeEmpty);
end;

Procedure TTokenizer.SetExcludeEmpty(ExcludeEmpty: Boolean);
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

Function TTokenizer.GetTokens(Token: Integer): TToken;
begin
  Result.FValue := FTokens[Token];
end;

Function TTokenizer.GetInt(Token: Integer): Integer;
begin
  Result := FTokens[Token].ToInteger;
end;

Function TTokenizer.GetInt64(Token: Integer): Int64;
begin
  Result := FTokens[Token].ToInt64;
end;

Function TTokenizer.GetFloat(Token: Integer): Float64;
begin
  Result := FTokens[Token].ToDouble;
end;

Procedure TTokenizer.SetSeparators(const Separators: array of Char);
begin
  FTokens := nil;
  ParseMethod := -1;
  FSeparators := TCharArrayBuilder.Create(Separators);
end;

Function TTokenizer.SeparatorCount: Integer;
begin
  Result := Length(FSeparators);
end;

Function TTokenizer.GetSeparators(Index: Integer): Char;
begin
  Result := FSeparators[Index];
end;

Procedure TTokenizer.CSV;
begin
  if ParseMethod <> Ord(Comma) then
  begin
    SetSeparators([#44]);
    ExcludeEmpty := false;
    ParseMethod := Ord(Comma);
  end;
end;

Procedure TTokenizer.TabDelimited;
begin
  if ParseMethod <> Ord(Tab) then
  begin
    SetSeparators([#9]);
    ExcludeEmpty := false;
    ParseMethod := Ord(Tab);
  end;
end;

Procedure TTokenizer.SpaceDelimited;
begin
  if ParseMethod <> Ord(Space) then
  begin
    SetSeparators([#9,#32]);
    ExcludeEmpty := true;
    ParseMethod := Ord(Space);
  end;
end;

Procedure TTokenizer.SemicolonDelimited;
begin
  if ParseMethod <> Ord(Semicolon) then
  begin
    SetSeparators([#59]);
    ExcludeEmpty := false;
    ParseMethod := Ord(Semicolon);
  end;
end;

Constructor TTokenizer.Create(Delimiter: TDelimiter; const Line: String = '');
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

Procedure TTokenizer.Clear;
begin
  FTokens := nil;
end;

Procedure TTokenizer.Assign(const Line: String);
begin
  FTokens := Line.Split(FSeparators,SplitOptions);
end;

Procedure TTokenizer.Assign(const Line: String; Quote: Char);
begin
  FTokens := Line.Split(FSeparators,Quote,Quote,SplitOptions);
end;

Procedure TTokenizer.ReadLine(var TextFile: TextFile);
var
  Line: String;
begin
  readln(TextFile,Line);
  Assign(Line);
end;

Procedure TTokenizer.ReadLine(const TextReader: TTextReader);
begin
  Assign(TextReader.ReadLine);
end;

Function TTokenizer.Count: Integer;
begin
  Result := Length(FTokens);
end;

Function TTokenizer.ToStrArray: TArray<String>;
begin
  Result := ToStrArray(0,Count);
end;

Function TTokenizer.ToStrArray(Offset,Count: Integer): TArray<String>;
begin
  SetLength(Result,Count);
  for var Token := 0 to Count-1 do Result[Token] := FTokens[Token+Offset];
end;

Function TTokenizer.ToIntArray: TArray<Int32>;
begin
  Result := ToIntArray(0,Count);
end;

Function TTokenizer.ToIntArray(Offset,Count: Integer): TArray<Int32>;
begin
  SetLength(Result,Count);
  for var Token := 0 to Count-1 do Result[Token] := StrToInt(FTokens[Token+Offset]);
end;

Function TTokenizer.ToFloatArray: TArray<Float64>;
begin
  Result := ToFloatArray(FormatSettings,0,Count);
end;

Function TTokenizer.ToFloatArray(Offset,Count: Integer): TArray<Float64>;
begin
  Result := ToFloatArray(FormatSettings,Offset,Count);
end;

Function TTokenizer.ToFloatArray(const FormatSettings: TFormatSettings): TArray<Float64>;
begin
  Result := ToFloatArray(FormatSettings,0,Count);
end;

Function TTokenizer.ToFloatArray(const FormatSettings: TFormatSettings; Offset,Count: Integer): TArray<Float64>;
begin
  SetLength(Result,Count);
  for var Token := 0 to Count-1 do Result[Token] := StrToFloat(FTokens[Token+Offset],FormatSettings);
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
