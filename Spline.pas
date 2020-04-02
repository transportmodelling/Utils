unit Spline;

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
  SysUtils,Math,Polynom;

Type
  TSpline = record
  private
    FNPieces: Integer;
    FKnots: array of Float64;
    FPolynomials: array of TPolynomial;
  public
    Class Operator Multiply(a: TSpline; b: TSpline): TSpline;
    Constructor Create(Const Knots: array of Float64; Const Polynomials: array of TPolynomial);
    Procedure Nullify;
    Function Integrate: Float64; overload;
    Function Integrate(Const a,b: Float64): Float64; overload;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TSpline.Multiply(a: TSpline; b: TSpline): TSpline;
Var
  Index_a,Index_b: Integer;
begin
  SetLength(Result.FKnots,a.FNPieces+b.FNPieces+2);
  SetLength(Result.FPolynomials,a.FNPieces+b.FNPieces);
  if (a.FNPieces > 0) and (b.FNPieces > 0) then
  begin
    // Set first knot
    if a.FKnots[0] < b.FKnots[0] then
    begin
      Result.FKnots[0] := b.FKnots[0];
      Index_a := 1;
      Index_b := 1;
      while (Index_a <= a.FNPieces) and (a.FKnots[Index_a] <= b.FKnots[0]) do Inc(Index_a);
    end else
    begin
      Result.FKnots[0] := a.FKnots[0];
      Index_a := 1;
      Index_b := 1;
      while (Index_b <= b.FNPieces) and (b.FKnots[Index_b] < a.FKnots[0]) do Inc(Index_b)
    end;
    // Set subsequent knots
    var Count := 0;
    while (Index_a <= a.FNPieces) and (Index_b <= b.FNPieces) do
    begin
      if a.FKnots[Index_a] < b.FKnots[Index_b] then
      begin
        Inc(Count);
        Result.FKnots[Count] := a.FKnots[Index_a];
        Result.FPolynomials[count-1] := a.FPolynomials[Index_a-1]*b.FPolynomials[Index_b-1];
        Inc(Index_a);
      end else
      if a.FKnots[Index_a] > b.FKnots[Index_b] then
      begin
        Inc(Count);
        Result.FKnots[Count] := b.FKnots[Index_b];
        Result.FPolynomials[count-1] := a.FPolynomials[Index_a-1]*b.FPolynomials[Index_b-1];
        Inc(Index_b);
      end else
      begin
        Inc(Count);
        Result.FKnots[Count] := a.FKnots[Index_a];
        Result.FPolynomials[count-1] := a.FPolynomials[Index_a-1]*b.FPolynomials[Index_b-1];
        Inc(Index_a);
        Inc(Index_b);
      end;
    end;
    Result.FNPieces := Count;
  end else Result.FNPieces := 0;
end;

Constructor TSpline.Create(Const Knots: array of Float64; Const Polynomials: array of TPolynomial);
begin
  if Length(Knots) = Length(Polynomials)+1 then
  begin
    FNPieces := Length(Polynomials);
    SetLength(FKnots,FNPieces+1);
    SetLength(FPolynomials,FNPieces);
    for var Piece := 0 to FNPieces-1 do
    begin
      FKnots[Piece] := Knots[Piece];
      FPolynomials[Piece] := Polynomials[Piece];
    end;
    FKnots[FNPieces] := Knots[FNPieces];
  end else raise Exception.Create('Inconsistent spline constructor arguments');
end;

Procedure TSpline.Nullify;
begin
  FNPieces := 0;
end;

Function TSpline.Integrate: Float64;
begin
  Result := 0;
  for var Piece := 0 to FNPieces-1 do
  Result := Result + FPolynomials[Piece].Integrate(FKnots[Piece],FKnots[Piece+1]);
end;

Function TSpline.Integrate(Const a,b: Float64): Float64;
begin
  Result := 0;
  for var Piece := 0 to FNPieces-1 do
  begin
    var c := Max(a,FKnots[Piece]);
    var d := Min(b,FKnots[Piece+1]);
    if d > c then Result := Result + FPolynomials[Piece].Integrate(c,d);
  end;
end;

end.
