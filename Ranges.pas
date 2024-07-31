unit Ranges;

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
  SysUtils, Parse, ArrayHlp;

Type
  TRange = record
  private
    FMin,FMax: Integer;
  public
    Constructor Create(const Min,Max: Integer);
    Function Count: Integer;
    Function Contains(const Value: Integer): Boolean;
    Function Values: TArray<Integer>;
    Function Split(NRanges: Integer): TArray<TRange>;
  public
    Property Min: Integer read FMin;
    Property Max: Integer read FMax;
  end;

  TRanges = record
  private
    FRanges: array of TRange;
    Function GetRanges(Range: Integer): TRange; inline;
  public
    Class Operator Implicit(const Values: array of Integer): TRanges;
    Class Operator Implicit(Ranges: String): TRanges;
    Class Operator Implicit(Ranges: TRanges): String;
  public
    Constructor Create(const Values: array of Integer); overload;
    Constructor Create(const Ranges: array of TRange); overload;
    Constructor Create(const Ranges: string); overload;
    Function Count: Integer;
    Function Contains(const Value: Integer): Boolean;
    Function Values: TArray<Integer>;
    Function AsString: String;
  public
    Property Ranges[Range: Integer]: TRange read GetRanges; default;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TRange.Create(const Min,Max: Integer);
begin
  if Min <= Max then
  begin
    FMin := Min;
    FMax := Max;
  end else
    raise Exception.Create('Min greater than Max');
end;

Function TRange.Count: Integer;
begin
  Result := Max-Min+1;
end;

Function TRange.Contains(const Value: Integer): Boolean;
begin
  Result := (Value >= FMin) and (Value <= FMax);
end;

Function TRange.Values: TArray<Integer>;
begin
  SetLength(Result,Count);
  for var Value := Min to Max do Result[Value-Min] := Value;
end;

Function TRange.Split(NRanges: Integer): TArray<TRange>;
begin
  // Ensure each range has at least 1 element
  if NRanges > Count then NRanges := Count;
  // Calculate number of elements in result ranges
  var CountDivNRanges := Count div NRanges;
  var Remainder := Count - NRanges*CountDivNRanges;
  // Set result
  var Last := FMin-1;
  SetLength(Result,NRanges);
  for var Range := 0 to NRanges-1 do
  begin
    Result[Range].FMin := Last+1;
    if Range < Remainder then
      Result[Range].FMax := Last+CountDivNRanges+1
    else
      Result[Range].FMax := Last+CountDivNRanges;
    Inc(Last,Result[Range].Count);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Class Operator TRanges.Implicit(const Values: array of Integer): TRanges;
begin
  if Length(Values) > 0 then
  begin
    var Arr := TArray<Integer>.Create(Values);
    // Sort values
    Arr.Sort;
    // Initialize first range
    var Value := Arr[0];
    var Range := TRange.Create(Value,Value);
    // Iterate values
    for var Index := 1 to Arr.Length-1 do
    if Arr[Index] = Value+1 then Inc(Value) else
    begin
      // Finalize range
      Range.FMax := Arr[Index-1];
      Result.FRanges := Result.FRanges + [Range];
      // Initialize next range
      Value := Arr[Index];
      Range.FMin := Value;
    end;
    // Finalize last range
    Range.FMax := Arr[Arr.Length-1];
    Result.FRanges := Result.FRanges + [Range];
  end;
end;

Class Operator TRanges.Implicit(Ranges: String): TRanges;
begin
  var Parser := TStringParser.Create(Comma,Ranges);
  SetLength(Result.FRanges,Parser.Count);
  for var Range := 0 to Parser.Count-1 do
  begin
    var P := Pos('-',Parser[Range]);
    if P = 0 then
    begin
      var Value := Parser[Range].ToInt;
      Result.FRanges[Range].FMin := Value;
      Result.FRanges[Range].FMax := Value;
    end else
    begin
      Result.FRanges[Range].FMin := StrToInt(Copy(Parser[Range],1,P-1));
      Result.FRanges[Range].FMax := StrToInt(Copy(Parser[Range],P+1,MaxInt));
    end;
  end;
end;

Class Operator TRanges.Implicit(Ranges: TRanges): String;
begin
  Result := Ranges.AsString;
end;

Constructor TRanges.Create(const Values: array of Integer);
begin
  Self := Values;
end;

Constructor TRanges.Create(const Ranges: array of TRange);
begin
  SetLength(FRanges,Length(Ranges));
  for var Range := low(Ranges) to high(Ranges) do FRanges[Range] := Ranges[Range];
end;

Constructor TRanges.Create(const Ranges: string);
begin
  Self := Ranges;
end;

Function TRanges.GetRanges(Range: Integer): TRange;
begin
  Result := FRanges[Range];
end;

Function TRanges.Count: Integer;
begin
  Result := Length(FRanges);
end;

Function TRanges.Contains(const Value: Integer): Boolean;
begin
  Result := false;
  for var Range := 0 to Count-1 do
  if FRanges[Range].Contains(Value) then Exit(true);
end;

Function TRanges.Values: TArray<Integer>;
begin
  Result := [];
  for var Range := 0 to Count-1 do Result := Result + FRanges[Range].Values;
end;

Function TRanges.AsString: string;
begin
  Result := '';
  var Separator := '';
  for var Range := 0 to Count-1 do
  begin
    if FRanges[Range].Count = 1 then
      Result := Result + Separator + FRanges[Range].FMin.ToString
    else
      Result := Result + Separator + FRanges[Range].FMin.ToString + '-' + FRanges[Range].FMax.ToString;
    Separator := ',';
  end;
end;

end.
