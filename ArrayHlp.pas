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
  SysUtils,Math,System.Generics.Collections;

Type
  TIntArrayHelper = record helper for TArray<Integer>
  private
    Function GetLength: Integer; inline;
    Procedure SetLength(Length: Integer); inline;
  public
    Constructor Create(const Values: array of Integer); overload;
    Constructor Create(const Length: Integer; Value: Integer = 0); overload;
    Function ToString(const Separator: Char = ','): String;
    Procedure Initialize(Value: Integer);
    Procedure Assign(const Values: array of Integer);
    Procedure Append(const Values: array of Integer);
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
    Function ToString(const Format: String; const Separator: Char = ','): String;
    Procedure Initialize(Value: Float64);
    Procedure Assign(const Values: array of Float64);
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
    Procedure Assign(const Values: array of String);
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

Procedure TIntArrayHelper.Append(const Values: array of Integer);
begin
  var Offset := Length;
  Length := Offset + System.Length(Values);
  for var Index := Offset to Length-1 do Self[Index] := Values[Index-Offset];
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

Function TFloat64ArrayHelper.ToString(const Format: String; const Separator: Char = ','): String;
begin
  if Self.Length > 0 then
  begin
    Result := FormatFloat(Format,Self[0]);
    for var Index := 1 to Length-1 do Result := Result + Separator + FormatFloat(Format,Self[Index]);
  end else
    Result := '';
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

Procedure TStringArrayHelper.Append(const Values: array of String);
begin
  var Offset := Length;
  Length := Offset + System.Length(Values);
  for var Index := Offset to Length-1 do Self[Index] := Values[Index-Offset];
end;

end.
