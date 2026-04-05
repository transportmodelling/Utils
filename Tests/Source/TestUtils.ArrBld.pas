unit TestUtils.ArrBld;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, ArrBld;

Type
  [TestFixture]
  TArrayBuilderTests = class
  public
    // Constructors
    [Test]
    Procedure TestCreateFromOpenArray;
    [Test]
    Procedure TestCreateFromSlice;
    [Test]
    Procedure TestCreateWithFill;
    [Test]
    Procedure TestCreateWithLength;
    // Implicit conversions
    [Test]
    Procedure TestImplicitFromOpenArray;
    [Test]
    Procedure TestImplicitToTArray;
    // Add operator
    [Test]
    Procedure TestAddBuilderAndOpenArray;
    [Test]
    Procedure TestAddTwoBuilders;
    // Concat
    [Test]
    Procedure TestConcatTwoArrays;
    [Test]
    Procedure TestConcatThreeArrays;
    // Instance methods
    [Test]
    Procedure TestLength;
    [Test]
    Procedure TestAppend;
    [Test]
    Procedure TestAppendSlice;
    [Test]
    Procedure TestClear;
    // Indexed property
    [Test]
    Procedure TestIndexedAccess;
    // Type aliases
    [Test]
    Procedure TestIntArrayBuilder;
    [Test]
    Procedure TestFloatArrayBuilder;
    [Test]
    Procedure TestStringArrayBuilder;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Constructors
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestCreateFromOpenArray;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([10, 20, 30]);
  Assert.AreEqual(3, Builder.Length);
  Assert.AreEqual(10, Builder[0]);
  Assert.AreEqual(20, Builder[1]);
  Assert.AreEqual(30, Builder[2]);
end;

Procedure TArrayBuilderTests.TestCreateFromSlice;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([10, 20, 30, 40, 50], 1, 3);
  Assert.AreEqual(3, Builder.Length);
  Assert.AreEqual(20, Builder[0]);
  Assert.AreEqual(30, Builder[1]);
  Assert.AreEqual(40, Builder[2]);
end;

Procedure TArrayBuilderTests.TestCreateWithFill;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create(4, 7);
  Assert.AreEqual(4, Builder.Length);
  Assert.AreEqual(7, Builder[0]);
  Assert.AreEqual(7, Builder[1]);
  Assert.AreEqual(7, Builder[2]);
  Assert.AreEqual(7, Builder[3]);
end;

Procedure TArrayBuilderTests.TestCreateWithLength;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create(5);
  Assert.AreEqual(5, Builder.Length);
end;

////////////////////////////////////////////////////////////////////////////////
// Implicit conversions
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestImplicitFromOpenArray;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := [1, 2, 3];
  Assert.AreEqual(3, Builder.Length);
  Assert.AreEqual(1, Builder[0]);
  Assert.AreEqual(2, Builder[1]);
  Assert.AreEqual(3, Builder[2]);
end;

Procedure TArrayBuilderTests.TestImplicitToTArray;
Var
  Builder: TArrayBuilder<Integer>;
  Arr: TArray<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([4, 5, 6]);
  Arr := Builder;
  Assert.AreEqual(3, Integer(System.Length(Arr)));
  Assert.AreEqual(4, Arr[0]);
  Assert.AreEqual(5, Arr[1]);
  Assert.AreEqual(6, Arr[2]);
end;

////////////////////////////////////////////////////////////////////////////////
// Add operator
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestAddBuilderAndOpenArray;
Var
  A, Result: TArrayBuilder<Integer>;
begin
  A := TArrayBuilder<Integer>.Create([1, 2]);
  Result := A + [3, 4];
  Assert.AreEqual(4, Result.Length);
  Assert.AreEqual(1, Result[0]);
  Assert.AreEqual(2, Result[1]);
  Assert.AreEqual(3, Result[2]);
  Assert.AreEqual(4, Result[3]);
end;

Procedure TArrayBuilderTests.TestAddTwoBuilders;
Var
  A, B, Result: TArrayBuilder<Integer>;
begin
  A := TArrayBuilder<Integer>.Create([1, 2]);
  B := TArrayBuilder<Integer>.Create([3, 4, 5]);
  Result := A + B;
  Assert.AreEqual(5, Result.Length);
  Assert.AreEqual(1, Result[0]);
  Assert.AreEqual(2, Result[1]);
  Assert.AreEqual(3, Result[2]);
  Assert.AreEqual(4, Result[3]);
  Assert.AreEqual(5, Result[4]);
end;

////////////////////////////////////////////////////////////////////////////////
// Concat
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestConcatTwoArrays;
Var
  Arr: TArray<Integer>;
