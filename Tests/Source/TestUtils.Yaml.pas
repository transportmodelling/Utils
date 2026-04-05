unit TestUtils.Yaml;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  DUnitX.TestFramework, System.SysUtils, System.IOUtils, System.JSON, System.Generics.Collections, Yaml;

type
  [TestFixture]
  TYamlTests = class
  public
    [Test]
    procedure TestSimpleKeyValuePair;
    [Test]
    procedure TestNestedObjects;
    [Test]
    procedure TestBlockArray;
    [Test]
    procedure TestFlowArray;
    [Test]
    procedure TestFlowMap;
    [Test]
    procedure TestTypes;
    [Test]
    procedure TestComments;
    [Test]
    procedure TestMultilineLiteral;
    [Test]
    procedure TestMultilineFolded;
    [Test]
    procedure TestComplexStructure;
    [Test]
    procedure TestFalseAndNullVariants;
    [Test]
    procedure TestNumericValues;
    [Test]
    procedure TestSingleQuotedString;
    [Test]
    procedure TestBareKeyAndEmptyString;
    [Test]
    procedure TestBlockScalarFollowedByKey;
    [Test]
    procedure TestFlowArrayTypes;
    [Test]
    procedure TestMultiDocument;
    [Test]
    procedure TestStreamEnd;
    [Test]
    procedure TestColonInKey;
    [Test]
    procedure TestTypeTags;
    [Test]
    procedure TestChompingIndicators;
    [Test]
    procedure TestBareSequenceRootRaisesException;
    [Test]
    procedure TestBareScalarRootRaisesException;
    [Test]
    procedure TestStringToValueMapping;
    [Test]
    procedure TestStringToValueSequence;
    [Test]
    procedure TestStringToValueScalar;
    [Test]
    procedure TestReadFromFileSimpleKeys;
    [Test]
    procedure TestReadFromFileNestedObject;
    [Test]
    procedure TestReadFromFileBlockArray;
    [Test]
    procedure TestReadFromFileSecondDocument;
    [Test]
    procedure TestReadValueFromFile;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

