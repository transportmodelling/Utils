unit ArrayHlp;

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
  SysUtils, Math, Generics.Collections, VarPtr, Parse;

Type
  TIntArrayHelper = record helper for TArray<Integer>
  private
    Function GetLength: Integer; inline;
    Procedure SetLength(Length: Integer); inline;
  public
    Constructor Create(const Values: array of Integer); overload;
    Constructor Create(const Length: Integer; Value: Integer = 0); overload;
    Function ToString(const Separator: Char = ','): String;
    Function ToStrings: TArray<String>;
    Procedure Initialize(Value: Integer);
    Procedure Assign(const Values: array of Integer); overload;
    Procedure Assign(const Values: array of String); overload;
    Procedure Assign(const Values: String; const Separator: Char = ','); overload;
    Procedure AssignTo(var Values: array of Integer; FromIndex: Integer = 0);
    Procedure AssignToVar(const Values: array of TVarPointer; FromIndex: Integer = 0);
    Procedure Append(const Values: array of Integer);
    Function Contains(Value: Integer): Boolean;
    Function  MinValue: Integer;
    Function  MaxValue: Integer;
    Function  Total: Integer;
    Procedure Sort;
  public
    Property Length: Integer read GetLength write SetLength;
  end;

  TFloat64ArrayHelper = record helper for TArray<Float64>
  private
    Function GetLength: Integer; inline;
    Procedure SetLength(Length: Integer); inline;
  public
    Constructor Create(const Values: array of Float64); overload;
    Constructor Create(const Length: Integer; Value: Float64 = 0.0); overload;
    Function ToString(const Separator: Char = ','): String; overload;
    Function ToString(const Format: String; const Separator: Char = ','): String; overload;
    Function ToStrings: TArray<String>; overload;
    Function ToStrings(const Format: String): TArray<String>; overload;
    Procedure Initialize(Value: Float64);
    Procedure Assign(const Values: array of Float64); overload;
    Procedure Assign(const Values: array of String); overload;
    Procedure Assign(const Values: String; const Separator: Char = ','); overload;
    Procedure AssignTo(var Values: array of Float64; FromIndex: Integer = 0);
    Procedure AssignToVar(const Values: array of TVarPointer; FromIndex: Integer = 0);
    Procedure Append(const Values: array of Float64);
    Function  MinValue: Float64;
    Function  MaxValue: Float64;
    Function  Total: Float64;
  public
    Property Length: Integer read GetLength write SetLength;
  end;

  TStringArrayHelper = record helper for TArray<String>
  private
    Function GetLength: Integer; inline;
    Procedure SetLength(Length: Integer); inline;
  public
    Constructor Create(const Values: array of String);
    Function ToString(const Separator: Char = ','): String;
    Procedure Assign(const Values: array of String); overload;
    Procedure Assign(const Values: String; const Separator: Char = ','); overload;
    Procedure Append(const Values: array of String);
  public
    Property Length: Integer read GetLength write SetLength;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TIntArrayHelper.Create(const Values: array of Integer);
begin
  Assign(Values)
end;

Constructor TIntArrayHelper.Create(const Length: Integer; Value: Integer = 0);
begin
  System.SetLength(Self,Length);
  for var Index := 0 to Length-1 do Self[Index] := Value;
end;

Function TIntArrayHelper.ToString(const Separator: Char = ','): String;
begin
  if Self.Length > 0 then
  begin
    Result := Self[0].ToString;
    for var Index := 1 to Length-1 do Result := Result + Separator + Self[Index].ToString;
  end else
    Result := '';
end;

Function TIntArrayHelper.ToStrings: TArray<String>;
begin
  System.SetLength(Result,Self.Length);
  for var Index := 0 to Length-1 do Result[Index] := Self[Index].ToString;
end;

Function TIntArrayHelper.GetLength: Integer;
begin
  Result := System.Length(Self);
end;

Procedure TIntArrayHelper.SetLength(Length: Integer);
begin
  System.SetLength(Self,Length);
end;

Procedure TIntArrayHelper.Initialize(Value: Integer);
begin
  for var Index := 0 to Length-1 do Self[Index] := Value;
end;

Procedure TIntArrayHelper.Assign(const Values: array of Integer);
begin
  Length := System.Length(Values);
  for var Index := 0 to Length-1 do Self[Index] := Values[Index];
end;

Procedure TIntArrayHelper.Assign(const Values: array of String);
begin
  Length := System.Length(Values);
  for var Index := 0 to Length-1 do Self[Index] := Values[Index].ToInteger;
end;

Procedure TIntArrayHelper.Assign(const Values: String; const Separator: Char = ',');
Var
  Parser: TStringParser;
begin
  Parser.SetSeparators([Separator]);
  Parser.Assign(Values);
  Self := Parser.ToIntArray;
end;

Procedure TIntArrayHelper.AssignTo(var Values: array of Integer; FromIndex: Integer = 0);
begin
  for var Token := low(Values) to high(Values) do
  begin
    Values[Token] := Self[FromIndex];
    Inc(FromIndex);
  end;
end;

Procedure TIntArrayHelper.AssignToVar(const Values: array of TVarPointer; FromIndex: Integer = 0);
begin
  for var Token := low(Values) to high(Values) do
  begin
    Values[Token].AsInt32 := Self[FromIndex];
    Inc(FromIndex);
  end;
end;

Procedure TIntArrayHelper.Append(const Values: array of Integer);
begin
  var Offset := Length;
  Length := Offset + System.Length(Values);
  for var Index := Offset to Length-1 do Self[Index] := Values[Index-Offset];
end;

