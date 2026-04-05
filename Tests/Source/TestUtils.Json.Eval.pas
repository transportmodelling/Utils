unit TestUtils.Json.Eval;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, System.Generics.Collections, DUnitX.TestFramework, System.JSON, Json.Eval, KeyVal;

Type
  [TestFixture]
  TJsonEvalTests = class
  private
    FJson: TJSONObject;
  public
    [Setup]
    Procedure Setup;
    [TearDown]
    Procedure TearDown;

    // GetKeyValuePairs (root)
    [Test] Procedure GetKeyValuePairs_Root_ReturnsAllPairs;
    [Test] Procedure GetKeyValuePairs_Root_IncludesNumericValues;
    [Test] Procedure GetKeyValuePairs_Root_SubObjectValueIsSerializedJson;
    [Test] Procedure GetKeyValuePairs_Root_StringArrayValueIsSerializedJson;
    [Test] Procedure GetKeyValuePairs_Root_NumberArrayValueIsSerializedJson;
    [Test] Procedure GetKeyValuePairs_Root_ObjectArrayValueIsSerializedJson;

    // GetKeyValuePairs with Keys
    [Test] Procedure GetKeyValuePairs_OneLevel_ReturnsSubObjectPairs;
    [Test] Procedure GetKeyValuePairs_TwoLevels_ReturnsNestedPairs;
    [Test] Procedure GetKeyValuePairs_KeyIsCaseInsensitive;
    [Test] Procedure GetKeyValuePairs_MissingKey_ReturnsFalse;
    [Test] Procedure GetKeyValuePairs_KeyNotAnObject_ReturnsFalse;
    [Test] Procedure GetKeyValuePairs_ArrayIndex_ReturnsObjectPairs;
    [Test] Procedure GetKeyValuePairs_ArrayIndex_OutOfRange_ReturnsFalse;
    [Test] Procedure GetKeyValuePairs_KeyStepOnArray_ReturnsFalse;
    [Test] Procedure GetKeyValuePairs_IndexStepOnObject_ReturnsFalse;
    [Test] Procedure GetKeyValuePairs_EmptyPath_ReturnsRootPairs;
    [Test] Procedure GetKeyValuePairs_EmptyPath_NotAnObject_ReturnsFalse;

    // GetStr
    [Test] Procedure GetStr_ExistingStringKey_ReturnsValue;
    [Test] Procedure GetStr_NestedKey_ReturnsValue;
    [Test] Procedure GetStr_KeyIsCaseInsensitive;
    [Test] Procedure GetStr_MissingKey_ReturnsFalse;
    [Test] Procedure GetStr_NumberValue_ReturnsFalse;
    [Test] Procedure GetStr_ArrayIndex_ReturnsValue;
    [Test] Procedure GetStr_EmptyPath_ReturnsValue;
    [Test] Procedure GetStr_EmptyPath_WrongType_ReturnsFalse;

    // AsStr
    [Test] Procedure AsStr_StringLeaf_ReturnsValue;
    [Test] Procedure AsStr_NumberLeaf_ReturnsValue;
    [Test] Procedure AsStr_BoolLeaf_ReturnsValue;
    [Test] Procedure AsStr_NullLeaf_ReturnsEmptyString;
    [Test] Procedure AsStr_ObjectLeaf_ReturnsSerializedJson;
    [Test] Procedure AsStr_ArrayLeaf_ReturnsSerializedJson;
    [Test] Procedure AsStr_MissingKey_ReturnsFalse;
    [Test] Procedure AsStr_EmptyPath_ReturnsValue;

    // GetInt
    [Test] Procedure GetInt_ValidNumber_ReturnsValue;
    [Test] Procedure GetInt_NestedKey_ReturnsValue;
    [Test] Procedure GetInt_StringValue_ReturnsFalse;
    [Test] Procedure GetInt_MissingKey_ReturnsFalse;
    [Test] Procedure GetInt_ArrayIndex_ReturnsValue;
    [Test] Procedure GetInt_EmptyPath_ReturnsValue;

    // GetInt64
    [Test] Procedure GetInt64_ValidNumber_ReturnsValue;
    [Test] Procedure GetInt64_StringValue_ReturnsFalse;

    // GetFloat
    [Test] Procedure GetFloat_ValidNumber_ReturnsValue;
    [Test] Procedure GetFloat_StringValue_ReturnsFalse;
    [Test] Procedure GetFloat_EmptyPath_ReturnsValue;

    // GetStrs
    [Test] Procedure GetStrs_ValidArray_ReturnsValues;
    [Test] Procedure GetStrs_EmptyPath_ReturnsValues;
    [Test] Procedure GetStrs_NotAnArray_ReturnsFalse;
    [Test] Procedure GetStrs_ElementNotAString_ReturnsFalse;

    // GetInts
    [Test] Procedure GetInts_ValidArray_ReturnsValues;
    [Test] Procedure GetInts_EmptyPath_ReturnsValues;
    [Test] Procedure GetInts_NotAnArray_ReturnsFalse;
    [Test] Procedure GetInts_ElementNotAnInteger_ReturnsFalse;

    // GetFloats
    [Test] Procedure GetFloats_ValidArray_ReturnsValues;
    [Test] Procedure GetFloats_EmptyPath_ReturnsValues;
    [Test] Procedure GetFloats_NotAnArray_ReturnsFalse;
    [Test] Procedure GetFloats_ElementNotANumber_ReturnsFalse;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

