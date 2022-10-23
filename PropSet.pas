unit PropSet;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils,Types,IOUtils,BaseDir,Parse;

Type
  TPropertySet = record
  private
    Type
      TProperty = record
        Name,Value: string;
      end;
    Var
      FReadOnly: Boolean;
      FNameValueSeparator: Char;
      FPropertiesSeparator: Char;
      FProperties: array of TProperty;
    Function IndexOf(const Name: String): Integer;
    Procedure SetNameValueSeparator(Separator: Char);
    Procedure SetPropertiesSeparator(Separator: Char);
    Function GetNames(Index: Integer): String; inline;
    Function GetValues(const Name: String): String; inline;
    Procedure SetValues(const Name,Value: String); inline;
    Function GetValueFromIndex(Index: Integer): String;
    Procedure SetValueFromIndex(Index: Integer; const Value: String);
    Function GetAsString: String;
    Procedure SetAsString(AsString: String);
    Function GetAsStrings: TStringDynArray;
    Procedure SetAsStrings(AsStrings: TStringDynArray);
    Procedure Append(const AsString: String); overload;
  public
    Class Var BaseDirectory: TBaseDirectory;
    Class Constructor Create;
  public
    Class Operator Initialize(out PropertySet: TPropertySet);
    Class Operator Assign(var Left: TPropertySet; const [ref] Right: TPropertySet);
    Class Operator Implicit(Properties: String): TPropertySet;
    Class Operator Implicit(Properties: TPropertySet): String;
    Class Operator Implicit(Properties: TStringDynArray): TPropertySet;
    Class Operator Implicit(Properties: TPropertySet): TStringDynArray;
  public
    Property ReadOnly: Boolean read FReadOnly;
    // Separator properties
    Property NameValueSeparator: Char read FNameValueSeparator write SetNameValueSeparator;
    Property PropertiesSeparator: Char read FPropertiesSeparator write SetPropertiesSeparator;
    // Type casts
    Property AsString: String read GetAsString write SetAsString;
    Property AsStrings: TStringDynArray read GetAsStrings write SetAsStrings;
    // Query content
    Function Count: Integer; inline;
    Function Contains(const Name: String): Boolean; overload;
    Function Contains(const Name: String; var Value: String): Boolean; overload;
    Function ContainsValue(const Name: String): Boolean; overload;
    Function ContainsValue(const Name: String; var Value: String): Boolean; overload;
    Property Names[Index: Integer]: String read GetNames;
    Property Values[const Name: String]: string read GetValues write SetValues; default;
    Property ValueFromIndex[Index: Integer]: String read GetValueFromIndex write SetValueFromIndex;
    // Convert property values
    Function ToStr(const Name,Default: String): String;
    Function ToInt(const Name: String): Integer; overload;
    Function ToInt(const Name: String; Default: Integer): Integer; overload;
    Function ToFloat(const Name: String): Float64; overload;
    Function ToFloat(const Name: String; Default: Float64): Float64; overload;
    Function ToBool(const Name,FalseStr,TrueStr: String): Boolean; overload;
    Function ToBool(const Name,FalseStr,TrueStr: String; Default: Boolean): Boolean; overload;
   	Function ToPath(const Name: String): String;
   	Function ToFileName(const Name: String): String; overload;
   	Function ToFileName(const Name,Extension: String): String; overload;
    Function Parse(const Name: String; Delimiter: TDelimiter = Comma): TStringParser;
    // Manage content
    Constructor Create(ReadOnly: Boolean); overload;
    Constructor Create(NameValueSeparator,PropertiesSeparator: Char; ReadOnly: Boolean = false); overload;
    Constructor Create(const [ref] Properties: TPropertySet; ReadOnly: Boolean = false); overload;
    Procedure Clear;
    Procedure RemoveUnassigned;
    Procedure Append(const Name,Value: String); overload;
    Procedure Append(const Properties: TPropertySet; SkipUnassigned,SkipDuplicates: Boolean); overload;
    Procedure Lock;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Constructor TPropertySet.Create;