procedure TYamlTests.TestSimpleKeyValuePair;
begin
  var Json := TYaml.StringToObject('Key: Value');
  try
    Assert.IsNotNull(Json);
    Assert.AreEqual('Value',Json.GetValue('Key').Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestNestedObjects;
begin
  var Json := TYaml.StringToObject('''
                                      Root:
                                        Child:
                                          Key: Value
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Root-object
    var Root := Json.GetValue('Root');
    Assert.IsNotNull(Root);
    Assert.IsTrue(Root is TJsonObject);
    // Assert Root-object has Child-object
    var RootObj := Root as TJsonObject;
    var Child := RootObj.GetValue('Child');
    Assert.IsNotNull(Child);
    Assert.IsTrue(Child is TJsonObject);
    // Assert Child-object has Key-property
    var ChildObj := Child as TJsonObject;
    Assert.AreEqual('Value',ChildObj.GetValue('Key').Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestBlockArray;
begin
  var Json := TYaml.StringToObject('''
                                     Items:
                                       - Item1
                                       - Item2
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Items-array
    var Items := Json.GetValue('Items');
    Assert.IsNotNull(Items);
    Assert.IsTrue(Items is TJsonArray);
    // Asssert correct Items-array
    var ItemsArr := Items as TJsonArray;
    Assert.AreEqual(2,ItemsArr.Count);
    Assert.AreEqual('Item1',ItemsArr.Items[0].Value);
    Assert.AreEqual('Item2',ItemsArr.Items[1].Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestFlowArray;
begin
  var Json := TYaml.StringToObject('Items: [A, B, "C, D"]');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Items-array
    var Items := Json.GetValue('Items');
    Assert.IsNotNull(Items);
    Assert.IsTrue(Items is TJsonArray);
    // Asssert correct Items-array
    var ItemsArr := Items as TJsonArray;
    Assert.IsNotNull(ItemsArr);
    Assert.AreEqual(3,ItemsArr.Count);
    Assert.AreEqual('A',ItemsArr.Items[0].Value);
    Assert.AreEqual('B',ItemsArr.Items[1].Value);
    Assert.AreEqual('C, D',ItemsArr.Items[2].Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestFlowMap;
begin
  var Json := TYaml.StringToObject('Obj: {a: 1, b: 2}');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Obj-property
    var Obj := Json.GetValue('Obj');
    Assert.IsNotNull(Obj);
    Assert.IsTrue(Obj is TJsonObject);
    // Assert a-value equals 1
    var Map := Obj as TJsonObject;
    var AValue := Map.GetValue('a');
    Assert.IsNotNull(AValue);
    Assert.IsTrue(AValue is TJSONNumber);
    Assert.AreEqual(1,(Avalue as TJSONNumber).AsInt);
    // Assert b-value equals 2
    var BValue := Map.GetValue('b');
    Assert.IsNotNull(BValue);
    Assert.IsTrue(BValue is TJSONNumber);
    Assert.AreEqual(2,(BValue as TJSONNumber).AsInt);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestTypes;
begin
  var Json := TYaml.StringToObject('''
                                     Bool: true
                                     Int: 123
                                     Float: 1.5
                                     Null: null
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Bool-property
    var Bool := Json.GetValue('Bool');
    Assert.IsNotNull(Bool);
    Assert.IsTrue(Bool is TJSONTrue);
    // Assert Json-object has Int-property
    var Int := Json.GetValue('Int');
    Assert.IsNotNull(Int);
    Assert.IsTrue(Int is TJSONNumber);
    Assert.AreEqual(123,(Int as TJSONNumber).AsInt);
    // Assert Json-object has Float-property
    var Float := Json.GetValue('Float');
    Assert.IsNotNull(Float);
    Assert.IsTrue(Float is TJSONNumber);
    Assert.AreEqual(1.5,(Float as TJSONNumber).AsDouble,0.0001);
    // Assert Json-object has Null-property
    var Null := Json.GetValue('Null');
    Assert.IsNotNull(Null);
    Assert.IsTrue(Null is TJSONNull);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestComments;
begin
  var Json := TYaml.StringToObject('''
                                     Key: Value # Comment
                                     # Full Line Comment
                                     Quoted: "Value # Kept"
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Key-property
    var Key := Json.GetValue('Key');
    Assert.IsNotNull(Key);
    Assert.IsTrue(Key is TJSONValue);
    Assert.AreEqual('Value',(Key as TJsonValue).Value);
    // Assert Json-object has Quoted-property
    var Quoted := Json.GetValue('Quoted');
    Assert.IsNotNull(Quoted);
    Assert.IsTrue(Quoted is TJSONValue);
    Assert.AreEqual('Value # Kept',(Quoted as TJsonValue).Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestMultilineLiteral;
begin
  var Json := TYaml.StringToObject('''
                                     Text: |
                                       Line 1
                                       Line 2
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Text-property
    var Text := Json.GetValue('Text');
    Assert.IsNotNull(Text);
    Assert.IsTrue(Text is TJSONValue);
    Assert.AreEqual('Line 1' + sLineBreak + 'Line 2' + sLineBreak,(Text as TJSONValue).Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestMultilineFolded;
begin
  var Json := TYaml.StringToObject('''
                                     Text: >
                                       Word1
                                       Word2
                                   ''');
  try
    // Assert Json-object has Text-property
    var Text := Json.GetValue('Text');
    Assert.IsNotNull(Text);
    Assert.IsTrue(Text is TJSONValue);
    Assert.AreEqual('Word1 Word2' + sLineBreak,(Text as TJSONValue).Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestComplexStructure;
begin
  var Json := TYaml.StringToObject('''
                                     Config:
                                       Enabled: true
                                       Ports: [80, 443]
                                       Users:
                                        - Name: Admin
                                          Roles: [Read, Write]
                                        - Name: Guest
                                          Roles: [Read]
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Assert Json-object has Config-property
    var Config := Json.GetValue('Config');
    Assert.IsNotNull(Config);
    Assert.IsTrue(Config is TJsonObject);
    // Assert Config-object has Enabled-property
    var ConfigObj := Config as TJsonObject;
    var Enabled := ConfigObj.GetValue('Enabled');
    Assert.IsNotNull(Enabled);
    Assert.IsTrue(Enabled is TJSONTrue);
    // Assert Config-object has Ports-property
    var Ports := ConfigObj.GetValue('Ports');
    Assert.IsNotNull(Ports);
    Assert.IsTrue(Ports is TJsonArray);
    // Assert correct Ports-array length
    var PortsArr := Ports as TJsonArray;
    Assert.AreEqual(2,PortsArr.Count);
    // Assert Config-object has Users-property
    var Users := ConfigObj.GetValue('Users');
    Assert.IsNotNull(Users);
    Assert.IsTrue(Users is TJsonArray);
    // Asssert correct Users-array length
    var UsersArr := Users as TJsonArray;
    Assert.AreEqual(2,UsersArr.Count);
    // Asssert correct Users-array content
    var Admin := UsersArr.Items[0];
    Assert.IsNotNull(Admin);
    Assert.IsTrue(Admin is TJsonObject);
    // Assert Admin has Name-property
    var AdminObj := Admin as TJsonObject;
    var Name := AdminObj.GetValue('Name');
    Assert.IsNotNull(Name);
    Assert.IsTrue(Name is TJsonValue);
    Assert.AreEqual('Admin',(Name as TJsonValue).Value);
    // Assert Admin has Roles-property
    var Roles := AdminObj.GetValue('Roles');
    Assert.IsNotNull(Roles);
    Assert.IsTrue(Roles is TJsonArray);
    // Assert correct Roles-array length
    var RolesArr := Roles as TJsonArray;
    Assert.AreEqual(2,RolesArr.Count);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestFalseAndNullVariants;
begin
  var Json := TYaml.StringToObject('''
                                     False: false
                                     Tilde: ~
                                     Quoted: "123"
                                   ''');
  try
    Assert.IsNotNull(Json);
    // false -> TJSONFalse
    var F := Json.GetValue('False');
    Assert.IsNotNull(F);
    Assert.IsTrue(F is TJSONFalse);
    // ~ -> TJSONNull
    var T := Json.GetValue('Tilde');
    Assert.IsNotNull(T);
    Assert.IsTrue(T is TJSONNull);
    // "123" -> TJSONString (quotes force string, not number)
    var Q := Json.GetValue('Quoted');
    Assert.IsNotNull(Q);
    Assert.IsTrue(Q is TJSONString);
    Assert.AreEqual('123',Q.Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestNumericValues;
begin
  var Json := TYaml.StringToObject('''
                                     Float: 1.5
                                     Negative: -3.14
                                     Scientific: 1.0e3
                                     NegInt: -1
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Float -> 1.5
    var Float := Json.GetValue('Float');
    Assert.IsNotNull(Float);
    Assert.IsTrue(Float is TJSONNumber);
    Assert.AreEqual(1.5,(Float as TJSONNumber).AsDouble,0.0001);
    // Negative -> -3.14
    var Negative := Json.GetValue('Negative');
    Assert.IsNotNull(Negative);
    Assert.IsTrue(Negative is TJSONNumber);
    Assert.AreEqual(-3.14,(Negative as TJSONNumber).AsDouble,0.0001);
    // Scientific -> 1000.0
    var Scientific := Json.GetValue('Scientific');
    Assert.IsNotNull(Scientific);
    Assert.IsTrue(Scientific is TJSONNumber);
    Assert.AreEqual(1000.0,(Scientific as TJSONNumber).AsDouble,0.0001);
    // NegInt -> -1
    var NegInt := Json.GetValue('NegInt');
    Assert.IsNotNull(NegInt);
    Assert.IsTrue(NegInt is TJSONNumber);
    Assert.AreEqual(-1,(NegInt as TJSONNumber).AsInt);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestSingleQuotedString;
begin
  var Json := TYaml.StringToObject('Key: ''hello world''');
  try
    Assert.IsNotNull(Json);
    var V := Json.GetValue('Key');
    Assert.IsNotNull(V);
    Assert.IsTrue(V is TJSONString);
    Assert.AreEqual('hello world',V.Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestBareKeyAndEmptyString;
begin
  var Json := TYaml.StringToObject('''
                                     Bare:
                                     Empty: ''
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Bare: -> TJSONNull (no value = absent)
    var Bare := Json.GetValue('Bare');
    Assert.IsNotNull(Bare);
    Assert.IsTrue(Bare is TJSONNull);
    // Empty: '' -> TJSONString with empty value (quotes signal explicit empty string)
    var Empty := Json.GetValue('Empty');
    Assert.IsNotNull(Empty);
    Assert.IsTrue(Empty is TJSONString);
    Assert.AreEqual('',Empty.Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestBlockScalarFollowedByKey;
begin
  var Json := TYaml.StringToObject('''
                                     First: |
                                       Line 1
                                       Line 2
                                     Second: after
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Block scalar is parsed correctly
    var First := Json.GetValue('First');
    Assert.IsNotNull(First);
    Assert.IsTrue(First is TJSONString);
    Assert.AreEqual('Line 1' + sLineBreak + 'Line 2' + sLineBreak,First.Value);
    // Key after the block is also parsed
    var Second := Json.GetValue('Second');
    Assert.IsNotNull(Second);
    Assert.AreEqual('after',Second.Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestFlowArrayTypes;
begin
  var Json := TYaml.StringToObject('Items: [1, true, null, "str"]');
  try
    Assert.IsNotNull(Json);
    var Items := Json.GetValue('Items');
    Assert.IsNotNull(Items);
    Assert.IsTrue(Items is TJsonArray);
    var Arr := Items as TJsonArray;
    Assert.AreEqual(4,Arr.Count);
    // 1 -> TJSONNumber
    Assert.IsTrue(Arr.Items[0] is TJSONNumber);
    Assert.AreEqual(1,(Arr.Items[0] as TJSONNumber).AsInt);
    // true -> TJSONTrue
    Assert.IsTrue(Arr.Items[1] is TJSONTrue);
    // null -> TJSONNull
    Assert.IsTrue(Arr.Items[2] is TJSONNull);
    // "str" -> TJSONString
    Assert.IsTrue(Arr.Items[3] is TJSONString);
    Assert.AreEqual('str',Arr.Items[3].Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestMultiDocument;
begin
  var Yaml := '---' + sLineBreak +
              'DocA: first' + sLineBreak +
              '---' + sLineBreak +
              'DocB: second';
  // Document 0
  var Json0 := TYaml.StringToObject(Yaml,0);
  try
    Assert.IsNotNull(Json0);
    Assert.IsNotNull(Json0.GetValue('DocA'));
    Assert.AreEqual('first',Json0.GetValue('DocA').Value);
    Assert.IsNull(Json0.GetValue('DocB'));
  finally
    Json0.Free;
  end;
  // Document 1
  var Json1 := TYaml.StringToObject(Yaml,1);
  try
    Assert.IsNotNull(Json1);
    Assert.IsNotNull(Json1.GetValue('DocB'));
    Assert.AreEqual('second',Json1.GetValue('DocB').Value);
    Assert.IsNull(Json1.GetValue('DocA'));
  finally
    Json1.Free;
  end;
end;

procedure TYamlTests.TestStreamEnd;
begin
  var Json := TYaml.StringToObject('''
                                     Key: Value
                                     ...
                                     Ignored: yes
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Key before ... is present
    var Key := Json.GetValue('Key');
    Assert.IsNotNull(Key);
    Assert.AreEqual('Value',Key.Value);
    // Key after ... is absent
    Assert.IsNull(Json.GetValue('Ignored'));
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestColonInKey;
begin
  // Key containing a colon must not be split at the wrong position
  var Json := TYaml.StringToObject('''
                                     "host:port": localhost:8080
                                     plain: value
                                   ''');
  try
    Assert.IsNotNull(Json);
    // Quoted key with colon is parsed as a single key
    var V := Json.GetValue('host:port');
    Assert.IsNotNull(V);
    Assert.AreEqual('localhost:8080',V.Value);
    // Unrelated plain key still works
    Assert.AreEqual('value',Json.GetValue('plain').Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestTypeTags;
begin
  var Json := TYaml.StringToObject('''
                                     Str:   !!str 123
                                     Null:  !!null
                                     Bool:  !!bool true
                                     Float: !!float 1
                                   ''');
  try
    Assert.IsNotNull(Json);
    // !!str forces string even though value looks like a number
    var Str := Json.GetValue('Str');
    Assert.IsNotNull(Str);
    Assert.IsTrue(Str is TJSONString);
    Assert.AreEqual('123',Str.Value);
    // !!null forces null
    var Null := Json.GetValue('Null');
    Assert.IsNotNull(Null);
    Assert.IsTrue(Null is TJSONNull);
    // !!bool forces boolean
    var Bool := Json.GetValue('Bool');
    Assert.IsNotNull(Bool);
    Assert.IsTrue(Bool is TJSONTrue);
    // !!float forces float (1 parses as number either way, just confirm it is a number)
    var Float := Json.GetValue('Float');
    Assert.IsNotNull(Float);
    Assert.IsTrue(Float is TJSONNumber);
    Assert.AreEqual(1.0,(Float as TJSONNumber).AsDouble,0.0001);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestChompingIndicators;
begin
  // Strip chomping: |- removes all trailing newlines
  var JsonStrip := TYaml.StringToObject('''
                                          Strip: |-
                                            Line 1
                                            Line 2
                                        ''');
  try
    var Strip := JsonStrip.GetValue('Strip');
    Assert.IsNotNull(Strip);
    Assert.AreEqual('Line 1' + sLineBreak + 'Line 2',Strip.Value);
  finally
    JsonStrip.Free;
  end;
  // Keep chomping: |+ preserves trailing newlines
  var JsonKeep := TYaml.StringToObject('''
                                         Keep: |+
                                           Line 1
                                           Line 2
                                       ''');
  try
    var Keep := JsonKeep.GetValue('Keep');
    Assert.IsNotNull(Keep);
    Assert.AreEqual('Line 1' + sLineBreak + 'Line 2' + sLineBreak,Keep.Value);
  finally
    JsonKeep.Free;
  end;
  // Clip chomping: | (default) strips trailing blank lines and appends exactly one newline
  var JsonClip := TYaml.StringToObject('Clip: |' + sLineBreak +
                                       '  Line 1' + sLineBreak +
                                       '  Line 2' + sLineBreak +
                                       '' + sLineBreak +
                                       '' + sLineBreak +
                                       'Other: done');
  try
    var Clip := JsonClip.GetValue('Clip');
    Assert.IsNotNull(Clip);
    Assert.AreEqual('Line 1' + sLineBreak + 'Line 2' + sLineBreak, Clip.Value);
  finally
    JsonClip.Free;
  end;
  // Folded strip: >- collapses lines and removes trailing newline
  var JsonFoldStrip := TYaml.StringToObject('''
                                               FoldStrip: >-
                                                 Word1
                                                 Word2
                                             ''');
  try
    var FoldStrip := JsonFoldStrip.GetValue('FoldStrip');
    Assert.IsNotNull(FoldStrip);
    Assert.AreEqual('Word1 Word2',FoldStrip.Value);
  finally
    JsonFoldStrip.Free;
  end;
end;

procedure TYamlTests.TestBareSequenceRootRaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      var Json := TYaml.StringToObject('''
                                         - Item1
                                         - Item2
                                       ''');
      Json.Free;
    end,
    EYamlParseException);
end;

procedure TYamlTests.TestBareScalarRootRaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      var Json := TYaml.StringToObject('just a scalar');
      Json.Free;
    end,
    EYamlParseException);
end;

procedure TYamlTests.TestStringToValueMapping;
begin
  // A mapping root returns a TJsonObject (same as StringToObject)
  var Value := TYaml.StringToValue('Key: Value');
  try
    Assert.IsNotNull(Value);
    Assert.IsTrue(Value is TJsonObject);
    Assert.AreEqual('Value',(Value as TJsonObject).GetValue('Key').Value);
  finally
    Value.Free;
  end;
end;

procedure TYamlTests.TestStringToValueSequence;
begin
  // A bare sequence root returns a TJSONArray
  var Value := TYaml.StringToValue('''
                                     - Alpha
                                     - Beta
                                     - Gamma
                                   ''');
  try
    Assert.IsNotNull(Value);
    Assert.IsTrue(Value is TJSONArray);
    var Arr := Value as TJSONArray;
    Assert.AreEqual(3,Arr.Count);
    Assert.AreEqual('Alpha',Arr.Items[0].Value);
    Assert.AreEqual('Beta',Arr.Items[1].Value);
    Assert.AreEqual('Gamma',Arr.Items[2].Value);
  finally
    Value.Free;
  end;
end;

procedure TYamlTests.TestStringToValueScalar;
begin
  // A bare scalar root returns the appropriate TJSONValue subclass
  var VNum := TYaml.StringToValue('42');
  try
    Assert.IsNotNull(VNum);
    Assert.IsTrue(VNum is TJSONNumber);
    Assert.AreEqual(42,(VNum as TJSONNumber).AsInt);
  finally
    VNum.Free;
  end;
  var VBool := TYaml.StringToValue('true');
  try
    Assert.IsNotNull(VBool);
    Assert.IsTrue(VBool is TJSONTrue);
  finally
    VBool.Free;
  end;
  var VStr := TYaml.StringToValue('hello');
  try
    Assert.IsNotNull(VStr);
    Assert.IsTrue(VStr is TJSONString);
    Assert.AreEqual('hello',VStr.Value);
  finally
    VStr.Free;
  end;
end;

procedure TYamlTests.TestReadFromFileSimpleKeys;
begin
  var FileName := TPath.GetFullPath(TPath.Combine(
    TPath.Combine(ExtractFileDir(ParamStr(0)), '..\Data'), 'sample.yaml'));
  var Json := TYaml.ReadFromFile(FileName);
  try
    Assert.IsNotNull(Json);
    // Name -> 'Alice'
    var Name := Json.GetValue('Name');
    Assert.IsNotNull(Name);
    Assert.AreEqual('Alice', Name.Value);
    // Age -> 30 (TJSONNumber)
    var Age := Json.GetValue('Age');
    Assert.IsNotNull(Age);
    Assert.IsTrue(Age is TJSONNumber);
    Assert.AreEqual(30, (Age as TJSONNumber).AsInt);
    // Score -> 9.5 (TJSONNumber)
    var Score := Json.GetValue('Score');
    Assert.IsNotNull(Score);
    Assert.IsTrue(Score is TJSONNumber);
    Assert.AreEqual(9.5, (Score as TJSONNumber).AsDouble, 0.0001);
    // Active -> true (TJSONTrue)
    var Active := Json.GetValue('Active');
    Assert.IsNotNull(Active);
    Assert.IsTrue(Active is TJSONTrue);
    // Notes -> null (TJSONNull)
    var Notes := Json.GetValue('Notes');
    Assert.IsNotNull(Notes);
    Assert.IsTrue(Notes is TJSONNull);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestReadFromFileNestedObject;
begin
  var FileName := TPath.GetFullPath(TPath.Combine(
    TPath.Combine(ExtractFileDir(ParamStr(0)), '..\Data'), 'sample.yaml'));
  var Json := TYaml.ReadFromFile(FileName);
  try
    Assert.IsNotNull(Json);
    // Address is a TJsonObject
    var Address := Json.GetValue('Address');
    Assert.IsNotNull(Address);
    Assert.IsTrue(Address is TJsonObject);
    var AddressObj := Address as TJsonObject;
    // City -> 'Amsterdam'
    var City := AddressObj.GetValue('City');
    Assert.IsNotNull(City);
    Assert.AreEqual('Amsterdam', City.Value);
    // Country -> 'Netherlands'
    var Country := AddressObj.GetValue('Country');
    Assert.IsNotNull(Country);
    Assert.AreEqual('Netherlands', Country.Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestReadFromFileBlockArray;
begin
  var FileName := TPath.GetFullPath(TPath.Combine(
    TPath.Combine(ExtractFileDir(ParamStr(0)), '..\Data'), 'sample.yaml'));
  var Json := TYaml.ReadFromFile(FileName);
  try
    Assert.IsNotNull(Json);
    // Tags is a TJSONArray with 3 items
    var Tags := Json.GetValue('Tags');
    Assert.IsNotNull(Tags);
    Assert.IsTrue(Tags is TJSONArray);
    var TagsArr := Tags as TJSONArray;
    Assert.AreEqual(3, TagsArr.Count);
    Assert.AreEqual('alpha', TagsArr.Items[0].Value);
    Assert.AreEqual('beta',  TagsArr.Items[1].Value);
    Assert.AreEqual('gamma', TagsArr.Items[2].Value);
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestReadFromFileSecondDocument;
begin
  var FileName := TPath.GetFullPath(TPath.Combine(
    TPath.Combine(ExtractFileDir(ParamStr(0)), '..\Data'), 'sample.yaml'));
  var Json := TYaml.ReadFromFile(FileName, 1);
  try
    Assert.IsNotNull(Json);
    // Name -> 'Bob'
    var Name := Json.GetValue('Name');
    Assert.IsNotNull(Name);
    Assert.AreEqual('Bob', Name.Value);
    // Age -> 25
    var Age := Json.GetValue('Age');
    Assert.IsNotNull(Age);
    Assert.IsTrue(Age is TJSONNumber);
    Assert.AreEqual(25, (Age as TJSONNumber).AsInt);
    // Keys from document 0 are absent
    Assert.IsNull(Json.GetValue('Address'));
    Assert.IsNull(Json.GetValue('Tags'));
  finally
    Json.Free;
  end;
end;

procedure TYamlTests.TestReadValueFromFile;
begin
  var FileName := TPath.GetFullPath(TPath.Combine(
    TPath.Combine(ExtractFileDir(ParamStr(0)), '..\Data'), 'sample.yaml'));
  var Value := TYaml.ReadValueFromFile(FileName);
  try
    Assert.IsNotNull(Value);
    Assert.IsTrue(Value is TJsonObject);
    Assert.AreEqual('Alice', (Value as TJsonObject).GetValue('Name').Value);
  finally
    Value.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TYamlTests);
end.
