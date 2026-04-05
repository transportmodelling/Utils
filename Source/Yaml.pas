unit Yaml;

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
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  System.Generics.Collections, Yaml.Parse;

Type
  EYamlParseException = Yaml.Parse.EYamlParseException;

  TYaml = record
  // TYaml parses a YAML document into a TJSONValue.
  // Anchors and aliases (&anchor / *alias) are not supported.
  // Multi-line flow collections (flow maps/arrays spanning more than one line) are not supported.
  public
    Class Function StringsToValue(const Yaml: array of String; Document: Integer = 0): TJSONValue; overload; static;
    Class Function StringsToValue(const Yaml: TStrings; Document: Integer = 0): TJSONValue; overload; static;
    Class Function StringToValue(const Yaml: String; Document: Integer = 0): TJSONValue; static;
    Class Function ReadValueFromFile(const FileName: TFileName; Document: Integer = 0): TJSONValue; static;

    Class Function StringsToObject(const Yaml: array of String; Document: Integer = 0): TJsonObject; overload; static;
    Class Function StringsToObject(const Yaml: TStrings; Document: Integer = 0): TJsonObject; overload; static;
    Class Function StringToObject(const Yaml: String; Document: Integer = 0): TJsonObject; static;
    Class Function ReadFromFile(const FileName: TFileName; Document: Integer = 0): TJsonObject; static;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Function TYaml.StringsToValue(const Yaml: array of String; Document: Integer = 0): TJSONValue;
begin
  var Parser := TYamlParser.Create;
  try
    Result := Parser.StringsToValue(Yaml, Document);
  finally
    Parser.Free;
  end;
end;

Class Function TYaml.StringsToValue(const Yaml: TStrings; Document: Integer = 0): TJSONValue;
begin
  Result := StringsToValue(Yaml.ToStringArray, Document);
end;

Class Function TYaml.StringToValue(const Yaml: String; Document: Integer = 0): TJSONValue;
begin
  Result := StringsToValue(Yaml.Split([sLineBreak]), Document);
end;

Class Function TYaml.ReadValueFromFile(const FileName: TFileName; Document: Integer = 0): TJSONValue;
begin
  Result := StringsToValue(TFile.ReadAllLines(FileName), Document);
end;

Class Function TYaml.StringsToObject(const Yaml: array of String; Document: Integer = 0): TJsonObject;
begin
  var Value := StringsToValue(Yaml, Document);
  if Value is TJsonObject then
    Result := TJsonObject(Value)
  else
  begin
    Value.Free;
    raise EYamlParseException.Create('YAML parse error: document root is not a mapping');
  end;
end;

Class Function TYaml.StringsToObject(const Yaml: TStrings; Document: Integer = 0): TJsonObject;
begin
  Result := StringsToObject(Yaml.ToStringArray, Document);
end;

Class Function TYaml.StringToObject(const Yaml: String; Document: Integer = 0): TJsonObject;
begin
  Result := StringsToObject(Yaml.Split([sLineBreak]), Document);
end;

Class Function TYaml.ReadFromFile(const FileName: TFileName; Document: Integer = 0): TJsonObject;
begin
  Result := StringsToObject(TFile.ReadAllLines(FileName), Document);
end;

end.
