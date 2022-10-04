unit ArrayBld;

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
  TArrayBuilder<T> = record
  private
    FValues: TArray<T>;
    Function GetValues(Index: Integer): T; inline;
  public
    Class Operator Implicit(const Values: array of T): TArrayBuilder<T>;
    Class Operator Implicit(const Builder: TArrayBuilder<T>): TArray<T>;
    Class Operator Add(const A: TArrayBuilder<T>; const B: array of T): TArrayBuilder<T>;
    Class Operator Add(const A: TArrayBuilder<T>; const B: TArrayBuilder<T>): TArrayBuilder<T>;
    Class Function Concat(const A: array of T; const B: array of T): TArray<T>; overload; static;
    Class Function Concat(const A: array of T; const B: array of T; const C: array of T): TArray<T>; overload; static;
  public
    Constructor Create(const Values: array of T); overload;
    Constructor Create(const Values: array of T; const First,count: Integer); overload;
    Constructor Create(const Length: Integer; const Values: T); overload;
    Constructor Create(const Length: Integer); overload;
    Function Length: Integer; inline;
    Procedure Append(const Values: array of T); overload;
    Procedure Append(const Values: array of T; const First,Count: Integer); overload;
    Procedure Clear;
  public
    Property AsArray: TArray<T> read FValues;
    Property Values[Index: Integer]: T read GetValues; default;
  end;

  TIntArrayBuilder = TArrayBuilder<Integer>;
  TFloatArrayBuilder = TArrayBuilder<Float64>;
  TFloat32ArrayBuilder = TArrayBuilder<Float32>;
  TStringArrayBuilder = TArrayBuilder<String>;
  TCharArrayBuilder = TArrayBuilder<Char>;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TArrayBuilder<T>.Implicit(const Values: array of T): TArrayBuilder<T>;
begin
  Result := TArrayBuilder<T>.Create(Values);
end;

Class Operator TArrayBuilder<T>.Implicit(const Builder: TArrayBuilder<T>): TArray<T>;
begin
  Result := Builder.AsArray;
end;

Class Operator TArrayBuilder<T>.Add(const A: TArrayBuilder<T>; const B: array of T): TArrayBuilder<T>;
begin
  Result.Append(A.FValues);
  Result.Append(B);
end;

Class Operator TArrayBuilder<T>.Add(const A: TArrayBuilder<T>; const B: TArrayBuilder<T>): TArrayBuilder<T>;
begin
  Result.Append(A.FValues);
  Result.Append(B.FValues);
end;

Class Function TArrayBuilder<T>.Concat(const A: array of T; const B: array of T): TArray<T>;
var
  Builder: TArrayBuilder<T>;
begin
  Builder.Append(A);
  Builder.Append(B);
  Result := Builder;
end;

Class Function TArrayBuilder<T>.Concat(const A: array of T; const B: array of T; const C: array of T): TArray<T>;
var
  Builder: TArrayBuilder<T>;
begin
  Builder.Append(A);
  Builder.Append(B);
  Builder.Append(C);
  Result := Builder;
end;

Constructor TArrayBuilder<T>.Create(const Values: array of T);
begin
  Finalize(FValues);
  Append(Values);
end;

Constructor TArrayBuilder<T>.Create(const Values: array of T; const First,count: Integer);
begin
  Finalize(FValues);
  Append(Values,First,Count);
end;

Constructor TArrayBuilder<T>.Create(const Length: Integer; const Values: T);
begin
  SetLength(FValues,Length);
  for var Index := 0 to Length-1 do FValues[Index] := Values;
end;

Constructor TArrayBuilder<T>.Create(const Length: Integer);
begin
  SetLength(FValues,Length);
end;

Function TArrayBuilder<T>.GetValues(Index: Integer): T;
begin
  Result := FValues[Index];
end;

Function TArrayBuilder<T>.Length: Integer;
begin
  Result := System.Length(FValues);
end;

Procedure TArrayBuilder<T>.Append(const Values: array of T);
begin
  Append(Values,low(Values),System.Length(Values));
end;

Procedure TArrayBuilder<T>.Append(const Values: array of T; const First,Count: Integer);
begin
  var Offset := Length;
  SetLength(FValues,Offset+Count);
  for var Index := 0 to Count-1 do FValues[Index+Offset] := Values[First+Index];
end;

Procedure TArrayBuilder<T>.Clear;
begin
  FValues := nil;
end;

end.