begin
  BaseDirectory := ExtractFileDir(ParamStr(0));
end;

Class Operator TPropertySet.Initialize(out PropertySet: TPropertySet);
begin
  PropertySet.FReadOnly := false;
  PropertySet.FNameValueSeparator := '=';
  PropertySet.FPropertiesSeparator := ';';
end;

Class Operator TPropertySet.Assign(var Left: TPropertySet; const [ref] Right: TPropertySet);
begin
  Left.FReadOnly := Right.FReadOnly;
  Left.FNameValueSeparator := Right.FNameValueSeparator;
  Left.FPropertiesSeparator := Right.FPropertiesSeparator;
  Left.FProperties := Copy(Right.FProperties);
end;

Class Operator TPropertySet.Implicit(Properties: String): TPropertySet;
begin
  Result.AsString := Properties;
end;

Class Operator TPropertySet.Implicit(Properties: TPropertySet): String;
begin
  Result := Properties.AsString;
end;

Class Operator TPropertySet.Implicit(Properties: TStringDynArray): TPropertySet;
begin
  Result.AsStrings := Properties;
end;

Class Operator TPropertySet.Implicit(Properties: TPropertySet): TStringDynArray;
begin
  Result := Properties.AsStrings;
end;

Constructor TPropertySet.Create(ReadOnly: Boolean);
begin
  FReadOnly := ReadOnly;
  Finalize(FProperties);
end;

Constructor TPropertySet.Create(NameValueSeparator,PropertiesSeparator: Char; ReadOnly: Boolean = false);
begin
  FReadOnly := ReadOnly;
  FNameValueSeparator := NameValueSeparator;
  FPropertiesSeparator := PropertiesSeparator;
  Finalize(FProperties);
end;

Constructor TPropertySet.Create(const [ref] Properties: TPropertySet; ReadOnly: Boolean = false);
begin
  FReadOnly := ReadOnly;
  FNameValueSeparator := Properties.FNameValueSeparator;
  FPropertiesSeparator := Properties.FPropertiesSeparator;
  FProperties := Copy(Properties.FProperties);
end;

Function TPropertySet.IndexOf(const Name: String): Integer;
begin
  Result := -1;
  for var Prop := low(FProperties) to high(FProperties) do
  if SameText(FProperties[Prop].Name,Name) then
  begin
    Result := Prop;
    Break;
  end;
end;

Procedure TPropertySet.SetNameValueSeparator(Separator: Char);
begin
  Clear;
  FNameValueSeparator := Separator;
end;

Procedure TPropertySet.SetPropertiesSeparator(Separator: Char);
begin
  Clear;
  FPropertiesSeparator := Separator;
end;

Function TPropertySet.GetNames(Index: Integer): string;
begin
  Result := FProperties[Index].Name;
end;

Function TPropertySet.GetValues(const Name: String): String;
begin
  Contains(Name,Result);
end;

Procedure TPropertySet.SetValues(const Name,Value: String);
begin
  if not FReadOnly then
  begin
    var Index := IndexOf(Name);
    if Index >= 0 then
      FProperties[Index].Value := Value
    else
      raise Exception.Create('Property does not exist (' + Name + ')');
  end else
    raise Exception.Create('Cannot modify a read only property set');
end;

Function TPropertySet.GetValueFromIndex(Index: Integer): String;
begin
  Result := FProperties[Index].Value;
end;

Procedure TPropertySet.SetValueFromIndex(Index: Integer; const Value: String);
begin
  if not FReadOnly then
    FProperties[Index].Value := Value
  else
    raise Exception.Create('Cannot modify a read only property set');
end;

