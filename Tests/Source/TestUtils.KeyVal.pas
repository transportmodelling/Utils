unit TestUtils.KeyVal;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, Generics.Collections, DUnitX.TestFramework, KeyVal;

Type
  [TestFixture]
  TKeyValTests = class
  private
    FPairs: TKeyValuePairs;
  public
    [Setup]
    Procedure Setup;

    // Create
    [Test] Procedure Create_FromArray_SetsExpectedPairs;
    [Test] Procedure Create_FromDictionary_SetsExpectedPairs;
    [Test] Procedure Create_FromString_SetsExpectedPairs;
    [Test] Procedure Create_FromString_SkipsTokensWithoutSeparator;

    // Clear
    [Test] Procedure Clear_EmptiesArray;

    // Append
    [Test] Procedure Append_KeyValue_IncreasesCount;
    [Test] Procedure Append_Pair_IncreasesCount;
    [Test] Procedure Append_PairsArray_AppendsAll;
    [Test] Procedure Append_Dictionary_AppendsAllPairs;
    [Test] Procedure Append_Dictionary_PreservesExistingPairs;
    [Test] Procedure Append_Dictionary_EmptyDictionary_CountUnchanged;
    [Test] Procedure Append_Dictionary_KeyCasingPreserved;

    // Delete
    [Test] Procedure Delete_ByIndex_RemovesPair;
    [Test] Procedure Delete_ByIndex_FirstElement_RemovesPair;
    [Test] Procedure Delete_ByIndex_LastElement_RemovesPair;
    [Test] Procedure Delete_ByIndex_OutOfRange_RaisesException;
    [Test] Procedure Delete_ByKey_RemovesFirstOccurrence;
    [Test] Procedure Delete_ByKey_IsCaseInsensitive;
    [Test] Procedure Delete_ByKey_MissingKey_RaisesException;

    // Count
    [Test] Procedure Count_ReturnsCorrectValue;

    // Contains
    [Test] Procedure Contains_ExistingKey_ReturnsTrue;
    [Test] Procedure Contains_MissingKey_ReturnsFalse;
    [Test] Procedure Contains_KeyIsCaseInsensitive;
    [Test] Procedure Contains_WithValue_ReturnsValue;

    // Str
    [Test] Procedure Str_ExistingKey_ReturnsValue;
    [Test] Procedure Str_KeyIsCaseInsensitive;
    [Test] Procedure Str_MissingKey_RaisesException;
    [Test] Procedure Str_DuplicateKey_FirstOccurrence;
    [Test] Procedure Str_DuplicateKey_SecondOccurrence;
    [Test] Procedure Str_OccurrenceOutOfRange_RaisesException;

    // Int
    [Test] Procedure Int_ValidInteger_ReturnsValue;
    [Test] Procedure Int_InvalidInteger_RaisesException;
    [Test] Procedure Int_MissingKey_RaisesException;

    // Int64
    [Test] Procedure Int64_ValidInt64_ReturnsValue;
    [Test] Procedure Int64_InvalidInt64_RaisesException;

    // Float
    [Test] Procedure Float_ValidFloat_ReturnsValue;
    [Test] Procedure Float_InvalidFloat_RaisesException;

    // AsString
    [Test] Procedure AsString_DefaultSeparators_ReturnsExpected;
    [Test] Procedure AsString_CustomSeparators_ReturnsExpected;
    [Test] Procedure AsString_EmptyPairs_ReturnsEmptyString;

    // AddToDictionary
    [Test] Procedure AddToDictionary_PopulatesDictionary;
    [Test] Procedure AddToDictionary_DuplicateKey_RaisesException;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

// Pairs used across all tests:
//
//   Name  = 'Alice'
//   City  = 'Amsterdam'
//   Count = '7'
//   Score = '9.5'

Procedure TKeyValTests.Setup;
begin
  FPairs.Clear;
  FPairs.Append('Name','Alice');
  FPairs.Append('City','Amsterdam');
  FPairs.Append('Count','7');
  FPairs.Append('Score','9.5');
end;

// Create

Procedure TKeyValTests.Create_FromArray_SetsExpectedPairs;
begin
  var KeyValuePairs := TKeyValuePairs.Create([TKeyValuePair.Create('A','1'),
                                              TKeyValuePair.Create('B','2') ]);
  Assert.AreEqual(2,KeyValuePairs.Count);
  Assert.AreEqual('1',KeyValuePairs.Str('A'));
  Assert.AreEqual('2',KeyValuePairs.Str('B'));
end;

Procedure TKeyValTests.Create_FromDictionary_SetsExpectedPairs;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    Dict.Add('Name', 'Alice');
    Dict.Add('City', 'Amsterdam');
    // Add dictionary to KeyValuePairs
    var KeyValuePairs := TKeyValuePairs.Create(Dict);
    Assert.AreEqual(2,KeyValuePairs.Count);
    Assert.IsTrue(KeyValuePairs.Contains('Name'));
    Assert.IsTrue(KeyValuePairs.Contains('City'));
    Assert.AreEqual('Alice',KeyValuePairs.Str('Name'));
    Assert.AreEqual('Amsterdam',KeyValuePairs.Str('City'));
  finally
    Dict.Free;
  end;
