unit Json.Eval;

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
  SysUtils, StrUtils, System.Generics.Collections, System.JSON, KeyVal;

Type
  TPathStep = record
  private
    IsIndex: Boolean;
    Key:     String;
    Index:   Integer;
  public
    Class operator Implicit(const AKey: String): TPathStep;
    Class operator Implicit(AIndex: Integer): TPathStep;
  end;

  TJsonEvaluator = record
  private
    Type
      TJsonTypeCast<T> = reference to Function(const JsonValue: TJsonValue; var Value: T): Boolean;
    Class Var
      FStringTypeCast: TJsonTypeCast<String>;
      FAsStringTypeCast: TJsonTypeCast<String>;
      FIntTypeCast: TJsonTypeCast<Integer>;
      FInt64TypeCast: TJsonTypeCast<Int64>;
      FFloatTypeCast: TJsonTypeCast<Float64>;
    Class Function StepToStr(const Step: TPathStep): String; static;
    Class Function CreateStringTypeCast: TJsonTypeCast<String>; static;
    Class Function CreateAsStringTypeCast: TJsonTypeCast<String>; static;
    Class Function CreateIntTypeCast: TJsonTypeCast<Integer>; static;
    Class Function CreateInt64TypeCast: TJsonTypeCast<Int64>; static;
    Class Function CreateFloatTypeCast: TJsonTypeCast<Float64>; static;
    Class Function TryGetArrayAtPath(JsonValue: TJSONValue; const Path: array of TPathStep; out Arr: TJSONArray): Boolean; static;
    Class Function TryParseArray<T>(const Arr: TJSONArray; const TypeCast: TJsonTypeCast<T>; out Values: TArray<T>): Boolean; static;
    Class Function GetValue<T>(const JsonValue: TJSONValue; const Path: array of TPathStep; 
                               const TypeCast: TJsonTypeCast<T>; const Default: T; out Value: T): Boolean; static;
    Class Function GetValues<T>(const JsonValue: TJSONValue; const Path: array of TPathStep; 
                                const TypeCast: TJsonTypeCast<T>; out Values: TArray<T>): Boolean; static;
  public
    Class Function TryNavigateTo(const JsonValue: TJSONValue; const Step: TPathStep; out Value: TJSONValue): Boolean; overload; static;
    Class Function TryNavigateTo(const JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TJSONValue): Boolean; overload; static;
    Class Function GetKeyValuePairs(JsonObject: TJSONObject; out Value: TKeyValuePairs): Boolean; overload; static;
    Class Function GetKeyValuePairs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TKeyValuePairs): Boolean; overload; static;
    Class Function GetStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean; static;
    Class Function GetInt(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Integer): Boolean; static;
    Class Function GetInt64(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Int64): Boolean; static;
    Class Function GetFloat(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Float64): Boolean; static;
    Class Function GetStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<String>): Boolean; static;
    Class Function GetInts(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<Integer>): Boolean; static;
    Class Function GetFloats(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<Float64>): Boolean; static;
    Class Function AsStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean; static;
    Class Function AsStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<String>): Boolean; static;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class operator TPathStep.Implicit(const AKey: String): TPathStep;
begin
  Result.IsIndex := False;
  Result.Key     := AKey;
  Result.Index   := 0;
end;

Class operator TPathStep.Implicit(AIndex: Integer): TPathStep;
begin
  Result.IsIndex := True;
  Result.Key     := '';
  Result.Index   := AIndex;
end;

////////////////////////////////////////////////////////////////////////////////

Class Function TJsonEvaluator.StepToStr(const Step: TPathStep): String;
// Returns a display string for a path step, used in error messages.
begin
  if Step.IsIndex then
    Result := '[' + IntToStr(Step.Index) + ']'
  else
    Result := Step.Key;
end;

Class Function TJsonEvaluator.CreateStringTypeCast: TJsonTypeCast<String>;
begin
  if not Assigned(FStringTypeCast) then
    FStringTypeCast :=
      Function(const JsonValue: TJsonValue; var Value: String): Boolean
      begin
        // In older Delphi-versions TJSONNumber inherits from TJSONString!
        if (JsonValue is TJSONString) and not (JsonValue is TJSONNumber) then
        begin
          Result := true;
          Value := JsonValue.Value
        end else
          Result := false;
      end;
  Result := FStringTypeCast;
end;

Class Function TJsonEvaluator.CreateAsStringTypeCast: TJsonTypeCast<String>;
begin
  if not Assigned(FAsStringTypeCast) then
    FAsStringTypeCast :=
      Function(const JsonValue: TJsonValue; var Value: String): Boolean
      begin
        Result := true;
        if (JsonValue is TJSONObject) or (JsonValue is TJSONArray) then Value := JsonValue.ToJSON else
        if JsonValue is TJSONNull then Value := '' else Value := JsonValue.Value;
      end;
  Result := FAsStringTypeCast;
