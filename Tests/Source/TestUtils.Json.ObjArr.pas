unit TestUtils.Json.ObjArr;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Classes, DUnitX.TestFramework, BaseDir, Json.ObjArr;

Type
  [TestFixture]
  TJsonObjectArrayParserTests = class
  public
    // Empty array sets EndOfArray immediately
    [Test] procedure TestEmptyArray;
    // Single object: returns it and sets EndOfArray
    [Test] procedure TestSingleObject;
    // Multiple objects: returns each in order
    [Test] procedure TestMultipleObjects;
    // Reading past EndOfArray raises an exception
    [Test] procedure TestReadPastEndRaises;
    // Whitespace (spaces, newlines) around brackets and objects is tolerated
    [Test] procedure TestWhitespaceTolerance;
    // NameCase ctLowercase lowercases key names
    [Test] procedure TestNameCaseLowercase;
    // NameCase ctUppercase uppercases key names
    [Test] procedure TestNameCaseUppercase;
    // NameCase ctAsIs preserves key names unchanged
    [Test] procedure TestNameCaseAsIs;
    // Nested object as a value is returned intact
    [Test] procedure TestNestedObject;
    // Nested array as a value is returned intact
    [Test] procedure TestNestedArray;
    // Missing opening '[' raises an exception
    [Test] procedure TestInvalidArrayStart;
    // A colon inside a string value should NOT flip Name to false
    [Test] procedure TestColonInStringValue;
    // A double-backslash followed by quote should end the string (ctAsIs)
    [Test] procedure TestDoubleBackslashEscape;
    // A double-backslash in a value must not cause trailing value chars to be
    // cased as key names when using ctUppercase
    [Test] procedure TestDoubleBackslashEscapeWithCase;
    // Read three objects from sample.json fixture file (TFileName overload)
    [Test] procedure TestFromFile;
    // Read three objects from sample.json fixture file (TStream overload)
    [Test] procedure TestFromFileStream;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

procedure TJsonObjectArrayParserTests.TestEmptyArray;
begin
  var P := TJsonObjectArrayParser.Create('[]');
  try
    Assert.IsTrue(P.EndOfArray);
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestSingleObject;
begin
  var P := TJsonObjectArrayParser.Create('[{"a":1}]');
  try
    Assert.IsFalse(P.EndOfArray);
    var S := P.Next;
    Assert.AreEqual('{"a":1}', S);
    Assert.IsTrue(P.EndOfArray);
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestMultipleObjects;
begin
  var P := TJsonObjectArrayParser.Create('[{"a":1},{"b":2},{"c":3}]');
  try
    Assert.AreEqual('{"a":1}', P.Next);
    Assert.AreEqual('{"b":2}', P.Next);
    Assert.AreEqual('{"c":3}', P.Next);
    Assert.IsTrue(P.EndOfArray);
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestReadPastEndRaises;
begin
  var P := TJsonObjectArrayParser.Create('[{"a":1}]');
  try
    P.Next;
    Assert.IsTrue(P.EndOfArray);
    Assert.WillRaiseAny(procedure begin P.Next; end);
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestWhitespaceTolerance;
begin
  var Json := '''
    [
      { "x" : 1 }
      ,
      { "y" : 2 }
    ]
    ''';
  var P := TJsonObjectArrayParser.Create(Json);
  try
    var S1 := P.Next;
    var S2 := P.Next;
    Assert.IsTrue(P.EndOfArray);
    Assert.IsTrue(S1.Contains('"x"'), 'First object should contain key x');
    Assert.IsTrue(S2.Contains('"y"'), 'Second object should contain key y');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestNameCaseLowercase;
begin
  var P := TJsonObjectArrayParser.Create('[{"Name":"Alice","Age":30}]');
  try
    var S := P.Next(ctLowercase);
    Assert.IsTrue(S.Contains('"name"'), 'Key "Name" should be lowercased');
    Assert.IsTrue(S.Contains('"age"'),  'Key "Age" should be lowercased');
    Assert.IsTrue(S.Contains('"Alice"'), 'Value "Alice" should be unchanged');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestNameCaseUppercase;
begin
  var P := TJsonObjectArrayParser.Create('[{"name":"Alice"}]');
  try
    var S := P.Next(ctUppercase);
    Assert.IsTrue(S.Contains('"NAME"'), 'Key "name" should be uppercased');
    Assert.IsTrue(S.Contains('"Alice"'), 'Value "Alice" should be unchanged');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestNameCaseAsIs;
begin
  var P := TJsonObjectArrayParser.Create('[{"MyKey":"MyVal"}]');
  try
    var S := P.Next(ctAsIs);
    Assert.IsTrue(S.Contains('"MyKey"'), 'Key should be unchanged');
    Assert.IsTrue(S.Contains('"MyVal"'), 'Value should be unchanged');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestNestedObject;
