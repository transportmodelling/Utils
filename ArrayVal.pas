unit ArrayVal;

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
  TArrayView<T> = record
  // Record that provides access to the array values, but prevents the array from being changed.
  private
    FValues: TArray<T>;
    Function GetValues(Index: Integer): T; inline;
  public
    Constructor Create(Values: TArray<T>);
    Function Length: Integer; inline;
  public
    Property Values[Index: Integer]: T read GetValues; default;
  end;

  TArrayValues<T> = record
  // Record that provides access to the array values, but prevents the array from being resized.
  private
    FValues: TArray<T>;
    Function GetValues(Index: Integer): T; inline;
    Procedure SetValues(Index: Integer; Value: T); inline;
  public
    Constructor Create(Values: TArray<T>);
    Function Length: Integer; inline;
  public
    Property Values[Index: Integer]: T read GetValues write SetValues; default;
  end;

  TStringArrayView = TArrayView<String>;
  TIntArrayView = TArrayView<Integer>;
  TFloat64ArrayView = TArrayView<Float64>;
  TFloat32ArrayView = TArrayView<Float32>;

  TStringArrayValues = TArrayValues<String>;
  TIntArrayValues = TArrayValues<Integer>;
  TFloat64ArrayValues = TArrayValues<Float64>;
  TFloat32ArrayValues = TArrayValues<Float32>;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TArrayView<T>.Create(Values: TArray<T>);
begin
  FValues := Values;
end;

Function TArrayView<T>.GetValues(Index: Integer): T;
begin
  Result := FValues[Index];
end;

Function TArrayView<T>.Length: Integer;
begin
  Result := System.Length(FValues);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TArrayValues<T>.Create(Values: TArray<T>);
begin
  FValues := Values;
end;

Function TArrayValues<T>.GetValues(Index: Integer): T;
begin
  Result := FValues[Index];
end;

Procedure TArrayValues<T>.SetValues(Index: Integer; Value: T);
begin
  FValues[Index] := Value;
end;

Function TArrayValues<T>.Length: Integer;
begin
  Result := System.Length(FValues);
end;

end.
