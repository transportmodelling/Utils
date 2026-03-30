unit TestUtils.FP16;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Math, DUnitX.TestFramework, FP16;

Type
  [TestFixture]
  TFloat16Tests = class
  public
    // Zero
    [Test] procedure TestPositiveZero;
    [Test] procedure TestNegativeZero;
    // Normal values: Float32 -> Float16 -> Float32 round-trip
    [Test] procedure TestOne;
    [Test] procedure TestNegativeOne;
    [Test] procedure TestSmallPositive;
    [Test] procedure TestLargePositive;
    [Test] procedure TestRoundTripPrecision;
    // Special values
    [Test] procedure TestPositiveInfinity;
    [Test] procedure TestNegativeInfinity;
    [Test] procedure TestNaN;
    // Edge cases
    [Test] procedure TestOverflowToInfinity;
    [Test] procedure TestUnderflowToZero;
    [Test] procedure TestDenormalized;
    // Bytes field
    [Test] procedure TestBytesZero;
    [Test] procedure TestBytesOne;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

procedure TFloat16Tests.TestPositiveZero;
begin
  var H: Float16 := Float32(0.0);
  var F: Float32 := H;
  Assert.AreEqual(Float32(0.0), F, 0.0);
end;

procedure TFloat16Tests.TestNegativeZero;
begin
  var H: Float16 := Float32(-0.0);
  var F: Float32 := H;
  // Negative zero should convert back to zero (sign may or may not be preserved)
  Assert.AreEqual(Float32(0.0), Abs(F), 0.0);
end;

procedure TFloat16Tests.TestOne;
begin
  var H: Float16 := Float32(1.0);
  var F: Float32 := H;
  Assert.AreEqual(Float32(1.0), F, 0.0);
end;

procedure TFloat16Tests.TestNegativeOne;
begin
  var H: Float16 := Float32(-1.0);
  var F: Float32 := H;
  Assert.AreEqual(Float32(-1.0), F, 0.0);
end;

procedure TFloat16Tests.TestSmallPositive;
begin
  // 0.5 is exactly representable in Float16
  var H: Float16 := Float32(0.5);
  var F: Float32 := H;
  Assert.AreEqual(Float32(0.5), F, 0.0);
end;

procedure TFloat16Tests.TestLargePositive;
begin
  // 1024.0 is exactly representable in Float16
  var H: Float16 := Float32(1024.0);
  var F: Float32 := H;
  Assert.AreEqual(Float32(1024.0), F, 0.0);
end;

procedure TFloat16Tests.TestRoundTripPrecision;
begin
  // Float16 has ~3 significant decimal digits of precision
  // 1.5 is exactly representable
  var H: Float16 := Float32(1.5);
  var F: Float32 := H;
  Assert.AreEqual(Float32(1.5), F, Float32(0.001));
  // -3.14 should round-trip to within Float16 precision (~0.005)
  var H2: Float16 := Float32(-3.14);
  var F2: Float32 := H2;
  Assert.AreEqual(Float32(-3.14), F2, Float32(0.01));
end;

procedure TFloat16Tests.TestPositiveInfinity;
begin
  var H: Float16 := Float32(Infinity);
  var F: Float32 := H;
  Assert.IsTrue(IsInfinite(F) and (F > 0), 'Expected positive infinity');
end;

procedure TFloat16Tests.TestNegativeInfinity;
begin
  var H: Float16 := Float32(NegInfinity);
  var F: Float32 := H;
  Assert.IsTrue(IsInfinite(F) and (F < 0), 'Expected negative infinity');
end;

procedure TFloat16Tests.TestNaN;
begin
  var H: Float16 := Float32(NaN);
  var F: Float32 := H;
  Assert.IsTrue(IsNaN(F), 'Expected NaN');
end;

procedure TFloat16Tests.TestOverflowToInfinity;
begin
  // Float16 max is ~65504; values above that overflow to infinity
  var H: Float16 := Float32(1.0e10);
  var F: Float32 := H;
  Assert.IsTrue(IsInfinite(F), 'Expected overflow to infinity');
end;

procedure TFloat16Tests.TestUnderflowToZero;
begin
  // Values with exponent below -24 underflow to zero in Float16
  var H: Float16 := Float32(1.0e-8);
  var F: Float32 := H;
  Assert.AreEqual(Float32(0.0), F, 0.0);
end;

procedure TFloat16Tests.TestDenormalized;
begin
  // 5.96e-8 is near the Float16 denormalized range (~6e-8 is the smallest denorm)
  // A value in the subnormal range should survive as non-zero
  var Input: Float32 := 5.96e-8;
  var H: Float16 := Input;
  var F: Float32 := H;
  Assert.IsTrue(F > 0.0, 'Expected denormalized value to be non-zero');
end;

procedure TFloat16Tests.TestBytesZero;
begin
  var H: Float16 := Float32(0.0);
  Assert.AreEqual(Integer(0), Integer(H.Bytes));
end;

procedure TFloat16Tests.TestBytesOne;
begin
  // Float16 bit pattern for 1.0 is $3C00
  var H: Float16 := Float32(1.0);
  Assert.AreEqual(Integer($3C00), Integer(H.Bytes));
end;

initialization
  TDUnitX.RegisterTestFixture(TFloat16Tests);

end.
