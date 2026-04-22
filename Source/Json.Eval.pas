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
    Class Function StepToStr(const Step: TPathStep): String; static;
  public
    Class Function TryNavigateTo(const JsonValue: TJSONValue; const Step: TPathStep; out Value: TJSONValue): Boolean; overload; static;
    Class Function TryNavigateTo(const JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TJSONValue): Boolean; overload; static;
    Class Function GetKeyValuePairs(JsonObject: TJSONObject; out Value: TKeyValuePairs): Boolean; overload; static;
    Class Function GetKeyValuePairs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TKeyValuePairs): Boolean; overload; static;
    Class Function GetStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean; static;
    Class Function GetInt(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Integer): Boolean; static;
    Class Function GetInt64(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Int64): Boolean; static;
    Class Function GetFloat(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Float64): Boolean; static;
    Class Function GetStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<String>): Boolean; static;
    Class Function GetInts(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Integer>): Boolean; static;
    Class Function GetFloats(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Float64>): Boolean; static;
    Class Function AsStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean; static;
    Class Function AsStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<String>): Boolean; static;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

// TPathStep

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

// TJsonEvaluator

Class Function TJsonEvaluator.StepToStr(const Step: TPathStep): String;
// Returns a display string for a path step, used in error messages.
begin
  if Step.IsIndex then
    Result := '[' + IntToStr(Step.Index) + ']'
  else
    Result := Step.Key;
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
      if (Pair.JsonValue is TJSONObject) or (Pair.JsonValue is TJSONArray) then
        PairValue := Pair.JsonValue.ToJSON
      else
        PairValue := Pair.JsonValue.Value;
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
Var
  Leaf: TJsonValue;
begin
  Result := false;
  Value := '';
  if TryNavigateTo(JsonValue,Path,Leaf) then
  // In older Delphi-versions TJSONNumber inherits from TJSONString!
  if (Leaf is TJSONString) and not (Leaf is TJSONNumber) then
  begin
    Result := true;
    Value := Leaf.Value;
  end;
end;

Class Function TJsonEvaluator.GetInt(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Integer): Boolean;
// Returns True and sets Value to the integer at Path if the leaf is a TJSONNumber
// convertible to Integer. Returns False on missing path, wrong type, or conversion failure.
Var
  Leaf: TJsonValue;
begin
  Result := false;
  Value := 0;
  if TryNavigateTo(JsonValue,Path,Leaf) then
  if Leaf is TJSONNumber then Result := TryStrToInt(Leaf.Value,Value)
end;

Class Function TJsonEvaluator.GetInt64(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Int64): Boolean;
// Returns True and sets Value to the Int64 at Path if the leaf is a TJSONNumber
// convertible to Int64. Returns False on missing path, wrong type, or conversion failure.
Var
  Leaf: TJsonValue;
begin
  Result := false;
  Value := 0;
  if TryNavigateTo(JsonValue,Path,Leaf) then
  if Leaf is TJSONNumber then Result := TryStrToInt64(Leaf.Value,Value)
end;

Class Function TJsonEvaluator.GetFloat(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Float64): Boolean;
// Returns True and sets Value to the Float64 at Path if the leaf is a TJSONNumber
// convertible to Float64. Returns False on missing path, wrong type, or conversion failure.
Var
  Leaf: TJsonValue;
begin
  Result := false;
  Value := 0;
  if TryNavigateTo(JsonValue,Path,Leaf) then
  if Leaf is TJSONNumber then Result := TryStrToFloat(Leaf.Value,Value)
end;

Class Function TJsonEvaluator.GetStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<String>): Boolean;
// Returns True and sets Value to a TArray<String> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONString.
// Returns False on missing path, wrong container type, or any non-string element.
Var
  Target: TJsonValue;
begin
  Result := false;
  Value := nil;
  if TryNavigateTo(JsonValue,Path,Target) then
  if Target is TJSONArray then
  begin
    var Arr := TJSONArray(Target);
    SetLength(Value,Arr.Count);
    for var Index := 0 to Arr.Count-1 do
    // In older Delphi-versions TJSONNumber inherits from TJSONString!
    if (Arr.Items[Index] is TJSONString) and not (Arr.Items[Index] is TJSONNumber) then
      Value[Index] := Arr.Items[Index].Value
    else
      begin
        Value := nil;
        Exit;
      end;
    Result := True;
  end;
end;

Class Function TJsonEvaluator.GetInts(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Integer>): Boolean;
// Returns True and sets Value to a TArray<Integer> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONNumber convertible to Integer.
// Returns False on missing path, wrong container type, or any non-integer element.
Var
  Target: TJsonValue;
begin
  Result := false;
  Value := nil;
  if TryNavigateTo(JsonValue,Path,Target) then
  if Target is TJSONArray then
  begin
    var Arr := TJSONArray(Target);
    SetLength(Value,Arr.Count);
    for var Index := 0 to Arr.Count-1 do
    if Arr.Items[Index] is TJSONNumber then
    begin
      if not TryStrToInt(Arr.Items[Index].Value,Value[Index]) then
      begin
        Value := nil;
        Exit;
      end;
    end else
    begin
      Value := nil;
      Exit;
    end;
    Result := True;
  end;
end;

Class Function TJsonEvaluator.GetFloats(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Float64>): Boolean;
// Returns True and sets Value to a TArray<Float64> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONNumber convertible to Float64.
// Returns False on missing path, wrong container type, or any non-float element.
Var
  Target: TJsonValue;
begin
  Result := false;
  Value := nil;
  if TryNavigateTo(JsonValue,Path,Target) then
  if Target is TJSONArray then
  begin
    var Arr := TJSONArray(Target);
    SetLength(Value,Arr.Count);
    for var Index := 0 to Arr.Count-1 do
    if Arr.Items[Index] is TJSONNumber then
    begin
      if not TryStrToFloat(Arr.Items[Index].Value,Value[Index]) then
      begin
        Value := nil;
        Exit;
      end;
    end else
    begin
      Value := nil;
      Exit;
    end;
    Result := True;
  end;
end;

Class Function TJsonEvaluator.AsStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean;
// Navigates to Path and converts any leaf to a String:
// - TJSONString, TJSONNumber, TJSONBool, TJSONNull: TJSONValue.Value
// - TJSONObject, TJSONArray: serialized JSON text via ToJSON
// Returns False only when navigation fails (missing key, out-of-range index, wrong container).
Var
  Leaf: TJsonValue;
begin
  if TryNavigateTo(JsonValue,Path,Leaf) then
  begin
    Result := true;
    if (Leaf is TJSONObject) or (Leaf is TJSONArray) then Value := Leaf.ToJSON else
    if Leaf is TJSONNull then Value := '' else Value := Leaf.Value;
  end else
  begin
    Result := false;
    Value := '';
  end;
end;

Class Function TJsonEvaluator.AsStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<String>): Boolean;
// Returns True and sets Value to a TArray<String> of all elements at Path if the
// target is a TJSONArray. Each element is converted to a String via AsStr, so any
// JSON type (string, number, bool, null, object, array) is accepted.
// Returns False on missing path, wrong container type, or any navigation error.
Var
  Target: TJsonValue;
begin
  Result := false;
  Value := nil;
  if TryNavigateTo(JsonValue,Path,Target) then
  if Target is TJSONArray then
  begin
    var Arr := TJSONArray(Target);
    SetLength(Value,Arr.Count);
    for var Index := 0 to Arr.Count-1 do
    if not AsStr(Arr.Items[Index],[],Value[Index]) then
    begin
      Result := false;
      Value := nil;
      Exit;
    end;
    Result := True;
  end;
end;

end.