// JSON used across all tests:
//
// {
//   "Name":    "Alice",
//   "City":    "Amsterdam",
//   "Version": "1.0.0",
//   "Count":   7,
//   "Score":   9.5,
//   "Tags":    ["alpha", "beta", "gamma"],
//   "Scores":  [10, 20, 30],
//   "Ratings": [1.5, 2.5, 3.5],
//   "Items":   [{"Id": 1, "Label": "first"}, {"Id": 2, "Label": "second"}],
//   "Address":
//    {
//      "Street": "Main Street",
//      "Number": "10",
//      "Location":
//         {
//           "Lat": "52.370216"
//         }
//    }
// }

Procedure TJsonEvalTests.Setup;
begin
  FJson := TJSONObject.ParseJSONValue('''
                                       {
                                         "Name":    "Alice",
                                         "City":    "Amsterdam",
                                         "Version": "1.0.0",
                                         "Count":   7,
                                         "Score":   9.5,
                                          "Tags":    ["alpha", "beta", "gamma"],
                                          "Scores":  [10, 20, 30],
                                          "Ratings": [1.5, 2.5, 3.5],
                                          "Items":   [{"Id": 1, "Label": "first"}, {"Id": 2, "Label": "second"}],
                                         "Address":
                                           {
                                             "Street": "Main Street",
                                              "Number": "10",
                                              "Location":
                                                {
                                                  "Lat": "52.370216"
                                                }
                                           }
                                       }
                                      ''') as TJSONObject;
end;

Procedure TJsonEvalTests.TearDown;
begin
  FJson.Free;
end;

// GetKeyValuePairs (root)

Procedure TJsonEvalTests.GetKeyValuePairs_Root_ReturnsAllPairs;
begin
  var Pairs: TKeyValuePairs;
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson,Pairs));
  Assert.AreEqual(10,Pairs.Count);
  Assert.IsTrue(Pairs.Contains('Name'));
  Assert.IsTrue(Pairs.Contains('City'));
  Assert.IsTrue(Pairs.Contains('Version'));
  Assert.AreEqual('Alice',Pairs.Str('Name'));
  Assert.AreEqual('Amsterdam',Pairs.Str('City'));
  Assert.AreEqual('1.0.0',Pairs.Str('Version'));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_Root_IncludesNumericValues;
Var
  Pairs: TKeyValuePairs;
begin
  // Numeric JSON values are represented as their string form via TJSONValue.Value
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson,Pairs));
  Assert.IsTrue(Pairs.Contains('Count'));
  Assert.AreEqual(7,Pairs.Int('Count'));
  Assert.AreEqual(Float64(9.5), Pairs.Float('Score'), 0.0001);
end;

Procedure TJsonEvalTests.GetKeyValuePairs_Root_SubObjectValueIsSerializedJson;
Var
  Pairs: TKeyValuePairs;
begin
  // Sub-object values are stored as their serialized JSON text
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson,Pairs));
  Assert.IsTrue(Pairs.Contains('Address'));
  // Create Json-object
  var AddressJson := Pairs.Str('Address');
  var Parsed := TJSONObject.ParseJSONValue(AddressJson) as TJSONObject;
  try
    Assert.IsNotNull(Parsed,'Address value should be valid JSON');
    Assert.IsTrue(Pairs.Contains('Address'));
  finally
    Parsed.Free;
  end;
end;

Procedure TJsonEvalTests.GetKeyValuePairs_Root_StringArrayValueIsSerializedJson;
Var
  Pairs: TKeyValuePairs;
