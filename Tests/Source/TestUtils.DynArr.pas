unit TestUtils.DynArr;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, Ranges, DynArr;

Type
  [TestFixture]
  TCompositeIndexTests = class
  public
    // Construction / basic properties
    [Test]
    Procedure TestRank1;
    [Test]
    Procedure TestRank2;
    [Test]
    Procedure TestRank3;
    [Test]
    Procedure TestReset;
    [Test]
    Procedure TestEmptyShape;
    // Count
    [Test]
    Procedure TestCount1D;
    [Test]
    Procedure TestCount2D;
    [Test]
    Procedure TestCount3D;
    // Shape round-trip
    [Test]
    Procedure TestShape1D;
    [Test]
    Procedure TestShape2D;
    [Test]
    Procedure TestShape3D;
    // CompositeIndex
    [Test]
    Procedure TestCompositeIndex1D;
    [Test]
    Procedure TestCompositeIndex2D;
    [Test]
    Procedure TestCompositeIndex3D;
    // Indices (reverse mapping)
    [Test]
    Procedure TestIndices1D;
    [Test]
    Procedure TestIndices2D;
    [Test]
    Procedure TestIndices3D;
    // GetIndices
    [Test]
    Procedure TestGetIndices2D;
    // CompositeIndexRange - exact rank
    [Test]
    Procedure TestCompositeIndexRangeExact;
    // CompositeIndexRange - partial indices (row slice)
    [Test]
    Procedure TestCompositeIndexRangePartial;
  end;

  [TestFixture]
  TDynamicArrayTests = class
  public
    // Allocated / not allocated
    [Test]
    Procedure TestNotAllocated;
    [Test]
    Procedure TestAllocated;
    // Create / Allocate
    [Test]
    Procedure TestCreate1D;
    [Test]
    Procedure TestCreate2D;
    [Test]
    Procedure TestCreate3D;
    [Test]
    Procedure TestAllocateReallocates;
    // Rank / Shape
    [Test]
    Procedure TestRank;
    [Test]
    Procedure TestShape;
    // Read / write via default property
    [Test]
    Procedure TestReadWrite1D;
    [Test]
    Procedure TestReadWrite2D;
    [Test]
    Procedure TestReadWrite3D;
    // Implicit from open array (rank-1 shorthand)
    [Test]
    Procedure TestImplicitFromArray;
    // Implicit to TArray<T> (rank-1 only)
    [Test]
    Procedure TestImplicitToTArray;
    // Type aliases
    [Test]
    Procedure TestDynamicIntArray;
    [Test]
    Procedure TestDynamicFloatArray;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// TCompositeIndexTests
////////////////////////////////////////////////////////////////////////////////

Procedure TCompositeIndexTests.TestRank1;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([5]);
  Assert.AreEqual(1, CI.Rank);
end;

Procedure TCompositeIndexTests.TestRank2;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([3, 4]);
  Assert.AreEqual(2, CI.Rank);
end;

Procedure TCompositeIndexTests.TestRank3;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([2, 3, 4]);
  Assert.AreEqual(3, CI.Rank);
end;

Procedure TCompositeIndexTests.TestReset;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([3, 4]);
  CI.Reset;
  Assert.AreEqual(0, CI.Rank);
  Assert.AreEqual(0, CI.Count);
end;

Procedure TCompositeIndexTests.TestEmptyShape;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([]);
  Assert.AreEqual(0, CI.Rank);
  Assert.AreEqual(0, CI.Count);
end;

Procedure TCompositeIndexTests.TestCount1D;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([7]);
  Assert.AreEqual(7, CI.Count);
end;

Procedure TCompositeIndexTests.TestCount2D;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([3, 4]);
  Assert.AreEqual(12, CI.Count);
end;

Procedure TCompositeIndexTests.TestCount3D;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([2, 3, 4]);
  Assert.AreEqual(24, CI.Count);
end;

Procedure TCompositeIndexTests.TestShape1D;
Var
  CI: TCompositeIndex;
  S: TArray<Integer>;
begin
  CI := TCompositeIndex.Create([5]);
  S := CI.Shape;
  Assert.AreEqual(1, Integer(System.Length(S)));
  Assert.AreEqual(5, S[0]);
end;

Procedure TCompositeIndexTests.TestShape2D;
Var
  CI: TCompositeIndex;
  S: TArray<Integer>;
begin
  CI := TCompositeIndex.Create([3, 4]);
  S := CI.Shape;
  Assert.AreEqual(2, Integer(System.Length(S)));
  Assert.AreEqual(3, S[0]);
  Assert.AreEqual(4, S[1]);
end;

Procedure TCompositeIndexTests.TestShape3D;
Var
  CI: TCompositeIndex;
  S: TArray<Integer>;
begin
  CI := TCompositeIndex.Create([2, 3, 4]);
  S := CI.Shape;
  Assert.AreEqual(3, Integer(System.Length(S)));
  Assert.AreEqual(2, S[0]);
  Assert.AreEqual(3, S[1]);
  Assert.AreEqual(4, S[2]);
