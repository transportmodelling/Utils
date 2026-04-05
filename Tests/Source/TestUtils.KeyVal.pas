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
    procedure Setup;

    // Create
    [Test] procedure Create_FromArray_SetsExpectedPairs;
    [Test] procedure Create_FromDictionary_SetsExpectedPairs;
    [Test] procedure Create_FromString_SetsExpectedPairs;
    [Test] procedure Create_FromString_SkipsTokensWithoutSeparator;

    // Clear
    [Test] procedure Clear_EmptiesArray;

    // Append
    [Test] procedure Append_KeyValue_IncreasesCount;
    [Test] procedure Append_Pair_IncreasesCount;
    [Test] procedure Append_PairsArray_AppendsAll;
    [Test] procedure Append_Dictionary_AppendsAllPairs;
    [Test] procedure Append_Dictionary_PreservesExistingPairs;
    [Test] procedure Append_Dictionary_EmptyDictionary_CountUnchanged;
    [Test] procedure Append_Dictionary_KeyCasingPreserved;

    // Delete
    [Test] procedure Delete_ByIndex_RemovesPair;
    [Test] procedure Delete_ByIndex_FirstElement_RemovesPair;
    [Test] procedure Delete_ByIndex_LastElement_RemovesPair;
    [Test] procedure Delete_ByIndex_OutOfRange_RaisesException;
    [Test] procedure Delete_ByKey_RemovesFirstOccurrence;
    [Test] procedure Delete_ByKey_IsCaseInsensitive;
    [Test] procedure Delete_ByKey_MissingKey_RaisesException;

    // Count
    [Test] procedure Count_ReturnsCorrectValue;

    // Contains
    [Test] procedure Contains_ExistingKey_ReturnsTrue;
    [Test] procedure Contains_MissingKey_ReturnsFalse;
    [Test] procedure Contains_KeyIsCaseInsensitive;
    [Test] procedure Contains_WithValue_ReturnsValue;

    // Str
    [Test] procedure Str_ExistingKey_ReturnsValue;
    [Test] procedure Str_KeyIsCaseInsensitive;
    [Test] procedure Str_MissingKey_RaisesException;
    [Test] procedure Str_DuplicateKey_FirstOccurrence;
    [Test] procedure Str_DuplicateKey_SecondOccurrence;
    [Test] procedure Str_OccurrenceOutOfRange_RaisesException;

    // Int
    [Test] procedure Int_ValidInteger_ReturnsValue;
    [Test] procedure Int_InvalidInteger_RaisesException;
    [Test] procedure Int_MissingKey_RaisesException;

    // Int64
    [Test] procedure Int64_ValidInt64_ReturnsValue;
    [Test] procedure Int64_InvalidInt64_RaisesException;

    // Float
    [Test] procedure Float_ValidFloat_ReturnsValue;
    [Test] procedure Float_InvalidFloat_RaisesException;

    // AsString
    [Test] procedure AsString_DefaultSeparators_ReturnsExpected;
    [Test] procedure AsString_CustomSeparators_ReturnsExpected;
    [Test] procedure AsString_EmptyPairs_ReturnsEmptyString;

    // AddToDictionary
    [Test] procedure AddToDictionary_PopulatesDictionary;
    [Test] procedure AddToDictionary_DuplicateKey_RaisesException;
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

procedure TKeyValTests.Setup;
begin
  FPairs.Clear;
  FPairs.Append('Name','Alice');
  FPairs.Append('City','Amsterdam');
  FPairs.Append('Count','7');
  FPairs.Append('Score','9.5');
end;

// Create

procedure TKeyValTests.Create_FromArray_SetsExpectedPairs;
begin
  var KeyValuePairs := TKeyValuePairs.Create([TKeyValuePair.Create('A','1'),
                                              TKeyValuePair.Create('B','2') ]);
  Assert.AreEqual(2,KeyValuePairs.Count);
  Assert.AreEqual('1',KeyValuePairs.Str('A'));
  Assert.AreEqual('2',KeyValuePairs.Str('B'));
end;

procedure TKeyValTests.Create_FromDictionary_SetsExpectedPairs;
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