begin
  // String array values are stored as their serialized JSON text
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson,Pairs));
  Assert.IsTrue(Pairs.Contains('Tags'));
  // Create Json-array
  var TagsJson := Pairs.Str('Tags');
  var Parsed := TJSONObject.ParseJSONValue(TagsJson) as TJSONArray;
  try
    Assert.IsNotNull(Parsed,'Tags value should be a valid JSON array');
    Assert.AreEqual(3,Parsed.Count);
    Assert.AreEqual('alpha',Parsed.Items[0].Value);
  finally
    Parsed.Free;
  end;
end;

Procedure TJsonEvalTests.GetKeyValuePairs_Root_NumberArrayValueIsSerializedJson;
begin
  // Number array values are stored as their serialized JSON text
  var Pairs: TKeyValuePairs;
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson, Pairs));
  Assert.IsTrue(Pairs.Contains('Scores'));
  // Create Json-array
  var ScoresJson := Pairs.Str('Scores');
  var Parsed := TJSONObject.ParseJSONValue(ScoresJson) as TJSONArray;
  try
    Assert.IsNotNull(Parsed, 'Scores value should be a valid JSON array');
    Assert.AreEqual(3, Parsed.Count);
    Assert.AreEqual(10, StrToInt(Parsed.Items[0].Value));
  finally
    Parsed.Free;
  end;
end;

Procedure TJsonEvalTests.GetKeyValuePairs_Root_ObjectArrayValueIsSerializedJson;
Var
  Pairs: TKeyValuePairs;
begin
  // Object array values are stored as their serialized JSON text
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson,Pairs));
  Assert.IsTrue(Pairs.Contains('Items'));
  // Create Json-array
  var ItemsJson := Pairs.Str('Items');
  var Parsed := TJSONObject.ParseJSONValue(ItemsJson) as TJSONArray;
  try
    Assert.IsNotNull(Parsed, 'Items value should be a valid JSON array');
    Assert.AreEqual(2,Parsed.Count);
    Assert.AreEqual('first', (Parsed.Items[0] as TJSONObject).GetValue<String>('Label'));
  finally
    Parsed.Free;
  end;
end;

// GetKeyValuePairs with Keys

Procedure TJsonEvalTests.GetKeyValuePairs_OneLevel_ReturnsSubObjectPairs;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson, ['Address'], Pairs));
  Assert.AreEqual(3, Pairs.Count);
  Assert.AreEqual('Main Street',Pairs.Str('Street'));
  Assert.AreEqual('10',Pairs.Str('Number'));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_TwoLevels_ReturnsNestedPairs;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson,['Address', 'Location'], Pairs));
  Assert.AreEqual(1,Pairs.Count);
  Assert.AreEqual('52.370216', Pairs.Str('Lat'));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_KeyIsCaseInsensitive;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson, ['address'], Pairs));
  Assert.IsTrue(Pairs.Contains('Street'));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_MissingKey_ReturnsFalse;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsFalse(TJsonEvaluator.GetKeyValuePairs(FJson, ['MISSING'], Pairs));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_KeyNotAnObject_ReturnsFalse;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsFalse(TJsonEvaluator.GetKeyValuePairs(FJson, ['Name'], Pairs));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_ArrayIndex_ReturnsObjectPairs;
Var
  Pairs: TKeyValuePairs;
begin
  // Navigate into Items[1] which is {"Id":2,"Label":"second"}
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson, ['Items', 1], Pairs));
  Assert.AreEqual(2,Pairs.Count);
  Assert.AreEqual('second', Pairs.Str('Label'));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_ArrayIndex_OutOfRange_ReturnsFalse;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsFalse(TJsonEvaluator.GetKeyValuePairs(FJson, ['Items', 99], Pairs));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_KeyStepOnArray_ReturnsFalse;
Var
  Pairs: TKeyValuePairs;
begin
  // 'Tags' is an array — a string key step into it must return False
  Assert.IsFalse(TJsonEvaluator.GetKeyValuePairs(FJson, ['Tags', 'x'], Pairs));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_IndexStepOnObject_ReturnsFalse;
Var
  Pairs: TKeyValuePairs;
begin
  // 'Address' is an object — an integer index step into it must return False
  Assert.IsFalse(TJsonEvaluator.GetKeyValuePairs(FJson, ['Address', 0], Pairs));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_EmptyPath_ReturnsRootPairs;
Var
  Pairs: TKeyValuePairs;
