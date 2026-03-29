unit VarPtr;

////////////////////////////////////////////////////////////////////////////////
//
// The VarPointer-type is primarily intended to facilitate the AssignToVar-methods
// in ArrayHlp.pas and Parse.pas
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils;

Type
  TVarType = (vtUnTyped,vtByte,vtInt16,vtInt32,vtInt64,vtFloat32,vtFloat64);

  TVarPointer = record
  private
    Var
      FVarType: TVarType;
      VarPointer: Pointer;
    Function GetAsByte: Byte;
    Function GetAsInt16: Int16;
    Function GetAsInt32: Int32;
    Function GetAsInt64: Int64;
    Function GetAsFloat32: Float32;
    Function GetAsFloat64: Float64;
    Procedure SetAsByte(AsByte: Byte);
    Procedure SetAsInt16(AsInt: Int16);
    Procedure SetAsInt32(AsInt: Int32);
    Procedure SetAsInt64(AsInt: Int64);
    Procedure SetAsFloat32(AsFloat: Float32);
    Procedure SetAsFloat64(AsFloat: Float64);
  public
    Class Operator Initialize(out VarRef: TVarPointer);
    Class Operator Implicit(const [ref] IntVar: Byte): TVarPointer;
    Class Operator Implicit(const [ref] IntVar: Int16): TVarPointer;
    Class Operator Implicit(const [ref] IntVar: Int32): TVarPointer;
    Class Operator Implicit(const [ref] IntVar: Int64): TVarPointer;
    Class Operator Implicit(const [ref] FloatVar: Float32): TVarPointer;
    Class Operator Implicit(const [ref] FloatVar: Float64): TVarPointer;
  public
    Property VarType: TVarType read FVarType;
    Property AsByte: Byte read GetAsByte write SetAsByte;
    Property AsInt16: Int16 read GetAsInt16 write SetAsInt16;
    Property AsInt32: Int32 read GetAsInt32 write SetAsInt32;
    Property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    Property AsFloat32: Float32 read GetAsFloat32 write SetAsFloat32;
    Property AsFloat64: Float64 read GetAsFloat64 write SetAsFloat64;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TVarPointer.Initialize(out varRef: TVarPointer);
begin
  VarRef.FVarType := vtUnTyped;
end;

Class Operator TVarPointer.Implicit(const [ref] IntVar: Byte): TVarPointer;
begin
  Result.FVarType := vtByte;
  Result.VarPointer := @IntVar;
end;

Class Operator TVarPointer.Implicit(const [ref] IntVar: Int16): TVarPointer;
begin
  Result.FVarType := vtInt16;
  Result.VarPointer := @IntVar;
end;

Class Operator TVarPointer.Implicit(const [ref] IntVar: Int32): TVarPointer;
begin
  Result.FVarType := vtInt32;
  Result.VarPointer := @IntVar;
end;

Class Operator TVarPointer.Implicit(const [ref] IntVar: Int64): TVarPointer;
begin
  Result.FVarType := vtInt64;
  Result.VarPointer := @IntVar;
end;

Class Operator TVarPointer.Implicit(const [ref] FloatVar: Float32): TVarPointer;
begin
  Result.FVarType := vtFloat32;
  Result.VarPointer := @FloatVar;
end;

Class Operator TVarPointer.Implicit(const [ref] FloatVar: Float64): TVarPointer;
begin
  Result.FVarType := vtFloat64;
  Result.VarPointer := @FloatVar;
end;

Function TVarPointer.GetAsByte: Byte;
begin
  if FVarType = vtByte then
    Result := PByte(VarPointer)^
  else
    raise Exception.Create('Invalid type');
end;

Function TVarPointer.GetAsInt16: Int16;
begin
  if FVarType = vtInt16 then
    Result := PSmallInt(VarPointer)^
  else
    raise Exception.Create('Invalid type');
end;

Function TVarPointer.GetAsInt32: Int32;
begin
  if FVarType = vtInt32 then
    Result := PInteger(VarPointer)^
  else
    raise Exception.Create('Invalid type');
end;

Function TVarPointer.GetAsInt64: Int64;
begin
  if FVarType = vtInt64 then
    Result := PInt64(VarPointer)^
  else
    raise Exception.Create('Invalid type');
end;

Function TVarPointer.GetAsFloat32: Float32;
begin
  if FVarType = vtFloat32 then
    Result := PSingle(VarPointer)^
  else
    raise Exception.Create('Invalid type');
end;

Function TVarPointer.GetAsFloat64: Float64;
begin
  if FVarType = vtFloat64 then
    Result := PDouble(VarPointer)^
  else
    raise Exception.Create('Invalid type');
end;

Procedure TVarPointer.SetAsByte(AsByte: Byte);
begin
  if FVarType = vtByte then
    PByte(VarPointer)^ := AsByte
  else
    raise Exception.Create('Invalid type');
end;

Procedure TVarPointer.SetAsInt16(AsInt: Int16);
begin
  if FVarType = vtInt16 then
    PSmallInt(VarPointer)^ := AsInt
  else
    raise Exception.Create('Invalid type');
end;

Procedure TVarPointer.SetAsInt32(AsInt: Int32);
begin
  if FVarType = vtInt32 then
    PInteger(VarPointer)^ := AsInt
  else
    raise Exception.Create('Invalid type');
end;

Procedure TVarPointer.SetAsInt64(AsInt: Int64);
begin
  if FVarType = vtInt64 then
    PInt64(VarPointer)^ := AsInt
  else
    raise Exception.Create('Invalid type');
end;

Procedure TVarPointer.SetAsFloat32(AsFloat: Float32);
begin
  if FVarType = vtFloat32 then
    PSingle(VarPointer)^ := AsFloat
  else
    raise Exception.Create('Invalid type');
end;

Procedure TVarPointer.SetAsFloat64(AsFloat: Float64);
begin
  if FVarType = vtFloat64 then
    PDouble(VarPointer)^ := AsFloat
  else
    raise Exception.Create('Invalid type');
end;

end.
