unit VarPtr;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Type
  TIntPointer = record
  private
    Pointer: ^Integer;
    Function GetValue: Integer;
    Procedure SetValue(Value: Integer);
  public
    Class Operator Implicit(const [ref] Value: Integer): TIntPointer;
  public
    Property Value: Integer read GetValue write SetValue;
  end;

  TFloat64Pointer = record
  private
    Pointer: ^Float64;
    Function GetValue: Float64;
    Procedure SetValue(Value: Float64);
  public
    Class Operator Implicit(const [ref] Value: Float64): TFloat64Pointer;
  public
    Property Value: Float64 read GetValue write SetValue;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TIntPointer.Implicit(const [ref] Value: Integer): TIntPointer;
begin
  Result.Pointer := @Value;
end;

Function TIntPointer.GetValue: Integer;
begin
  Result := Pointer^;
end;

Procedure TIntPointer.SetValue(Value: Integer);
begin
  Pointer^ := Value;
end;

////////////////////////////////////////////////////////////////////////////////

Class Operator TFloat64Pointer.Implicit(const [ref] Value: Float64): TFloat64Pointer;
begin
  Result.Pointer := @Value;
end;

Function TFloat64Pointer.GetValue: Float64;
begin
  Result := Pointer^;
end;

Procedure TFloat64Pointer.SetValue(Value: Float64);
begin
  Pointer^ := Value;
end;

end.
