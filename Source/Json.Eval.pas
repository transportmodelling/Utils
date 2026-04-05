unit Json.Eval;

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
    Class Function NavigatePath(Root: TJSONValue; const Path: array of TPathStep): TJSONValue; static;
  public
    Class Function NavigateTo(const JsonValue: TJSONValue; const Step: TPathStep): TJSONValue; static;
    Class Function GetKeyValuePairs(JsonObject: TJSONObject; out Value: TKeyValuePairs): Boolean; overload; static;
    Class Function GetKeyValuePairs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TKeyValuePairs): Boolean; overload; static;
    Class Function GetStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean; static;
    Class Function AsStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean; static;
    Class Function GetInt(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Integer): Boolean; static;
    Class Function GetInt64(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Int64): Boolean; static;
    Class Function GetFloat(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Float64): Boolean; static;
    Class Function GetStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<String>): Boolean; static;
    Class Function GetInts(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Integer>): Boolean; static;
    Class Function GetFloats(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Float64>): Boolean; static;
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

Class Function TJsonEvaluator.NavigateTo(const JsonValue: TJSONValue; const Step: TPathStep): TJSONValue;
// Applies a single step to Value:
//   - A string step expects Value to be a TJSONObject and finds the named field (case-insensitive).
//   - An integer step expects Value to be a TJSONArray and returns the element at that index.
// Raises if the step is missing, out of range, or hits the wrong container type.
begin
  if Step.IsIndex then
    if JsonValue is TJSONArray then
    begin
      var Arr := TJSONArray(JsonValue);
      if (Step.Index >= 0) and (Step.Index < Arr.Count) then
        Result := Arr.Items[Step.Index]
      else
        raise Exception.CreateFmt('JSON array index [%d] is out of range (count: %d)', [Step.Index, Arr.Count]);
    end else
      raise Exception.CreateFmt('JSON path step [%d]: current value is not an array', [Step.Index])
  else
    if JsonValue is TJSONObject then
    begin
      Result := nil;
      for var Pair in TJSONObject(JsonValue) do
        if SameText(Pair.JsonString.Value, Step.Key) then
        begin
          Result := Pair.JsonValue;
          Break;
        end;
      if not Assigned(Result) then raise Exception.CreateFmt('JSON key (%s) does not exist', [Step.Key]);
    end else
      raise Exception.CreateFmt('JSON path step (%s): current value is not an object', [Step.Key]);
end;

Class Function TJsonEvaluator.NavigatePath(Root: TJSONValue; const Path: array of TPathStep): TJSONValue;
// Walks Root one step at a time through Path by calling NavigateTo for each step.
// Returns the TJSONValue reached at the end of the path.
begin
  Result := Root;
  for var Step in Path do Result := NavigateTo(Result, Step);
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
begin
  Value.Clear;
  try
    var Target := NavigatePath(JsonValue,Path);
    if Target is TJSONObject then
      Result := GetKeyValuePairs(TJSONObject(Target), Value)
    else
      Result := False;
  except
    Result := False;
  end;
end;

Class Function TJsonEvaluator.GetStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean;
// Returns True and sets Value to the string at Path if the leaf is a TJSONString.
// Returns False on missing path, wrong type, or any navigation error.
begin
  try
    var Leaf := NavigatePath(JsonValue, Path);
    if Leaf is TJSONString then
    begin
      Value := Leaf.Value;
      Result := True;
    end else
      Result := False;
  except
    Result := False;
  end;
  if not Result then Value := '';
end;

Class Function TJsonEvaluator.AsStr(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: String): Boolean;
// Navigates to Path and converts any leaf to a String:
// - TJSONString, TJSONNumber, TJSONBool, TJSONNull: TJSONValue.Value
// - TJSONObject, TJSONArray: serialized JSON text via ToJSON
// Returns False only when navigation fails (missing key, out-of-range index, wrong container).
begin
  try
    var Leaf := NavigatePath(JsonValue, Path);
    if (Leaf is TJSONObject) or (Leaf is TJSONArray) then
      Value := Leaf.ToJSON
    else if Leaf is TJSONNull then
      Value := ''
    else
      Value := Leaf.Value;
    Result := True;
  except
    Value := '';
    Result := False;
  end;
end;

