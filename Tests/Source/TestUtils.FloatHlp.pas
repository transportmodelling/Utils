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

initialization
  TDUnitX.RegisterTestFixture(TFloat64HelperTests);

end.
