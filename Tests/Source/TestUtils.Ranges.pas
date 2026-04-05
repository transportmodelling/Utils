unit TestUtils.Ranges;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, Ranges;

Type
  [TestFixture]
  TRangeTests = class
  public
    // Create with valid Min < Max
    [Test] Procedure TestCreateValid;
    // Create with Min = Max (single-element range)
    [Test] Procedure TestCreateMinEqualsMax;
    // Create with Min > Max raises an exception
    [Test] Procedure TestCreateMinGreaterThanMax;
    // Count = Max - Min + 1
    [Test] Procedure TestCount;
    // Contains: value strictly inside range
    [Test] Procedure TestContainsInside;
    // Contains: values at both boundaries
    [Test] Procedure TestContainsBoundary;
    // Contains: values outside both ends
    [Test] Procedure TestContainsOutside;
    // Values returns every integer in the range
    [Test] Procedure TestValues;
    // Split into equal sub-ranges
    [Test] Procedure TestSplitEven;
    // Split with remainder distributed to front ranges
    [Test] Procedure TestSplitWithRemainder;
    // Split count capped at range Count
    [Test] Procedure TestSplitCappedAtCount;
  end;

  [TestFixture]
  TRangesTests = class
  public
    // Create from integer values: sorts and merges consecutive integers
    [Test] Procedure TestCreateFromValues;
    // Create from explicit TRange array
    [Test] Procedure TestCreateFromRangeArray;
    // Create from string with a single value
    [Test] Procedure TestCreateFromString_Single;
    // Create from string with a range token
    [Test] Procedure TestCreateFromString_Range;
    // Create from string with mixed tokens
    [Test] Procedure TestCreateFromString_Mixed;
    // Count returns number of ranges
    [Test] Procedure TestCount;
    // Contains: value present in one of the ranges
    [Test] Procedure TestContainsTrue;
    // Contains: value absent from all ranges
    [Test] Procedure TestContainsFalse;
    // Values concatenates all sub-range values
    [Test] Procedure TestValues;
    // AsString: single-element range serialises as 'N'
    [Test] Procedure TestAsString_Single;
    // AsString: two-element range serialises as 'M,N'
    [Test] Procedure TestAsString_TwoAdjacent;
    // AsString: wider range serialises as 'M-N'
    [Test] Procedure TestAsString_WiderRange;
    // Implicit cast to String calls AsString
    [Test] Procedure TestImplicitToString;
    // Ranges[i] default property returns the i-th TRange
    [Test] Procedure TestRangeIndexer;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

// --------------------------------------------------------------------------
// TRangeTests
// --------------------------------------------------------------------------

Procedure TRangeTests.TestCreateValid;
begin
  var R := TRange.Create(2, 5);
  Assert.AreEqual(2, R.Min);
  Assert.AreEqual(5, R.Max);
end;

Procedure TRangeTests.TestCreateMinEqualsMax;
begin
  var R := TRange.Create(3, 3);
  Assert.AreEqual(1, R.Count);
end;

Procedure TRangeTests.TestCreateMinGreaterThanMax;
begin
  Assert.WillRaiseAny(procedure begin TRange.Create(5, 2); end);
end;

Procedure TRangeTests.TestCount;
begin
  var R := TRange.Create(2, 5);
  Assert.AreEqual(4, R.Count);
end;

Procedure TRangeTests.TestContainsInside;
begin
  var R := TRange.Create(2, 5);
  Assert.IsTrue(R.Contains(3));
  Assert.IsTrue(R.Contains(4));
end;

Procedure TRangeTests.TestContainsBoundary;
begin
  var R := TRange.Create(2, 5);
  Assert.IsTrue(R.Contains(2), 'Min boundary');
  Assert.IsTrue(R.Contains(5), 'Max boundary');
end;

Procedure TRangeTests.TestContainsOutside;
begin
  var R := TRange.Create(2, 5);
  Assert.IsFalse(R.Contains(1), 'Below Min');
  Assert.IsFalse(R.Contains(6), 'Above Max');
end;

Procedure TRangeTests.TestValues;
begin
  var R := TRange.Create(2, 4);
  var V := R.Values;
  Assert.AreEqual(3, Integer(Length(V)));
  Assert.AreEqual(2, V[0]);
  Assert.AreEqual(3, V[1]);
  Assert.AreEqual(4, V[2]);
end;

Procedure TRangeTests.TestSplitEven;
begin
  // [0..5] has Count=6; split into 3 => each sub-range has 2 elements
  var R := TRange.Create(0, 5);
  var Parts := R.Split(3);
  Assert.AreEqual(3, Integer(Length(Parts)));
  Assert.AreEqual(0, Parts[0].Min); Assert.AreEqual(1, Parts[0].Max);
  Assert.AreEqual(2, Parts[1].Min); Assert.AreEqual(3, Parts[1].Max);
  Assert.AreEqual(4, Parts[2].Min); Assert.AreEqual(5, Parts[2].Max);
end;

Procedure TRangeTests.TestSplitWithRemainder;
begin
  // [0..6] has Count=7; split into 3 => sizes 3,2,2
  // CountDivNRanges=2, Remainder=1: first range (< Remainder) gets +1 => [0..2],[3..4],[5..6]
  var R := TRange.Create(0, 6);
  var Parts := R.Split(3);
  Assert.AreEqual(3, Integer(Length(Parts)));
  Assert.AreEqual(3, Parts[0].Count, 'First part');
  Assert.AreEqual(0, Parts[0].Min);
  Assert.AreEqual(2, Parts[0].Max);
  Assert.AreEqual(2, Parts[1].Count, 'Second part');
  Assert.AreEqual(3, Parts[1].Min);
  Assert.AreEqual(4, Parts[1].Max);
  Assert.AreEqual(2, Parts[2].Count, 'Third part');
  Assert.AreEqual(5, Parts[2].Min);
  Assert.AreEqual(6, Parts[2].Max);
