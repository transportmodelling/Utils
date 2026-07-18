# Utils
A general utilities library for Delphi projects

## ArrBld.pas
Provides an array builder to easily convert an open array to a dynamic array.

```
  Procedure Test(const Values: array of Float64);
  begin
    var Tst: TArray<Float64> := TArrayBuilder<Float64>.Create(Values);
  end;
```

## ArrHlp.pas
Provides record helpers for `TArray<Integer>`, `TArray<Float64>` and `TArray<String>` that add a `Length` property, constructors, and common query, mutation, sorting and formatting operations. Also provides `TArrayInfo` for inspecting the reference count and length of a dynamic array by pointer.

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

## ArrVal.pas
Provides `TArrayView<T>` and `TArrayValues<T>` records that wrap a `TArray<T>` to restrict what callers can do with it.

- `TArrayView<T>`  --  read-only view: exposes indexed read and `Length`, but prevents any modification of the values or reallocation of the array.
- `TArrayValues<T>`  --  read/write values view: allows indexed read and write, but prevents reallocation of the array.

Convenience type aliases are provided for common element types (e.g. `TFloat64ArrayView`).

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

## BaseDir.pas
Provides `TBaseDirectory`  --  a record that wraps a base directory path and offers path containment checks and relative/absolute path conversion. The path is always stored normalised (fully expanded, with a trailing path delimiter). The record auto-initialises to the current working directory.

```
  var Base := TBaseDirectory.Create('C:\Projects\MyApp');

  // Test whether a path belongs to the base directory
  writeln(Base.Contains('C:\Projects\MyApp\data\file.txt'));  // True

  // Convert an absolute path to a relative one
  writeln(Base.RelativePath('C:\Projects\MyApp\data\file.txt'));  // data\file.txt

  // Convert a relative path to an absolute one
  writeln(Base.AbsolutePath('data\file.txt'));  // C:\Projects\MyApp\data\file.txt
```

## DBF.pas
Provides low-level dBase (.dbf) file reading and writing. Three types are involved:

- `TDBFField`  --  describes a single field: name, type (`C`/`D`/`L`/`N`/`F`), length and decimal count.
- `TDBFReader`  --  opens an existing file and reads its records forward-only; field values can be accessed by index or by name.
- `TDBFWriter`  --  creates a new file from a field schema (or from an existing reader's schema) and appends records one at a time.

Memo fields are not supported (they read back as `Null`).

```
  // Read
  var R := TDBFReader.Create('data.dbf');
  try
    writeln(R.FieldCount);            // number of fields
    while R.NextRecord do
      writeln(R['NAME']);             // field value by name
  finally
    R.Free;
  end;

  // Write
  var Fields: TArray<TDBFField> := [
    TDBFField.Create('ID',   'N', 5, 0),
    TDBFField.Create('NAME', 'C', 30, 0)
  ];
  var W := TDBFWriter.Create('out.dbf', Fields);
  try
    W['ID']   := 1;
    W['NAME'] := 'Alice';
    W.AppendRecord;
  finally
    W.Free;
  end;
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

## FloatHlp.pas
Provides `TFloat64Helper`  --  a record helper for `Float64` that adds rounding, in-place and functional arithmetic, and flexible string formatting.

```
  var V: Float64 := 1234.5678;

  // Banker's rounding
  writeln(V.Round);                           // 1235

  // In-place arithmetic
  V.Add(0.1);
  V.MultiplyBy(2.0);

  // Functional arithmetic (original unchanged)
  var W := V.MultipliedBy(3.0);

  // Format with a fixed number of decimals
  writeln(V.ToString(2, False));              // e.g. '2469.34'

  // Adaptive decimals: fewer decimals for larger integer parts
  writeln(V.ToString(3, False, False));       // '2469.3' (1 fewer decimal for 4-digit integer)
```

## FP16.pas
Provides `Float16`  --  a record representing an IEEE 754 half-precision (16-bit) floating-point number. Supports implicit conversion to and from `Float32`, correctly handling normal values, denormalized values, signed zero, infinity, and NaN.

```
  // Convert Float32 to Float16 and back
  var H: Float16 := Float32(1.0);
  var F: Float32 := H;
  writeln(F);                  // 1.0

  // Inspect the raw 16-bit pattern
  writeln(H.Bytes);            // 15360 ($3C00)

  // Overflow to infinity
  var Big: Float16 := Float32(1.0e10);
  writeln(IsInfinite(Float32(Big)));   // True
```

## Json.Eval.pas
Provides `TJsonEvaluator` -- a stateless record with class methods for navigating a `TJSONValue` tree and extracting strictly typed values (strings, integers, floats, and arrays thereof) from it. Paths are sequences of string keys (for objects) and integer indices (for arrays). All methods return `True` on success and `False` on any navigation or type mismatch, so no exception handling is needed. Any value can also be converted directly to a string, with objects and arrays rendered as serialised JSON.

```
  var Json := TJSONObject.ParseJSONValue(
    '{"user":{"name":"Alice","score":9.5},"tags":["a","b"]}') as TJSONObject;
  try
    var Name: String;
    if TJsonEvaluator.GetStr(Json, ['user', 'name'], Name) then
      writeln(Name);                      // Alice

    var Fields: TArray<TJsonField>;
    TJsonEvaluator.GetFields(Json, ['user'], Fields);
    for var F in Fields do
      writeln(F.Key, ' = ', TJsonEvaluator.AsStr(F.Value));   // name = Alice  score = 9.5

    var Tags: TArray<String>;
    TJsonEvaluator.GetStrs(Json, ['tags'], Tags);
    writeln(Tags[0]);                     // a
  finally
    Json.Free;
  end;
```
## Json.ObjArr.pas
Provides `TJsonObjectArrayParser`  --  a lightweight streaming parser that iterates over the top-level objects of a JSON array without loading the entire document into memory. Each call to `Next` returns the raw JSON text of the next object; `EndOfArray` signals when no more objects remain. Key names can be normalised to lowercase or uppercase on the fly.

```
  // Parse from a string
  var P := TJsonObjectArrayParser.Create('[{"Name":"Alice","Age":30},{"Name":"Bob","Age":25}]');
  try
    while not P.EndOfArray do
      writeln(P.Next(ctLowercase));   // prints each object with lower-cased keys
  finally
    P.Free;
  end;

  // Parse from a file
  var Base: TBaseDirectory;
  Base.SetExeDir;
  var P2 := TJsonObjectArrayParser.Create(Base.AbsolutePath('data.json'));
  try
    while not P2.EndOfArray do
      writeln(P2.Next(ctAsIs));
  finally
    P2.Free;
  end;
```

## KeyVal.pas
Provides `TKeyValuePairsHelper`  --  a record helper for `TKeyValuePairs` (an alias for `TArray<TPair<String,String>>`) that turns it into an ordered list of string key-value pairs with construction, mutation, querying and serialization support. Keys are matched case-insensitively, duplicate keys are allowed, and the list can be parsed from and serialized to a delimited string with configurable separators. Conversion from and to a `TDictionary<String,String>` is also supported.

```
  var KV: TKeyValuePairs;
  KV.Append('host', 'localhost');
  KV.Append('port', '5432');
  KV.Append('port', '5433');        // duplicate key allowed

  writeln(KV.Str('host'));          // localhost
  writeln(KV.Int('port'));          // 5432
  writeln(KV.Int('port', 1));       // 5433  (second occurrence)
  writeln(KV.AsString);             // host: localhost; port: 5432; port: 5433

  // Parse from a string
  var KV2: TKeyValuePairs;
  KV2 := TKeyValuePairs.Create('x=1,y=2,z=3', '=', ',');
  writeln(KV2.Float('y'));          // 2.0
```

## MemDBF.pas
Provides `TMemDBF`  --  loads a `.dbf` file into a `TFDMemTable` for in-memory editing using the full FireDAC dataset API, then writes it back out via `DBF.pas`. Requires FireDAC.

Two constructors:
- `Create(FileName)`  --  creates and owns an internal `TFDMemTable`.
- `Create(FileName, Table)`  --  populates a caller-supplied `TFDMemTable`; the caller retains ownership and must free it.

```
  var M := TMemDBF.Create('data.dbf');
  try
    // Edit in memory using the standard TFDMemTable API
    M.Table.First;
    M.Table.Edit;
    M.Table.FieldByName('NAME').AsString := 'Modified';
    M.Table.Post;

    M.Save;                        // overwrite original file
    M.SaveAs('data_copy.dbf');     // write to a new file
  finally
    M.Free;
  end;
```

## ObjRef.pas
Provides `TReference<T>`  --  a smart-pointer helper that wraps any class instance in a reference-counted `TFunc<T>`. The wrapped object is automatically freed when the last reference goes out of scope, eliminating the need for a manual `Free` call.

```
  var Obj: TFunc<TStringList> := TReference<TStringList>.Create(TStringList.Create);
  Obj().Add('hello');        // access the object via Obj()
  writeln(Obj().Count);      // 1
  // Obj goes out of scope here -> TStringList is freed automatically
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
Provides `TPolynomial`  --  a record representing a polynomial with `Float64` coefficients. The degree is tracked automatically and leading zero coefficients are stripped. Supports construction from a constant or a coefficients array (constant term first), evaluation, arithmetic operators, and calculus: differentiation, anti-differentiation, and definite integration.

```
  var P: TPolynomial := [1.0, 0.0, 2.0];   // 1 + 2x^2
  writeln(P[3.0]);                         // 19
  writeln(P.Derivative[3.0]);              // 12  (derivative is 4x)
  writeln(P.Integrate(0, 1));              // 1.6666...  (primitive is x + 2x^3/3)
```

## PropSet.pas
Provides a property set, implemented as a set of name-value pairs.

```
  var Properties := TPropertySet.Create('Property1=Value1; Property2=Value2');
  writeln(Properties['Property1']);
  Properties := 'Property3=Value3; Property4=Value4';
  writeln(Properties['Property3']);
```

## Ranges.pas
Provides `TRange` and `TRanges` for working with inclusive integer ranges.

- `TRange`  --  a single inclusive range `[Min..Max]` that can be queried, enumerated, and split into sub-ranges.
- `TRanges`  --  a collection of ranges that can be parsed from and converted back to a string such as `'1,3-5,7'`.

```
  // Single range
  var R := TRange.Create(2, 5);
  writeln(R.Count);           // 4
  writeln(R.Contains(3));     // True

  // Split into sub-ranges
  for var Part in R.Split(2) do writeln(Part.Min, '-', Part.Max);  // 2-3, 4-5

  // Collection of ranges, parsed from string
  var RS := TRanges.Create('1,3-5,7');
  writeln(RS.Count);          // 3
  writeln(RS.Contains(4));    // True
  writeln(String(RS));        // '1,3-5,7'
```

## Spline.pas
Provides `TSpline`  --  a record representing a piecewise polynomial (spline) defined by an ordered sequence of knots and a polynomial for each interval between them. Supports:

- **Construction** from a knots array (N+1 values) and a polynomials array (N pieces); the two must be consistent in length.
- **Multiplication** of two splines: the `*` operator produces a new spline whose domain is the intersection of the two operands' domains, with piece boundaries merged and each resulting piece being the product of the corresponding polynomials.
- **Integration** over the full domain (`Integrate`) or over a sub-interval (`Integrate(a, b)`), summing the definite integrals of each covered piece.

## TxtTab.pas
Provides `TTextTableReader`  --  a forward-only reader for tab-delimited (or custom-delimited) text files with a header row. The first row is read automatically as field names; each subsequent call to `ReadLine` advances to the next data row and returns `False` when the file is exhausted.

```
  var Reader := TTextTableReader.Create('data.txt');
  try
    writeln(Reader.FieldCount);                    // number of columns
    writeln(Reader.Names[0]);                      // first column name

    // Look up a column index (case-insensitive by default)
    var AgeIdx := Reader.IndexOf('age', {MustExist=}True);

    while Reader.ReadLine do
    begin
      writeln(Reader[0].Value);                    // string value of first column
      writeln(Reader[AgeIdx].AsInteger);           // integer value of 'age' column
    end;

    writeln(Reader.LineCount);                     // number of data rows read
  finally
    Reader.Free;
  end;
```

## ThrdLib.pas
Provides a structured thread-management and parallel-iteration library built on top of `TThread`.

- **`TGuardedThread`**  --  abstract base for managed threads; unhandled exceptions are captured and forwarded to the owning guard rather than crashing the process.
- **`TThreadsGuard<T>`**  --  starts batches of `TGuardedThread` descendants, waits for their completion, and collects the first error raised by any thread. A global instance `ThreadsGuard` is created at unit initialization.
- **`TBlockingThreadsGuard<T>`**  --  a `TThreadsGuard<T>` that refuses a new batch until the previous batch has finished, and can terminate all running threads.
- **`TThreadedIterator`**  --  base class implementing the reusable worker-thread pool that the classes below are built on.
- **`TParallelFor`**  --  parallel for loop with a configurable thread-pool size. Each iteration receives both the iteration index and the zero-based thread-pool index, allowing per-thread accumulation buffers that avoid `TInterlocked`.
- **`TParallel`**  --  executes a list of tasks in parallel on the thread pool, each task receiving the thread-pool index. (Unrelated to the PPL's `System.Threading.TParallel`.)

```
  // Sum primes in parallel, one accumulator slot per thread
  var ParallelFor := TParallelFor.Create(4);
  try
    var NPrimes: array[0..3] of Integer;
    ParallelFor.Execute(2, Max,
      procedure(I, Thread: Integer)
      begin
        if IsPrime(I) then Inc(NPrimes[Thread]);
      end);
    var Total := NPrimes[0] + NPrimes[1] + NPrimes[2] + NPrimes[3];
    writeln(Total);
  finally
    ParallelFor.Free;
  end;

  // Run a list of distinct tasks in parallel
  var Parallel := TParallel.Create(4);
  try
    Parallel.Execute([
      procedure(Thread: Integer) begin LoadZones end,
      procedure(Thread: Integer) begin LoadNetwork end,
      procedure(Thread: Integer) begin LoadMatrices end
    ]);
  finally
    Parallel.Free;
  end;

  // Use the global guard to fire-and-forget a batch of threads
  var Msg: string;
  ThreadsGuard.StartThreads([TMyThread.Create, TMyThread.Create]);
  ThreadsGuard.WaitFor;
  if ThreadsGuard.Error(Msg) then writeln('Error: ', Msg);
```

## Yaml.pas
Provides `TYaml`  --  a record with class methods that parse a YAML document (from a string, a `TStrings`, or a file) into a `TJSONValue` tree. The `...Object` methods expect a mapping root and return a `TJsonObject`; the `...Value` methods accept any root, including bare sequences and scalars. Multi-document streams are supported via a 0-based document index. Anchors/aliases and multi-line flow collections are not supported.

```
  // Read a YAML file into a JSON object
  var Config := TYaml.ReadFromFile('config.yaml');
  try
    writeln(Config.GetValue('host').Value);          // e.g. 'localhost'
    writeln((Config.GetValue('port') as TJSONNumber).AsInt);  // e.g. 5432
  finally
    Config.Free;
  end;

  // Parse a multi-document stream  --  select the second document
  var Doc := TYaml.ReadFromFile('data.yaml', 1);
  try
    writeln(Doc.GetValue('Name').Value);
  finally
    Doc.Free;
  end;
```
