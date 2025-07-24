unit FloatHlp;

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
  SysUtils, Math;

Type
  TFloat64Helper = record helper for Float64
  public
    Function Round: Int64;
    Procedure Add(const Value: Float64);
    Procedure Subtract(const Value: Float64);
    Procedure MultiplyBy(const Value: Float64);
    Function MultipliedBy(const Value: Float64): Float64;
    Procedure DivideBy(const Value: Float64);
    Function DividedBy(const Value: Float64): Float64;
    Function ToString: String; overload;
    Function ToString(const Format: String): String; overload;
    Function ToString(Decimals: Byte; SkipTrailingZeroDecimals: Boolean): string; overload;
    Function ToString(Decimals: Byte; FixedDecimals,SkipTrailingZeroDecimals: Boolean): string; overload;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Function TFloat64Helper.Round: Int64;
begin
  Result := System.Round(Self);
end;

Procedure TFloat64Helper.Add(const Value: Float64);
begin
  Self := Self + Value;
end;

Procedure TFloat64Helper.Subtract(const Value: Float64);
begin
  Self := Self - Value;
end;

Procedure TFloat64Helper.MultiplyBy(const Value: Float64);
begin
  Self := Value*Self;
end;

Function TFloat64Helper.MultipliedBy(const Value: Float64): Float64;
begin
  Result := Value*Self;
end;

Procedure TFloat64Helper.DivideBy(const Value: Float64);
begin
  Self := Self/Value;
end;

Function TFloat64Helper.DividedBy(const Value: Float64): Float64;
begin
  Result := Self/Value;
end;

Function TFloat64Helper.ToString: String;
begin
  Result := FloatToStr(Self);
end;

Function TFloat64Helper.ToString(const Format: String): String;
begin
  Result := FormatFloat(Format,Self);
end;

Function TFloat64Helper.ToString(Decimals: Byte; SkipTrailingZeroDecimals: Boolean): string;
begin
  if Decimals > 16 then Decimals := 16;
  case Decimals of
    // For performance use hard-coded format strings for low decimal values
    0: Result := FormatFloat('0',Self);
    1: if SkipTrailingZeroDecimals then
         Result := FormatFloat('0.#',Self)
       else
         Result := FormatFloat('0.0',Self);
    2: if SkipTrailingZeroDecimals then
         Result := FormatFloat('0.##',Self)
       else
         Result := FormatFloat('0.00',Self);
    3: if SkipTrailingZeroDecimals then
         Result := FormatFloat('0.###',Self)
       else
         Result := FormatFloat('0.000',Self);
    4: if SkipTrailingZeroDecimals then
         Result := FormatFloat('0.####',Self)
       else
         Result := FormatFloat('0.0000',Self);
    5: if SkipTrailingZeroDecimals then
         Result := FormatFloat('0.#####',Self)
       else
         Result := FormatFloat('0.00000',Self);
    else
       // For higher values, use dynamic format string creation
       if SkipTrailingZeroDecimals then
         Result := FormatFloat('0.'+StringOfChar('#',Decimals),Self)
       else
         Result := FormatFloat('0.'+StringOfChar('0',Decimals),Self);
  end;
end;

Function TFloat64Helper.ToString(Decimals: Byte; FixedDecimals,SkipTrailingZeroDecimals: Boolean): string;
// If not FixedDecimals the number of decimals decreases for big numbers, 1 less for each additional digit.
// Decimals gives the number of decimals when the absolute value is less than 1.
begin
  if Decimals > 16 then Decimals := 16;
  if FixedDecimals then Result := ToString(Decimals,SkipTrailingZeroDecimals) else
  begin
    var Threshold: UInt64 := 1;
    var HideDecimals: Byte := 0;
    while (Abs(Self) >= Threshold) and (HideDecimals < Decimals) do
    begin
      Inc(HideDecimals);
      Threshold := 10*Threshold;
    end;
    Result := ToString(Decimals-HideDecimals,SkipTrailingZeroDecimals);
  end;
end;

end.
