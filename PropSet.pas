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
  SysUtils;

Type
  TPropertySet = record
  private
    Type
      TProperty = record
        Name,Value: string;
      end;
    Const
      NameValueSeparator = '=';
      PropertiesSeparator = ';';
    Var
      FProperties: array of TProperty;
    Function IndexOf(const Name: String): Integer;
    Function GetNames(Index: Integer): String; inline;
    Function GetValues(const Name: String): String; inline;
    Function GetAsString: String;
    Procedure SetAsString(AsString: String);
    Procedure Append(const AsString: String); overload;
  public
    // Type casts
    Class Operator Implicit(AsString: String): TPropertySet;
    Class Operator Implicit(PropertySet: TPropertySet): String;
    // Query content
    Function Count: Integer; inline;
    Function Contains(const Name: String): Boolean; overload;
    Function Contains(const Name: String; var Value: String): Boolean; overload;
    Property Names[Index: Integer]: String read GetNames;
    Property Values[const Name: String]: string read GetValues; default;
    // Convert property values
    Function ToInt(const Name: String): Integer; overload;
    Function ToInt(const Name: String; Default: Integer): Integer; overload;
    Function ToFloat(const Name: String): Float64; overload;
    Function ToFloat(const Name: String; Default: Float64): Float64; overload;
    Property AsString: String read GetAsString write SetAsString;
    // Manage content
    Constructor Create(Properties: TPropertySet);
    Procedure Clear;
    Procedure Append(const Name,Value: String); overload;
    Procedure Append(const Properties: TPropertySet; SkipUnassigned,SkipDuplicates: Boolean); overload;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TPropertySet.Implicit(AsString: String): TPropertySet;
begin
  Result.SetAsString(AsString);
end;

Class Operator TPropertySet.Implicit(PropertySet: TPropertySet): String;
begin
  Result := PropertySet.GetAsString;
end;

Constructor TPropertySet.Create(Properties: TPropertySet);
begin
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

Function TPropertySet.GetNames(Index: Integer): string;
begin
  Result := FProperties[Index].Name;
end;

Function TPropertySet.GetValues(const Name: String): String;
begin
  Contains(Name,Result);
end;

Function TPropertySet.GetAsString: String;
begin
  if Length(FProperties) > 0 then
  begin
    Result := FProperties[0].Name + NameValueSeparator + FProperties[0].Value;
    for var Prop := 1 to Count-1 do
    Result := Result + PropertiesSeparator + ' ' + FProperties[Prop].Name + NameValueSeparator + FProperties[Prop].Value;
  end else Result := '';
end;

Procedure TPropertySet.SetAsString(AsString: string);
begin
  FProperties := nil;
  if AsString <> '' then
  begin
    var PropertySeparatorPos := Pos(PropertiesSeparator,AsString);
    while PropertySeparatorPos > 0 do
    begin
      Append(Copy(AsString,1,PropertySeparatorPos-1));
      AsString := Trim(Copy(AsString,PropertySeparatorPos+1,MaxInt));
      PropertySeparatorPos := Pos(PropertiesSeparator,AsString);
    end;
    // Append last property
    Append(AsString);
  end;
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

Procedure TPropertySet.Clear;
begin
  Finalize(FProperties);
end;

Procedure TPropertySet.Append(const AsString: String);
begin
  if AsString <> '' then
  begin
    var NameValueSeparatorPos := Pos(NameValueSeparator,AsString);
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
      raise Exception.Create('Missing Name-Value separator');
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
