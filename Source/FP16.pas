unit FP16;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
// Half precision floating point implementation based on:
// https://galfar.vevb.net/wp/2011/16bit-half-float-in-pascaldelphi/
// posted by Marek Mauder on March 29, 2011
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils,Math;

Type
  Float16 = record
  public
    Bytes: UInt16;
    Class Operator Implicit(Value: Float32): Float16;
    Class Operator Implicit(Value: Float16): Float32;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator Float16.Implicit(Value: Float32): Float16;
var
  Bytes: UInt32 absolute Value;
  Sign,Exp,Mantissa: Int32;
begin
  // Extract sign, exponent, and mantissa from Single number
  Sign := Bytes shr 31;
  Exp := Int32((Bytes and $7F800000) shr 23) - 127 + 15;
  Mantissa := Bytes and $007FFFFF;

  if (Exp > 0) and (Exp < 30) then
  begin
    // Simple case - round the significand and combine it with the sign and exponent
    Result.Bytes := (Sign shl 15) or (Exp shl 10) or ((Mantissa + $00001000) shr 13);
  end else
  if Bytes = 0 then
  begin
    // Input float is zero - return zero
    Result.Bytes := 0;
  end else
  begin
    // Difficult case - lengthy conversion
    if Exp <= 0 then
    begin
      if Exp < -10 then
      begin
        // Input float's value is less than HalfMin, return zero
         Result.Bytes := 0;
      end else
      begin
        // Float is a normalized Single whose magnitude is less than HalfNormMin.
        // We convert it to denormalized half.
        Mantissa := (Mantissa or $00800000) shr (1 - Exp);
        // Round to nearest
        if (Mantissa and $00001000) > 0 then Mantissa := Mantissa + $00002000;
        // Assemble Sign and Mantissa (Exp is zero to get denormalized number)
        Result.Bytes := (Sign shl 15) or (Mantissa shr 13);
      end;
    end else
    if Exp = 255 - 127 + 15 then
    begin
      if Mantissa = 0 then
      begin
        // Input float is infinity, create infinity half with original sign
        Result.Bytes := (Sign shl 15) or $7C00;
      end else
      begin
        // Input float is NaN, create half NaN with original sign and mantissa
        Result.Bytes := (Sign shl 15) or $7C00 or (Mantissa shr 13);
      end;
    end else
    begin
      // Exp is > 0 so input float is normalized Single
      // Round to nearest
      if (Mantissa and $00001000) > 0 then
      begin
        Mantissa := Mantissa + $00002000;
        if (Mantissa and $00800000) > 0 then
        begin
          Mantissa := 0;
          Exp := Exp + 1;
        end;
      end;
      if Exp > 30 then
      begin
        // Exponent overflow - return infinity half
        Result.Bytes := (Sign shl 15) or $7C00;
      end  else
      // Assemble normalized half
      Result.Bytes := (Sign shl 15) or (Exp shl 10) or (Mantissa shr 13);
    end;
  end;
end;

Class Operator Float16.Implicit(Value: Float16): Float32;
var
  Bytes: UInt32 absolute Result;
  Sign,Mantissa: UInt32;
  Exp: Int32;
begin
  // Extract sign, exponent, and mantissa from half number
  Sign := Value.Bytes shr 15;
  Exp := (Value.Bytes and $7C00) shr 10;
  Mantissa := Value.Bytes and 1023;

  if (Exp > 0) and (Exp < 31) then
  begin
    // Common normalized number
    Exp := Exp + (127 - 15);
    Mantissa := Mantissa shl 13;
    Bytes := (Sign shl 31) or (UInt32(Exp) shl 23) or Mantissa;
    // Result := Power(-1, Sign) * Power(2, Exp - 15) * (1 + Mantissa / 1024);
  end else
  if (Exp = 0) and (Mantissa = 0) then
  begin
    // Zero - preserve sign
    Bytes := Sign shl 31;
  end else
  if (Exp = 0) and (Mantissa <> 0) then
  begin
    // Denormalized number - renormalize it
    while (Mantissa and $00000400) = 0 do
    begin
      Mantissa := Mantissa shl 1;
      Dec(Exp);
    end;
    Inc(Exp);
    Mantissa := Mantissa and not $00000400;
    // Now assemble normalized number
    Exp := Exp + (127 - 15);
    Mantissa := Mantissa shl 13;
    Bytes := (Sign shl 31) or (LongWord(Exp) shl 23) or Mantissa;
    // Result := Power(-1, Sign) * Power(2, -14) * (Mantissa / 1024);
  end else
  if (Exp = 31) and (Mantissa = 0) then
  begin
    // +/- infinity
    Bytes := (Sign shl 31) or $7F800000;
  end else //if (Exp = 31) and (Mantisa <> 0) then
  begin
    // Not a number - preserve sign and mantissa
    Bytes:= (Sign shl 31) or $7F800000 or (Mantissa shl 13);
  end;
end;

end.
