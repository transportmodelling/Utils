unit FloatHlp;

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
  TFloat64Helper = record helper for Float64
  public
    Function Round: Int64;
    Procedure Add(const Value: Float64);
    Procedure Subtract(const Value: Float64);
    Procedure MultiplyBy(const Value: Float64);
    Function MultipliedBy(const Value: Float64): Float64;
    Procedure DivideBy(const Value: Float64);
    Function DividedBy(const Value: Float64): Float64;
    Function ToString: String; overload;
    Function ToString(const Format: String): String; overload;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Function TFloat64Helper.Round: Int64;
begin
  Result := System.Round(Self);
end;

Procedure TFloat64Helper.Add(const Value: Float64);
begin
  Self := Self + Value;
end;

Procedure TFloat64Helper.Subtract(const Value: Float64);
begin
  Self := Self - Value;
end;

Procedure TFloat64Helper.MultiplyBy(const Value: Float64);
begin
  Self := Value*Self;
end;

Function TFloat64Helper.MultipliedBy(const Value: Float64): Float64;
begin
  Result := Value*Self;
end;

Procedure TFloat64Helper.DivideBy(const Value: Float64);
begin
  Self := Self/Value;
end;

Function TFloat64Helper.DividedBy(const Value: Float64): Float64;
begin
  Result := Self/Value;
end;

Function TFloat64Helper.ToString: String;
begin
  Result := FloatToStr(Self);
end;

Function TFloat64Helper.ToString(const Format: String): String;
begin
  Result := FormatFloat(Format,Self);
end;

end.
