unit TestUtils.FloatHlp;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Math, DUnitX.TestFramework, FloatHlp;

Type
  [TestFixture]
  TFloat64HelperTests = class
  private
    Function Outcome(const F: TFunc<Float64>): String;
  public
    // Round: banker's rounding (half rounds to even)
    [Test] Procedure TestRound_HalfToEven_0_5;
    [Test] Procedure TestRound_HalfToEven_1_5;
    [Test] Procedure TestRound_HalfToEven_2_5;
    [Test] Procedure TestRound_Negative;
    [Test] Procedure TestRound_Exact;
    // Add / Subtract (in-place)
    [Test] Procedure TestAdd;
    [Test] Procedure TestSubtract;
    // MultiplyBy / DivideBy (in-place)
    [Test] Procedure TestMultiplyBy;
    [Test] Procedure TestDivideBy;
    // MultipliedBy / DividedBy (functional, original unchanged)
    [Test] Procedure TestMultipliedBy_OriginalUnchanged;
    [Test] Procedure TestDividedBy_OriginalUnchanged;
    // Exponentiate (function and helper method)
    [Test] Procedure TestExponentiate_Zero;
    [Test] Procedure TestExponentiate_One;
    [Test] Procedure TestExponentiate_MatchesSystemExp;
    [Test] Procedure TestExponentiate_OnExpression;
    [Test] Procedure TestExponentiate_HelperSameAsFunction;
    // Outside [-708,709] Exponentiate passes the argument on to System.Exp
    [Test] Procedure TestExponentiate_Overflow_SameAsSystemExp;
    [Test] Procedure TestExponentiate_Subnormal_SameAsSystemExp;
    [Test] Procedure TestExponentiate_Underflow_SameAsSystemExp;
    [Test] Procedure TestExponentiate_NaN;
    // ToString (no args)
    [Test] Procedure TestToString_Default;
    // ToString(Format)
    [Test] Procedure TestToString_Format;
    // ToString(Decimals, SkipTrailingZeroDecimals)
    [Test] Procedure TestToString_Decimals_Fixed;
    [Test] Procedure TestToString_Decimals_SkipTrailing;
    [Test] Procedure TestToString_Decimals_HigherThan5;
    [Test] Procedure TestToString_Decimals_Zero;
    // ToString(Decimals, FixedDecimals, SkipTrailingZeroDecimals) - adaptive
    [Test] Procedure TestToString_Adaptive_SmallNumber;
    [Test] Procedure TestToString_Adaptive_LargeNumber;
    [Test] Procedure TestToString_Adaptive_FixedOverride;
    // ToString(Decimals, SkipTrailingZeroDecimals) gives the text of FormatFloat with the masks it replaced
    [Test] Procedure TestToString_Decimals_LiteralCases;
    [Test] Procedure TestToString_Decimals_SpecialValues;
    [Test] Procedure TestToString_Decimals_TinyValues;
    [Test] Procedure TestToString_Decimals_Midpoints;
    [Test] Procedure TestToString_Decimals_RandomValues;
    [Test] Procedure TestToString_Decimals_LargeValues;
    [Test] Procedure TestToString_Decimals_DecimalSeparator;
    [Test] Procedure TestToString_Adaptive_RandomValues;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TFloat64HelperTests.TestRound_HalfToEven_0_5;
begin
  // 0.5 rounds to 0 (nearest even)
  var V: Float64 := 0.5;
  Assert.AreEqual(Int64(0), V.Round);
end;

Procedure TFloat64HelperTests.TestRound_HalfToEven_1_5;
begin
  // 1.5 rounds to 2 (nearest even)
  var V: Float64 := 1.5;
  Assert.AreEqual(Int64(2), V.Round);
end;

Procedure TFloat64HelperTests.TestRound_HalfToEven_2_5;
begin
  // 2.5 rounds to 2 (nearest even)
  var V: Float64 := 2.5;
  Assert.AreEqual(Int64(2), V.Round);
