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
    [Test]
    Procedure TestRefCount;
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

initialization
  TDUnitX.RegisterTestFixture(TArrayHelperTests);
end.