end;

Class Function TJsonEvaluator.CreateIntTypeCast: TJsonTypeCast<Integer>;
begin
  if not Assigned(FIntTypeCast) then
    FIntTypeCast :=
      Function(const JsonValue: TJsonValue; var Value: Integer): Boolean
      begin
        Result := (JsonValue is TJSONNumber) and TryStrToInt(JsonValue.Value,Value);
      end;
  Result := FIntTypeCast;
end;

Class Function TJsonEvaluator.CreateInt64TypeCast: TJsonTypeCast<Int64>;
begin
  if not Assigned(FInt64TypeCast) then
    FInt64TypeCast :=
      Function(const JsonValue: TJsonValue; var Value: Int64): Boolean
      begin
        Result := (JsonValue is TJSONNumber) and TryStrToInt64(JsonValue.Value,Value);
      end;
  Result := FInt64TypeCast;
end;

Class Function TJsonEvaluator.CreateFloatTypeCast: TJsonTypeCast<Float64>;
begin
  if not Assigned(FFloatTypeCast) then
    FFloatTypeCast :=
      Function(const JsonValue: TJsonValue; var Value: Float64): Boolean
      begin
        Result := (JsonValue is TJSONNumber) and TryStrToFloat(JsonValue.Value,Value);
      end;
  Result := FFloatTypeCast;
end;

Class Function TJsonEvaluator.TryGetArrayAtPath(JsonValue: TJSONValue; const Path: array of TPathStep; out Arr: TJSONArray): Boolean;
Var
  Target: TJSONValue;
begin
  Result := TryNavigateTo(JsonValue,Path,Target) and (Target is TJSONArray);
  if Result then Arr := TJSONArray(Target) else Arr := nil;
end;

Class Function TJsonEvaluator.TryParseArray<T>(const Arr: TJSONArray;
                                               const TypeCast: TJsonTypeCast<T>;
                                               out   Values: TArray<T>): Boolean;
begin
  Result := true;
  SetLength(Values,Arr.Count);
  for var Index := 0 to Arr.Count-1 do
  if not TypeCast(Arr.Items[Index],Values[Index]) then
  begin
    Result := false;
    Values := nil;
    Break;
  end;
end;

Class Function TJsonEvaluator.GetValue<T>(const JsonValue: TJSONValue; const Path: array of TPathStep; 
                                          const TypeCast: TJsonTypeCast<T>; const Default: T; out Value: T): Boolean;
Var
  Leaf: TJsonValue;
begin
  if TryNavigateTo(JsonValue,Path,Leaf) then
    Result := TypeCast(Leaf,Value)
  else
    begin
      Result := false;
      Value := Default;
    end;
end;

Class Function TJsonEvaluator.GetValues<T>(const JsonValue: TJSONValue; const Path: array of TPathStep; 
                                           const TypeCast: TJsonTypeCast<T>; out Values: TArray<T>): Boolean;
Var
  Arr: TJSONArray;
begin
  Values := nil;
  Result := TryGetArrayAtPath(JsonValue,Path,Arr) and TryParseArray<T>(Arr,TypeCast,Values);
end;

Class Function TJsonEvaluator.TryNavigateTo(const JsonValue: TJSONValue; const Step: TPathStep; out Value: TJSONValue): Boolean;
// Applies a single step to Value:
//   - A string step expects Value to be a TJSONObject and finds the named field (case-insensitive).
//   - An integer step expects Value to be a TJSONArray and returns the element at that index.
begin
  Result := false;
  Value := nil;
  if Step.IsIndex then
  begin
    if JsonValue is TJSONArray then
    begin
      var Arr := TJSONArray(JsonValue);
      if (Step.Index >= 0) and (Step.Index < Arr.Count) then
      begin
        Result := true;
        Value := Arr.Items[Step.Index];
      end
    end;
  end else
  begin
    if JsonValue is TJSONObject then
    for var Pair in TJSONObject(JsonValue) do
    if SameText(Pair.JsonString.Value,Step.Key) then
    begin
      Result := true;
      Value := Pair.JsonValue;
      Break;
    end;
  end;
end;

Class Function TJsonEvaluator.TryNavigateTo(const JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TJSONValue): Boolean;
// Walks Root one step at a time through Path by calling TryNavigateTo for each step.
// Returns the TJSONValue reached at the end of the path.
begin
  Result := true;
  Value := JsonValue;
  for var Step := 0 to Length(Path)-1 do
  if not TryNavigateTo(Value,Path[Step],Value) then
  begin
    Value := nil;
    Result := false;
    Break;
  end;