end;

Procedure TFloat64HelperTests.TestRound_Negative;
begin
  var V: Float64 := -1.5;
  Assert.AreEqual(Int64(-2), V.Round);
end;

Procedure TFloat64HelperTests.TestRound_Exact;
begin
  var V: Float64 := 3.0;
  Assert.AreEqual(Int64(3), V.Round);
end;

Procedure TFloat64HelperTests.TestAdd;
begin
  var V: Float64 := 1.0;
  V.Add(2.5);
  Assert.AreEqual(3.5, V, 1e-12);
end;

Procedure TFloat64HelperTests.TestSubtract;
begin
  var V: Float64 := 5.0;
  V.Subtract(1.5);
  Assert.AreEqual(3.5, V, 1e-12);
end;

Procedure TFloat64HelperTests.TestMultiplyBy;
begin
  var V: Float64 := 4.0;
  V.MultiplyBy(2.5);
  Assert.AreEqual(10.0, V, 1e-12);
end;

Procedure TFloat64HelperTests.TestDivideBy;
begin
  var V: Float64 := 9.0;
  V.DivideBy(3.0);
  Assert.AreEqual(3.0, V, 1e-12);
end;

Procedure TFloat64HelperTests.TestMultipliedBy_OriginalUnchanged;
begin
  var V: Float64 := 4.0;
  var R := V.MultipliedBy(3.0);
  Assert.AreEqual(12.0, R, 1e-12);
  Assert.AreEqual(4.0,  V, 1e-12, 'Original must not change');
end;

Procedure TFloat64HelperTests.TestDividedBy_OriginalUnchanged;
begin
  var V: Float64 := 8.0;
  var R := V.DividedBy(4.0);
  Assert.AreEqual(2.0, R, 1e-12);
  Assert.AreEqual(8.0, V, 1e-12, 'Original must not change');
end;

Function TFloat64HelperTests.Outcome(const F: TFunc<Float64>): String;
// The result as text, or the class of the exception raised
begin
  try
    Result := FloatToStr(F());
  except
    on E: Exception do Result := E.ClassName;
  end;
end;

Procedure TFloat64HelperTests.TestExponentiate_Zero;
begin
  Assert.AreEqual(1.0, Exponentiate(0.0), 0.0);
end;

Procedure TFloat64HelperTests.TestExponentiate_One;
begin
  Assert.AreEqual(2.718281828459045, Exponentiate(1.0), 1e-15);
end;

Procedure TFloat64HelperTests.TestExponentiate_MatchesSystemExp;
// Max 3 ulp from the correctly rounded result, System.Exp max 1 ulp: within 4 ulp of each other
begin
  var MaxRelDiff: Float64 := 0;
  for var I := 0 to 1000000 do
  begin
    var X: Float64 := -707 + 1415*I/1000000;
    var RelDiff := Abs(Exponentiate(X) - System.Exp(X))/System.Exp(X);
    if RelDiff > MaxRelDiff then MaxRelDiff := RelDiff;
  end;
  Assert.IsTrue(MaxRelDiff <= 1e-15, 'Max relative difference ' + FloatToStr(MaxRelDiff));
end;

Procedure TFloat64HelperTests.TestExponentiate_OnExpression;
// A real-valued expression has type Extended; the function accepts it like any Float64
begin
  var A: Float64 := -4.0;
  var B: Float64 := 5.0;
  Assert.AreEqual(System.Exp(A*B), Exponentiate(A*B), 1e-15*System.Exp(A*B));
end;

Procedure TFloat64HelperTests.TestExponentiate_HelperSameAsFunction;
begin
  for var I := 0 to 1000 do
  begin
    var V: Float64 := -800 + 1600*I/1000;
    Assert.AreEqual(Outcome(function: Float64 begin Result := Exponentiate(V) end),
                    Outcome(function: Float64 begin Result := V.Exponentiate end));
  end;
end;