procedure TKeyValTests.Create_FromString_SetsExpectedPairs;
begin
  var KeyValuePairs := TKeyValuePairs.Create('Name=Alice;City=Amsterdam', '=', ';');
  Assert.AreEqual(2,KeyValuePairs.Count);
  Assert.AreEqual('Alice',KeyValuePairs.Str('Name'));
  Assert.AreEqual('Amsterdam',KeyValuePairs.Str('City'));
end;

procedure TKeyValTests.Create_FromString_SkipsTokensWithoutSeparator;
begin
  var KeyValuePairs := TKeyValuePairs.Create('Name=Alice;NoSeparatorToken;City=Amsterdam','=',';');
  Assert.AreEqual(2,KeyValuePairs.Count);
  Assert.AreEqual('Alice',KeyValuePairs.Str('Name'));
  Assert.AreEqual('Amsterdam',KeyValuePairs.Str('City'));
end;

// Clear

procedure TKeyValTests.Clear_EmptiesArray;
begin
  FPairs.Clear;
  Assert.AreEqual(0,FPairs.Count);
end;

// Append

procedure TKeyValTests.Append_KeyValue_IncreasesCount;
begin
  FPairs.Append('Version','1.0.0');
  Assert.AreEqual(5,FPairs.Count);
end;

procedure TKeyValTests.Append_Pair_IncreasesCount;
begin
  FPairs.Append(TKeyValuePair.Create('Version','1.0.0'));
  Assert.AreEqual(5,FPairs.Count);
end;

procedure TKeyValTests.Append_PairsArray_AppendsAll;
begin
  FPairs.Append([TKeyValuePair.Create('Street', 'Main Street'),
                 TKeyValuePair.Create('Number', '10')]);
  Assert.AreEqual(6,FPairs.Count);
  Assert.AreEqual('Main Street',FPairs.Str('Street'));
  Assert.AreEqual('10',FPairs.Str('Number'));
end;

procedure TKeyValTests.Append_Dictionary_AppendsAllPairs;
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

procedure TKeyValTests.Append_Dictionary_PreservesExistingPairs;
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

procedure TKeyValTests.Append_Dictionary_EmptyDictionary_CountUnchanged;
begin
  var Dict := TDictionary<String,String>.Create;
  try
    FPairs.Append(Dict);
    Assert.AreEqual(4,FPairs.Count);
  finally
    Dict.Free;
  end;
end;

procedure TKeyValTests.Append_Dictionary_KeyCasingPreserved;
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

procedure TKeyValTests.Delete_ByIndex_RemovesPair;
begin
  FPairs.Delete(1); // removes 'City'
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('City'));
  Assert.AreEqual('Alice',FPairs.Str('Name'));
end;

procedure TKeyValTests.Delete_ByIndex_FirstElement_RemovesPair;
begin
  FPairs.Delete(0); // removes 'Name'
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('Name'));
  Assert.AreEqual('Amsterdam',FPairs.Str('City'));
end;

procedure TKeyValTests.Delete_ByIndex_LastElement_RemovesPair;
begin
  FPairs.Delete(FPairs.Count-1); // removes 'Score'
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('Score'));
end;

procedure TKeyValTests.Delete_ByIndex_OutOfRange_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Delete(99) end);
  Assert.WillRaiseAny(procedure begin FPairs.Delete(-1) end);
end;

procedure TKeyValTests.Delete_ByKey_RemovesFirstOccurrence;
begin
  FPairs.Append('Name','Bob'); // duplicate
  FPairs.Delete('Name');
  Assert.AreEqual(4,FPairs.Count);
  Assert.AreEqual('Bob',FPairs.Str('Name')); // second occurrence is now first
end;

procedure TKeyValTests.Delete_ByKey_IsCaseInsensitive;
begin
  FPairs.Delete('CITY');
  Assert.AreEqual(3,FPairs.Count);
  Assert.IsFalse(FPairs.Contains('City'));
end;

procedure TKeyValTests.Delete_ByKey_MissingKey_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Delete('MISSING') end);
end;

// Count

procedure TKeyValTests.Count_ReturnsCorrectValue;
begin
  Assert.AreEqual(4,FPairs.Count);
end;

// Contains

procedure TKeyValTests.Contains_ExistingKey_ReturnsTrue;
begin
  Assert.IsTrue(FPairs.Contains('Name'));