begin
  Assert.IsTrue(TJsonEvaluator.GetKeyValuePairs(FJson, [], Pairs));
  Assert.AreEqual('Alice', Pairs.Str('Name'));
  Assert.AreEqual('Amsterdam', Pairs.Str('City'));
end;

Procedure TJsonEvalTests.GetKeyValuePairs_EmptyPath_NotAnObject_ReturnsFalse;
begin
  var Arr := FJson.Values['Tags'] as TJSONArray;
  var Pairs: TKeyValuePairs;
  Assert.IsFalse(TJsonEvaluator.GetKeyValuePairs(Arr, [], Pairs));
end;

// GetStr

Procedure TJsonEvalTests.GetStr_ExistingStringKey_ReturnsValue;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.GetStr(FJson, ['Version'], Value));
  Assert.AreEqual('1.0.0', Value);
end;

Procedure TJsonEvalTests.GetStr_NestedKey_ReturnsValue;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.GetStr(FJson, ['Address', 'Street'], Value));
  Assert.AreEqual('Main Street', Value);
end;

Procedure TJsonEvalTests.GetStr_KeyIsCaseInsensitive;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.GetStr(FJson, ['version'], Value));
  Assert.AreEqual('1.0.0', Value);
end;

Procedure TJsonEvalTests.GetStr_MissingKey_ReturnsFalse;
Var
  Value: String;
begin
  Assert.IsFalse(TJsonEvaluator.GetStr(FJson, ['MISSING'], Value));
end;

Procedure TJsonEvalTests.GetStr_NumberValue_ReturnsFalse;
Var
  Value: String;
begin
  Assert.IsFalse(TJsonEvaluator.GetStr(FJson, ['Count'], Value));
end;

Procedure TJsonEvalTests.GetStr_ArrayIndex_ReturnsValue;
Var
  Value: String;
begin
  // Tags[1] is "beta"
  Assert.IsTrue(TJsonEvaluator.GetStr(FJson, ['Tags', 1], Value));
  Assert.AreEqual('beta', Value);
end;

Procedure TJsonEvalTests.GetStr_EmptyPath_ReturnsValue;
begin
  var JsonStr := TJSONString.Create('Alice');
  try
    var Value: String;
    Assert.IsTrue(TJsonEvaluator.GetStr(JsonStr, [], Value));
    Assert.AreEqual('Alice', Value);
  finally
    JsonStr.Free;
  end;
end;

Procedure TJsonEvalTests.GetStr_EmptyPath_WrongType_ReturnsFalse;
begin
  var JsonNum := TJSONNumber.Create(7);
  try
    var Value: String;
    Assert.IsFalse(TJsonEvaluator.GetStr(JsonNum, [], Value));
  finally
    JsonNum.Free;
  end;
end;

// AsStr

Procedure TJsonEvalTests.AsStr_StringLeaf_ReturnsValue;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.AsStr(FJson, ['Name'], Value));
  Assert.AreEqual('Alice', Value);
end;

Procedure TJsonEvalTests.AsStr_NumberLeaf_ReturnsValue;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.AsStr(FJson, ['Count'], Value));
  Assert.AreEqual('7', Value);
end;

Procedure TJsonEvalTests.AsStr_BoolLeaf_ReturnsValue;
Var
  Value: String;
begin
  var Json := TJSONObject.ParseJSONValue('{"Flag":true}') as TJSONObject;
  try
    Assert.IsTrue(TJsonEvaluator.AsStr(Json, ['Flag'], Value));
    Assert.AreEqual('true', Value);
  finally
    Json.Free;
  end;
end;

Procedure TJsonEvalTests.AsStr_NullLeaf_ReturnsEmptyString;
Var
  Value: String;
begin
  var Json := TJSONObject.ParseJSONValue('{"Empty":null}') as TJSONObject;
  try
    Assert.IsTrue(TJsonEvaluator.AsStr(Json, ['Empty'], Value));
    Assert.AreEqual('', Value);
  finally
    Json.Free;
  end;
end;

Procedure TJsonEvalTests.AsStr_ObjectLeaf_ReturnsSerializedJson;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.AsStr(FJson, ['Address'], Value));
  // Create Json-object
  var Parsed := TJSONObject.ParseJSONValue(Value) as TJSONObject;
  try
    Assert.IsNotNull(Parsed);
  finally
    Parsed.Free;
  end;
end;

Procedure TJsonEvalTests.AsStr_ArrayLeaf_ReturnsSerializedJson;
Var
  Value: String;
