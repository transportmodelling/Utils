unit TestUtils.Polynom;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, Polynom;

Type
  [TestFixture]
  TPolynomialTests = class
  public
    // Construction and basic properties
    [Test] procedure TestCreateConstant;
    [Test] procedure TestCreateCoefs;
    [Test] procedure TestImplicitFromConstant;
    [Test] procedure TestImplicitFromCoefs;
    [Test] procedure TestDegreeReducedWhenLeadingZero;
    // Null
    [Test] procedure TestNullForZeroConstant;
    [Test] procedure TestNotNullForNonZeroConstant;
    [Test] procedure TestNotNullForHigherDegree;
    // Evaluation
    [Test] procedure TestValueConstant;
    [Test] procedure TestValueLinear;
    [Test] procedure TestValueQuadratic;
    [Test] procedure TestValueAtZero;
    // Equality
    [Test] procedure TestEqualSamePolynomial;
    [Test] procedure TestEqualDifferentCoefs;
    [Test] procedure TestEqualDifferentDegrees;
    // Addition
    [Test] procedure TestAddScalarToPolynomial;
    [Test] procedure TestAddPolynomialsSameDegree;
    [Test] procedure TestAddPolynomialsDifferentDegrees;
    // Multiplication
    [Test] procedure TestMultiplyScalarByPolynomial;
    [Test] procedure TestMultiplyScalarZero;
    [Test] procedure TestMultiplyPolynomials;
    [Test] procedure TestMultiplyByNull;
    // Differentiate (in-place)
    [Test] procedure TestDifferentiateConstant;
    [Test] procedure TestDifferentiateLinear;
    [Test] procedure TestDifferentiateQuadratic;
    // Derivative (functional)
    [Test] procedure TestDerivativeConstant;
    [Test] procedure TestDerivativeQuadratic;
    // AntiDifferentiate (in-place)
    [Test] procedure TestAntiDifferentiateConstant;
    [Test] procedure TestAntiDifferentiateLinear;
    // Primitive (functional)
    [Test] procedure TestPrimitiveConstant;
    [Test] procedure TestPrimitiveQuadratic;
    [Test] procedure TestPrimitiveWithConstant;
    // Integrate
    [Test] procedure TestIntegrateConstant;
    [Test] procedure TestIntegrateLinear;
    [Test] procedure TestIntegrateQuadratic;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

const
  Eps = 1e-10;

// Construction and basic properties

procedure TPolynomialTests.TestCreateConstant;
begin
  var P := TPolynomial.Create(5.0);
  Assert.AreEqual(0, P.Degree);
  Assert.AreEqual(5.0, P.Coefs[0], Eps);
end;

procedure TPolynomialTests.TestCreateCoefs;
begin
  // 3 + 2x + x^2
  var P := TPolynomial.Create([3.0, 2.0, 1.0]);
  Assert.AreEqual(2, P.Degree);
  Assert.AreEqual(3.0, P.Coefs[0], Eps);
  Assert.AreEqual(2.0, P.Coefs[1], Eps);
  Assert.AreEqual(1.0, P.Coefs[2], Eps);
end;

procedure TPolynomialTests.TestImplicitFromConstant;
begin
  var P: TPolynomial := 7.0;
  Assert.AreEqual(0, P.Degree);
  Assert.AreEqual(7.0, P.Coefs[0], Eps);
end;

procedure TPolynomialTests.TestImplicitFromCoefs;
begin
  var P: TPolynomial := [1.0, 0.0, 4.0];
  Assert.AreEqual(2, P.Degree);
  Assert.AreEqual(1.0, P.Coefs[0], Eps);
  Assert.AreEqual(4.0, P.Coefs[2], Eps);
end;

procedure TPolynomialTests.TestDegreeReducedWhenLeadingZero;
begin
  // Supplying [1, 2, 0] — leading coef is 0, so true degree is 1
  var P: TPolynomial := [1.0, 2.0, 0.0];
  Assert.AreEqual(1, P.Degree);
end;

// Null

procedure TPolynomialTests.TestNullForZeroConstant;
begin
  var P: TPolynomial := 0.0;
  Assert.IsTrue(P.Null);
end;

procedure TPolynomialTests.TestNotNullForNonZeroConstant;
begin
  var P: TPolynomial := 3.0;
  Assert.IsFalse(P.Null);
end;

procedure TPolynomialTests.TestNotNullForHigherDegree;
begin
  var P: TPolynomial := [0.0, 1.0];
  Assert.IsFalse(P.Null);
end;

// Evaluation

procedure TPolynomialTests.TestValueConstant;
begin
  var P: TPolynomial := 4.0;
  Assert.AreEqual(4.0, P[2.0], Eps);
  Assert.AreEqual(4.0, P[-1.0], Eps);
end;

procedure TPolynomialTests.TestValueLinear;
begin
  // 2 + 3x  =>  at x=4: 14
  var P: TPolynomial := [2.0, 3.0];
  Assert.AreEqual(14.0, P[4.0], Eps);
