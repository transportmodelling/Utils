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
  Math;

Type
  TIntArrayHelper = record helper for TArray<Integer>
  private
    Function GetLength: Integer; inline;
    Procedure SetLength(Length: Integer); inline;
  public
    Procedure Initialize(Value: Integer);
    Procedure Assign(const Values: array of Integer);
    Procedure Append(const Values: array of Integer);
    Function  MinValue: Integer;
    Function  MaxValue: Integer;
    Function  Total: Integer;
  public
    Property Length: Integer read GetLength write SetLength;
  end;

  TFloat64ArrayHelper = record helper for TArray<Float64>
  private
    Function GetLength: Integer; inline;
    Procedure SetLength(Length: Integer); inline;
  public
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
    Procedure Assign(const Values: array of String);
    Procedure Append(const Values: array of String);
  public
    Property Length: Integer read GetLength write SetLength;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////

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
