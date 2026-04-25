unit TestUtils.ArrVal;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, DUnitX.TestFramework, ArrVal;

Type
  [TestFixture]
  TArrayViewTests = class
  public
    // TArrayView<T>
    [Test]
    Procedure TestViewCreate;
    [Test]
    Procedure TestViewLength;
    [Test]
    Procedure TestViewIndexedRead;
    [Test]
    Procedure TestViewEmptyArray;
    [Test]
    Procedure TestViewAssignTo;
    [Test]
    Procedure TestViewAssignToLengthMismatch;
    // TArrayValues<T>
    [Test]
    Procedure TestValuesCreate;
    [Test]
    Procedure TestValuesLength;
    [Test]
    Procedure TestValuesIndexedRead;
    [Test]
    Procedure TestValuesIndexedWrite;
    [Test]
    Procedure TestValuesWriteDoesNotReallocate;
    [Test]
    Procedure TestValuesEmptyArray;
    [Test]
    Procedure TestValuesAssignTo;
    [Test]
    Procedure TestValuesAssignToLengthMismatch;
    // Type aliases - TArrayView
    [Test]
    Procedure TestIntArrayView;
    [Test]
    Procedure TestFloat64ArrayView;
    [Test]
    Procedure TestStringArrayView;
    // Type aliases - TArrayValues
    [Test]
    Procedure TestIntArrayValues;
    [Test]
    Procedure TestFloat64ArrayValues;
    [Test]
    Procedure TestStringArrayValues;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// TArrayView<T>
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayViewTests.TestViewCreate;
Var
  Arr: TArray<Integer>;
  View: TArrayView<Integer>;
begin
  Arr := TArray<Integer>.Create(10, 20, 30);
  View := TArrayView<Integer>.Create(Arr);
  Assert.AreEqual(3, View.Length);
end;

Procedure TArrayViewTests.TestViewLength;
Var
  Arr: TArray<Integer>;
  View: TArrayView<Integer>;
begin
  Arr := TArray<Integer>.Create(1, 2, 3, 4, 5);
  View := TArrayView<Integer>.Create(Arr);
  Assert.AreEqual(5, View.Length);
end;

Procedure TArrayViewTests.TestViewIndexedRead;
Var
  Arr: TArray<Integer>;
  View: TArrayView<Integer>;
begin
  Arr := TArray<Integer>.Create(10, 20, 30);
  View := TArrayView<Integer>.Create(Arr);
  Assert.AreEqual(10, View[0]);
  Assert.AreEqual(20, View[1]);
  Assert.AreEqual(30, View[2]);
end;

Procedure TArrayViewTests.TestViewEmptyArray;
Var
  Arr: TArray<Integer>;
  View: TArrayView<Integer>;
begin
  SetLength(Arr, 0);
  View := TArrayView<Integer>.Create(Arr);
  Assert.AreEqual(0, View.Length);
end;

////////////////////////////////////////////////////////////////////////////////
// TArrayValues<T>
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayViewTests.TestValuesCreate;
Var
  Arr: TArray<Integer>;
  Vals: TArrayValues<Integer>;
begin
  Arr := TArray<Integer>.Create(10, 20, 30);
  Vals := TArrayValues<Integer>.Create(Arr);
  Assert.AreEqual(3, Vals.Length);
end;

Procedure TArrayViewTests.TestValuesLength;
Var
  Arr: TArray<Integer>;
  Vals: TArrayValues<Integer>;
begin
  Arr := TArray<Integer>.Create(1, 2, 3, 4);
  Vals := TArrayValues<Integer>.Create(Arr);
  Assert.AreEqual(4, Vals.Length);
end;

Procedure TArrayViewTests.TestValuesIndexedRead;
Var
  Arr: TArray<Integer>;
  Vals: TArrayValues<Integer>;
begin
  Arr := TArray<Integer>.Create(7, 8, 9);
  Vals := TArrayValues<Integer>.Create(Arr);
  Assert.AreEqual(7, Vals[0]);
  Assert.AreEqual(8, Vals[1]);
  Assert.AreEqual(9, Vals[2]);
end;

Procedure TArrayViewTests.TestValuesIndexedWrite;
Var
  Arr: TArray<Integer>;
  Vals: TArrayValues<Integer>;
begin
  Arr := TArray<Integer>.Create(1, 2, 3);
  Vals := TArrayValues<Integer>.Create(Arr);
  Vals[1] := 99;
  Assert.AreEqual(1,  Vals[0]);
  Assert.AreEqual(99, Vals[1]);
  Assert.AreEqual(3,  Vals[2]);
end;

Procedure TArrayViewTests.TestValuesWriteDoesNotReallocate;
// Writing through TArrayValues must update the original TArray<T>, not a copy.
Var
  Arr: TArray<Integer>;
  Vals: TArrayValues<Integer>;
begin
  Arr := TArray<Integer>.Create(10, 20, 30);
  Vals := TArrayValues<Integer>.Create(Arr);
  Vals[0] := 100;
  // The change must be visible through the original array reference
  Assert.AreEqual(100, Arr[0]);
end;

Procedure TArrayViewTests.TestValuesEmptyArray;
Var
  Arr: TArray<Integer>;
  Vals: TArrayValues<Integer>;