end;

Procedure TKeyValTests.Create_FromString_SetsExpectedPairs;
begin
  var KeyValuePairs := TKeyValuePairs.Create('Name=Alice;City=Amsterdam', '=', ';');
  Assert.AreEqual(2,KeyValuePairs.Count);
  Assert.AreEqual('Alice',KeyValuePairs.Str('Name'));
  Assert.AreEqual('Amsterdam',KeyValuePairs.Str('City'));
end;

Procedure TKeyValTests.Create_FromString_SkipsTokensWithoutSeparator;
begin
  var KeyValuePairs := TKeyValuePairs.Create('Name=Alice;NoSeparatorToken;City=Amsterdam','=',';');
  Assert.AreEqual(2,KeyValuePairs.Count);
  Assert.AreEqual('Alice',KeyValuePairs.Str('Name'));
  Assert.AreEqual('Amsterdam',KeyValuePairs.Str('City'));
end;

// Clear

Procedure TKeyValTests.Clear_EmptiesArray;
begin
  FPairs.Clear;
  Assert.AreEqual(0,FPairs.Count);
end;

// Append

Procedure TKeyValTests.Append_KeyValue_IncreasesCount;
begin
  FPairs.Append('Version','1.0.0');
  Assert.AreEqual(5,FPairs.Count);
end;

Procedure TKeyValTests.Append_Pair_IncreasesCount;
begin
  FPairs.Append(TKeyValuePair.Create('Version','1.0.0'));
  Assert.AreEqual(5,FPairs.Count);
end;

Procedure TKeyValTests.Append_PairsArray_AppendsAll;
begin
  FPairs.Append([TKeyValuePair.Create('Street', 'Main Street'),
                 TKeyValuePair.Create('Number', '10')]);
  Assert.AreEqual(6,FPairs.Count);
  Assert.AreEqual('Main Street',FPairs.Str('Street'));
  Assert.AreEqual('10',FPairs.Str('Number'));
end;

Procedure TKeyValTests.Append_Dictionary_AppendsAllPairs;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    Dict.Add('Street','Main Street');
    Dict.Add('Number','10');
    FPairs.Append(Dict);
    Assert.AreEqual(6,FPairs.Count);
    Assert.AreEqual('Main Street',FPairs.Str('Street'));
    Assert.AreEqual('10',FPairs.Str('Number'));
  finally
    Dict.Free;
  end;
end;

Procedure TKeyValTests.Append_Dictionary_PreservesExistingPairs;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    Dict.Add('Street','Main Street');
    FPairs.Append(Dict);
    Assert.AreEqual(5,FPairs.Count);
    Assert.AreEqual('Alice',FPairs.Str('Name'));
  finally
    Dict.Free;
  end;
end;

Procedure TKeyValTests.Append_Dictionary_EmptyDictionary_CountUnchanged;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    FPairs.Append(Dict);
    Assert.AreEqual(4,FPairs.Count);
  finally
    Dict.Free;
  end;
end;

Procedure TKeyValTests.Append_Dictionary_KeyCasingPreserved;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    Dict.Add('STREET','Main Street');
    FPairs.Append(Dict);
    Assert.IsTrue(FPairs.Contains('STREET'));
    Assert.AreEqual('Main Street',FPairs.Str('STREET'));
  finally
    Dict.Free;
  end;
end;

// Delete

Procedure TKeyValTests.Delete_ByIndex_RemovesPair;
begin
  FPairs.Delete(1); // removes 'City'
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('City'));
  Assert.AreEqual('Alice',FPairs.Str('Name'));
end;

Procedure TKeyValTests.Delete_ByIndex_FirstElement_RemovesPair;
begin
  FPairs.Delete(0); // removes 'Name'
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('Name'));
  Assert.AreEqual('Amsterdam',FPairs.Str('City'));
end;

Procedure TKeyValTests.Delete_ByIndex_LastElement_RemovesPair;
begin
  FPairs.Delete(FPairs.Count-1); // removes 'Score'
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('Score'));
end;

Procedure TKeyValTests.Delete_ByIndex_OutOfRange_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Delete(99) end);
  Assert.WillRaiseAny(Procedure begin FPairs.Delete(-1) end);
end;

Procedure TKeyValTests.Delete_ByKey_RemovesFirstOccurrence;
begin
  FPairs.Append('Name','Bob'); // duplicate
  FPairs.Delete('Name');
  Assert.AreEqual(4,FPairs.Count);
  Assert.AreEqual('Bob',FPairs.Str('Name')); // second occurrence is now first
end;

