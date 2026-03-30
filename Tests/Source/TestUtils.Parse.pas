unit TestUtils.Parse;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Classes, DUnitX.TestFramework, Parse, BaseDir;

Type
  [TestFixture]
  TTokenTests = class
  public
    // Value property and implicit conversions
    [Test] procedure TestImplicitToString;
    [Test] procedure TestImplicitToInteger;
    [Test] procedure TestImplicitToInt64;
    [Test] procedure TestImplicitToFloat64;
    // Methods
    [Test] procedure TestToChar;
    [Test] procedure TestToCharMultiCharRaises;
    [Test] procedure TestToInt;
    [Test] procedure TestToFloat;
    [Test] procedure TestRound;
  end;

  [TestFixture]
  TDelimiterHelperTests = class
  public
    [Test] procedure TestDelimiterChar_Comma;
    [Test] procedure TestDelimiterChar_Tab;
    [Test] procedure TestDelimiterChar_Semicolon;
    [Test] procedure TestDelimiterChar_Space;
    [Test] procedure TestToString_Comma;
    [Test] procedure TestToString_Tab;
    [Test] procedure TestToString_Semicolon;
    [Test] procedure TestToString_Space;
    [Test] procedure TestCreateFromString_Valid;
    [Test] procedure TestCreateFromString_Invalid;
  end;

  [TestFixture]
  TStringParserTests = class
  public
    // Count and basic parsing
    [Test] procedure TestCountCommaDelimited;
    [Test] procedure TestCountTabDelimited;
    [Test] procedure TestCountSemicolonDelimited;
    [Test] procedure TestCountSpaceDelimited;
    [Test] procedure TestCountEmpty;
    // Indexed token access
    [Test] procedure TestIndexedTokenValue;
    [Test] procedure TestStrProperty;
    [Test] procedure TestIntProperty;
    [Test] procedure TestFloatProperty;
    [Test] procedure TestCharProperty;
    // Sequential getters (advance cursor)
    [Test] procedure TestGetStrAdvancesCursor;
    [Test] procedure TestGetIntAdvancesCursor;
    [Test] procedure TestGetFloatAdvancesCursor;
    [Test] procedure TestGetStrPastEndRaises;
    // Token cursor
    [Test] procedure TestTokenCursorSet;
    [Test] procedure TestTokenCursorOutOfRangeRaises;
    // ExcludeEmpty
    [Test] procedure TestExcludeEmptyFalse;
    [Test] procedure TestExcludeEmptyTrue;
    // RemoveTrailingEmpties
    [Test] procedure TestRemoveTrailingEmpties;
    // TrimTokens
    [Test] procedure TestTrimTokens;
    // Extract
    [Test] procedure TestExtractByIndex;
    [Test] procedure TestExtractByString;
    [Test] procedure TestExtractNotFound;
    // Clear
    [Test] procedure TestClear;
    // Assign with quote
    [Test] procedure TestAssignWithQuote;
    // IndexOf
    [Test] procedure TestIndexOfFound;
    [Test] procedure TestIndexOfNotFound;
    [Test] procedure TestIndexOfWithOffset;
    // ToStrArray
    [Test] procedure TestToStrArray;
    [Test] procedure TestToStrArraySlice;
    // ToIntArray
    [Test] procedure TestToIntArray;
    [Test] procedure TestToIntArraySlice;
    // ToFloatArray
    [Test] procedure TestToFloatArray;
    // TryToInt / TryToFloat
    [Test] procedure TestTryToIntSuccess;
    [Test] procedure TestTryToIntFail;
    [Test] procedure TestTryToFloatSuccess;
    [Test] procedure TestTryToFloatFail;
    // TryToFloatArray
    [Test] procedure TestTryToFloatArraySuccess;
    [Test] procedure TestTryToFloatArrayFail;
    // TrySum
    [Test] procedure TestTrySumSuccess;
    [Test] procedure TestTrySumFail;
    // AssignTo
    [Test] procedure TestAssignToIntArray;
    [Test] procedure TestAssignToFloatArray;
    // ReadLine
    [Test] procedure TestReadLine_SkipHeaderReadRow;
    [Test] procedure TestReadLine_AllDataRows;
    [Test] procedure TestReadLineWithQuote;
  end;

  [TestFixture]
  TFixedWidthParserTests = class
  public
    [Test] procedure TestCount;
    [Test] procedure TestTokenValues;
    [Test] procedure TestIntProperty;
    [Test] procedure TestFloatProperty;
    [Test] procedure TestAssignShorterThanWidths;
    [Test] procedure TestReadLine;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