end;

Procedure TCompositeIndexTests.TestCompositeIndex1D;
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([5]);
  Assert.AreEqual(0, CI.CompositeIndex([0]));
  Assert.AreEqual(3, CI.CompositeIndex([3]));
  Assert.AreEqual(4, CI.CompositeIndex([4]));
end;

Procedure TCompositeIndexTests.TestCompositeIndex2D;
// Shape [2,3]: layout matches the header example (row-major)
//   [0,0]=0  [0,1]=1  [0,2]=2
//   [1,0]=3  [1,1]=4  [1,2]=5
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([2, 3]);
  Assert.AreEqual(0, CI.CompositeIndex([0, 0]));
  Assert.AreEqual(1, CI.CompositeIndex([0, 1]));
  Assert.AreEqual(2, CI.CompositeIndex([0, 2]));
  Assert.AreEqual(3, CI.CompositeIndex([1, 0]));
  Assert.AreEqual(4, CI.CompositeIndex([1, 1]));
  Assert.AreEqual(5, CI.CompositeIndex([1, 2]));
end;

Procedure TCompositeIndexTests.TestCompositeIndex3D;
// Shape [2,3,2]: Count=12
Var
  CI: TCompositeIndex;
begin
  CI := TCompositeIndex.Create([2, 3, 2]);
  Assert.AreEqual(0,  CI.CompositeIndex([0, 0, 0]));
  Assert.AreEqual(1,  CI.CompositeIndex([0, 0, 1]));
  Assert.AreEqual(2,  CI.CompositeIndex([0, 1, 0]));
  Assert.AreEqual(6,  CI.CompositeIndex([1, 0, 0]));
  Assert.AreEqual(11, CI.CompositeIndex([1, 2, 1]));
end;

Procedure TCompositeIndexTests.TestIndices1D;
Var
  CI: TCompositeIndex;
  Idx: TArray<Integer>;
begin
  CI := TCompositeIndex.Create([5]);
  Idx := CI.Indices(3);
  Assert.AreEqual(1, Integer(System.Length(Idx)));
  Assert.AreEqual(3, Idx[0]);
end;

Procedure TCompositeIndexTests.TestIndices2D;
Var
  CI: TCompositeIndex;
  Idx: TArray<Integer>;
begin
  CI := TCompositeIndex.Create([2, 3]);
  Idx := CI.Indices(4);   // expect [1,1]
  Assert.AreEqual(2, Integer(System.Length(Idx)));
  Assert.AreEqual(1, Idx[0]);
  Assert.AreEqual(1, Idx[1]);
end;

Procedure TCompositeIndexTests.TestIndices3D;
Var
  CI: TCompositeIndex;
  Idx: TArray<Integer>;
begin
  CI := TCompositeIndex.Create([2, 3, 2]);
  Idx := CI.Indices(11);  // expect [1,2,1]
  Assert.AreEqual(3, Integer(System.Length(Idx)));
  Assert.AreEqual(1, Idx[0]);
  Assert.AreEqual(2, Idx[1]);
  Assert.AreEqual(1, Idx[2]);
end;

Procedure TCompositeIndexTests.TestGetIndices2D;
Var
  CI: TCompositeIndex;
  Idx: array[0..1] of Integer;
begin
  CI := TCompositeIndex.Create([2, 3]);
  CI.GetIndices(5, Idx);  // expect [1,2]
  Assert.AreEqual(1, Idx[0]);
  Assert.AreEqual(2, Idx[1]);
end;

Procedure TCompositeIndexTests.TestCompositeIndexRangeExact;
// Full index supplied: range should be a single element
Var
  CI: TCompositeIndex;
  R: TRange;
begin
  CI := TCompositeIndex.Create([2, 3]);
  R := CI.CompositeIndexRange([1, 2]);  // composite index = 5
  Assert.AreEqual(5, R.Min);
  Assert.AreEqual(5, R.Max);
end;

Procedure TCompositeIndexTests.TestCompositeIndexRangePartial;
// Only row index supplied for a [2,3] array:
// row 0 -> composites 0..2, row 1 -> composites 3..5
Var
  CI: TCompositeIndex;
  R: TRange;
begin
  CI := TCompositeIndex.Create([2, 3]);
  R := CI.CompositeIndexRange([0]);
  Assert.AreEqual(0, R.Min);
  Assert.AreEqual(2, R.Max);
  R := CI.CompositeIndexRange([1]);
  Assert.AreEqual(3, R.Min);
  Assert.AreEqual(5, R.Max);
end;

////////////////////////////////////////////////////////////////////////////////
// TDynamicArrayTests
////////////////////////////////////////////////////////////////////////////////

Procedure TDynamicArrayTests.TestNotAllocated;
Var
  A: TDynamicArray<Integer>;
begin
  Assert.IsFalse(A.Allocated);
  Assert.AreEqual(0, A.Rank);
end;

Procedure TDynamicArrayTests.TestAllocated;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([3]);
  Assert.IsTrue(A.Allocated);
