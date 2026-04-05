unit TestUtils.ObjRef;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Classes, DUnitX.TestFramework, ObjRef;

Type
  [TestFixture]
  TReferenceTests = class
  private
    Type
      // Helper class: sets a Boolean flag when destroyed
      TDestructionTracker = class
      private
        FDestroyed: PBoolean;
      public
        Constructor Create(var Destroyed: Boolean);
        Destructor Destroy; override;
      end;
  public
    // Invoking the TFunc<T> returns the original object
    [Test]
    Procedure TestInvokeReturnsWrappedObject;
    // The wrapped object is freed when the TFunc<T> reference goes out of scope
    [Test]
    Procedure TestObjectFreedOnRelease;
    // Invoking multiple times always returns the same object
    [Test]
    Procedure TestInvokeIsIdempotent;
    // Works with TStringList as a concrete example
    [Test]
    Procedure TestWithStringList;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TReferenceTests.TDestructionTracker.Create(var Destroyed: Boolean);
begin
  inherited Create;
  Destroyed := False;
  FDestroyed := @Destroyed;
end;

Destructor TReferenceTests.TDestructionTracker.Destroy;
begin
  FDestroyed^ := True;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TReferenceTests.TestInvokeReturnsWrappedObject;
Var
  Original: TObject;
  Ref: TFunc<TObject>;
begin
  Original := TObject.Create;
  Ref := TReference<TObject>.Create(Original);
  Assert.AreSame(Original, Ref());
end;

Procedure TReferenceTests.TestObjectFreedOnRelease;
Var
  Destroyed: Boolean;
begin
  Destroyed := False;
  // Inner block: Ref goes out of scope at end, freeing the tracked object
  begin
    var Ref := TReference<TDestructionTracker>.Create(TDestructionTracker.Create(Destroyed));
    Assert.IsFalse(Destroyed, 'Object should not be destroyed while reference is held');
  end;
  Assert.IsTrue(Destroyed, 'Object should be destroyed after reference is released');
end;

Procedure TReferenceTests.TestInvokeIsIdempotent;
Var
  Ref: TFunc<TObject>;
begin
  Ref := TReference<TObject>.Create(TObject.Create);
  Assert.AreSame(Ref(), Ref(), 'Repeated invocations must return the same object');
end;

Procedure TReferenceTests.TestWithStringList;
Var
  Ref: TFunc<TStringList>;
begin
  Ref := TReference<TStringList>.Create(TStringList.Create);
  Ref().Add('alpha');
  Ref().Add('beta');
  Assert.AreEqual(2,       Ref().Count);
  Assert.AreEqual('alpha', Ref()[0]);
  Assert.AreEqual('beta',  Ref()[1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TReferenceTests);

end.