begin
  Arr := TArrayBuilder<Integer>.Concat([1, 2], [3, 4]);
  Assert.AreEqual(4, Integer(System.Length(Arr)));
  Assert.AreEqual(1, Arr[0]);
  Assert.AreEqual(2, Arr[1]);
  Assert.AreEqual(3, Arr[2]);
  Assert.AreEqual(4, Arr[3]);
end;

Procedure TArrayBuilderTests.TestConcatThreeArrays;
Var
  Arr: TArray<Integer>;
begin
  Arr := TArrayBuilder<Integer>.Concat([1, 2], [3, 4], [5, 6]);
  Assert.AreEqual(6, Integer(System.Length(Arr)));
  Assert.AreEqual(1, Arr[0]);
  Assert.AreEqual(2, Arr[1]);
  Assert.AreEqual(3, Arr[2]);
  Assert.AreEqual(4, Arr[3]);
  Assert.AreEqual(5, Arr[4]);
  Assert.AreEqual(6, Arr[5]);
end;

////////////////////////////////////////////////////////////////////////////////
// Instance methods
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestLength;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([1, 2, 3, 4]);
  Assert.AreEqual(4, Builder.Length);
  // Empty builder
  Builder.Clear;
  Assert.AreEqual(0, Builder.Length);
end;

Procedure TArrayBuilderTests.TestAppend;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([1, 2]);
  Builder.Append([3, 4, 5]);
  Assert.AreEqual(5, Builder.Length);
  Assert.AreEqual(1, Builder[0]);
  Assert.AreEqual(2, Builder[1]);
  Assert.AreEqual(3, Builder[2]);
  Assert.AreEqual(4, Builder[3]);
  Assert.AreEqual(5, Builder[4]);
end;

Procedure TArrayBuilderTests.TestAppendSlice;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([1, 2]);
  Builder.Append([10, 20, 30, 40], 1, 2);
  Assert.AreEqual(4, Builder.Length);
  Assert.AreEqual(1,  Builder[0]);
  Assert.AreEqual(2,  Builder[1]);
  Assert.AreEqual(20, Builder[2]);
  Assert.AreEqual(30, Builder[3]);
end;

Procedure TArrayBuilderTests.TestClear;
Var
  Builder: TArrayBuilder<Integer>;
begin
  Builder := TArrayBuilder<Integer>.Create([1, 2, 3]);
  Assert.AreEqual(3, Builder.Length);
  Builder.Clear;
  Assert.AreEqual(0, Builder.Length);
  Assert.IsTrue(Builder.AsArray = nil);
end;

////////////////////////////////////////////////////////////////////////////////
// Indexed property
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestIndexedAccess;
Var
  Builder: TArrayBuilder<Float64>;
begin
  Builder := TArrayBuilder<Float64>.Create([1.1, 2.2, 3.3]);
  Assert.AreEqual(1.1, Builder[0], 1e-12);
  Assert.AreEqual(2.2, Builder[1], 1e-12);
  Assert.AreEqual(3.3, Builder[2], 1e-12);
end;

////////////////////////////////////////////////////////////////////////////////
// Type aliases
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayBuilderTests.TestIntArrayBuilder;
Var
  Builder: TIntArrayBuilder;
  Arr: TArray<Integer>;
begin
  Builder := TIntArrayBuilder.Create([1, 2, 3]);
  Arr := Builder;
  Assert.AreEqual(3, Integer(System.Length(Arr)));
  Assert.AreEqual(1, Arr[0]);
  Assert.AreEqual(2, Arr[1]);
  Assert.AreEqual(3, Arr[2]);
end;

Procedure TArrayBuilderTests.TestFloatArrayBuilder;
Var
  Builder: TFloatArrayBuilder;
  Arr: TArray<Float64>;
begin
  Builder := TFloatArrayBuilder.Create([0.5, 1.5, 2.5]);
  Arr := Builder;
  Assert.AreEqual(3, Integer(System.Length(Arr)));
  Assert.AreEqual(0.5, Arr[0], 1e-12);
  Assert.AreEqual(1.5, Arr[1], 1e-12);
  Assert.AreEqual(2.5, Arr[2], 1e-12);
end;

Procedure TArrayBuilderTests.TestStringArrayBuilder;
Var
  Builder: TStringArrayBuilder;
  Arr: TArray<String>;
begin
  Builder := TStringArrayBuilder.Create(['alpha', 'beta', 'gamma']);
  Arr := Builder;
  Assert.AreEqual(3, Integer(System.Length(Arr)));
  Assert.AreEqual('alpha', Arr[0]);
  Assert.AreEqual('beta',  Arr[1]);
  Assert.AreEqual('gamma', Arr[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TArrayBuilderTests);

end.