const
  Eps = 1e-10;

// Helper: build a TToken with a given string value via TStringParser
function MakeToken(const S: String): TToken;
begin
  var P := TStringParser.Create(Comma, S + ',dummy');
  Result := P[0];
end;

////////////////////////////////////////////////////////////////////////////////
// TTokenTests
////////////////////////////////////////////////////////////////////////////////

procedure TTokenTests.TestImplicitToString;
begin
  var T := MakeToken('hello');
  var S: String := T;
  Assert.AreEqual('hello', S);
end;

procedure TTokenTests.TestImplicitToInteger;
begin
  var T := MakeToken('42');
  var I: Integer := T;
  Assert.AreEqual(42, I);
end;

procedure TTokenTests.TestImplicitToInt64;
begin
  var T := MakeToken('9876543210');
  var I: Int64 := T;
  Assert.AreEqual(Int64(9876543210), I);
end;

procedure TTokenTests.TestImplicitToFloat64;
begin
  var T := MakeToken('3.14');
  var F: Float64 := T;
  Assert.AreEqual(3.14, F, Eps);
end;

procedure TTokenTests.TestToChar;
begin
  var T := MakeToken('X');
  Assert.AreEqual('X', T.ToChar);
end;

procedure TTokenTests.TestToCharMultiCharRaises;
begin
  var T := MakeToken('AB');
  Assert.WillRaiseAny(procedure begin T.ToChar; end);
end;

procedure TTokenTests.TestToInt;
begin
  var T := MakeToken('7');
  Assert.AreEqual(7, T.ToInt);
end;

procedure TTokenTests.TestToFloat;
begin
  var T := MakeToken('2.5');
  Assert.AreEqual(2.5, T.ToFloat, Eps);
end;

procedure TTokenTests.TestRound;
begin
  var T := MakeToken('2.7');
  Assert.AreEqual(3, T.Round);
end;

////////////////////////////////////////////////////////////////////////////////
// TDelimiterHelperTests
////////////////////////////////////////////////////////////////////////////////

procedure TDelimiterHelperTests.TestDelimiterChar_Comma;
begin
  Assert.AreEqual(',', Comma.Delimiter);
end;

