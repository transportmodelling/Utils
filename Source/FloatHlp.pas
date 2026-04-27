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
    Procedure Add(const Value: Float64); inline;
    Procedure Subtract(const Value: Float64); inline;
    Procedure MultiplyBy(const Value: Float64); inline;
    Function MultipliedBy(const Value: Float64): Float64; inline;
    Procedure DivideBy(const Value: Float64); inline;
    Function DividedBy(const Value: Float64): Float64; inline;
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
const
  FixedFormats: array[0..5] of string = ('0','0.0','0.00','0.000','0.0000','0.00000');
  TrimmedFormats: array[0..5] of string = ('0','0.#','0.##','0.###','0.####','0.#####');
var
  FormatMask: string;
begin
  if Decimals > 16 then Decimals := 16;
  if Decimals <= 5 then
    if SkipTrailingZeroDecimals then
      FormatMask := TrimmedFormats[Decimals]
    else
      FormatMask := FixedFormats[Decimals]
  else
    if SkipTrailingZeroDecimals then
      FormatMask := '0.' + StringOfChar('#', Decimals)
    else
      FormatMask := '0.' + StringOfChar('0', Decimals);
  Result := FormatFloat(FormatMask, Self);
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