Function TIntArrayHelper.Contains(Value: Integer): Boolean;
begin
  Result := false;
  for var Index := 0 to Length-1 do
  if Self[Index] = Value then Exit(true);
end;

Function TIntArrayHelper.MinValue: Integer;
begin
  Result := MinIntValue(Self);
end;

Function TIntArrayHelper.MaxValue: Integer;
begin
  Result := MaxIntValue(Self);
end;

Function TIntArrayHelper.Total: Integer;
begin
  Result := 0;
  for var Index := 0 to Length-1 do Result := Result  + Self[Index];
end;

Procedure TIntArrayHelper.Sort;
begin
  System.Generics.Collections.TArray.Sort<Integer>(Self);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TFloat64ArrayHelper.Create(const Values: array of Float64);
begin
  Assign(Values)
end;

Constructor TFloat64ArrayHelper.Create(const Length: Integer; Value: Float64 = 0.0);
begin
  System.SetLength(Self,Length);
  for var Index := 0 to Length-1 do Self[Index] := Value;
end;

Function TFloat64ArrayHelper.ToString(const Separator: Char = ','): String;
begin
  if Self.Length > 0 then
  begin
    Result := Self[0].ToString;
    for var Index := 1 to Length-1 do Result := Result + Separator + Self[Index].ToString;
  end else
    Result := '';
end;

Function TFloat64ArrayHelper.ToString(const Format: String; const Separator: Char = ','): String;
begin
  if Self.Length > 0 then
  begin
    Result := FormatFloat(Format,Self[0]);
    for var Index := 1 to Length-1 do Result := Result + Separator + FormatFloat(Format,Self[Index]);
  end else
    Result := '';
end;

Function TFloat64ArrayHelper.ToStrings: TArray<String>;
begin
  System.SetLength(Result,Self.Length);
  for var Index := 0 to Length-1 do Result[Index] := Self[Index].ToString;
end;

Function TFloat64ArrayHelper.ToStrings(const Format: String): TArray<String>;
begin
  System.SetLength(Result,Self.Length);
  for var Index := 0 to Length-1 do Result[Index] := FormatFloat(Format,Self[Index]);
end;

Function TFloat64ArrayHelper.GetLength: Integer;
begin
  Result := System.Length(Self);
end;

Procedure TFloat64ArrayHelper.SetLength(Length: Integer);
begin
  System.SetLength(Self,Length);
end;

Procedure TFloat64ArrayHelper.Initialize(Value: Float64);
begin
  for var Index := 0 to Length-1 do Self[Index] := Value;
end;

Procedure TFloat64ArrayHelper.Assign(const Values: array of Float64);
begin
  Length := System.Length(Values);
  for var Index := 0 to Length-1 do Self[Index] := Values[Index];
end;

Procedure TFloat64ArrayHelper.Assign(const Values: array of String);
begin
  Length := System.Length(Values);
  for var Index := 0 to Length-1 do Self[Index] := Values[Index].ToDouble;
end;

Procedure TFloat64ArrayHelper.Assign(const Values: String; const Separator: Char = ',');
Var
  Parser: TStringParser;
begin
  Parser.SetSeparators([Separator]);
  Parser.Assign(Values);
  Self := Parser.ToFloatArray;
end;

Procedure TFloat64ArrayHelper.AssignTo(var Values: array of Float64; FromIndex: Integer = 0);
begin
  for var Token := low(Values) to high(Values) do
  begin
    Values[Token] := Self[FromIndex];
    Inc(FromIndex);
  end;
end;

Procedure TFloat64ArrayHelper.AssignToVar(const Values: array of TVarPointer; FromIndex: Integer = 0);
begin
  for var Token := low(Values) to high(Values) do
  begin
    Values[Token].AsFloat64 := Self[FromIndex];
    Inc(FromIndex);
  end;
end;

Procedure TFloat64ArrayHelper.Append(const Values: array of Float64);
begin
  var Offset := Length;
  Length := Offset + System.Length(Values);
  for var Index := Offset to Length-1 do Self[Index] := Values[Index-Offset];
end;

Function TFloat64ArrayHelper.MinValue: Float64;
begin
  Result := Math.MinValue(Self);
end;

Function TFloat64ArrayHelper.MaxValue: Float64;
begin
  Result := Math.MaxValue(Self);
end;

Function TFloat64ArrayHelper.Total: Float64;
begin
  Result := 0.0;
  for var Index := 0 to Length-1 do Result := Result  + Self[Index];
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TStringArrayHelper.Create(const Values: array of String);
begin
  Assign(Values)
end;

Function TStringArrayHelper.ToString(const Separator: Char = ','): String;
begin
  if Self.Length > 0 then
  begin
    Result := Self[0];
    for var Index := 1 to Length-1 do Result := Result + Separator + Self[Index];
  end else
    Result := '';
end;

Function TStringArrayHelper.GetLength: Integer;
begin
  Result := System.Length(Self);
end;

Procedure TStringArrayHelper.SetLength(Length: Integer);
begin
  System.SetLength(Self,Length);
end;

Procedure TStringArrayHelper.Assign(const Values: array of String);
begin
  Length := System.Length(Values);
  for var Index := 0 to Length-1 do Self[Index] := Values[Index];
end;

Procedure TStringArrayHelper.Assign(const Values: String; const Separator: Char = ',');
Var
  Parser: TStringParser;
begin
  Parser.SetSeparators([Separator]);
  Parser.Assign(Values);
  Self := Parser.ToStrArray;
end;

Procedure TStringArrayHelper.Append(const Values: array of String);
begin
  var Offset := Length;
  Length := Offset + System.Length(Values);
  for var Index := Offset to Length-1 do Self[Index] := Values[Index-Offset];
end;

end.
