unit Polynom;

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
  Types,ArrayBld;

Type
  TPolynomial = record
  private
    FDegree: Integer;
    FCoefs: TDoubleDynArray;
    Procedure Allocate; overload;
    Procedure Allocate(Const MaxDegree: Integer); overload;
    Procedure SetDegree(MaxDegree: Integer);
    Function GetCoefs(Power: Integer): Float64;
    Function GetValue(x: Float64): Float64; inline;
  public
    Class Operator Implicit(const Constant: Float64): TPolynomial;
    Class Operator Implicit(const Coefs: array of Float64): TPolynomial;
    Class Operator Equal(a: TPolynomial; b: TPolynomial): Boolean;
    Class Operator Add(a: Float64; b: TPolynomial): TPolynomial;
    Class Operator Add(a: TPolynomial; b: TPolynomial): TPolynomial;
    Class Operator Multiply(a: Float64; b: TPolynomial): TPolynomial;
    Class Operator Multiply(a: TPolynomial; b: TPolynomial): TPolynomial;
  public
    Constructor Create(const Constant: Float64); overload;
    Constructor Create(const Coefs: array of Float64); overload;
    Function Null: Boolean;
    Procedure Differentiate;
    Function Derivative: TPolynomial;
    Procedure AntiDifferentiate(Const Constant: Float64 = 0);
    Function Primitive(Const Constant: Float64 = 0): TPolynomial;
    Function Integrate(Const a,b: Float64): Float64;
  public
    Property Degree: Integer read FDegree;
    Property Coefs[Power: Integer]: Float64 read GetCoefs;
    Property Value[x: Float64]: Float64 read GetValue; default;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TPolynomial.Implicit(const Constant: Float64): TPolynomial;
begin
  Result.FDegree := 0;
  Result.Allocate;
  Result.FCoefs[0] := Constant;
end;

Class Operator TPolynomial.Implicit(Const Coefs: array of Float64): TPolynomial;
begin
  Result.FCoefs := TFloatArrayBuilder.Create(Coefs);
  Result.SetDegree(Length(Coefs)-1);
end;

Class Operator TPolynomial.Equal(a: TPolynomial; b: TPolynomial): Boolean;
begin
  if a.FDegree = b.FDegree then
  begin
    Result := true;
    for var Coef := 0 to a.FDegree do
    if a.FCoefs[Coef] <> b.FCoefs[Coef] then
    begin
      Result := false;
      Break;
    end;
  end else
    Result := false;
end;

Class Operator TPolynomial.Add(a: Float64; b: TPolynomial): TPolynomial;
begin
  Result.FDegree := b.FDegree;
  Result.Allocate;
  for var Coef := 0 to b.FDegree do Result.FCoefs[Coef] := b.FCoefs[Coef];
  Result.FCoefs[0] := Result.FCoefs[0] + a;
end;

Class Operator TPolynomial.Add(a: TPolynomial; b: TPolynomial): TPolynomial;
Var
  Coef: Integer;
begin
  if a.FDegree = b.FDegree then
  begin
    Result.Allocate(a.FDegree);
    for Coef := 0 to a.FDegree do
    Result.FCoefs[Coef] := a.FCoefs[Coef] + b.FCoefs[Coef];
    Result.SetDegree(a.FDegree);
  end else
  if a.FDegree < b.FDegree then
  begin
    Result.FDegree := b.FDegree;
    Result.Allocate;
    for Coef := 0 to a.FDegree do Result.FCoefs[Coef] := a.FCoefs[Coef] + b.FCoefs[Coef];
    for Coef := a.FDegree+1 to b.FDegree do Result.FCoefs[Coef] := b.FCoefs[Coef];
  end else
  begin
    Result.FDegree := a.FDegree;
    Result.Allocate;
    for Coef := 0 to b.FDegree do Result.FCoefs[Coef] := a.FCoefs[Coef] + b.FCoefs[Coef];
    for Coef := b.FDegree+1 to a.FDegree do Result.FCoefs[Coef] := a.FCoefs[Coef];
  end;
end;

