unit TestUtils.ArrHlp;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Classes, Windows, DUnitX.TestFramework, ArrHlp;

Type
  [TestFixture]
  TArrayHelperTests = class
  public
    // TArrayInfo
    [Test]
    Procedure TestRefCount;
    // TIntArrayHelper
    [Test]
    Procedure TestIntCreateFromValues;
    [Test]
    Procedure TestIntCreateWithLength;
    [Test]
    Procedure TestIntInitialize;
    [Test]
    Procedure TestIntAssignFromArray;
    [Test]
    Procedure TestIntAssignFromStrings;
    [Test]
    Procedure TestIntAssignFromDelimitedString;
    [Test]
    Procedure TestIntToString;
    [Test]
    Procedure TestIntToStrings;
    [Test]
    Procedure TestIntAppend;
    [Test]
    Procedure TestIntContains;
    [Test]
    Procedure TestIntAggregates;
    [Test]
    Procedure TestIntSort;
    [Test]
    Procedure TestIntAssignTo;
    // TFloat64ArrayHelper
    [Test]
    Procedure TestFloatCreateFromValues;
    [Test]
    Procedure TestFloatCreateWithLength;
    [Test]
    Procedure TestFloatInitialize;
    [Test]
    Procedure TestFloatAssignFromArray;
    [Test]
    Procedure TestFloatAssignFromStrings;
    [Test]
    Procedure TestFloatAssignFromDelimitedString;
    [Test]
    Procedure TestFloatToString;
    [Test]
    Procedure TestFloatToStringFormatted;
    [Test]
    Procedure TestFloatToStrings;
    [Test]
    Procedure TestFloatToStringsFormatted;
    [Test]
    Procedure TestFloatAppend;
    [Test]
    Procedure TestFloatAggregates;
    [Test]
    Procedure TestFloatAssignTo;
    // TStringArrayHelper
    [Test]
    Procedure TestStringCreateFromValues;
    [Test]
    Procedure TestStringAssignFromArray;
    [Test]
    Procedure TestStringAssignFromDelimitedString;
    [Test]
    Procedure TestStringToString;
    [Test]
    Procedure TestStringAppend;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayHelperTests.TestRefCount;
Const
  ArrLength = 42;
Var
  Arr: array of Float64;
begin
  // Allocate array
  SetLength(Arr,ArrLength);
  Assert.AreEqual(1,TArrayInfo.RefCount(Arr));
  Assert.AreEqual(ArrLength,TArrayInfo.Length(Arr));
  // Now make a copy, thus increasing the reference count
  var Copy := Arr;
  Assert.AreEqual(2,TArrayInfo.RefCount(Arr));
  Assert.AreEqual(ArrLength,TArrayInfo.Length(Arr));
end;

////////////////////////////////////////////////////////////////////////////////
// TIntArrayHelper
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayHelperTests.TestIntCreateFromValues;
Var
  Arr: TArray<Integer>;
begin
  Arr := TArray<Integer>.Create([3, 1, 4, 1, 5]);
  Assert.AreEqual(5, Arr.Length);
  Assert.AreEqual(3, Arr[0]);
  Assert.AreEqual(1, Arr[1]);
  Assert.AreEqual(4, Arr[2]);
  Assert.AreEqual(1, Arr[3]);
  Assert.AreEqual(5, Arr[4]);
end;

Procedure TArrayHelperTests.TestIntCreateWithLength;
Var
  Arr: TArray<Integer>;
begin
  Arr := TArray<Integer>.Create(4, 7);
  Assert.AreEqual(4, Arr.Length);
  Assert.AreEqual(7, Arr[0]);
  Assert.AreEqual(7, Arr[1]);
  Assert.AreEqual(7, Arr[2]);
  Assert.AreEqual(7, Arr[3]);
end;

Procedure TArrayHelperTests.TestIntInitialize;
Var
  Arr: TArray<Integer>;
begin
  Arr := TArray<Integer>.Create([1, 2, 3]);
  Arr.Initialize(99);
  Assert.AreEqual(3, Arr.Length);
  Assert.AreEqual(99, Arr[0]);
  Assert.AreEqual(99, Arr[1]);
  Assert.AreEqual(99, Arr[2]);
end;

