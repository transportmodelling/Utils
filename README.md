# Utils
A general utilities library for Delphi projects

## DBF.pas
Provides DBFReader and DBFWriter classes to read/write dBase files. Memo fields are not supported and will have an UnUssigned-value.

## MemDBF.pas
Provides a class to manipulate a dbf file. Data are read into a FireDac memory table to be manipulated. The manipulated table can be saved to file again.

## ArrHlp.pas
Provides record helpers for `TArray<Integer>`, `TArray<Float64>` and `TArray<String>` that add a `Length` property, constructors, and common operations such as `Initialize`, `Assign`, `Append`, `Contains`, `MinValue`, `MaxValue`, `Total`, `Sort`, `ToString` and `ToStrings`. Also provides `TArrayInfo` for inspecting the reference count and length of a dynamic array by pointer.

```
  var Ints: TArray<Integer> := TArray<Integer>.Create([3,1,4,1,5]);
  Ints.Sort;
  writeln(Ints.ToString(','));   // 1,1,3,4,5
  writeln(Ints.MinValue);       // 1
  writeln(Ints.Total);          // 14

  var Floats: TArray<Float64> := TArray<Float64>.Create(3, 0.0);
  Floats.Assign('1.1,2.2,3.3');
  writeln(Floats.ToString('0.0', ','));  // 1.1,2.2,3.3
```

## ArrBld.pas
Provides an array builder to easily convert an open array to a dynamic array.

```
  Procedure Test(const Values: array of Float64);
  begin
    var Tst: TArray<Float64> := TArrayBuilder<Float64>.Create(Values);
  end;
```

## ArrVal.pas
Provides `TArrayView<T>` and `TArrayValues<T>` records that wrap a `TArray<T>` to restrict what callers can do with it.

- `TArrayView<T>` — read-only view: exposes indexed read and `Length`, but prevents any modification of the values or reallocation of the array.
- `TArrayValues<T>` — read/write values view: allows indexed read and write, but prevents reallocation of the array.

Convenience type aliases are provided for common element types: `TIntArrayView`, `TFloat64ArrayView`, `TFloat32ArrayView`, `TStringArrayView` and their `TArrayValues` counterparts.

```
  var Data: TArray<Float64> := TArray<Float64>.Create(1.0, 2.0, 3.0);

  // Pass a read-only view to a consumer
  var View: TFloat64ArrayView := TFloat64ArrayView.Create(Data);
  writeln(View.Length);   // 3
  writeln(View[0]);       // 1

  // Pass a writable-values view to a consumer (values can change, array cannot grow)
  var Vals: TFloat64ArrayValues := TFloat64ArrayValues.Create(Data);
  Vals[0] := 9.9;
  writeln(Data[0]);       // 9.9  (change is reflected in the original array)
```

## DynArr.pas
Provides an array with dynamic rank.

```
  // (Rank 3) Example: allocate 2x3x2 array
  var X := TDynamicArray<Integer>.Create([2,3,2]);
  X[0,0,0] := 1;
  writeln(X[0,0,0]);
  writeln(X.Rank);

  // (Rank 1) Example: assign 1-dimentional (constant) array
  X := [0,1,2];
  writeln(X[0]);
  writeln(X.Rank);
```

## ObjRef.pas
Provides `TReference<T>` — a smart-pointer helper that wraps any class instance in a reference-counted `TFunc<T>`. The wrapped object is automatically freed when the last reference goes out of scope, eliminating the need for a manual `Free` call.

```
  var Obj: TFunc<TStringList> := TReference<TStringList>.Create(TStringList.Create);
  Obj().Add('hello');        // access the object via Obj()
  writeln(Obj().Count);      // 1
  // Obj goes out of scope here -> TStringList is freed automatically
```

## PropSet.pas
Provides a property set, implemented as a set of name-value pairs.

```
  var Properties := TPropertySet.Create('Property1=Value1; Property2=Value2');
  writeln(Properties['Property1']);
  Properties := 'Property3=Value3; Property4=Value4';
  writeln(Properties['Property3']);
```

## Parse.pas
Provides a TStringParser that splits strings into multiple tokens.

```
  var Parser := TStringParser.Create(Comma,'1,2,3,4');
  writeln(Parser.Count);
  // List tokens
  for var Token := 0 to Parser.Count-1 do writeln(Parser[Token].Value);
  // Typecast tokens to integers
  for var Token := 0 to Parser.Count-1 do writeln(Parser.Int[Token]);
```

## Polynom.pas
Provides a structure for the manipulation of polynomials. 

## Spline.pas
Provides a structure for the manipulation of splines. 
