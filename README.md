# Utils
A general utilities library for Delphi projects

## DBF.pas
Provides DBFReader and DBFWriter classes to read/write dBase files. Memo fields are not supported and will have an UnUssigned-value.

## MemDBF.pas
Provides a class to manipulate a dbf file. Data are read into a FireDac memory table to be manipulated. The manipulated table can be saved to file again.

## ArrayBld.pas
Provides an array builder to easily convert an open array to a dynamic array.

```
  Procedure Test(const Values: array of Float64);
  begin
    var Tst: TArray<Float64> := TArrayBuilder<Float64>.Create(Values);
  end;
```

## DynArray.pas
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
