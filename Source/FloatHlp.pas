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
    // Exponentiate(Self), see below. Not named Exp: SysUtils' Double/Extended helpers have an Exp property
    // (the raw exponent bits), which would be used instead on expressions and depending on the uses order.
    Function Exponentiate: Float64; inline;
    Function IsPositive: Boolean;
    Function IsNegative: Boolean;
    Function IsGreaterThan(const Value: Float64): Boolean;
    Function IsGreaterEqual(const Value: Float64): Boolean;
    Function IsLessThan(const Value: Float64): Boolean;
    Function IsLessEqual(const Value: Float64): Boolean;
    Function IsBetween(const MinValue,MaxValue: Float64; const Inclusive: Boolean = true): Boolean;
    Function ToString: String; overload;
    Function ToString(const Format: String): String; overload;
    // The text FormatFloat gives with the mask '0.000...' (or '0.###...' when trailing zero decimals are
    // skipped), with Decimals decimals and the decimal separator of FormatSettings. See the implementation.
    Function ToString(Decimals: Byte; SkipTrailingZeroDecimals: Boolean): string; overload;
    Function ToString(Decimals: Byte; FixedDecimals,SkipTrailingZeroDecimals: Boolean): string; overload;
  end;

// Exp(X) as 2^n*exp(r), with n = round(X/ln2) and exp(r) a degree-12 Taylor polynomial (the algorithm
// VecMath vectorizes). In loops over many values about 1.6x as fast as System.Exp, at an error of at most
// 3 ulp instead of 1 (86% of the results correctly rounded, against 99.7% for System.Exp).
// Arguments outside [-708,709], NaN and infinities are passed on to System.Exp.
Function Exponentiate(const X: Float64): Float64; inline;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Function Exponentiate(const X: Float64): Float64;
// n is rounded by adding and subtracting 1.5*2^52 and read from the bits of the sum, instead of
// converting an integer to Float64: cvtsi2sd only writes the low half of its target register and so
// waits for the register's previous contents, which can serialize a whole loop (System.Exp has one).
const
  LOG2E = 1.4426950408889634;
  LN2HI = 6.93147180369123816490e-1;
  LN2LO = 1.90821492927058770002e-10;
  Shifter = 6755399441055744.0;            // 1.5*2^52
  ShifterBits = Int64($4338000000000000);  // bits of Shifter
var
  K,N,R,P: Float64;
  Bits: Int64;
begin
  if (X > -708.0) and (X < 709.0) then
  begin
    K := X*LOG2E + Shifter;  // round(X*LOG2E) in the low mantissa bits
    N := K - Shifter;        // round(X*LOG2E)
    R := (X - N*LN2HI) - N*LN2LO;
    P := R*(1.0/479001600.0) + (1.0/39916800.0);
    P := R*P + (1.0/3628800.0);
    P := R*P + (1.0/362880.0);
    P := R*P + (1.0/40320.0);
    P := R*P + (1.0/5040.0);
    P := R*P + (1.0/720.0);
    P := R*P + (1.0/120.0);
    P := R*P + (1.0/24.0);
    P := R*P + (1.0/6.0);
    P := R*P + 0.5;
    P := R*P + 1.0;
    P := R*P + 1.0;
    Bits := ((PInt64(@K)^ - ShifterBits) + 1023) shl 52;  // 2^n
    Result := P*PDouble(@Bits)^;
  end else
    Result := System.Exp(X);
end;

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

Function TFloat64Helper.Exponentiate: Float64;
begin
  Result := FloatHlp.Exponentiate(Self);
end;

Function TFloat64Helper.IsPositive: Boolean;
begin
  Result := (Self > 0);
end;

Function TFloat64Helper.IsNegative: Boolean;
begin
  Result := (Self < 0);
end;

Function TFloat64Helper.IsGreaterThan(const Value: Float64): Boolean;
begin
  Result := (Self > Value);
end;

Function TFloat64Helper.IsGreaterEqual(const Value: Float64): Boolean;
begin
  Result := (Self >= Value);
end;

Function TFloat64Helper.IsLessThan(const Value: Float64): Boolean;
begin
  Result := (Self < Value);
end;

Function TFloat64Helper.IsLessEqual(const Value: Float64): Boolean;
begin
  Result := (Self <= Value);
end;

Function TFloat64Helper.IsBetween(const MinValue,MaxValue: Float64; const Inclusive: Boolean = true): Boolean;
begin
  if Inclusive then
    Result := ( (Self >= MinValue) and (Self <= MaxValue) )
  else
    Result := ( (Self > MinValue) and (Self < MaxValue) )