end;

Class Function TJsonEvaluator.GetKeyValuePairs(JsonObject: TJSONObject; out Value: TKeyValuePairs): Boolean;
// Extracts all immediate key-value pairs from JsonObject.
// For scalar values (string, number, bool, null) the string representation is used as the value.
// For sub-object and array values the serialized JSON text is used.
// Returns True on success; False if JsonObject is nil.
Var
  PairValue: String;
begin
  if Assigned(JsonObject) then
  begin
    Result := True;
    Value.Clear;
    for var Pair in JsonObject do
    begin
      CreateAsStringTypeCast()(Pair.JsonValue,PairValue);
      Value.Append(Pair.JsonString.Value, PairValue);
    end;
  end else
    Result := false;
end;

Class Function TJsonEvaluator.GetKeyValuePairs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TKeyValuePairs): Boolean;
// Navigates into JsonValue by following Path, then extracts all immediate key-value pairs from the resulting sub-object.
// An empty Path treats JsonValue itself as the target.
// Returns True if the target resolves to a TJSONObject; False otherwise.
Var
  Target: TJsonValue;
begin
  Result := false;
  Value.Clear;
  if TryNavigateTo(JsonValue,Path,Target) then
  if Target is TJSONObject then
  Result := GetKeyValuePairs(TJSONObject(Target),Value)
end;

Class Function TJsonEvaluator.GetStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean;
// Returns True and sets Value to the string at Path if the leaf is a TJSONString.
// Returns False on missing path, wrong type, or any navigation error.
begin
  Result := GetValue<String>(JsonValue,Path,CreateStringTypeCast(),'',Value);
end;

Class Function TJsonEvaluator.GetInt(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Integer): Boolean;
// Returns True and sets Value to the integer at Path if the leaf is a TJSONNumber
// convertible to Integer. Returns False on missing path, wrong type, or conversion failure.
begin
  Result := GetValue<Integer>(JsonValue,Path,CreateIntTypeCast(),0,Value);
end;

Class Function TJsonEvaluator.GetInt64(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Int64): Boolean;
// Returns True and sets Value to the Int64 at Path if the leaf is a TJSONNumber
// convertible to Int64. Returns False on missing path, wrong type, or conversion failure.
begin
  Result := GetValue<Int64>(JsonValue,Path,CreateInt64TypeCast(),0,Value);
end;

Class Function TJsonEvaluator.GetFloat(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Float64): Boolean;
// Returns True and sets Value to the Float64 at Path if the leaf is a TJSONNumber
// convertible to Float64. Returns False on missing path, wrong type, or conversion failure.
begin
  Result := GetValue<Float64>(JsonValue,Path,CreateFloatTypeCast(),0.0,Value);
end;

Class Function TJsonEvaluator.GetStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<String>): Boolean;
// Returns True and sets Value to a TArray<String> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONString.
// Returns False on missing path, wrong container type, or any non-string element.
begin
  Result := GetValues<String>(JsonValue,Path,CreateStringTypeCast(),Values);
end;

Class Function TJsonEvaluator.GetInts(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<Integer>): Boolean;
// Returns True and sets Value to a TArray<Integer> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONNumber convertible to Integer.
// Returns False on missing path, wrong container type, or any non-integer element.
begin
  Result := GetValues<Integer>(JsonValue,Path,CreateIntTypeCast(),Values);
end;

Class Function TJsonEvaluator.GetFloats(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<Float64>): Boolean;
// Returns True and sets Value to a TArray<Float64> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONNumber convertible to Float64.
// Returns False on missing path, wrong container type, or any non-float element.
begin
  Result := GetValues<Float64>(JsonValue,Path,CreateFloatTypeCast(),Values);
end;

Class Function TJsonEvaluator.AsStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean;
// Navigates to Path and converts any leaf to a String:
// - TJSONString, TJSONNumber, TJSONBool, TJSONNull: TJSONValue.Value
// - TJSONObject, TJSONArray: serialized JSON text via ToJSON
// Returns False only when navigation fails (missing key, out-of-range index, wrong container).
begin
  Result := GetValue<String>(JsonValue,Path,CreateAsStringTypeCast(),'',Value);
end;

Class Function TJsonEvaluator.AsStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Values: TArray<String>): Boolean;
// Returns True and sets Value to a TArray<String> of all elements at Path if the
// target is a TJSONArray. Each element is converted to a String via AsStr, so any
// JSON type (string, number, bool, null, object, array) is accepted.
// Returns False on missing path, wrong container type, or any navigation error.
begin
  Result := GetValues<String>(JsonValue,Path,CreateAsStringTypeCast(),Values);
end;

end.