Procedure TFloat64HelperTests.TestExponentiate_Overflow_SameAsSystemExp;
begin
  Assert.AreEqual(Outcome(function: Float64 begin Result := System.Exp(800.0) end),
                  Outcome(function: Float64 begin Result := Exponentiate(800.0) end));
end;

Procedure TFloat64HelperTests.TestExponentiate_Subnormal_SameAsSystemExp;
begin
  Assert.AreEqual(System.Exp(-720.0), Exponentiate(-720.0), 0.0);
end;

Procedure TFloat64HelperTests.TestExponentiate_Underflow_SameAsSystemExp;
begin
  Assert.AreEqual(Outcome(function: Float64 begin Result := System.Exp(-800.0) end),
                  Outcome(function: Float64 begin Result := Exponentiate(-800.0) end));
end;

Procedure TFloat64HelperTests.TestExponentiate_NaN;
begin
  Assert.IsTrue(IsNan(Exponentiate(NaN)));
end;

Procedure TFloat64HelperTests.TestToString_Default;
begin
  var V: Float64 := 1.25;
  Assert.AreEqual(FloatToStr(1.25), V.ToString);
end;

Procedure TFloat64HelperTests.TestToString_Format;
begin
  var V: Float64 := 1234.5;
  Assert.AreEqual(FormatFloat('0.00', 1234.5), V.ToString('0.00'));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_Fixed;
begin
  var V: Float64 := 1.5;
  // 2 decimals, no skip -> '1.50'
  Assert.AreEqual('1.50', V.ToString(2, False));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_SkipTrailing;
begin
  var V: Float64 := 1.5;
  // 2 decimals, skip trailing zeros -> '1.5'
  Assert.AreEqual('1.5', V.ToString(2, True));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_HigherThan5;
begin
  var V: Float64 := 1.0;
  // 7 decimals, no skip -> '1.0000000'
  Assert.AreEqual('1.0000000', V.ToString(7, False));
  // 7 decimals, skip -> '1'
  Assert.AreEqual('1', V.ToString(7, True));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_Zero;
begin
  var V: Float64 := 3.9;
  // 0 decimals -> rounded, no decimal separator
  Assert.AreEqual('4', V.ToString(0, False));
end;

Procedure TFloat64HelperTests.TestToString_Adaptive_SmallNumber;
begin
  var V: Float64 := 0.5;
  // |V| < 1 -> HideDecimals stays 0 -> same as ToString(3, False)
  Assert.AreEqual('0.500', V.ToString(3, False, False));
end;

Procedure TFloat64HelperTests.TestToString_Adaptive_LargeNumber;
begin
  var V: Float64 := 100.0;
  // |V| >= 1 -> HideDecimals=1; >= 10 -> HideDecimals=2; >= 100 -> HideDecimals=3
  // Decimals=3, HideDecimals=3 -> ToString(0, False) -> '100'
  Assert.AreEqual('100', V.ToString(3, False, False));
end;

Procedure TFloat64HelperTests.TestToString_Adaptive_FixedOverride;
begin
  var V: Float64 := 100.0;
  // FixedDecimals=true -> no adaptation, same as ToString(3, False)
  Assert.AreEqual('100.000', V.ToString(3, True, False));
end;

////////////////////////////////////////////////////////////////////////////////
// ToString(Decimals, SkipTrailingZeroDecimals)
////////////////////////////////////////////////////////////////////////////////

Function Reference(const Value: Float64; Decimals: Byte; SkipTrailingZeroDecimals: Boolean): String;
// The implementation that ToString(Decimals,SkipTrailingZeroDecimals) replaced
begin
  if Decimals > 16 then Decimals := 16;
  if SkipTrailingZeroDecimals then
    Result := FormatFloat('0.' + StringOfChar('#',Decimals),Value)
  else
    Result := FormatFloat('0.' + StringOfChar('0',Decimals),Value);
end;