end;

Function TFloat64Helper.ToString: String;
begin
  Result := FloatToStr(Self);
end;

Function TFloat64Helper.ToString(const Format: String): String;
begin
  Result := FormatFloat(Format,Self);
end;

Function FormatWithMask(const Value: Float64; Decimals: Byte; SkipTrailingZeroDecimals: Boolean): string;
// FormatFloat with the mask '0.000...' or '0.###...': the reference for ToString(Decimals,SkipTrailingZeroDecimals)
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
  Result := FormatFloat(FormatMask, Value);
end;

Function TFloat64Helper.ToString(Decimals: Byte; SkipTrailingZeroDecimals: Boolean): string;
// The same text as FormatWithMask, about 4x as fast: the absolute value is scaled by 10^Decimals and rounded
// to an integer, whose digits are written directly. FormatWithMask is used where this is not known to give
// the same text:
// - NaN and infinities;
// - scaled values of 2^52 or more, where adding 0.5 is no longer exact;
// - scaled values within rounding error of a half: FormatFloat rounds the decimal digits of the value,
//   which can come out on the other side of the half than the scaled value;
// - nonzero values that round to zero: FormatFloat then writes all zero decimals, even with the mask '0.###'.
const
  Scales: array[0..16] of UInt64 = (1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000,
                                    10000000000,100000000000,1000000000000,10000000000000,100000000000000,
                                    1000000000000000,10000000000000000);
  MaxScaled: Float64 = 4503599627370496.0;  // 2^52
  // Distance from a half within which the rounding of FormatFloat is used (powers of 2, so exact doubles)
  MinHalfTolerance: Float64 = 1/1099511627776;        // 2^-40, about 1E-12
  RelativeHalfTolerance: Float64 = 1/70368744177664;  // 2^-46, about 1.4E-14
var
  Scaled: Float64;
  Rounded,Whole,Fraction: UInt64;
  Digits: array[0..39] of Char;  // Sign, up to 16 whole digits, separator, up to 16 decimals
  Pos,NDecimals,Decimal: Integer;
begin
  if Decimals > 16 then Decimals := 16;
  if IsNan(Self) or IsInfinite(Self) then Exit(FormatWithMask(Self,Decimals,SkipTrailingZeroDecimals));
  Scaled := Abs(Self)*Scales[Decimals];
  if (Scaled >= MaxScaled) or (Abs(Frac(Scaled)-0.5) <= Max(MinHalfTolerance,Scaled*RelativeHalfTolerance)) then
    Exit(FormatWithMask(Self,Decimals,SkipTrailingZeroDecimals));
  Rounded := UInt64(Trunc(Scaled+0.5));
  if (Rounded = 0) and (Self <> 0) then Exit(FormatWithMask(Self,Decimals,SkipTrailingZeroDecimals));
  Whole := Rounded div Scales[Decimals];
  Fraction := Rounded mod Scales[Decimals];
  // Write the digits from the end of the buffer backwards
  Pos := Length(Digits);
  NDecimals := Decimals;
  if SkipTrailingZeroDecimals then
  while (NDecimals > 0) and (Fraction mod 10 = 0) do
  begin
    Fraction := Fraction div 10;
    Dec(NDecimals);
  end;
  for Decimal := 1 to NDecimals do
  begin
    Dec(Pos);
    Digits[Pos] := Char(Ord('0') + Integer(Fraction mod 10));
    Fraction := Fraction div 10;
  end;
  if NDecimals > 0 then
  begin
    Dec(Pos);
    Digits[Pos] := FormatSettings.DecimalSeparator;
  end;
  repeat
    Dec(Pos);
    Digits[Pos] := Char(Ord('0') + Integer(Whole mod 10));
    Whole := Whole div 10;
  until Whole = 0;
  if Self < 0 then
  begin
    Dec(Pos);
    Digits[Pos] := '-';
  end;
  SetString(Result,PChar(@Digits[Pos]),Length(Digits)-Pos);
end;

Function TFloat64Helper.ToString(Decimals: Byte; FixedDecimals,SkipTrailingZeroDecimals: Boolean): string;
// Magnitude-adaptive formatting: if not FixedDecimals, the number of decimals is reduced by 1 for each
// integer digit, keeping the total number of significant digits constant.
// Decimals gives the number of decimals for values with Abs(Self) < 1.
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
