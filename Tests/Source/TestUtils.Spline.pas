unit TestUtils.Spline;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, Polynom, Spline;

Type
  [TestFixture]
  TSplineTests = class
  public
    // Construction
    [Test] procedure TestCreateSinglePiece;
    [Test] procedure TestCreateMultiplePieces;
    [Test] procedure TestCreateInconsistentArgumentsRaises;
    // Nullify
    [Test] procedure TestNullifyZeroesIntegral;
    // Integrate (full range)
    [Test] procedure TestIntegrateConstantSinglePiece;
    [Test] procedure TestIntegrateLinearSinglePiece;
    [Test] procedure TestIntegrateConstantTwoPieces;
    [Test] procedure TestIntegrateQuadraticSinglePiece;
    // Integrate(a,b) — partial range
    [Test] procedure TestIntegrateRangeFullSpan;
    [Test] procedure TestIntegrateRangeSubset;
    [Test] procedure TestIntegrateRangeClipsToKnots;
    [Test] procedure TestIntegrateRangeStraddlesKnot;
    [Test] procedure TestIntegrateRangeEmptyInterval;
    // Multiply
    [Test] procedure TestMultiplySameKnots;
    [Test] procedure TestMultiplyInterleavedKnots;
    [Test] procedure TestMultiplyDisjointRanges;
    [Test] procedure TestMultiplyFirstStartsEarlier;
    [Test] procedure TestMultiplySecondStartsEarlier;
    [Test] procedure TestMultiplyResultIntegral;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

const
  Eps = 1e-10;

// Helpers — build simple constant and linear splines
function ConstantSpline(x0, x1, c: Float64): TSpline;
var
  P: TPolynomial;
begin
  P := c;
  Result := TSpline.Create([x0, x1], [P]);
end;

function LinearSpline(x0, x1, c0, c1: Float64): TSpline;
var
  P: TPolynomial;
begin
  P := TPolynomial.Create([c0, c1]);
  Result := TSpline.Create([x0, x1], [P]);
end;

// Construction

procedure TSplineTests.TestCreateSinglePiece;
begin
  // Should not raise: one piece needs 2 knots
  var P: TPolynomial := 1.0;
  var S := TSpline.Create([0.0, 1.0], [P]);
  Assert.AreEqual(1.0, S.Integrate, Eps);
end;

procedure TSplineTests.TestCreateMultiplePieces;
begin
  // Three pieces need 4 knots
  var P: TPolynomial := 2.0;
  var S := TSpline.Create([0.0, 1.0, 2.0, 3.0], [P, P, P]);
  Assert.AreEqual(6.0, S.Integrate, Eps);
end;

procedure TSplineTests.TestCreateInconsistentArgumentsRaises;
begin
  var P: TPolynomial := 1.0;
  // 3 knots but 2 polynomials is fine; 3 knots with 1 polynomial is wrong
  Assert.WillRaiseAny(procedure
  begin
    TSpline.Create([0.0, 1.0, 2.0], [P]);
  end);
end;

// Nullify

procedure TSplineTests.TestNullifyZeroesIntegral;
begin
  var S := ConstantSpline(0.0, 5.0, 3.0);
  S.Nullify;
  Assert.AreEqual(0.0, S.Integrate, Eps);
end;

// Integrate (full range)

procedure TSplineTests.TestIntegrateConstantSinglePiece;
begin
  // integral of 4 over [0,3] = 12
  var S := ConstantSpline(0.0, 3.0, 4.0);
  Assert.AreEqual(12.0, S.Integrate, Eps);
end;

procedure TSplineTests.TestIntegrateLinearSinglePiece;
begin
  // integral of (2x) over [1,3] = [x^2] from 1 to 3 = 9-1 = 8
  var S := LinearSpline(1.0, 3.0, 0.0, 2.0);
  Assert.AreEqual(8.0, S.Integrate, Eps);
end;

procedure TSplineTests.TestIntegrateConstantTwoPieces;
begin
  // piece 1: constant 1 over [0,2] = 2
  // piece 2: constant 3 over [2,5] = 9
  // total = 11
  var P1: TPolynomial := 1.0;
  var P2: TPolynomial := 3.0;
  var S := TSpline.Create([0.0, 2.0, 5.0], [P1, P2]);
  Assert.AreEqual(11.0, S.Integrate, Eps);
end;

procedure TSplineTests.TestIntegrateQuadraticSinglePiece;
begin
  // integral of x^2 over [0,3] = 9
  var P := TPolynomial.Create([0.0, 0.0, 1.0]);
  var S := TSpline.Create([0.0, 3.0], [P]);
  Assert.AreEqual(9.0, S.Integrate, Eps);
end;

// Integrate(a,b) — partial range