Procedure TKeyValTests.Delete_ByKey_IsCaseInsensitive;
begin
  FPairs.Delete('CITY');
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('City'));
end;

Procedure TKeyValTests.Delete_ByKey_MissingKey_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Delete('MISSING') end);
end;

// Count

Procedure TKeyValTests.Count_ReturnsCorrectValue;
begin
  Assert.AreEqual(4,FPairs.Count);
end;

// Contains

Procedure TKeyValTests.Contains_ExistingKey_ReturnsTrue;
begin
  Assert.IsTrue(FPairs.Contains('Name'));
end;

Procedure TKeyValTests.Contains_MissingKey_ReturnsFalse;
begin
  Assert.IsFalse(FPairs.Contains('MISSING'));
end;

Procedure TKeyValTests.Contains_KeyIsCaseInsensitive;
begin
  Assert.IsTrue(FPairs.Contains('name'));
  Assert.IsTrue(FPairs.Contains('NAME'));
end;

Procedure TKeyValTests.Contains_WithValue_ReturnsValue;
Var
  Value: String;
begin
  Assert.IsTrue(FPairs.Contains('Name',Value));
  Assert.AreEqual('Alice',Value);
end;

// Str

Procedure TKeyValTests.Str_ExistingKey_ReturnsValue;
begin
  Assert.AreEqual('Alice',FPairs.Str('Name'));
end;

Procedure TKeyValTests.Str_KeyIsCaseInsensitive;
begin
  Assert.AreEqual('Alice',FPairs.Str('name'));
  Assert.AreEqual('Alice',FPairs.Str('NAME'));
end;

Procedure TKeyValTests.Str_MissingKey_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Str('MISSING') end);
end;

Procedure TKeyValTests.Str_DuplicateKey_FirstOccurrence;
begin
  FPairs.Append('Name','Bob');
  Assert.AreEqual('Alice', FPairs.Str('Name',0));
end;

Procedure TKeyValTests.Str_DuplicateKey_SecondOccurrence;
begin
  FPairs.Append('Name','Bob');
  Assert.AreEqual('Bob',FPairs.Str('Name', 1));
end;

Procedure TKeyValTests.Str_OccurrenceOutOfRange_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Str('Name',1) end);
end;

// Int

Procedure TKeyValTests.Int_ValidInteger_ReturnsValue;
begin
  Assert.AreEqual(7,FPairs.Int('Count'));
end;

Procedure TKeyValTests.Int_InvalidInteger_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Int('Name') end);
end;

Procedure TKeyValTests.Int_MissingKey_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Int('MISSING') end);
end;

// Int64

Procedure TKeyValTests.Int64_ValidInt64_ReturnsValue;
begin
  Assert.AreEqual(Int64(7),FPairs.Int64('Count'));
end;

Procedure TKeyValTests.Int64_InvalidInt64_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Int64('Name') end);
end;

// Float

Procedure TKeyValTests.Float_ValidFloat_ReturnsValue;
begin
  Assert.AreEqual(Float64(9.5),FPairs.Float('Score'),0.0001);
end;

Procedure TKeyValTests.Float_InvalidFloat_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FPairs.Float('Name') end);
end;

// AsString

Procedure TKeyValTests.AsString_DefaultSeparators_ReturnsExpected;
begin
  var KeyValuePairs := TKeyValuePairs.Create([TKeyValuePair.Create('Name','Alice'),
                                              TKeyValuePair.Create('City','Amsterdam')]);
  Assert.AreEqual('Name: Alice; City: Amsterdam',KeyValuePairs.AsString);
end;

Procedure TKeyValTests.AsString_CustomSeparators_ReturnsExpected;
begin
  var KeyValuePairs := TKeyValuePairs.Create([TKeyValuePair.Create('Name','Alice'),
                                              TKeyValuePair.Create('City','Amsterdam')]);
  Assert.AreEqual('Name= Alice& City= Amsterdam',KeyValuePairs.AsString('=', '&'));
end;

Procedure TKeyValTests.AsString_EmptyPairs_ReturnsEmptyString;
Var
  KeyValuePairs: TKeyValuePairs;
begin
  KeyValuePairs.Clear;
  Assert.AreEqual('',KeyValuePairs.AsString);
end;

// AddToDictionary

Procedure TKeyValTests.AddToDictionary_PopulatesDictionary;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    FPairs.AddToDictionary(Dict);
    Assert.AreEqual(FPairs.Count,Integer(Dict.Count));
    Assert.AreEqual('Alice',Dict['Name']);
    Assert.AreEqual('Amsterdam',Dict['City']);
  finally
    Dict.Free;
  end;
end;

Procedure TKeyValTests.AddToDictionary_DuplicateKey_RaisesException;
begin
  var Dict := TDictionary<String,String>.Create;
  Dict.Add('Name','Existing');
  try
    Assert.WillRaiseAny(Procedure begin FPairs.AddToDictionary(Dict) end);
  finally
    Dict.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TKeyValTests);
end.
