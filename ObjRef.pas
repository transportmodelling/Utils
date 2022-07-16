unit ObjRef;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
// Code based on Barry Kelly's blog post: http://blog.barrkel.com/2008/11/somewhat-more-efficient-smart-pointers.html
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils;

Type
  TReference<T: Class> = record
  private
    Type
      TObjectReference = Class(TInterfacedObject,TFunc<T>)
      private
        Value: T;
      public
        Constructor Create(AObject: T);
        Function Invoke: T;
        Destructor Destroy; override;
      end;
  public
    Class Function Create(AObject: T): TFunc<T>; static;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TReference<T>.TObjectReference.Create(AObject: T);
begin
  inherited Create;
  Value := AObject;
end;

Function TReference<T>.TObjectReference.Invoke: T;
begin
  Result := Value;
end;

Destructor TReference<T>.TObjectReference.Destroy;
begin
  Value.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Class Function TReference<T>.Create(AObject: T): TFunc<T>;
begin
  Result := TObjectReference.Create(AObject);
end;

end.
