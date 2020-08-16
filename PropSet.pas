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
  SysUtils,Types,IOUtils,Parse;

Type
  TPropertySet = record
  private
    Type
      TProperty = record
        Name,Value: string;
      end;
    Class Var
      FBaseDirectory: String;
    Var
      FNameValueSeparator: Char;
      FPropertiesSeparator: Char;
      FProperties: array of TProperty;
    Class Procedure SetBaseDirectory(BaseDir: String); static;
    Function IndexOf(const Name: String): Integer;
    Procedure SetNameValueSeparator(Separator: Char);
    Procedure SetPropertiesSeparator(Separator: Char);
    Function GetNames(Index: Integer): String; inline;
    Function GetValues(const Name: String): String; inline;
    Function GetValueFromIndex(Index: Integer): String;
    Function GetAsString: String;
    Procedure SetAsString(AsString: String);
    Function GetAsStrings: TStringDynArray;
    Procedure SetAsStrings(AsStrings: TStringDynArray);
    Procedure Append(const AsString: String); overload;
  public
    Class Constructor Create;
    Class Property BaseDirectory: String read FBaseDirectory write SetBaseDirectory;
    Class Function FullPath(const RelativePath: String): String; static;
  public
    Class Operator Initialize(out PropertySet: TPropertySet);
    Class Operator Assign(var Left: TPropertySet; const [ref] Right: TPropertySet);
    Class Operator Implicit(Properties: String): TPropertySet;
    Class Operator Implicit(Properties: TPropertySet): String;
    Class Operator Implicit(Properties: TStringDynArray): TPropertySet;
    Class Operator Implicit(Properties: TPropertySet): TStringDynArray;
  public
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
    Property Names[Index: Integer]: String read GetNames;
    Property Values[const Name: String]: string read GetValues; default;
    Property ValueFromIndex[Index: Integer]: String read GetValueFromIndex;
    // Convert property values
    Function ToInt(const Name: String): Integer; overload;
    Function ToInt(const Name: String; Default: Integer): Integer; overload;
    Function ToFloat(const Name: String): Float64; overload;
    Function ToFloat(const Name: String; Default: Float64): Float64; overload;
   	Function ToPath(const Name: String): String;
    Function Parse(const Name: String; Delimiter: TDelimiter = Comma): TStringParser;
    // Manage content
    Constructor Create(NameValueSeparator,PropertiesSeparator: Char); overload;
    Constructor Create(const [ref] Properties: TPropertySet); overload;
    Procedure Clear;
    Procedure RemoveUnassigned;
    Procedure Append(const Name,Value: String); overload;
    Procedure Append(const Properties: TPropertySet; SkipUnassigned,SkipDuplicates: Boolean); overload;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Constructor TPropertySet.Create;
begin
  BaseDirectory := ExtractFileDir(ParamStr(0));
end;

Class Procedure TPropertySet.SetBaseDirectory(BaseDir: String);
begin
  FBaseDirectory := IncludeTrailingPathDelimiter(BaseDir);
end;

Class Function TPropertySet.FullPath(const RelativePath: String): String;
// Relative paths are assumed to be relative to the base directory
// of the property set instead of relative to the current directory
begin
  if TPath.IsRelativePath(RelativePath) then
    Result := ExpandFileName(FBaseDirectory+RelativePath)
  else
    Result := RelativePath;
end;

Class Operator TPropertySet.Initialize(out PropertySet: TPropertySet);
begin
  PropertySet.FNameValueSeparator := '=';
  PropertySet.FPropertiesSeparator := ';';
end;

Class Operator TPropertySet.Assign(var Left: TPropertySet; const [ref] Right: TPropertySet);
begin
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

Constructor TPropertySet.Create(NameValueSeparator,PropertiesSeparator: Char);
begin
  FNameValueSeparator := NameValueSeparator;
  FPropertiesSeparator := PropertiesSeparator;
  FProperties := nil;
end;

Constructor TPropertySet.Create(const [ref] Properties: TPropertySet);
begin
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

Function TPropertySet.GetValueFromIndex(Index: Integer): String;
begin
  Result := FProperties[Index].Value;
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
begin
  Result := false;
  for var Prop := low(FProperties) to high(FProperties) do
  if SameText(FProperties[Prop].Name,Name) then
  begin
    Result := true;
    Break;
  end;
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

Function TPropertySet.ToPath(const Name: String): String;
begin
  if Contains(Name,Result) then Result := FullPath(Result);
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

end.
