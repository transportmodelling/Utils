# Utils
A general utilities library for Delphi projects

## DBF.pas
Provides a DBFReader class to read dBase V files. Memo fields are not supported and will have an UnUssigned-value.

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

## Tokenize.pas
Provides a Tokenizer that splits strings into multiple tokens.

```
  var Tokenizer := TTokenizer.Create(Comma,'1,2,3,4');
  writeln(Tokenizer.Count);
  // List tokens
  for var Token := 0 to Tokenizer.Count-1 do writeln(Tokenizer[Token]);
  // Typecast tokens to integers
  for var Token := 0 to Tokenizer.Count-1 do writeln(Tokenizer.Int[Token]);
```