Class Operator TPolynomial.Multiply(a: Float64; b: TPolynomial): TPolynomial;
begin
  if a = 0 then Result := 0 else
  for var Coef := 0 to b.FDegree do Result.FCoefs[Coef] := a*b.FCoefs[Coef];
end;

Class Operator TPolynomial.Multiply(a: TPolynomial; b: TPolynomial): TPolynomial;
begin
  if a.Null or b.Null then Result := 0 else
  begin
    Result.FDegree := a.FDegree+b.FDegree;
    Result.Allocate;
    for var aCoef := 0 to a.FDegree do
    for var bCoef := 0 to b.FDegree do
    Result.FCoefs[aCoef+bCoef] := Result.FCoefs[aCoef+bCoef] + a.FCoefs[aCoef]*b.FCoefs[bCoef];
  end;
end;

Constructor TPolynomial.Create(const Constant: Float64);
begin
  FDegree := 0;
  Allocate;
  FCoefs[0] := Constant;
end;

Constructor TPolynomial.Create(const Coefs: array of Float64);
begin
  FCoefs := TFloatArrayBuilder.Create(Coefs);
  SetDegree(Length(Coefs)-1);
end;

Procedure TPolynomial.Allocate;
begin
  FCoefs := nil;
  SetLength(FCoefs,FDegree+8);
end;

Procedure TPolynomial.Allocate(Const MaxDegree: Integer);
begin
  SetLength(FCoefs,MaxDegree+8);
end;

Procedure TPolynomial.SetDegree(MaxDegree: Integer);
begin
  FDegree := 0;
  for var Power := MaxDegree downto 0 do
  if FCoefs[Power] <> 0 then
  begin
    FDegree := Power;
    Break;
  end;
end;

Function TPolynomial.GetCoefs(Power: Integer): Float64;
begin
  Result := FCoefs[Power];
end;

Function TPolynomial.GetValue(x: Float64): Float64;
begin
  Result := FCoefs[FDegree];
  for var Power := FDegree-1 downto 0 do
  Result := x*Result + FCoefs[Power];
end;

Function TPolynomial.Null: Boolean;
begin
  Result := (FDegree = 0) and (FCoefs[0] = 0);
end;

Procedure TPolynomial.Differentiate;
begin
  if FDegree = 0 then FCoefs[0] := 0 else
  begin
    FDegree := FDegree-1;
    for var Coef := 0 to FDegree do FCoefs[Coef] := (Coef+1)*FCoefs[Coef+1]
  end;
end;

Function TPolynomial.Derivative: TPolynomial;
begin
  if FDegree = 0 then Result := 0 else
  begin
    Result.FDegree := FDegree-1;
    Result.Allocate;
    for var Coef := 0 to FDegree-1 do Result.FCoefs[Coef] := (Coef+1)*FCoefs[Coef+1]
  end;
end;

Procedure TPolynomial.AntiDifferentiate(Const Constant: Float64 = 0);
begin
  FDegree := FDegree+1;
  if Length(FCoefs) <= FDegree then SetLength(FCoefs,FDegree+8);
  for var Coef := FDegree downto 1 do FCoefs[Coef] := FCoefs[Coef-1]/Coef;
  FCoefs[0] := Constant;
end;

Function TPolynomial.Primitive(Const Constant: Float64 = 0): TPolynomial;
begin
  if Null then Result := Constant else
  begin
    Result.FDegree := FDegree+1;
    Result.Allocate;
    for var Coef := FDegree+1 downto 1 do Result.FCoefs[Coef] := FCoefs[Coef-1]/Coef;
    Result.FCoefs[0] := Constant;
  end;
end;

Function TPolynomial.Integrate(Const a,b: Float64): Float64;
begin
  var Coef := FCoefs[FDegree]/(FDegree+1);
  var Primitive_a := a*Coef;
  var Primitive_b := b*Coef;
  for var Power := FDegree-1 downto 0 do
  begin
    Coef := FCoefs[Power]/(Power+1);
    Primitive_a := a*(Primitive_a + Coef);
    Primitive_b := b*(Primitive_b + Coef);
  end;
  Result := Primitive_b - Primitive_a;
end;

end.
