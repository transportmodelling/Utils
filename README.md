# Utils
A general utilities library for Delphi projects

## DBF.pas
Provides a DBFReader class to read dBase V files. Memo fields are not supported and will have an UnUssigned-value.

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

