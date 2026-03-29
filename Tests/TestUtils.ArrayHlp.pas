unit TestUtils.ArrayHlp;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Classes, Windows, DUnitX.TestFramework, ArrayHlp;

Type
  [TestFixture]
  TRefCountTest = class
  public
    [Test]
    Procedure TestRefCount;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TRefCountTest.TestRefCount;
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

initialization
  TDUnitX.RegisterTestFixture(TRefCountTest);
end.