begin
  var P := TJsonObjectArrayParser.Create('[{"a":{"b":2}}]');
  try
    var S := P.Next;
    Assert.AreEqual('{"a":{"b":2}}', S);
    Assert.IsTrue(P.EndOfArray);
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestNestedArray;
begin
  var P := TJsonObjectArrayParser.Create('[{"a":[1,2,3]}]');
  try
    var S := P.Next;
    Assert.AreEqual('{"a":[1,2,3]}', S);
    Assert.IsTrue(P.EndOfArray);
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestInvalidArrayStart;
begin
  Assert.WillRaiseAny(procedure begin
    TJsonObjectArrayParser.Create('{"a":1}').Free;
  end);
end;

procedure TJsonObjectArrayParserTests.TestColonInStringValue;
begin
  // A comma inside a string value re-flips Name:=true mid-value, causing
  // subsequent value characters to be cased as if they were key names.
  // Input: [{"k":"a,b"}]  — value contains a comma.
  // With ctUppercase and the bug, after the ',' in the value, Name flips to
  // true so 'b' gets uppercased -> value becomes "a,B" instead of "a,b".
  var P := TJsonObjectArrayParser.Create('[{"k":"a,b"}]');
  try
    var S := P.Next(ctUppercase);
    Assert.IsTrue(S.Contains('"K"'),   'Key should be uppercased');
    Assert.IsTrue(S.Contains('"a,b"'), 'Value should be unchanged (comma inside string must not flip Name)');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestDoubleBackslashEscape;
begin
  // JSON text: [{"a":"x\\","b":1}]  — value of "a" is the two-char string x\
  var Json     := '[{"a":"x\\","b":1}]';
  var Expected := '{"a":"x\\","b":1}';
  var P := TJsonObjectArrayParser.Create(Json);
  try
    var S := P.Next;
    Assert.AreEqual(Expected, S, 'Object string should exactly match, with backslash escape intact');
    Assert.IsTrue(P.EndOfArray, 'Should be at end of array after one object');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestDoubleBackslashEscapeWithCase;
begin
  // JSON text: [{"k":"x\\yz"}]  — value is x\yz (backslash escaped as \\).
  // With ctUppercase: after \\ the Escape flag must be false so '"' ends the
  // string and 'yz' is not cased as a key name.
  var Json := '[{"k":"x\\yz"}]';
  var P := TJsonObjectArrayParser.Create(Json);
  try
    var S := P.Next(ctUppercase);
    Assert.IsTrue(S.Contains('"K"'),       'Key should be uppercased');
    Assert.IsTrue(S.Contains('"x\\yz"'),   'Value should be unchanged');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestFromFile;
  // Reads sample.json from Tests\Data\ via the TFileName overload.
begin
  var BaseDirectory := TBaseDirectory.Create(true);
  // AbsolutePath returns TFileName, so the compiler resolves to
  // Create(const FileName: TFileName) rather than Create(const Json: String).
  var FileName := BaseDirectory.AbsolutePath('..\Data\sample.json');
  var P := TJsonObjectArrayParser.Create(FileName);
  try
    var S1 := P.Next(ctLowercase);
    var S2 := P.Next(ctLowercase);
    var S3 := P.Next(ctLowercase);
    Assert.IsTrue(P.EndOfArray, 'Should be at end of array after three objects');
    Assert.IsTrue(S1.Contains('"name"') and S1.Contains('"Alice"'), 'First object: name=Alice');
    Assert.IsTrue(S2.Contains('"name"') and S2.Contains('"Bob"'),   'Second object: name=Bob');
    Assert.IsTrue(S3.Contains('"name"') and S3.Contains('"Carol"'), 'Third object: name=Carol');
  finally
    P.Free;
  end;
end;

procedure TJsonObjectArrayParserTests.TestFromFileStream;
begin
  // Same fixture, but exercises the TStream overload explicitly.
  var BaseDirectory := TBaseDirectory.Create(true);
  var FileName := BaseDirectory.AbsolutePath('..\Data\sample.json');
  var Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  var P := TJsonObjectArrayParser.Create(Stream);
  try
    var S1 := P.Next(ctLowercase);
    var S2 := P.Next(ctLowercase);
    var S3 := P.Next(ctLowercase);
    Assert.IsTrue(P.EndOfArray, 'Should be at end of array after three objects');
    Assert.IsTrue(S1.Contains('"name"') and S1.Contains('"Alice"'), 'First object: name=Alice');
    Assert.IsTrue(S2.Contains('"name"') and S2.Contains('"Bob"'),   'Second object: name=Bob');
    Assert.IsTrue(S3.Contains('"name"') and S3.Contains('"Carol"'), 'Third object: name=Carol');
  finally
    P.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TJsonObjectArrayParserTests);

end.