begin
  Assert.IsTrue(TJsonEvaluator.AsStr(FJson, ['Tags'], Value));
  // Create Json-array
  var Parsed := TJSONObject.ParseJSONValue(Value) as TJSONArray;
  try
    Assert.IsNotNull(Parsed);
    Assert.AreEqual(3, Parsed.Count);
  finally
    Parsed.Free;
  end;
end;

Procedure TJsonEvalTests.AsStr_MissingKey_ReturnsFalse;
Var
  Value: String;
begin
  Assert.IsFalse(TJsonEvaluator.AsStr(FJson, ['MISSING'], Value));
end;

Procedure TJsonEvalTests.AsStr_EmptyPath_ReturnsValue;
Var
  Value: String;
begin
  var JsonStr := TJSONString.Create('Alice');
  try
    Assert.IsTrue(TJsonEvaluator.AsStr(JsonStr, [], Value));
    Assert.AreEqual('Alice', Value);
  finally
    JsonStr.Free;
  end;
end;

// GetInt

Procedure TJsonEvalTests.GetInt_ValidNumber_ReturnsValue;
Var
  Value: Integer;
begin
  Assert.IsTrue(TJsonEvaluator.GetInt(FJson, ['Count'], Value));
  Assert.AreEqual(7, Value);
end;

Procedure TJsonEvalTests.GetInt_NestedKey_ReturnsValue;
Var
  Value: Integer;
begin
  // 'Count' is a JSON integer at root level
  Assert.IsTrue(TJsonEvaluator.GetInt(FJson, ['Count'], Value));
  Assert.AreEqual(7, Value);
end;

Procedure TJsonEvalTests.GetInt_StringValue_ReturnsFalse;
Var
  Value: Integer;
begin
  Assert.IsFalse(TJsonEvaluator.GetInt(FJson, ['Name'], Value));
end;

Procedure TJsonEvalTests.GetInt_MissingKey_ReturnsFalse;
Var
  Value: Integer;
begin
  Assert.IsFalse(TJsonEvaluator.GetInt(FJson, ['MISSING'], Value));
end;

Procedure TJsonEvalTests.GetInt_ArrayIndex_ReturnsValue;
Var
  Value: Integer;
begin
  // Scores[0] is 10
  Assert.IsTrue(TJsonEvaluator.GetInt(FJson, ['Scores', 0], Value));
  Assert.AreEqual(10, Value);
end;

Procedure TJsonEvalTests.GetInt_EmptyPath_ReturnsValue;
begin
  var JsonNum := TJSONNumber.Create(7);
  try
    var Value: Integer;
    Assert.IsTrue(TJsonEvaluator.GetInt(JsonNum, [], Value));
    Assert.AreEqual(7, Value);
  finally
    JsonNum.Free;
  end;
end;

// GetInt64

Procedure TJsonEvalTests.GetInt64_ValidNumber_ReturnsValue;
Var
  Value: Int64;
begin
  Assert.IsTrue(TJsonEvaluator.GetInt64(FJson, ['Count'], Value));
  Assert.AreEqual(Int64(7), Value);
end;

Procedure TJsonEvalTests.GetInt64_StringValue_ReturnsFalse;
Var
  Value: Int64;
begin
  Assert.IsFalse(TJsonEvaluator.GetInt64(FJson, ['Name'], Value));
end;

// GetFloat

Procedure TJsonEvalTests.GetFloat_ValidNumber_ReturnsValue;
Var
  Value: Float64;
begin
  Assert.IsTrue(TJsonEvaluator.GetFloat(FJson, ['Score'], Value));
  Assert.AreEqual(Float64(9.5), Value, 0.0001);
end;

Procedure TJsonEvalTests.GetFloat_StringValue_ReturnsFalse;
Var
  Value: Float64;
begin
  Assert.IsFalse(TJsonEvaluator.GetFloat(FJson, ['Name'], Value));
end;

Procedure TJsonEvalTests.GetFloat_EmptyPath_ReturnsValue;
begin
  var JsonNum := TJSONNumber.Create(9.5);
  try
    var Value: Float64;
    Assert.IsTrue(TJsonEvaluator.GetFloat(JsonNum, [], Value));
    Assert.AreEqual(Float64(9.5), Value, 0.0001);
  finally
    JsonNum.Free;
  end;
end;

// GetStrs

Procedure TJsonEvalTests.GetStrs_ValidArray_ReturnsValues;
Var
  Values: TArray<String>;