Function Adjacent(const Value: Float64; const Steps: Integer): Float64;
// The double Steps representable values further from zero (or closer to zero for negative Steps)
begin
  Result := Value;
  PInt64(@Result)^ := PInt64(@Result)^ + Steps;
end;

Procedure CheckSameAsReference(const Value: Float64);
// For every number of decimals, with and without trailing zero decimals
begin
  for var Decimals := 0 to 17 do
  for var SkipTrailingZeroDecimals := false to true do
  Assert.AreEqual(Reference(Value,Decimals,SkipTrailingZeroDecimals),Value.ToString(Decimals,SkipTrailingZeroDecimals),
                  'Value ' + FloatToStr(Value) + ' (' + Value.ToString('0.00000000000000000E+0') + '), ' +
                  Decimals.ToString + ' decimals, skip trailing zeros ' + BoolToStr(SkipTrailingZeroDecimals,true));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_LiteralCases;
// Texts verified against FormatFloat
begin
  var V: Float64 := 0;
  Assert.AreEqual('0',V.ToString(3,true));
  Assert.AreEqual('0.000',V.ToString(3,false));
  V := -1.5;
  Assert.AreEqual('-1.50',V.ToString(2,false));
  Assert.AreEqual('-1.5',V.ToString(2,true));
  V := 2.5;
  Assert.AreEqual('2.5',V.ToString(5,true));
  Assert.AreEqual('2.50000',V.ToString(5,false));
  V := 1234567.891;
  Assert.AreEqual('1234567.891',V.ToString(3,false));
  Assert.AreEqual('1234567.9',V.ToString(1,true));
  Assert.AreEqual('1234568',V.ToString(0,true));
  // The decimal digits of the value are rounded half away from zero
  V := 0.000125;
  Assert.AreEqual('0.00013',V.ToString(5,true));
  V := -0.000005;
  Assert.AreEqual('-0.00001',V.ToString(5,true));
  // The double of 0.123455 is just above the half and rounds up; a value just below it rounds down
  V := 0.123455;
  Assert.AreEqual('0.12346',V.ToString(5,true));
  V := 0.1234549999999996;
  Assert.AreEqual('0.12345',V.ToString(5,true));
  // A nonzero value that rounds to zero gets all its zero decimals, even when trailing zeros are skipped
  V := 0.0000026;
  Assert.AreEqual('0.00000',V.ToString(5,true));
  V := -0.0000026;
  Assert.AreEqual('0.00000',V.ToString(5,true));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_SpecialValues;
begin
  var Zero: Float64 := 0;
  CheckSameAsReference(Zero);
  CheckSameAsReference(-Zero);
  CheckSameAsReference(NaN);
  CheckSameAsReference(Infinity);
  CheckSameAsReference(NegInfinity);
  CheckSameAsReference(MaxDouble);
  CheckSameAsReference(-MaxDouble);
  CheckSameAsReference(MinDouble);
  CheckSameAsReference(4.9E-324);  // Smallest subnormal
  CheckSameAsReference(1);
  CheckSameAsReference(-1);
  CheckSameAsReference(0.5);
  CheckSameAsReference(-0.5);
  CheckSameAsReference(0.1);
  CheckSameAsReference(0.3);
  CheckSameAsReference(1/3);
  CheckSameAsReference(2/3);
  CheckSameAsReference(Pi);
  CheckSameAsReference(-Exp(1));
end;

Procedure TFloat64HelperTests.TestToString_Decimals_TinyValues;
// Values that round to zero at some or all numbers of decimals
begin
  for var Exponent := -1 downto -30 do
  for var Mantissa in [1.0,2.6,4.9,5.0,5.1,9.9] do
  begin
    var V: Float64 := Mantissa*IntPower(10,Exponent);
    CheckSameAsReference(V);
    CheckSameAsReference(-V);
    CheckSameAsReference(Adjacent(V,1));
    CheckSameAsReference(Adjacent(V,-1));
  end;
end;