Procedure TArrayHelperTests.TestIntAssignFromArray;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign([10, 20, 30]);
  Assert.AreEqual(3, Arr.Length);
  Assert.AreEqual(10, Arr[0]);
  Assert.AreEqual(20, Arr[1]);
  Assert.AreEqual(30, Arr[2]);
end;

Procedure TArrayHelperTests.TestIntAssignFromStrings;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign(['5', '15', '25']);
  Assert.AreEqual(3, Arr.Length);
  Assert.AreEqual(5,  Arr[0]);
  Assert.AreEqual(15, Arr[1]);
  Assert.AreEqual(25, Arr[2]);
end;

Procedure TArrayHelperTests.TestIntAssignFromDelimitedString;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign('1,2,3,4');
  Assert.AreEqual(4, Arr.Length);
  Assert.AreEqual(1, Arr[0]);
  Assert.AreEqual(2, Arr[1]);
  Assert.AreEqual(3, Arr[2]);
  Assert.AreEqual(4, Arr[3]);
  // Non-default separator
  Arr.Assign('10;20;30', ';');
  Assert.AreEqual(3,  Arr.Length);
  Assert.AreEqual(10, Arr[0]);
  Assert.AreEqual(20, Arr[1]);
  Assert.AreEqual(30, Arr[2]);
end;

Procedure TArrayHelperTests.TestIntToString;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign([1, 2, 3]);
  Assert.AreEqual('1,2,3', Arr.ToString);
  Assert.AreEqual('1;2;3', Arr.ToString(';'));
  // Empty array
  Arr.Length := 0;
  Assert.AreEqual('', Arr.ToString);
end;

Procedure TArrayHelperTests.TestIntToStrings;
Var
  Arr: TArray<Integer>;
  Strs: TArray<String>;
begin
  Arr.Assign([7, 8, 9]);
  Strs := Arr.ToStrings;
  Assert.AreEqual(3, Integer(System.Length(Strs)));
  Assert.AreEqual('7', Strs[0]);
  Assert.AreEqual('8', Strs[1]);
  Assert.AreEqual('9', Strs[2]);
end;

Procedure TArrayHelperTests.TestIntAppend;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign([1, 2]);
  Arr.Append([3, 4, 5]);
  Assert.AreEqual(5, Arr.Length);
  Assert.AreEqual(1, Arr[0]);
  Assert.AreEqual(2, Arr[1]);
  Assert.AreEqual(3, Arr[2]);
  Assert.AreEqual(4, Arr[3]);
  Assert.AreEqual(5, Arr[4]);
end;

Procedure TArrayHelperTests.TestIntContains;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign([10, 20, 30]);
  Assert.IsTrue(Arr.Contains(20));
  Assert.IsFalse(Arr.Contains(99));
end;

Procedure TArrayHelperTests.TestIntAggregates;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign([3, 1, 4, 1, 5, 9]);
  Assert.AreEqual(1,  Arr.MinValue);
  Assert.AreEqual(9,  Arr.MaxValue);
  Assert.AreEqual(23, Arr.Total);
end;

Procedure TArrayHelperTests.TestIntSort;
Var
  Arr: TArray<Integer>;
begin
  Arr.Assign([5, 3, 8, 1, 4]);
  Arr.Sort;
  Assert.AreEqual(5, Arr.Length);
  Assert.AreEqual(1, Arr[0]);
  Assert.AreEqual(3, Arr[1]);
  Assert.AreEqual(4, Arr[2]);
  Assert.AreEqual(5, Arr[3]);
  Assert.AreEqual(8, Arr[4]);
end;

Procedure TArrayHelperTests.TestIntAssignTo;
Var
  Src: TArray<Integer>;
  Dst: array[0..2] of Integer;
begin
  Src.Assign([10, 20, 30, 40, 50]);
  // Copy 3 elements starting at index 1 (values 20, 30, 40) into Dst
  Src.AssignTo(Dst, 1);
  Assert.AreEqual(20, Dst[0]);
  Assert.AreEqual(30, Dst[1]);
  Assert.AreEqual(40, Dst[2]);
end;

////////////////////////////////////////////////////////////////////////////////
// TFloat64ArrayHelper
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayHelperTests.TestFloatCreateFromValues;
Var
  Arr: TArray<Float64>;