end;

procedure TPolynomialTests.TestValueQuadratic;
begin
  // 1 + 2x + x^2  =>  at x=3: 1+6+9 = 16
  var P: TPolynomial := [1.0, 2.0, 1.0];
  Assert.AreEqual(16.0, P[3.0], Eps);
end;

procedure TPolynomialTests.TestValueAtZero;
begin
  // Value at 0 is always the constant term
  var P: TPolynomial := [5.0, 3.0, 2.0];
  Assert.AreEqual(5.0, P[0.0], Eps);
end;

// Equality

procedure TPolynomialTests.TestEqualSamePolynomial;
begin
  var A: TPolynomial := [1.0, 2.0, 3.0];
  var B: TPolynomial := [1.0, 2.0, 3.0];
  Assert.IsTrue(A = B);
end;

procedure TPolynomialTests.TestEqualDifferentCoefs;
begin
  var A: TPolynomial := [1.0, 2.0, 3.0];
  var B: TPolynomial := [1.0, 2.0, 4.0];
  Assert.IsFalse(A = B);
end;

procedure TPolynomialTests.TestEqualDifferentDegrees;
begin
  var A: TPolynomial := [1.0, 2.0];
  var B: TPolynomial := [1.0, 2.0, 3.0];
  Assert.IsFalse(A = B);
end;

// Addition

procedure TPolynomialTests.TestAddScalarToPolynomial;
begin
  // 10 + (1 + 2x) = 11 + 2x
  var P: TPolynomial := [1.0, 2.0];
  var R: TPolynomial := 10.0 + P;
  Assert.AreEqual(1, R.Degree);
  Assert.AreEqual(11.0, R.Coefs[0], Eps);
  Assert.AreEqual(2.0,  R.Coefs[1], Eps);
end;

procedure TPolynomialTests.TestAddPolynomialsSameDegree;
begin
  // (1 + 2x) + (3 + 4x) = 4 + 6x
  var A: TPolynomial := [1.0, 2.0];
  var B: TPolynomial := [3.0, 4.0];
  var R: TPolynomial := A + B;
  Assert.AreEqual(1, R.Degree);
  Assert.AreEqual(4.0, R.Coefs[0], Eps);
  Assert.AreEqual(6.0, R.Coefs[1], Eps);
end;

procedure TPolynomialTests.TestAddPolynomialsDifferentDegrees;
begin
  // (1 + 2x) + (3 + 4x + 5x^2) = 4 + 6x + 5x^2
  var A: TPolynomial := [1.0, 2.0];
  var B: TPolynomial := [3.0, 4.0, 5.0];
  var R: TPolynomial := A + B;
  Assert.AreEqual(2, R.Degree);
  Assert.AreEqual(4.0, R.Coefs[0], Eps);
  Assert.AreEqual(6.0, R.Coefs[1], Eps);
  Assert.AreEqual(5.0, R.Coefs[2], Eps);
end;

// Multiplication

procedure TPolynomialTests.TestMultiplyScalarByPolynomial;
begin
  // 3 * (2 + x) = 6 + 3x
  var P: TPolynomial := [2.0, 1.0];
  var R: TPolynomial := 3.0 * P;
  Assert.AreEqual(1, R.Degree);
  Assert.AreEqual(6.0, R.Coefs[0], Eps);
  Assert.AreEqual(3.0, R.Coefs[1], Eps);
end;

procedure TPolynomialTests.TestMultiplyScalarZero;
begin
  var P: TPolynomial := [2.0, 1.0];
  var R: TPolynomial := 0.0 * P;
  Assert.IsTrue(R.Null);
end;

procedure TPolynomialTests.TestMultiplyPolynomials;
begin
  // (1 + x) * (1 + x) = 1 + 2x + x^2
  var P: TPolynomial := [1.0, 1.0];
  var R: TPolynomial := P * P;
  Assert.AreEqual(2, R.Degree);
  Assert.AreEqual(1.0, R.Coefs[0], Eps);
  Assert.AreEqual(2.0, R.Coefs[1], Eps);
  Assert.AreEqual(1.0, R.Coefs[2], Eps);
end;

procedure TPolynomialTests.TestMultiplyByNull;
begin
  var A: TPolynomial := [1.0, 2.0];
  var Z: TPolynomial := 0.0;
  var R: TPolynomial := A * Z;
  Assert.IsTrue(R.Null);
end;

// Differentiate (in-place)

procedure TPolynomialTests.TestDifferentiateConstant;
begin
  var P: TPolynomial := 5.0;
  P.Differentiate;
  Assert.IsTrue(P.Null);
end;

procedure TPolynomialTests.TestDifferentiateLinear;
begin
  // d/dx (3 + 2x) = 2
  var P: TPolynomial := [3.0, 2.0];
  P.Differentiate;
  Assert.AreEqual(0, P.Degree);
  Assert.AreEqual(2.0, P.Coefs[0], Eps);