end;

Procedure TDynamicArrayTests.TestCreate1D;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([4]);
  Assert.AreEqual(1, A.Rank);
  var S := A.Shape;
  Assert.AreEqual(1, Integer(System.Length(S)));
  Assert.AreEqual(4, S[0]);
end;

Procedure TDynamicArrayTests.TestCreate2D;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3]);
  Assert.AreEqual(2, A.Rank);
  var S := A.Shape;
  Assert.AreEqual(2, S[0]);
  Assert.AreEqual(3, S[1]);
end;

Procedure TDynamicArrayTests.TestCreate3D;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3, 4]);
  Assert.AreEqual(3, A.Rank);
  var S := A.Shape;
  Assert.AreEqual(2, S[0]);
  Assert.AreEqual(3, S[1]);
  Assert.AreEqual(4, S[2]);
end;

Procedure TDynamicArrayTests.TestAllocateReallocates;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3]);
  A.Allocate([4, 5]);
  Assert.AreEqual(2, A.Rank);
  var S := A.Shape;
  Assert.AreEqual(4, S[0]);
  Assert.AreEqual(5, S[1]);
end;

Procedure TDynamicArrayTests.TestRank;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3, 2]);
  Assert.AreEqual(3, A.Rank);
end;

Procedure TDynamicArrayTests.TestShape;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3, 2]);
  var S := A.Shape;
  Assert.AreEqual(3, Integer(System.Length(S)));
  Assert.AreEqual(2, S[0]);
  Assert.AreEqual(3, S[1]);
  Assert.AreEqual(2, S[2]);
end;

Procedure TDynamicArrayTests.TestReadWrite1D;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([3]);
  A[[0]] := 10;
  A[[1]] := 20;
  A[[2]] := 30;
  Assert.AreEqual(10, A[[0]]);
  Assert.AreEqual(20, A[[1]]);
  Assert.AreEqual(30, A[[2]]);
end;

Procedure TDynamicArrayTests.TestReadWrite2D;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3]);
  A[[0, 0]] := 1;
  A[[0, 1]] := 2;
  A[[0, 2]] := 3;
  A[[1, 0]] := 4;
  A[[1, 1]] := 5;
  A[[1, 2]] := 6;
  Assert.AreEqual(1, A[[0, 0]]);
  Assert.AreEqual(2, A[[0, 1]]);
  Assert.AreEqual(3, A[[0, 2]]);
  Assert.AreEqual(4, A[[1, 0]]);
  Assert.AreEqual(5, A[[1, 1]]);
  Assert.AreEqual(6, A[[1, 2]]);
end;

Procedure TDynamicArrayTests.TestReadWrite3D;
Var
  A: TDynamicArray<Integer>;
begin
  A := TDynamicArray<Integer>.Create([2, 3, 2]);
  A[[0, 0, 0]] := 1;
  A[[1, 2, 1]] := 99;
  Assert.AreEqual(1,  A[[0, 0, 0]]);
  Assert.AreEqual(99, A[[1, 2, 1]]);
end;

Procedure TDynamicArrayTests.TestImplicitFromArray;
// Assigning an open array produces a rank-1 TDynamicArray
Var
  A: TDynamicArray<Integer>;
begin
  A := [10, 20, 30];
  Assert.AreEqual(1,  A.Rank);
  Assert.AreEqual(10, A[[0]]);
  Assert.AreEqual(20, A[[1]]);
  Assert.AreEqual(30, A[[2]]);
end;

Procedure TDynamicArrayTests.TestImplicitToTArray;
// A rank-1 TDynamicArray can be implicitly converted to TArray<T>
Var
  A: TDynamicArray<Integer>;
  Arr: TArray<Integer>;
begin
  A := [4, 5, 6];
  Arr := A;
  Assert.AreEqual(3, Integer(System.Length(Arr)));
  Assert.AreEqual(4, Arr[0]);
  Assert.AreEqual(5, Arr[1]);
  Assert.AreEqual(6, Arr[2]);
end;

Procedure TDynamicArrayTests.TestDynamicIntArray;
Var
  A: TDynamicIntArray;
begin
  A := TDynamicIntArray.Create([2, 2]);
  A[[0, 0]] := 1;
  A[[1, 1]] := 9;
  Assert.AreEqual(1, A[[0, 0]]);
  Assert.AreEqual(9, A[[1, 1]]);
end;

Procedure TDynamicArrayTests.TestDynamicFloatArray;
Var
  A: TDynamicFloatArray;
begin
  A := TDynamicFloatArray.Create([2, 2]);
  A[[0, 0]] := 1.5;
  A[[1, 1]] := 9.9;
  Assert.AreEqual(1.5, A[[0, 0]], 1e-12);
  Assert.AreEqual(9.9, A[[1, 1]], 1e-12);
end;

initialization
  TDUnitX.RegisterTestFixture(TCompositeIndexTests);
  TDUnitX.RegisterTestFixture(TDynamicArrayTests);

end.