begin
  SetLength(Arr, 0);
  Vals := TArrayValues<Integer>.Create(Arr);
  Assert.AreEqual(0, Vals.Length);
end;

Procedure TArrayViewTests.TestViewAssignTo;
Var
  Src: TArray<Integer>;
  Dest: array[0..2] of Integer;
  View: TArrayView<Integer>;
begin
  Src := TArray<Integer>.Create(10, 20, 30);
  View := TArrayView<Integer>.Create(Src);
  View.AssignTo(Dest);
  Assert.AreEqual(10, Dest[0]);
  Assert.AreEqual(20, Dest[1]);
  Assert.AreEqual(30, Dest[2]);
end;

Procedure TArrayViewTests.TestViewAssignToLengthMismatch;
Var
  Src: TArray<Integer>;
  Dest: array[0..1] of Integer;
  View: TArrayView<Integer>;
begin
  Src := TArray<Integer>.Create(10, 20, 30);
  View := TArrayView<Integer>.Create(Src);
  Assert.WillRaise(
    procedure begin View.AssignTo(Dest) end,
    Exception);
end;

Procedure TArrayViewTests.TestValuesAssignTo;
Var
  Src: TArray<Integer>;
  Dest: array[0..2] of Integer;
  Vals: TArrayValues<Integer>;
begin
  Src := TArray<Integer>.Create(10, 20, 30);
  Vals := TArrayValues<Integer>.Create(Src);
  Vals.AssignTo(Dest);
  Assert.AreEqual(10, Dest[0]);
  Assert.AreEqual(20, Dest[1]);
  Assert.AreEqual(30, Dest[2]);
end;

Procedure TArrayViewTests.TestValuesAssignToLengthMismatch;
Var
  Src: TArray<Integer>;
  Dest: array[0..1] of Integer;
  Vals: TArrayValues<Integer>;
begin
  Src := TArray<Integer>.Create(10, 20, 30);
  Vals := TArrayValues<Integer>.Create(Src);
  Assert.WillRaise(
    procedure begin Vals.AssignTo(Dest) end,
    Exception);
end;

////////////////////////////////////////////////////////////////////////////////
// Type aliases - TArrayView
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayViewTests.TestIntArrayView;
Var
  Arr: TArray<Integer>;
  View: TIntArrayView;
begin
  Arr := TArray<Integer>.Create(1, 2, 3);
  View := TIntArrayView.Create(Arr);
  Assert.AreEqual(3, View.Length);
  Assert.AreEqual(1, View[0]);
  Assert.AreEqual(2, View[1]);
  Assert.AreEqual(3, View[2]);
end;

Procedure TArrayViewTests.TestFloat64ArrayView;
Var
  Arr: TArray<Float64>;
  View: TFloat64ArrayView;
begin
  Arr := TArray<Float64>.Create(1.1, 2.2, 3.3);
  View := TFloat64ArrayView.Create(Arr);
  Assert.AreEqual(3,   View.Length);
  Assert.AreEqual(1.1, View[0], 1e-12);
  Assert.AreEqual(2.2, View[1], 1e-12);
  Assert.AreEqual(3.3, View[2], 1e-12);
end;

Procedure TArrayViewTests.TestStringArrayView;
Var
  Arr: TArray<String>;
  View: TStringArrayView;
begin
  Arr := TArray<String>.Create('alpha', 'beta', 'gamma');
  View := TStringArrayView.Create(Arr);
  Assert.AreEqual(3,       View.Length);
  Assert.AreEqual('alpha', View[0]);
  Assert.AreEqual('beta',  View[1]);
  Assert.AreEqual('gamma', View[2]);
end;

////////////////////////////////////////////////////////////////////////////////
// Type aliases - TArrayValues
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayViewTests.TestIntArrayValues;
Var
  Arr: TArray<Integer>;
  Vals: TIntArrayValues;
begin
  Arr := TArray<Integer>.Create(4, 5, 6);
  Vals := TIntArrayValues.Create(Arr);
  Assert.AreEqual(3, Vals.Length);
  Vals[2] := 60;
  Assert.AreEqual(60, Vals[2]);
  Assert.AreEqual(60, Arr[2]);
end;

Procedure TArrayViewTests.TestFloat64ArrayValues;
Var
  Arr: TArray<Float64>;
  Vals: TFloat64ArrayValues;
begin
  Arr := TArray<Float64>.Create(0.5, 1.5);
  Vals := TFloat64ArrayValues.Create(Arr);
  Assert.AreEqual(2,   Vals.Length);
  Vals[0] := 9.9;
  Assert.AreEqual(9.9, Vals[0], 1e-12);
  Assert.AreEqual(9.9, Arr[0],  1e-12);
end;

Procedure TArrayViewTests.TestStringArrayValues;
Var
  Arr: TArray<String>;
  Vals: TStringArrayValues;
begin
  Arr := TArray<String>.Create('x', 'y');
  Vals := TStringArrayValues.Create(Arr);
  Assert.AreEqual(2,   Vals.Length);
  Vals[1] := 'z';
  Assert.AreEqual('z', Vals[1]);
  Assert.AreEqual('z', Arr[1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TArrayViewTests);

end.