end;

procedure TPolynomialTests.TestDifferentiateQuadratic;
begin
  // d/dx (1 + 2x + 3x^2) = 2 + 6x
  var P: TPolynomial := [1.0, 2.0, 3.0];
  P.Differentiate;
  Assert.AreEqual(1, P.Degree);
  Assert.AreEqual(2.0, P.Coefs[0], Eps);
  Assert.AreEqual(6.0, P.Coefs[1], Eps);
end;

// Derivative (functional)

procedure TPolynomialTests.TestDerivativeConstant;
begin
  var P: TPolynomial := 9.0;
  var D := P.Derivative;
  Assert.IsTrue(D.Null);
end;

procedure TPolynomialTests.TestDerivativeQuadratic;
begin
  // d/dx (1 + 2x + 3x^2) = 2 + 6x
  var P: TPolynomial := [1.0, 2.0, 3.0];
  var D := P.Derivative;
  Assert.AreEqual(1, D.Degree);
  Assert.AreEqual(2.0, D.Coefs[0], Eps);
  Assert.AreEqual(6.0, D.Coefs[1], Eps);
  // Original unchanged
  Assert.AreEqual(2, P.Degree);
end;

// AntiDifferentiate (in-place)

procedure TPolynomialTests.TestAntiDifferentiateConstant;
begin
  // integral of 4  =>  0 + 4x  (constant defaults to 0)
  var P: TPolynomial := 4.0;
  P.AntiDifferentiate;
  Assert.AreEqual(1, P.Degree);
  Assert.AreEqual(0.0, P.Coefs[0], Eps);
  Assert.AreEqual(4.0, P.Coefs[1], Eps);
end;

procedure TPolynomialTests.TestAntiDifferentiateLinear;
begin
  // integral of (2 + 6x)  =>  C + 2x + 3x^2  (C=5)
  var P: TPolynomial := [2.0, 6.0];
  P.AntiDifferentiate(5.0);
  Assert.AreEqual(2, P.Degree);
  Assert.AreEqual(5.0, P.Coefs[0], Eps);
  Assert.AreEqual(2.0, P.Coefs[1], Eps);
  Assert.AreEqual(3.0, P.Coefs[2], Eps);
end;

// Primitive (functional)

procedure TPolynomialTests.TestPrimitiveConstant;
begin
  // Primitive of null polynomial is the constant
  var Z: TPolynomial := 0.0;
  var Q := Z.Primitive(7.0);
  Assert.AreEqual(0, Q.Degree);
  Assert.AreEqual(7.0, Q.Coefs[0], Eps);
end;

procedure TPolynomialTests.TestPrimitiveQuadratic;
begin
  // Primitive of (6x^2)  =>  2x^3
  var P: TPolynomial := [0.0, 0.0, 6.0];
  var Q := P.Primitive;
  Assert.AreEqual(3, Q.Degree);
  Assert.AreEqual(0.0, Q.Coefs[0], Eps);
  Assert.AreEqual(0.0, Q.Coefs[1], Eps);
  Assert.AreEqual(0.0, Q.Coefs[2], Eps);
  Assert.AreEqual(2.0, Q.Coefs[3], Eps);
  // Original unchanged
  Assert.AreEqual(2, P.Degree);
end;

procedure TPolynomialTests.TestPrimitiveWithConstant;
begin
  // Primitive of 2x  =>  C + x^2  (C=3)
  var P: TPolynomial := [0.0, 2.0];
  var Q := P.Primitive(3.0);
  Assert.AreEqual(2, Q.Degree);
  Assert.AreEqual(3.0, Q.Coefs[0], Eps);
  Assert.AreEqual(0.0, Q.Coefs[1], Eps);
  Assert.AreEqual(1.0, Q.Coefs[2], Eps);
end;

// Integrate

procedure TPolynomialTests.TestIntegrateConstant;
begin
  // integral of 3 from 0 to 2 = 6
  var P: TPolynomial := 3.0;
  Assert.AreEqual(6.0, P.Integrate(0.0, 2.0), Eps);
end;

procedure TPolynomialTests.TestIntegrateLinear;
begin
  // integral of 2x from 1 to 3 = [x^2] from 1 to 3 = 9 - 1 = 8
  var P: TPolynomial := [0.0, 2.0];
  Assert.AreEqual(8.0, P.Integrate(1.0, 3.0), Eps);
end;

procedure TPolynomialTests.TestIntegrateQuadratic;
begin
  // integral of x^2 from 0 to 3 = [x^3/3] from 0 to 3 = 9
  var P: TPolynomial := [0.0, 0.0, 1.0];
  Assert.AreEqual(9.0, P.Integrate(0.0, 3.0), Eps);
end;

initialization
  TDUnitX.RegisterTestFixture(TPolynomialTests);

end.