Class Function TJsonEvaluator.GetInt(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Integer): Boolean;
// Returns True and sets Value to the integer at Path if the leaf is a TJSONNumber
// convertible to Integer. Returns False on missing path, wrong type, or conversion failure.
begin
  try
    var Leaf := NavigatePath(JsonValue,Path);
    if Leaf is TJSONNumber then
      Result := TryStrToInt(Leaf.Value,Value)
    else
      Result := False;
  except
    Result := False;
  end;
  if not Result then Value := 0;
end;

Class Function TJsonEvaluator.GetInt64(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Int64): Boolean;
// Returns True and sets Value to the Int64 at Path if the leaf is a TJSONNumber
// convertible to Int64. Returns False on missing path, wrong type, or conversion failure.
begin
  try
    var Leaf := NavigatePath(JsonValue,Path);
    if Leaf is TJSONNumber then
      Result := TryStrToInt64(Leaf.Value, Value)
    else
      Result := False;
  except
    Result := False;
  end;
  if not Result then Value := 0;
end;

Class Function TJsonEvaluator.GetFloat(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: Float64): Boolean;
// Returns True and sets Value to the Float64 at Path if the leaf is a TJSONNumber
// convertible to Float64. Returns False on missing path, wrong type, or conversion failure.
begin
  try
    var Leaf := NavigatePath(JsonValue, Path);
    if Leaf is TJSONNumber then
      Result := TryStrToFloat(Leaf.Value,Value)
    else
      Result := False;
  except
    Result := False;
  end;
  if not Result then Value := 0;
end;

Class Function TJsonEvaluator.GetStrs(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<String>): Boolean;
// Returns True and sets Value to a TArray<String> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONString.
// Returns False on missing path, wrong container type, or any non-string element.
begin
  try
    var Target := NavigatePath(JsonValue,Path);
    if Target is TJSONArray then
    begin
      var Arr := TJSONArray(Target);
      Result := True;
      SetLength(Value,Arr.Count);
      for var Index := 0 to Arr.Count-1 do
      if Arr.Items[Index] is TJSONString then
        Value[Index] := Arr.Items[Index].Value
      else
        begin
          Value := nil;
          Exit(false);
        end;
    end else
      Result := False;
  except
    Value := nil;
    Result := False;
  end;
end;

Class Function TJsonEvaluator.GetInts(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Integer>): Boolean;
// Returns True and sets Value to a TArray<Integer> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONNumber convertible to Integer.
// Returns False on missing path, wrong container type, or any non-integer element.
begin
  try
    var Target := NavigatePath(JsonValue,Path);
    if Target is TJSONArray then
    begin
      var Arr := TJSONArray(Target);
      Result := True;
      SetLength(Value, Arr.Count);
      for var Index := 0 to Arr.Count-1 do
      if Arr.Items[Index] is TJSONNumber then
      begin
        if not TryStrToInt(Arr.Items[Index].Value,Value[Index]) then
        begin
          Value := nil;
          Exit(false);
        end;
     end else
     begin
       Value := nil;
       Exit(false);
     end;
    end else
    begin
      Value := nil;
      Result := False;
    end;
  except
    Value := nil;
    Result := False;
  end;
end;

Class Function TJsonEvaluator.GetFloats(JsonValue: TJSONValue; const Path: array of TPathStep; out Value: TArray<Float64>): Boolean;
// Returns True and sets Value to a TArray<Float64> of all elements at Path if the
// target is a TJSONArray whose elements are all TJSONNumber convertible to Float64.
// Returns False on missing path, wrong container type, or any non-float element.
begin
  try
    var Target := NavigatePath(JsonValue,Path);
    if Target is TJSONArray then
    begin
      var Arr := TJSONArray(Target);
      Result := True;
      SetLength(Value, Arr.Count);
      for var Index := 0 to Arr.Count-1 do
      if Arr.Items[Index] is TJSONNumber then
      begin
        if not TryStrToFloat(Arr.Items[Index].Value,Value[Index]) then
        begin
          Value := nil;
          Exit(false);
        end;
     end else
     begin
       Value := nil;
       Exit(false);
     end;
    end else
    begin
      Value := nil;
      Result := False;
    end;
  except
    Value := nil;
    Result := False;
  end;
end;

end.