begin
  Assert.IsTrue(TJsonEvaluator.GetStrs(FJson, ['Tags'], Values));
  Assert.AreEqual(3, Integer(Length(Values)));
  Assert.AreEqual('alpha', Values[0]);
  Assert.AreEqual('beta',  Values[1]);
  Assert.AreEqual('gamma', Values[2]);
end;

Procedure TJsonEvalTests.GetStrs_EmptyPath_ReturnsValues;
Var
  Values: TArray<String>;
begin
  var Arr := FJson.Values['Tags'] as TJSONArray;
  Assert.IsTrue(TJsonEvaluator.GetStrs(Arr, [], Values));
  Assert.AreEqual(3, Integer(Length(Values)));
  Assert.AreEqual('alpha', Values[0]);
  Assert.AreEqual('beta',  Values[1]);
  Assert.AreEqual('gamma', Values[2]);
end;

Procedure TJsonEvalTests.GetStrs_NotAnArray_ReturnsFalse;
Var
  Values: TArray<String>;
begin
  Assert.IsFalse(TJsonEvaluator.GetStrs(FJson, ['Name'], Values));
end;

Procedure TJsonEvalTests.GetStrs_ElementNotAString_ReturnsFalse;
Var
  Values: TArray<String>;
begin
  Assert.IsFalse(TJsonEvaluator.GetStrs(FJson, ['Scores'], Values));
end;

// GetInts

Procedure TJsonEvalTests.GetInts_ValidArray_ReturnsValues;
Var
  Values: TArray<Integer>;
begin
  Assert.IsTrue(TJsonEvaluator.GetInts(FJson, ['Scores'], Values));
  Assert.AreEqual(3, Integer(Length(Values)));
  Assert.AreEqual(10, Values[0]);
  Assert.AreEqual(20, Values[1]);
  Assert.AreEqual(30, Values[2]);
end;

Procedure TJsonEvalTests.GetInts_EmptyPath_ReturnsValues;
Var
  Values: TArray<Integer>;
begin
  var Arr := FJson.Values['Scores'] as TJSONArray;
  Assert.IsTrue(TJsonEvaluator.GetInts(Arr, [], Values));
  Assert.AreEqual(3, Integer(Length(Values)));
  Assert.AreEqual(10, Values[0]);
  Assert.AreEqual(20, Values[1]);
  Assert.AreEqual(30, Values[2]);
end;

Procedure TJsonEvalTests.GetInts_NotAnArray_ReturnsFalse;
Var
  Values: TArray<Integer>;
begin
  Assert.IsFalse(TJsonEvaluator.GetInts(FJson, ['Name'], Values));
end;

Procedure TJsonEvalTests.GetInts_ElementNotAnInteger_ReturnsFalse;
Var
  Values: TArray<Integer>;
begin
  Assert.IsFalse(TJsonEvaluator.GetInts(FJson, ['Ratings'], Values));
end;

// GetFloats

Procedure TJsonEvalTests.GetFloats_ValidArray_ReturnsValues;
Var
  Values: TArray<Float64>;
begin
  Assert.IsTrue(TJsonEvaluator.GetFloats(FJson, ['Ratings'], Values));
  Assert.AreEqual(3, Integer(Length(Values)));
  Assert.AreEqual(Float64(1.5), Values[0], 0.0001);
  Assert.AreEqual(Float64(2.5), Values[1], 0.0001);
  Assert.AreEqual(Float64(3.5), Values[2], 0.0001);
end;

Procedure TJsonEvalTests.GetFloats_EmptyPath_ReturnsValues;
begin
  var Arr := FJson.Values['Ratings'] as TJSONArray;
  var Values: TArray<Float64>;
  Assert.IsTrue(TJsonEvaluator.GetFloats(Arr, [], Values));
  Assert.AreEqual(3, Integer(Length(Values)));
  Assert.AreEqual(Float64(1.5), Values[0], 0.0001);
  Assert.AreEqual(Float64(2.5), Values[1], 0.0001);
  Assert.AreEqual(Float64(3.5), Values[2], 0.0001);
end;

Procedure TJsonEvalTests.GetFloats_NotAnArray_ReturnsFalse;
Var
  Values: TArray<Float64>;
begin
  Assert.IsFalse(TJsonEvaluator.GetFloats(FJson, ['Name'], Values));
end;

Procedure TJsonEvalTests.GetFloats_ElementNotANumber_ReturnsFalse;
Var
  Values: TArray<Float64>;
begin
  Assert.IsFalse(TJsonEvaluator.GetFloats(FJson, ['Tags'], Values));
end;

initialization
  TDUnitX.RegisterTestFixture(TJsonEvalTests);

end.