begin
  Arr := TArray<Float64>.Create([1.0, 2.5, 3.75]);
  Assert.AreEqual(3, Arr.Length);
  Assert.AreEqual(1.0,  Arr[0], 1e-12);
  Assert.AreEqual(2.5,  Arr[1], 1e-12);
  Assert.AreEqual(3.75, Arr[2], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatCreateWithLength;
Var
  Arr: TArray<Float64>;
begin
  Arr := TArray<Float64>.Create(3, 2.5);
  Assert.AreEqual(3,   Arr.Length);
  Assert.AreEqual(2.5, Arr[0], 1e-12);
  Assert.AreEqual(2.5, Arr[1], 1e-12);
  Assert.AreEqual(2.5, Arr[2], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatInitialize;
Var
  Arr: TArray<Float64>;
begin
  Arr := TArray<Float64>.Create([1.0, 2.0, 3.0]);
  Arr.Initialize(0.5);
  Assert.AreEqual(3,   Arr.Length);
  Assert.AreEqual(0.5, Arr[0], 1e-12);
  Assert.AreEqual(0.5, Arr[1], 1e-12);
  Assert.AreEqual(0.5, Arr[2], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatAssignFromArray;
Var
  Arr: TArray<Float64>;
begin
  Arr.Assign([1.1, 2.2, 3.3]);
  Assert.AreEqual(3,   Arr.Length);
  Assert.AreEqual(1.1, Arr[0], 1e-12);
  Assert.AreEqual(2.2, Arr[1], 1e-12);
  Assert.AreEqual(3.3, Arr[2], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatAssignFromStrings;
Var
  Arr: TArray<Float64>;
begin
  Arr.Assign(['1.5', '2.5', '3.5']);
  Assert.AreEqual(3,   Arr.Length);
  Assert.AreEqual(1.5, Arr[0], 1e-12);
  Assert.AreEqual(2.5, Arr[1], 1e-12);
  Assert.AreEqual(3.5, Arr[2], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatAssignFromDelimitedString;
Var
  Arr: TArray<Float64>;
begin
  Arr.Assign('1.0,2.0,3.0');
  Assert.AreEqual(3,   Arr.Length);
  Assert.AreEqual(1.0, Arr[0], 1e-12);
  Assert.AreEqual(2.0, Arr[1], 1e-12);
  Assert.AreEqual(3.0, Arr[2], 1e-12);
  // Non-default separator
  Arr.Assign('4.0;5.0', ';');
  Assert.AreEqual(2,   Arr.Length);
  Assert.AreEqual(4.0, Arr[0], 1e-12);
  Assert.AreEqual(5.0, Arr[1], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatToString;
Var
  Arr: TArray<Float64>;
  Expected: String;
begin
  Arr.Assign([1.0, 2.0, 3.0]);
  // Build expected using the same Float64.ToString as the implementation does
  Expected := Arr[0].ToString + ',' + Arr[1].ToString + ',' + Arr[2].ToString;
  Assert.AreEqual(Expected, Arr.ToString);
  // Custom separator
  Expected := Arr[0].ToString + ';' + Arr[1].ToString + ';' + Arr[2].ToString;
  Assert.AreEqual(Expected, Arr.ToString(';'));
  // Empty array
  Arr.Length := 0;
  Assert.AreEqual('', Arr.ToString);
end;

Procedure TArrayHelperTests.TestFloatToStringFormatted;
Var
  Arr: TArray<Float64>;
begin
  Arr.Assign([1.5, 2.5, 3.5]);
  Assert.AreEqual('1.5,2.5,3.5', Arr.ToString('0.0'));
  Assert.AreEqual('1.5;2.5;3.5', Arr.ToString('0.0', ';'));
end;

Procedure TArrayHelperTests.TestFloatToStrings;
Var
  Arr: TArray<Float64>;
  Strs: TArray<String>;
begin
  Arr.Assign([1.0, 2.0]);
  Strs := Arr.ToStrings;
  Assert.AreEqual(2, Integer(System.Length(Strs)));
  Assert.AreEqual(Arr[0].ToString, Strs[0]);
  Assert.AreEqual(Arr[1].ToString, Strs[1]);
end;

Procedure TArrayHelperTests.TestFloatToStringsFormatted;
Var
  Arr: TArray<Float64>;
  Strs: TArray<String>;
begin
  Arr.Assign([1.5, 2.75]);
  Strs := Arr.ToStrings('0.00');
  Assert.AreEqual(2,      Integer(System.Length(Strs)));
  Assert.AreEqual('1.50', Strs[0]);
  Assert.AreEqual('2.75', Strs[1]);
end;

Procedure TArrayHelperTests.TestFloatAppend;
Var
  Arr: TArray<Float64>;
begin
  Arr.Assign([1.0, 2.0]);
  Arr.Append([3.0, 4.0]);
  Assert.AreEqual(4,   Arr.Length);
  Assert.AreEqual(1.0, Arr[0], 1e-12);
  Assert.AreEqual(2.0, Arr[1], 1e-12);
  Assert.AreEqual(3.0, Arr[2], 1e-12);
  Assert.AreEqual(4.0, Arr[3], 1e-12);
end;

Procedure TArrayHelperTests.TestFloatAggregates;
Var
  Arr: TArray<Float64>;
begin
  Arr.Assign([1.0, 3.0, 2.0]);
  Assert.AreEqual(1.0, Arr.MinValue, 1e-12);
  Assert.AreEqual(3.0, Arr.MaxValue, 1e-12);
  Assert.AreEqual(6.0, Arr.Total,    1e-12);
end;

Procedure TArrayHelperTests.TestFloatAssignTo;
Var
  Src: TArray<Float64>;
  Dst: array[0..1] of Float64;
begin
  Src.Assign([1.0, 2.0, 3.0, 4.0]);
  // Copy 2 elements starting at index 2 (values 3.0, 4.0) into Dst
  Src.AssignTo(Dst, 2);
  Assert.AreEqual(3.0, Dst[0], 1e-12);
  Assert.AreEqual(4.0, Dst[1], 1e-12);
end;

////////////////////////////////////////////////////////////////////////////////
// TStringArrayHelper
////////////////////////////////////////////////////////////////////////////////

Procedure TArrayHelperTests.TestStringCreateFromValues;
Var
  Arr: TArray<String>;
begin
  Arr := TArray<String>.Create(['alpha', 'beta', 'gamma']);
  Assert.AreEqual(3,       Arr.Length);
  Assert.AreEqual('alpha', Arr[0]);
  Assert.AreEqual('beta',  Arr[1]);
  Assert.AreEqual('gamma', Arr[2]);
end;

Procedure TArrayHelperTests.TestStringAssignFromArray;
Var
  Arr: TArray<String>;
begin
  Arr.Assign(['one', 'two', 'three']);
  Assert.AreEqual(3,       Arr.Length);
  Assert.AreEqual('one',   Arr[0]);
  Assert.AreEqual('two',   Arr[1]);
  Assert.AreEqual('three', Arr[2]);
end;

Procedure TArrayHelperTests.TestStringAssignFromDelimitedString;
Var
  Arr: TArray<String>;
begin
  Arr.Assign('a,b,c');
  Assert.AreEqual(3,   Arr.Length);
  Assert.AreEqual('a', Arr[0]);
  Assert.AreEqual('b', Arr[1]);
  Assert.AreEqual('c', Arr[2]);
  // Non-default separator
  Arr.Assign('x;y', ';');
  Assert.AreEqual(2,   Arr.Length);
  Assert.AreEqual('x', Arr[0]);
  Assert.AreEqual('y', Arr[1]);
end;

Procedure TArrayHelperTests.TestStringToString;
Var
  Arr: TArray<String>;
begin
  Arr.Assign(['a', 'b', 'c']);
  Assert.AreEqual('a,b,c', Arr.ToString);
  Assert.AreEqual('a|b|c', Arr.ToString('|'));
  // Empty array
  Arr.Length := 0;
  Assert.AreEqual('', Arr.ToString);
end;

Procedure TArrayHelperTests.TestStringAppend;
Var
  Arr: TArray<String>;
begin
  Arr.Assign(['a', 'b']);
  Arr.Append(['c', 'd']);
  Assert.AreEqual(4,   Arr.Length);
  Assert.AreEqual('a', Arr[0]);
  Assert.AreEqual('b', Arr[1]);
  Assert.AreEqual('c', Arr[2]);
  Assert.AreEqual('d', Arr[3]);
end;

initialization
  TDUnitX.RegisterTestFixture(TArrayHelperTests);
end.
