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
  Classes,SysUtils;

Type
  TDelimiter = (Comma,Tab,Semicolon,Space);

  TTokenizer = record
  private
    FTokens: TArray<String>;
    FSeparators: TArray<Char>;
    SplitOptions: TStringSplitOptions;
    Function GetExcludeEmpty: Boolean;
    Procedure SetExcludeEmpty(ExcludeEmpty: Boolean);
    Function GetTokens(Token: Integer): String; inline;
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
    Procedure Assign(const Line: String);
    Procedure ReadLine(var TextFile: TextFile); overload;
    Procedure ReadLine(const TextReader: TTextReader); overload;
    // Query Tokens
    Function Count: Integer; inline;
    Property Tokens[Token: Integer]: String read GetTokens; default;
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

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TTokenizer.Initialize(out Tokenizer: TTokenizer);
begin
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
    FTokens := nil; // Clear content
    if ExcludeEmpty then
      SplitOptions := TStringSplitOptions.ExcludeEmpty
    else
      SplitOptions := TStringSplitOptions.None;
  end;
end;

Function TTokenizer.GetTokens(Token: Integer): String;
begin
  Result := FTokens[Token];
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
  FTokens := nil; // Clear content
  SetLength(FSeparators,Length(Separators));
  for var Separator := low(Separators) to high(Separators) do
    FSeparators[Separator] := Separators[Separator];
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
  SetSeparators([#44]);
  ExcludeEmpty := false;
end;

Procedure TTokenizer.TabDelimited;
begin
  SetSeparators([#9]);
  ExcludeEmpty := false;
end;

Procedure TTokenizer.SpaceDelimited;
begin
  SetSeparators([#9,#32]);
  ExcludeEmpty := true;
end;

Procedure TTokenizer.SemicolonDelimited;
begin
  SetSeparators([#59]);
  ExcludeEmpty := false;
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

end.