Function TPropertySet.GetAsString: String;
begin
  if Length(FProperties) > 0 then
  begin
    Result := FProperties[0].Name + FNameValueSeparator + FProperties[0].Value;
    for var Prop := 1 to Count-1 do
    Result := Result + FPropertiesSeparator + ' ' + FProperties[Prop].Name + FNameValueSeparator + FProperties[Prop].Value;
  end else Result := '';
end;

Procedure TPropertySet.SetAsString(AsString: string);
begin
  FProperties := nil;
  if AsString <> '' then
  begin
    var PropertySeparatorPos := Pos(FPropertiesSeparator,AsString);
    while PropertySeparatorPos > 0 do
    begin
      Append(Copy(AsString,1,PropertySeparatorPos-1));
      AsString := Trim(Copy(AsString,PropertySeparatorPos+1,MaxInt));
      PropertySeparatorPos := Pos(FPropertiesSeparator,AsString);
    end;
    // Append last property
    Append(AsString);
  end;
end;

Function TPropertySet.GetAsStrings: TStringDynArray;
begin
  SetLength(Result,Count);
  for var Prop := 0 to Count-1 do
  Result[Prop] := FProperties[Prop].Name + FNameValueSeparator + FProperties[Prop].Value;
end;

Procedure TPropertySet.SetAsStrings(AsStrings: TStringDynArray);
begin
  FProperties := nil;
  for var Prop := low(AsStrings) to high(AsStrings) do Append(AsStrings[Prop]);
end;

Function TPropertySet.Count: Integer;
begin
  Result := Length(FProperties);
end;

Function TPropertySet.Contains(const Name: String): Boolean;
Var
  Value: String;
begin
  Result := Contains(Name,Value);
end;

Function TPropertySet.Contains(const Name: String; var Value: String): Boolean;
begin
  Result := false;
  Value := '';
  for var Prop := low(FProperties) to high(FProperties) do
  if SameText(FProperties[Prop].Name,Name) then
  begin
    Result := true;
    Value := FProperties[Prop].Value;
    Break;
  end;
end;

Function TPropertySet.ContainsValue(const Name: String): Boolean;
Var
  Value: String;
begin
  Result := ContainsValue(Name,Value);
end;

Function TPropertySet.ContainsValue(const Name: String; var Value: String): Boolean;
begin
  if Contains(Name,Value) then
    Result := (Value <> '')
  else
    Result := false;
end;

Function TPropertySet.ToStr(const Name,Default: String): String;
begin
  if not Contains(Name,Result) then Result := Default;
end;

Function TPropertySet.ToInt(const Name: String): Integer;
begin
  try
    Result := GetValues(Name).ToInteger;
  except
    raise Exception.Create('Invalid integer value (' + Name + ')');
  end;
end;

Function TPropertySet.ToInt(const Name: String; Default: Integer): Integer;
Var
  Value: String;
begin
  if Contains(Name,Value) then
    try
      Result := GetValues(Name).ToInteger;
    except
      raise Exception.Create('Invalid integer value (' + Name + ')');
    end
  else
    Result := Default;
end;

Function TPropertySet.ToFloat(const Name: String): Float64;
begin
  try
    Result := GetValues(Name).ToDouble;
  except
    raise Exception.Create('Invalid floating point value (' + Name + ')');
  end;
end;

Function TPropertySet.ToFloat(const Name: String; Default: Float64): Float64;
Var
  Value: String;
begin
  if Contains(Name,Value) then
    try
      Result := GetValues(Name).ToDouble;
    except
      raise Exception.Create('Invalid floating point value (' + Name + ')');
    end
  else
    Result := Default;
end;

Function TPropertySet.ToBool(const Name,FalseStr,TrueStr: String): Boolean;
begin
  var Value := GetValues(Name);
  if SameText(Value,FalseStr) then Result := false else
  if SameText(Value,TrueStr) then Result := true else
  raise Exception.Create('Invalid boolean value (' + Name + ')');
end;

Function TPropertySet.ToBool(const Name,FalseStr,TrueStr: String; Default: Boolean): Boolean;
Var
  Value: String;