Procedure TFloat64HelperTests.TestToString_Decimals_Midpoints;
// Decimal halves at each number of decimals, and the doubles next to them
begin
  RandSeed := 20261019;
  for var Decimals := 0 to 10 do
  begin
    var Scale: Float64 := IntPower(10,Decimals);
    for var I := 1 to 2000 do
    begin
      var V: Float64 := (Random(10000000) + 0.5)/Scale;
      CheckSameAsReference(V);
      CheckSameAsReference(-V);
      CheckSameAsReference(Adjacent(V,1));
      CheckSameAsReference(Adjacent(V,-1));
      CheckSameAsReference(Adjacent(-V,1));
      CheckSameAsReference(Adjacent(-V,-1));
    end;
  end;
end;

Procedure TFloat64HelperTests.TestToString_Decimals_RandomValues;
// Magnitudes from 1E-10 to 1E10, both signs, and values with a few decimals as they occur in model output
begin
  RandSeed := 20261019;
  for var I := 1 to 20000 do
  begin
    var V: Float64 := (2*Random-1)*Power(10,20*Random-10);
    CheckSameAsReference(V);
  end;
  for var Decimals := 0 to 8 do
  begin
    var Scale: Float64 := IntPower(10,Decimals);
    for var I := 1 to 2000 do
    CheckSameAsReference((Random(20000001)-10000000)/Scale);
  end;
end;

Procedure TFloat64HelperTests.TestToString_Decimals_LargeValues;
// Around and beyond 2^52, where the scaled value no longer has a fraction bit
begin
  var TwoPow52: Float64 := 4503599627370496.0;
  for var Decimals := 0 to 17 do
  begin
    var Scale: Float64 := IntPower(10,Decimals);
    for var Steps := -3 to 3 do
    begin
      CheckSameAsReference(Adjacent(TwoPow52/Scale,Steps));
      CheckSameAsReference(Adjacent(-TwoPow52/Scale,Steps));
      CheckSameAsReference(Adjacent(2*TwoPow52/Scale,Steps));
    end;
  end;
  CheckSameAsReference(1E15);
  CheckSameAsReference(1E16);
  CheckSameAsReference(1E17);
  CheckSameAsReference(123456789012345678.0);
  CheckSameAsReference(1E300);
  CheckSameAsReference(-1E300);
end;

Procedure TFloat64HelperTests.TestToString_Decimals_DecimalSeparator;
// The decimal separator of FormatSettings is used, like FormatFloat does
Var
  Separator: Char;
begin
  Separator := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := ',';
    var V: Float64 := 1.5;
    Assert.AreEqual('1,50',V.ToString(2,false));
    Assert.AreEqual('1,5',V.ToString(2,true));
    Assert.AreEqual('2',V.ToString(0,false));
    RandSeed := 20261019;
    for var I := 1 to 1000 do CheckSameAsReference((2*Random-1)*Power(10,12*Random-6));
  finally
    FormatSettings.DecimalSeparator := Separator;
  end;
end;

Procedure TFloat64HelperTests.TestToString_Adaptive_RandomValues;
// The adaptive overload hides one decimal per integer digit, and then formats like the fixed overload
begin
  RandSeed := 20261019;
  for var I := 1 to 5000 do
  begin
    var V: Float64 := (2*Random-1)*Power(10,16*Random-8);
    var HideDecimals := 0;
    var Threshold: Float64 := 1;
    while (Abs(V) >= Threshold) and (HideDecimals < 5) do
    begin
      Inc(HideDecimals);
      Threshold := 10*Threshold;
    end;
    Assert.AreEqual(Reference(V,5-HideDecimals,true),V.ToString(5,false,true),'Value ' + FloatToStr(V));
    Assert.AreEqual(Reference(V,5-HideDecimals,false),V.ToString(5,false,false),'Value ' + FloatToStr(V));
    Assert.AreEqual(Reference(V,5,true),V.ToString(5,true,true),'Value ' + FloatToStr(V));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFloat64HelperTests);

end.