procedure TSplineTests.TestIntegrateRangeFullSpan;
begin
  // Integrating over the exact knot span should equal the full integral
  var S := ConstantSpline(1.0, 4.0, 2.0);
  Assert.AreEqual(6.0, S.Integrate(1.0, 4.0), Eps);
end;

procedure TSplineTests.TestIntegrateRangeSubset;
begin
  // integral of 2 over [1,3] inside knot span [0,5] = 4
  var S := ConstantSpline(0.0, 5.0, 2.0);
  Assert.AreEqual(4.0, S.Integrate(1.0, 3.0), Eps);
end;

procedure TSplineTests.TestIntegrateRangeClipsToKnots;
begin
  // Requesting a range wider than the spline should only integrate over the knot span
  var S := ConstantSpline(1.0, 3.0, 5.0);
  // integral of 5 over [1,3] = 10, even though we ask [-10, 10]
  Assert.AreEqual(10.0, S.Integrate(-10.0, 10.0), Eps);
end;

procedure TSplineTests.TestIntegrateRangeStraddlesKnot;
begin
  // Two-piece spline; integrate over a range that crosses the internal knot
  // piece 1: constant 1 over [0,2], piece 2: constant 3 over [2,4]
  // Integrate from 1 to 3: 1*(2-1) + 3*(3-2) = 1 + 3 = 4
  var P1: TPolynomial := 1.0;
  var P2: TPolynomial := 3.0;
  var S := TSpline.Create([0.0, 2.0, 4.0], [P1, P2]);
  Assert.AreEqual(4.0, S.Integrate(1.0, 3.0), Eps);
end;

procedure TSplineTests.TestIntegrateRangeEmptyInterval;
begin
  // a = b => integral should be 0
  var S := ConstantSpline(0.0, 5.0, 7.0);
  Assert.AreEqual(0.0, S.Integrate(2.0, 2.0), Eps);
end;

// Multiply

procedure TSplineTests.TestMultiplySameKnots;
begin
  // (constant 2) * (constant 3) over same knots [0,4] => constant 6 over [0,4]
  // Integral = 24
  var A := ConstantSpline(0.0, 4.0, 2.0);
  var B := ConstantSpline(0.0, 4.0, 3.0);
  var R := A * B;
  Assert.AreEqual(24.0, R.Integrate, Eps);
end;

procedure TSplineTests.TestMultiplyInterleavedKnots;
begin
  // A: constant 2 over [0,4], knots 0,2,4 (two pieces both = 2)
  // B: constant 3 over [0,4], knots 0,4  (one piece = 3)
  // Product: 6 over [0,4], integral = 24
  var P2: TPolynomial := 2.0;
  var P3: TPolynomial := 3.0;
  var A := TSpline.Create([0.0, 2.0, 4.0], [P2, P2]);
  var B := TSpline.Create([0.0, 4.0], [P3]);
  var R := A * B;
  Assert.AreEqual(24.0, R.Integrate, Eps);
end;

procedure TSplineTests.TestMultiplyDisjointRanges;
begin
  // A over [0,1], B over [2,3] — no overlap => result has 0 pieces => integral = 0
  var A := ConstantSpline(0.0, 1.0, 5.0);
  var B := ConstantSpline(2.0, 3.0, 5.0);
  var R := A * B;
  Assert.AreEqual(0.0, R.Integrate, Eps);
end;

procedure TSplineTests.TestMultiplyFirstStartsEarlier;
begin
  // A: constant 2 over [0,4]
  // B: constant 3 over [2,6]
  // Overlap [2,4], product = 6, integral = 12
  var A := ConstantSpline(0.0, 4.0, 2.0);
  var B := ConstantSpline(2.0, 6.0, 3.0);
  var R := A * B;
  Assert.AreEqual(12.0, R.Integrate, Eps);
end;

procedure TSplineTests.TestMultiplySecondStartsEarlier;
begin
  // A: constant 2 over [2,6]
  // B: constant 3 over [0,4]
  // Overlap [2,4], product = 6, integral = 12
  var A := ConstantSpline(2.0, 6.0, 2.0);
  var B := ConstantSpline(0.0, 4.0, 3.0);
  var R := A * B;
  Assert.AreEqual(12.0, R.Integrate, Eps);
end;

procedure TSplineTests.TestMultiplyResultIntegral;
begin
  // A: linear (x) over [0,2]  — integral of x^2 from 0 to 2 = 8/3
  // B: linear (x) over [0,2]
  // Product: x^2 over [0,2], integral = 8/3
  var P := TPolynomial.Create([0.0, 1.0]);
  var A := TSpline.Create([0.0, 2.0], [P]);
  var B := TSpline.Create([0.0, 2.0], [P]);
  var R := A * B;
  Assert.AreEqual(8.0/3.0, R.Integrate, Eps);
end;

initialization
  TDUnitX.RegisterTestFixture(TSplineTests);

end.