begin
  if Contains(Name,Value) then
  begin
    if SameText(Value,FalseStr) then Result := false else
    if SameText(Value,TrueStr) then Result := true else
    raise Exception.Create('Invalid boolean value (' + Name + ')')
  end else
    Result := Default;
end;

Function TPropertySet.ToPath(const Name: String): String;
begin
  if Contains(Name,Result) then
    Result := BaseDirectory.AbsolutePath(Result)
  else
    Result := '';
end;

Function TPropertySet.ToFileName(const Name: String): String;
begin
  // Set file name
  if Contains(Name,Result) then
    if Result <> '' then
      Result := BaseDirectory.AbsolutePath(Result)
    else
      Result := ''
  else
    Result := '';
end;

Function TPropertySet.ToFileName(const Name,Extension: String): String;
begin
  // Set file name
  if Contains(Name,Result) then
    if Result <> '' then
      Result := ChangeFileExt(BaseDirectory.AbsolutePath(Result),Extension)
    else
      Result := ''
  else
    Result := '';
end;

Function TPropertySet.Parse(const Name: String; Delimiter: TDelimiter = Comma): TStringParser;
Var
  Value: string;
begin
  if Contains(Name,Value) then
    Result := TStringParser.Create(Delimiter,Value)
  else
    Result := TStringParser.Create(Delimiter,'');
end;

Procedure TPropertySet.Clear;
begin
  Finalize(FProperties);
end;

Procedure TPropertySet.RemoveUnassigned;
begin
  var Index := 0;
  for var Prop := low(FProperties) to high(FProperties) do
  if FProperties[Prop].Value <> '' then
  begin
    if Index < Prop then FProperties[Index] := FProperties[Prop];
    Inc(Index);
  end;
  SetLength(FProperties,Index);
end;

Procedure TPropertySet.Append(const AsString: String);
begin
  if AsString <> '' then
  begin
    var NameValueSeparatorPos := Pos(FNameValueSeparator,AsString);
    if NameValueSeparatorPos > 0 then
    begin
      var Name := Trim(Copy(AsString,1,NameValueSeparatorPos-1));
      if Name <> '' then
        if IndexOf(Name) < 0 then
        begin
          var Value := Trim(Copy(AsString,NameValueSeparatorPos+1,MaxInt));
          Append(Name,Value);
        end else
          raise Exception.Create('Duplicate property (' + Name + ')')
      else
        raise Exception.Create('Missing Property Name');
    end else
      raise Exception.Create('Missing Name-Value separator (' + AsString + ')');
  end;
end;

Procedure TPropertySet.Append(const Name,Value: String);
begin
  if Name <> '' then
    if IndexOf(Name) < 0 then
    begin
      var Index := Count;
      SetLength(FProperties,Index+1);
      FProperties[Index].Name := Name;
      FProperties[Index].Value := Value;
    end else
      raise Exception.Create('Duplicate property (' + Name + ')')
  else
    raise Exception.Create('Missing Property Name');
end;

Procedure TPropertySet.Append(const Properties: TPropertySet; SkipUnassigned,SkipDuplicates: Boolean);
begin
  var Index := Count;
  SetLength(FProperties,Count+Properties.Count);
  for var Prop := 0 to Properties.Count-1 do
  begin
    var PropertyIndex := IndexOf(Properties.Names[Prop]);
    if  ((not SkipUnassigned) or (Properties.FProperties[Prop].Value <> ''))
    and ((not SkipDuplicates) or (PropertyIndex < 0)) then
    if PropertyIndex < 0 then
    begin
      FProperties[Index] := Properties.FProperties[Prop];
      Inc(Index);
    end else
      raise Exception.Create('Duplicate property (' + Properties.Names[Prop] + ')')
  end;
  SetLength(FProperties,Index);
end;

Procedure TPropertySet.Lock;
begin
  FReadOnly := true;
end;

end.