end;

Procedure TRangeTests.TestSplitCappedAtCount;
begin
  // [0..2] has Count=3; requesting 10 splits => capped to 3
  var R := TRange.Create(0, 2);
  var Parts := R.Split(10);
  Assert.AreEqual(3, Integer(Length(Parts)));
  Assert.AreEqual(1, Parts[0].Count);
  Assert.AreEqual(1, Parts[1].Count);
  Assert.AreEqual(1, Parts[2].Count);
end;

// --------------------------------------------------------------------------
// TRangesTests
// --------------------------------------------------------------------------

Procedure TRangesTests.TestCreateFromValues;
begin
  // [3,1,4,1,5] -> sorted, deduplicated runs: [1..1], [3..5]
  var RS := TRanges.Create([3, 1, 4, 1, 5]);
  Assert.AreEqual(2, RS.Count);
  Assert.AreEqual(1, RS[0].Min); Assert.AreEqual(1, RS[0].Max);
  Assert.AreEqual(3, RS[1].Min); Assert.AreEqual(5, RS[1].Max);
end;

Procedure TRangesTests.TestCreateFromRangeArray;
begin
  var RS := TRanges.Create([TRange.Create(1, 3), TRange.Create(5, 7)]);
  Assert.AreEqual(2, RS.Count);
  Assert.AreEqual(1, RS[0].Min); Assert.AreEqual(3, RS[0].Max);
  Assert.AreEqual(5, RS[1].Min); Assert.AreEqual(7, RS[1].Max);
end;

Procedure TRangesTests.TestCreateFromString_Single;
begin
  var RS := TRanges.Create('5');
  Assert.AreEqual(1, RS.Count);
  Assert.AreEqual(5, RS[0].Min);
  Assert.AreEqual(5, RS[0].Max);
end;

Procedure TRangesTests.TestCreateFromString_Range;
begin
  var RS := TRanges.Create('2-4');
  Assert.AreEqual(1, RS.Count);
  Assert.AreEqual(2, RS[0].Min);
  Assert.AreEqual(4, RS[0].Max);
end;

Procedure TRangesTests.TestCreateFromString_Mixed;
begin
  // '1,3-5,7' -> three ranges: [1..1], [3..5], [7..7]
  var RS := TRanges.Create('1,3-5,7');
  Assert.AreEqual(3, RS.Count);
  Assert.AreEqual(1, RS[0].Min); Assert.AreEqual(1, RS[0].Max);
  Assert.AreEqual(3, RS[1].Min); Assert.AreEqual(5, RS[1].Max);
  Assert.AreEqual(7, RS[2].Min); Assert.AreEqual(7, RS[2].Max);
end;

Procedure TRangesTests.TestCount;
begin
  var RS := TRanges.Create([TRange.Create(1, 2), TRange.Create(5, 6), TRange.Create(9, 10)]);
  Assert.AreEqual(3, RS.Count);
end;

Procedure TRangesTests.TestContainsTrue;
begin
  var RS := TRanges.Create([TRange.Create(1, 3), TRange.Create(7, 9)]);
  Assert.IsTrue(RS.Contains(2));
  Assert.IsTrue(RS.Contains(8));
end;

Procedure TRangesTests.TestContainsFalse;
begin
  var RS := TRanges.Create([TRange.Create(1, 3), TRange.Create(7, 9)]);
  Assert.IsFalse(RS.Contains(5));
  Assert.IsFalse(RS.Contains(0));
end;

Procedure TRangesTests.TestValues;
begin
  var RS := TRanges.Create([TRange.Create(1, 2), TRange.Create(5, 6)]);
  var V := RS.Values;
  Assert.AreEqual(4, Integer(Length(V)));
  Assert.AreEqual(1, V[0]);
  Assert.AreEqual(2, V[1]);
  Assert.AreEqual(5, V[2]);
  Assert.AreEqual(6, V[3]);
end;

Procedure TRangesTests.TestAsString_Single;
begin
  var RS := TRanges.Create([TRange.Create(5, 5)]);
  Assert.AreEqual('5', RS.AsString);
end;

Procedure TRangesTests.TestAsString_TwoAdjacent;
begin
  // Two-element range: FMax = FMin+1 -> serialised as 'M,N'
  var RS := TRanges.Create([TRange.Create(3, 4)]);
  Assert.AreEqual('3,4', RS.AsString);
end;

Procedure TRangesTests.TestAsString_WiderRange;
begin
  var RS := TRanges.Create([TRange.Create(2, 5)]);
  Assert.AreEqual('2-5', RS.AsString);
end;

Procedure TRangesTests.TestImplicitToString;
begin
  var RS := TRanges.Create([TRange.Create(1, 3)]);
  var S: String := RS;
  Assert.AreEqual('1-3', S);
end;

Procedure TRangesTests.TestRangeIndexer;
begin
  var RS := TRanges.Create([TRange.Create(10, 20), TRange.Create(30, 40)]);
  Assert.AreEqual(10, RS[0].Min);
  Assert.AreEqual(30, RS[1].Min);
end;

initialization
  TDUnitX.RegisterTestFixture(TRangeTests);
  TDUnitX.RegisterTestFixture(TRangesTests);

end.