end;

procedure TKeyValTests.Contains_MissingKey_ReturnsFalse;
begin
  Assert.IsFalse(FPairs.Contains('MISSING'));
end;

procedure TKeyValTests.Contains_KeyIsCaseInsensitive;
begin
  Assert.IsTrue(FPairs.Contains('name'));
  Assert.IsTrue(FPairs.Contains('NAME'));
end;

procedure TKeyValTests.Contains_WithValue_ReturnsValue;
Var
  Value: String;
begin
  Assert.IsTrue(FPairs.Contains('Name',Value));
  Assert.AreEqual('Alice',Value);
end;

// Str

procedure TKeyValTests.Str_ExistingKey_ReturnsValue;
begin
  Assert.AreEqual('Alice',FPairs.Str('Name'));
end;

procedure TKeyValTests.Str_KeyIsCaseInsensitive;
begin
  Assert.AreEqual('Alice',FPairs.Str('name'));
  Assert.AreEqual('Alice',FPairs.Str('NAME'));
end;

procedure TKeyValTests.Str_MissingKey_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Str('MISSING') end);
end;

procedure TKeyValTests.Str_DuplicateKey_FirstOccurrence;
begin
  FPairs.Append('Name','Bob');
  Assert.AreEqual('Alice', FPairs.Str('Name',0));
end;

procedure TKeyValTests.Str_DuplicateKey_SecondOccurrence;
begin
  FPairs.Append('Name','Bob');
  Assert.AreEqual('Bob',FPairs.Str('Name', 1));
end;

procedure TKeyValTests.Str_OccurrenceOutOfRange_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Str('Name',1) end);
end;

// Int

procedure TKeyValTests.Int_ValidInteger_ReturnsValue;
begin
  Assert.AreEqual(7,FPairs.Int('Count'));
end;

procedure TKeyValTests.Int_InvalidInteger_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Int('Name') end);
end;

procedure TKeyValTests.Int_MissingKey_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Int('MISSING') end);
end;

// Int64

procedure TKeyValTests.Int64_ValidInt64_ReturnsValue;
begin
  Assert.AreEqual(Int64(7),FPairs.Int64('Count'));
end;

procedure TKeyValTests.Int64_InvalidInt64_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Int64('Name') end);
end;

// Float

procedure TKeyValTests.Float_ValidFloat_ReturnsValue;
begin
  Assert.AreEqual(Float64(9.5),FPairs.Float('Score'),0.0001);
end;

procedure TKeyValTests.Float_InvalidFloat_RaisesException;
begin
  Assert.WillRaiseAny(procedure begin FPairs.Float('Name') end);
end;

// AsString

procedure TKeyValTests.AsString_DefaultSeparators_ReturnsExpected;
begin
  var KeyValuePairs := TKeyValuePairs.Create([TKeyValuePair.Create('Name','Alice'),
                                              TKeyValuePair.Create('City','Amsterdam')]);
  Assert.AreEqual('Name: Alice; City: Amsterdam',KeyValuePairs.AsString);
end;

procedure TKeyValTests.AsString_CustomSeparators_ReturnsExpected;
begin
  var KeyValuePairs := TKeyValuePairs.Create([TKeyValuePair.Create('Name','Alice'),
                                              TKeyValuePair.Create('City','Amsterdam')]);
  Assert.AreEqual('Name= Alice& City= Amsterdam',KeyValuePairs.AsString('=', '&'));
end;

procedure TKeyValTests.AsString_EmptyPairs_ReturnsEmptyString;
Var
  KeyValuePairs: TKeyValuePairs;
begin
  KeyValuePairs.Clear;
  Assert.AreEqual('',KeyValuePairs.AsString);
end;

// AddToDictionary

procedure TKeyValTests.AddToDictionary_PopulatesDictionary;
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

procedure TKeyValTests.AddToDictionary_DuplicateKey_RaisesException;
begin
  var Dict := TDictionary<String,String>.Create;
  Dict.Add('Name','Existing');
  try
    Assert.WillRaiseAny(procedure begin FPairs.AddToDictionary(Dict) end);
  finally
    Dict.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TKeyValTests);
end.