procedure TDelimiterHelperTests.TestDelimiterChar_Tab;
begin
  Assert.AreEqual(#9, Tab.Delimiter);
end;

procedure TDelimiterHelperTests.TestDelimiterChar_Semicolon;
begin
  Assert.AreEqual(';', Semicolon.Delimiter);
end;

procedure TDelimiterHelperTests.TestDelimiterChar_Space;
begin
  Assert.AreEqual(' ', Space.Delimiter);
end;

procedure TDelimiterHelperTests.TestToString_Comma;
begin
  Assert.AreEqual('comma', Comma.ToString);
end;

procedure TDelimiterHelperTests.TestToString_Tab;
begin
  Assert.AreEqual('tab', Tab.ToString);
end;

procedure TDelimiterHelperTests.TestToString_Semicolon;
begin
  Assert.AreEqual('semicolon', Semicolon.ToString);
end;

procedure TDelimiterHelperTests.TestToString_Space;
begin
  Assert.AreEqual('space', Space.ToString);
end;

procedure TDelimiterHelperTests.TestCreateFromString_Valid;
begin
  var D := TDelimiter.Create('comma');
  Assert.IsTrue(D = Comma);
  D := TDelimiter.Create('TAB');   // case-insensitive
  Assert.IsTrue(D = Tab);
end;

procedure TDelimiterHelperTests.TestCreateFromString_Invalid;
begin
  var Raised := false;
  try
    TDelimiter.Create('pipe');
  except
    Raised := true;
  end;
  Assert.IsTrue(Raised);
end;

////////////////////////////////////////////////////////////////////////////////
// TStringParserTests
////////////////////////////////////////////////////////////////////////////////

procedure TStringParserTests.TestCountCommaDelimited;
begin
  var P := TStringParser.Create(Comma, '1,2,3,4');
  Assert.AreEqual(4, P.Count);
end;

procedure TStringParserTests.TestCountTabDelimited;
begin
  var P := TStringParser.Create(Tab, 'a'#9'b'#9'c');
  Assert.AreEqual(3, P.Count);
end;

procedure TStringParserTests.TestCountSemicolonDelimited;
begin
  var P := TStringParser.Create(Semicolon, 'x;y');
  Assert.AreEqual(2, P.Count);
end;

procedure TStringParserTests.TestCountSpaceDelimited;
begin
  // Space delimiter uses ExcludeEmpty so multiple spaces count as one separator
  var P := TStringParser.Create(Space, 'a  b  c');
  Assert.AreEqual(3, P.Count);
end;

procedure TStringParserTests.TestCountEmpty;
begin
  var P := TStringParser.Create(Comma, '');
  // Delphi String.Split on '' returns an empty array, not ['']
  Assert.AreEqual(0, P.Count);
end;

procedure TStringParserTests.TestIndexedTokenValue;
begin
  var P := TStringParser.Create(Comma, 'alpha,beta,gamma');
  Assert.AreEqual('alpha', P[0].Value);
  Assert.AreEqual('beta',  P[1].Value);
  Assert.AreEqual('gamma', P[2].Value);
end;

procedure TStringParserTests.TestStrProperty;
begin
  var P := TStringParser.Create(Comma, 'hello,world');
  Assert.AreEqual('hello', P.Str[0]);
  Assert.AreEqual('world', P.Str[1]);
end;

procedure TStringParserTests.TestIntProperty;
begin
  var P := TStringParser.Create(Comma, '10,20,30');
  Assert.AreEqual(10, P.Int[0]);
  Assert.AreEqual(20, P.Int[1]);
  Assert.AreEqual(30, P.Int[2]);
end;

procedure TStringParserTests.TestFloatProperty;
begin
  var P := TStringParser.Create(Comma, '1.5,2.5');
  Assert.AreEqual(1.5, P.Float[0], Eps);
  Assert.AreEqual(2.5, P.Float[1], Eps);
end;

procedure TStringParserTests.TestCharProperty;
begin
  var P := TStringParser.Create(Comma, 'A,B,C');
  Assert.AreEqual('A', P.Char[0]);
  Assert.AreEqual('B', P.Char[1]);
end;

procedure TStringParserTests.TestGetStrAdvancesCursor;
begin
  var P := TStringParser.Create(Comma, 'one,two,three');
  Assert.AreEqual('one',   P.GetStr);
  Assert.AreEqual('two',   P.GetStr);
  Assert.AreEqual('three', P.GetStr);
end;

procedure TStringParserTests.TestGetIntAdvancesCursor;
begin
  var P := TStringParser.Create(Comma, '1,2,3');
  Assert.AreEqual(1, P.GetInt);
  Assert.AreEqual(2, P.GetInt);
  Assert.AreEqual(3, P.GetInt);
end;

procedure TStringParserTests.TestGetFloatAdvancesCursor;
begin
  var P := TStringParser.Create(Comma, '0.1,0.2');
  Assert.AreEqual(0.1, P.GetFloat, Eps);
  Assert.AreEqual(0.2, P.GetFloat, Eps);
end;

procedure TStringParserTests.TestGetStrPastEndRaises;
begin
  var P := TStringParser.Create(Comma, 'only');
  P.GetStr; // consumes the one token
  var Raised := false;
  try P.GetStr; except Raised := true; end;
  Assert.IsTrue(Raised);
end;

procedure TStringParserTests.TestTokenCursorSet;
begin
  var P := TStringParser.Create(Comma, 'a,b,c');
  P.Token := 2;
  Assert.AreEqual('c', P.GetStr);
end;

procedure TStringParserTests.TestTokenCursorOutOfRangeRaises;
begin
  var P := TStringParser.Create(Comma, 'a,b');
  var Raised := false;
  try P.Token := 5; except Raised := true; end;
  Assert.IsTrue(Raised);
end;

procedure TStringParserTests.TestExcludeEmptyFalse;
begin
  // CSV keeps empty tokens
  var P := TStringParser.Create(Comma, 'a,,b');
  Assert.AreEqual(3, P.Count);
  Assert.AreEqual('', P.Str[1]);
end;

procedure TStringParserTests.TestExcludeEmptyTrue;
begin
  // Space delimiter excludes empty tokens by default
  var P := TStringParser.Create(Space, '  a  b  ');
  Assert.AreEqual(2, P.Count);
  Assert.AreEqual('a', P.Str[0]);
  Assert.AreEqual('b', P.Str[1]);
end;

procedure TStringParserTests.TestRemoveTrailingEmpties;
begin
  var P := TStringParser.Create(Comma, 'a,b,,');
  Assert.AreEqual(4, P.Count);
  P.RemoveTrailingEmpties;
  Assert.AreEqual(2, P.Count);
  Assert.AreEqual('a', P.Str[0]);
  Assert.AreEqual('b', P.Str[1]);
end;

procedure TStringParserTests.TestTrimTokens;
begin
  var P := TStringParser.Create(Comma, ' hello , world ');
  P.TrimTokens;
  Assert.AreEqual('hello', P.Str[0]);
  Assert.AreEqual('world', P.Str[1]);
end;

procedure TStringParserTests.TestExtractByIndex;
begin
  var P := TStringParser.Create(Comma, 'a,b,c');
  var V := P.Extract(1);
  Assert.AreEqual('b', V);
  Assert.AreEqual(2, P.Count);
  Assert.AreEqual('a', P.Str[0]);
  Assert.AreEqual('c', P.Str[1]);
end;

procedure TStringParserTests.TestExtractByString;
begin
  var P := TStringParser.Create(Comma, 'a,b,c');
  var Idx := P.Extract('b');
  Assert.AreEqual(1, Idx);
  Assert.AreEqual(2, P.Count);
end;

procedure TStringParserTests.TestExtractNotFound;
begin
  // Extract of a non-existent token returns -1 and leaves count unchanged
  var P := TStringParser.Create(Comma, 'a,b,c');
  var Idx := P.Extract('z');
  Assert.AreEqual(-1, Idx);
  Assert.AreEqual(3, P.Count);
end;

procedure TStringParserTests.TestClear;
begin
  var P := TStringParser.Create(Comma, '1,2,3');
  P.Clear;
  Assert.AreEqual(0, P.Count);
end;

procedure TStringParserTests.TestAssignWithQuote;
begin
  // Delphi's String.Split with a quote char groups tokens but does NOT strip
  // the surrounding quote characters from the token value
  var P := TStringParser.Create(Comma);
  P.Assign('"hello, world",foo', '"');
  Assert.AreEqual(2, P.Count);
  Assert.AreEqual('"hello, world"', P.Str[0]);
  Assert.AreEqual('foo',            P.Str[1]);
end;

procedure TStringParserTests.TestIndexOfFound;
begin
  var P := TStringParser.Create(Comma, 'alpha,beta,gamma');
  Assert.AreEqual(1, P.IndexOf('beta'));
end;

procedure TStringParserTests.TestIndexOfNotFound;
begin
  var P := TStringParser.Create(Comma, 'alpha,beta');
  Assert.AreEqual(-1, P.IndexOf('delta'));
end;

procedure TStringParserTests.TestIndexOfWithOffset;
begin
  var P := TStringParser.Create(Comma, 'a,b,a,c');
  // Without offset finds first occurrence
  Assert.AreEqual(0, P.IndexOf('a'));
  // With offset skips first
  Assert.AreEqual(2, P.IndexOf('a', 1));
end;

procedure TStringParserTests.TestToStrArray;
begin
  var P := TStringParser.Create(Comma, 'x,y,z');
  var A := P.ToStrArray;
  Assert.AreEqual(3, Integer(System.Length(A)));
  Assert.AreEqual('x', A[0]);
  Assert.AreEqual('y', A[1]);
  Assert.AreEqual('z', A[2]);
end;

procedure TStringParserTests.TestToStrArraySlice;
begin
  var P := TStringParser.Create(Comma, 'a,b,c,d');
  var A := P.ToStrArray(1, 2);
  Assert.AreEqual(2, Integer(System.Length(A)));
  Assert.AreEqual('b', A[0]);
  Assert.AreEqual('c', A[1]);
end;

procedure TStringParserTests.TestToIntArray;
begin
  var P := TStringParser.Create(Comma, '10,20,30');
  var A := P.ToIntArray;
  Assert.AreEqual(3, Integer(System.Length(A)));
  Assert.AreEqual(10, A[0]);
  Assert.AreEqual(20, A[1]);
  Assert.AreEqual(30, A[2]);
end;

procedure TStringParserTests.TestToIntArraySlice;
begin
  var P := TStringParser.Create(Comma, '1,2,3,4');
  var A := P.ToIntArray(1, 2);
  Assert.AreEqual(2, Integer(System.Length(A)));
  Assert.AreEqual(2, A[0]);
  Assert.AreEqual(3, A[1]);
end;

procedure TStringParserTests.TestToFloatArray;
begin
  var P := TStringParser.Create(Comma, '1.1,2.2,3.3');
  var A := P.ToFloatArray;
  Assert.AreEqual(3, Integer(System.Length(A)));
  Assert.AreEqual(1.1, A[0], Eps);
  Assert.AreEqual(2.2, A[1], Eps);
  Assert.AreEqual(3.3, A[2], Eps);
end;

procedure TStringParserTests.TestTryToIntSuccess;
begin
  var P := TStringParser.Create(Comma, '5,abc');
  var V: Integer;
  Assert.IsTrue(P.TryToInt(0, V));
  Assert.AreEqual(5, V);
end;

procedure TStringParserTests.TestTryToIntFail;
begin
  var P := TStringParser.Create(Comma, '5,abc');
  var V: Integer;
  Assert.IsFalse(P.TryToInt(1, V));
end;

procedure TStringParserTests.TestTryToFloatSuccess;
begin
  var P := TStringParser.Create(Comma, '3.14,bad');
  var V: Float64;
  Assert.IsTrue(P.TryToFloat(0, V));
  Assert.AreEqual(3.14, V, Eps);
end;

procedure TStringParserTests.TestTryToFloatFail;
begin
  var P := TStringParser.Create(Comma, '3.14,bad');
  var V: Float64;
  Assert.IsFalse(P.TryToFloat(1, V));
end;

procedure TStringParserTests.TestTryToFloatArraySuccess;
begin
  var P := TStringParser.Create(Comma, '1.0,2.0,3.0');
  var A: TArray<Float64>;
  Assert.IsTrue(P.TryToFloatArray(A));
  Assert.AreEqual(3, Integer(System.Length(A)));
  Assert.AreEqual(2.0, A[1], Eps);
end;

procedure TStringParserTests.TestTryToFloatArrayFail;
begin
  var P := TStringParser.Create(Comma, '1.0,oops,3.0');
  var A: TArray<Float64>;
  Assert.IsFalse(P.TryToFloatArray(A));
end;

procedure TStringParserTests.TestTrySumSuccess;
begin
  var P := TStringParser.Create(Comma, '1.0,2.0,3.0');
  var S: Float64;
  Assert.IsTrue(P.TrySum(S));
  Assert.AreEqual(6.0, S, Eps);
end;

procedure TStringParserTests.TestTrySumFail;
begin
  var P := TStringParser.Create(Comma, '1.0,bad,3.0');
  var S: Float64;
  Assert.IsFalse(P.TrySum(S));
end;

procedure TStringParserTests.TestAssignToIntArray;
begin
  var P := TStringParser.Create(Comma, '10,20,30,40');
  var A: array[0..1] of Integer;
  P.AssignTo(A, 1);  // start from token 1
  Assert.AreEqual(20, A[0]);
  Assert.AreEqual(30, A[1]);
end;

procedure TStringParserTests.TestAssignToFloatArray;
begin
  var P := TStringParser.Create(Comma, '1.0,2.0,3.0');
  var A: array[0..2] of Float64;
  P.AssignTo(A);
  Assert.AreEqual(1.0, A[0], Eps);
  Assert.AreEqual(2.0, A[1], Eps);
  Assert.AreEqual(3.0, A[2], Eps);
end;

// sample.txt layout (tab-delimited, 4 lines):
//   Name  Age  Score
//   Alice  30  8.5
//   Bob    25  7.0
//   Carol  42  9.1

procedure TStringParserTests.TestReadLine_SkipHeaderReadRow;
begin
  var BaseDir := TBaseDirectory.Create(true);
  var Reader := TStreamReader.Create(BaseDir.AbsolutePath('..\Data\sample.txt'), TEncoding.ASCII);
  try
    var P := TStringParser.Create(Tab);
    P.ReadLine(Reader); // skip header
    P.ReadLine(Reader); // Alice row
    Assert.AreEqual('Alice', P.Str[0]);
    Assert.AreEqual(30,      P.Int[1]);
    Assert.AreEqual(8.5,     P.Float[2], Eps);
  finally
    Reader.Free;
  end;
end;

procedure TStringParserTests.TestReadLine_AllDataRows;
begin
  var BaseDir := TBaseDirectory.Create(true);
  var Reader := TStreamReader.Create(BaseDir.AbsolutePath('..\Data\sample.txt'), TEncoding.ASCII);
  try
    var P := TStringParser.Create(Tab);
    P.ReadLine(Reader); // skip header
    var Names: array[0..2] of String;
    for var I := 0 to 2 do
    begin
      P.ReadLine(Reader);
      Names[I] := P.Str[0];
    end;
    Assert.AreEqual('Alice', Names[0]);
    Assert.AreEqual('Bob',   Names[1]);
    Assert.AreEqual('Carol', Names[2]);
  finally
    Reader.Free;
  end;
end;

procedure TStringParserTests.TestReadLineWithQuote;
begin
  // In-memory CSV with a quoted field containing a comma
  var Csv := '"Smith, John",42'#13#10'"Doe, Jane",35';
  var Reader := TStringReader.Create(Csv);
  try
    var P := TStringParser.Create(Comma);
    P.ReadLine(Reader, '"');
    // Delphi's Split retains quote chars in token values
    Assert.AreEqual(2,               P.Count);
    Assert.AreEqual('"Smith, John"', P.Str[0]);
    Assert.AreEqual('42',            P.Str[1]);
    P.ReadLine(Reader, '"');
    Assert.AreEqual('"Doe, Jane"', P.Str[0]);
    Assert.AreEqual('35',          P.Str[1]);
  finally
    Reader.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// TFixedWidthParserTests
////////////////////////////////////////////////////////////////////////////////

procedure TFixedWidthParserTests.TestCount;
begin
  // Count reflects parsed token count; must Assign a line first
  var P := TFixedWidthParser.Create([3, 4, 5]);
  P.Assign('123456789012');
  Assert.AreEqual(3, P.Count);
end;

procedure TFixedWidthParserTests.TestTokenValues;
begin
  // '123456789012' split as widths 3,4,5 => '123','4567','89012'
  var P := TFixedWidthParser.Create([3, 4, 5]);
  P.Assign('123456789012');
  Assert.AreEqual('123',   P[0].Value);
  Assert.AreEqual('4567',  P[1].Value);
  Assert.AreEqual('89012', P[2].Value);
end;

procedure TFixedWidthParserTests.TestIntProperty;
begin
  // Integers with leading spaces — Int[] trims before converting
  var P := TFixedWidthParser.Create([4, 4]);
  P.Assign('  42  99');
  Assert.AreEqual(42, P.Int[0]);
  Assert.AreEqual(99, P.Int[1]);
end;

procedure TFixedWidthParserTests.TestFloatProperty;
begin
  var P := TFixedWidthParser.Create([5, 5]);
  P.Assign(' 1.50 2.75');
  Assert.AreEqual(1.5,  P.Float[0], Eps);
  Assert.AreEqual(2.75, P.Float[1], Eps);
end;

procedure TFixedWidthParserTests.TestAssignShorterThanWidths;
begin
  // When the line is shorter than the sum of widths, Copy() returns what is
  // available — no exception, tokens just get truncated content
  var P := TFixedWidthParser.Create([5, 5]);
  P.Assign('abc');   // only 3 chars
  Assert.AreEqual('abc', P[0].Value);
  Assert.AreEqual('',    P[1].Value);
end;

procedure TFixedWidthParserTests.TestReadLine;
begin
  // Two fixed-width records: widths 5, 3, 4
  var Data := 'Alice030 8.5'#13#10'Bob  025 7.0 ';
  var Reader := TStringReader.Create(Data);
  try
    var P := TFixedWidthParser.Create([5, 3, 4]);
    P.ReadLine(Reader);
    Assert.AreEqual('Alice', P[0].Value);
    Assert.AreEqual(30,      P.Int[1]);
    Assert.AreEqual(8.5,     P.Float[2], Eps);
    P.ReadLine(Reader);
    Assert.AreEqual('Bob  ', P[0].Value);
    Assert.AreEqual(25,      P.Int[1]);
  finally
    Reader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTokenTests);
  TDUnitX.RegisterTestFixture(TDelimiterHelperTests);
  TDUnitX.RegisterTestFixture(TStringParserTests);
  TDUnitX.RegisterTestFixture(TFixedWidthParserTests);

end.
