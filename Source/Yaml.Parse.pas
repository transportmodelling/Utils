unit Yaml.Parse;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak (initial implementation generated with Claude Sonnet 4.6)
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  System.SysUtils, System.JSON, System.Generics.Collections, System.Classes;

Type
  EYamlParseException = class(Exception);

  TYamlParser = Class
  private
    Type
      TContext = record
        Node: TJSONValue;
        Indent: Integer;
      end;
    var
      FCurrentDocIndex: Integer;
      FDocStarted: Boolean;
      FContextStack: TList<TContext>;
      FLastPair: TJSONPair;
      FTargetDocument: Integer;
      FRootNode: TJSONValue;
      FStopParsing: Boolean;
      // Multiline Block Handling
      FCurrentBlock: String;
      FBlockIndent: Integer;
      FBlockType: Char;    // '|' or '>'
      FChompingStyle: Char; // ' '=clip (default), '-'=strip, '+'=keep
      FExplicitIndent: Integer; // 0 = auto-detect
    Function StripComment(const Line: String): String;
    Function UnQuotedString(const S: String): String;
    Function CountIndent(const S: String): Integer;
    Function SplitFlowItems(const Inner: String): TArray<String>;
    Function ParseFlowSequence(const S: String): TJSONArray;
    Function ParseFlowMap(const S: String): TJSONObject;
    Function ParseScalar(const S: String): TJSONValue;
    Function ParseFlowValue(const S: String): TJSONValue;
    Function FindKeySeparator(const YamlLine: String): Integer;
    Function HandleBlockScalarLine(const RawLine, YamlLine: String; LineIndent: Integer): Boolean;
    Procedure ResetContext;
    Procedure HandleDocumentSeparator;
    Procedure HandleStreamEnd;
    Procedure ApplyFoldedStyle;
    Procedure ApplyChomping;
    Procedure FinalizeBlockScalar;
    Procedure AdjustContext(LineIndent: Integer; IsListItem: Boolean);
    Procedure InitBlockScalar(const Value: String; Pair: TJSONPair);
    Procedure ParseKeyPair(const YamlLine: String);
    Procedure ParseListItem(const YamlLine: String; LineIndent: Integer);
    Procedure ParseLine(const RawLine: String);
  public
    Constructor Create;
    Function StringsToValue(const Yaml: array of String; Document: Integer = 0): TJSONValue;
    Function StringsToObject(const Yaml: array of String; Document: Integer = 0): TJsonObject;
    Destructor Destroy; override;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TYamlParser.Create;
begin
  inherited Create;
  FContextStack := TList<TContext>.Create;
end;

Function TYamlParser.UnQuotedString(const S: String): String;
begin
  Result := S;
  if (Length(Result) >= 2) and
     (((Result.StartsWith('"')) and (Result.EndsWith('"'))) or
      ((Result.StartsWith('''')) and (Result.EndsWith('''')))) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

Function TYamlParser.StripComment(const Line: String): String;
begin
  var InQuote := False;
  var QuoteChar := #0;
  Result := Line;
  for var i := 1 to Length(Line) do
  begin
    if (Line[i] = '"') or (Line[i] = '''') then
      if InQuote then
      begin
        if (Line[i] = QuoteChar) and ((i = 1) or (Line[i-1] <> '\')) then InQuote := False;
      end else
      begin
        InQuote := True;
        QuoteChar := Line[i];
      end
    else
      if (Line[i] = '#') and (not InQuote) then Exit(Trim(Copy(Line,1,i-1)));
  end;
end;

Function TYamlParser.ParseScalar(const S: String): TJSONValue;
begin
  var Unquoted := UnQuotedString(S);
  // If quoted, return string content without inference
  if (S.StartsWith('"') and S.EndsWith('"')) or
     (S.StartsWith('''') and S.EndsWith('''')) then Exit(TJSONString.Create(Unquoted));
  // Type tags: !!str, !!int, !!float, !!bool, !!null
  // Strip the tag prefix and optionally force a specific type
  var ForcedTag := '';
  var TaggedValue := Unquoted;
  if Unquoted.StartsWith('!!') then
  begin
    var SpacePos := Pos(' ', Unquoted);
    if SpacePos > 0 then
    begin
      ForcedTag := LowerCase(Copy(Unquoted, 3, SpacePos - 3));
      TaggedValue := Trim(Copy(Unquoted, SpacePos + 1, Length(Unquoted)));
    end  else
    begin
      // tag with no value (e.g. bare "!!null") — treat value as empty
      ForcedTag := LowerCase(Copy(Unquoted, 3, Length(Unquoted)));
      TaggedValue := '';
    end;
  end;

  if ForcedTag = 'str' then Exit(TJSONString.Create(TaggedValue));

  if ForcedTag = 'null' then Exit(TJSONNull.Create);

  if ForcedTag = 'bool' then
  if SameText(TaggedValue, 'true') then Exit(TJSONTrue.Create) else Exit(TJSONFalse.Create);

  // For !!int and !!float fall through to normal numeric parsing below,
  // using TaggedValue (tag stripped). For unknown/absent tags use Unquoted.
  var ParseTarget := Unquoted;
  if ForcedTag <> '' then ParseTarget := TaggedValue;

  // Booleans (YAML 1.2: true, false)
  if SameText(ParseTarget, 'true') then Exit(TJSONTrue.Create);
  if SameText(ParseTarget, 'false') then Exit(TJSONFalse.Create);

  // Nulls (YAML 1.2: null, ~)
  if SameText(ParseTarget, 'null') or (ParseTarget = '~') or (ParseTarget = '') then
    Exit(TJSONNull.Create);

  // Numbers
  var I: Int64;
  if TryStrToInt64(ParseTarget, I) then Exit(TJSONNumber.Create(I));

  var D: Double;
  if TryStrToFloat(ParseTarget, D, TFormatSettings.Invariant) then Exit(TJSONNumber.Create(D));

  // Fallback to string
  Result := TJSONString.Create(ParseTarget);
end;

Function TYamlParser.ParseFlowValue(const S: String): TJSONValue;
begin
  if S = '' then Exit(TJSONNull.Create);

  if (S.StartsWith('{')) then
  begin
     // Try standard JSON first
     Result := TJSONObject.ParseJSONValue(S);
     if Result <> nil then Exit;
     Result := ParseFlowMap(S);
     Exit;
  end;

  if (S.StartsWith('[')) then
  begin
     // Try standard JSON first
     Result := TJSONObject.ParseJSONValue(S);
     if Result <> nil then Exit;
     Result := ParseFlowSequence(S);
     Exit;
  end;

  Result := ParseScalar(S);
end;

Function TYamlParser.SplitFlowItems(const Inner: String): TArray<String>;
begin
  Result := [];
  var StartPos := 1;
  var Depth := 0;
  var InQuote := False;
  var QuoteChar := #0;

  for var i := 1 to Length(Inner) do
  begin
    var C := Inner[i];
    if InQuote then
    begin
      if (C = QuoteChar) and ((i = 1) or (Inner[i-1] <> '\')) then InQuote := False;
    end
    else
    begin
      if (C = '"') or (C = '''') then
      begin
        InQuote := True;
        QuoteChar := C;
      end
      else if (C = '{') or (C = '[') then Inc(Depth)
      else if (C = '}') or (C = ']') then Dec(Depth)
      else if (C = ',') and (Depth = 0) then
      begin
        Result := Result + [Trim(Copy(Inner, StartPos, i - StartPos))];
        StartPos := i + 1;
      end;
    end;
  end;

  if StartPos <= Length(Inner) then
    Result := Result + [Trim(Copy(Inner, StartPos, Length(Inner) - StartPos + 1))];
end;

Function TYamlParser.ParseFlowMap(const S: String): TJSONObject;
begin
  Result := TJsonObject.Create;
  if Length(S) <= 2 then Exit; // empty {}

  for var ItemStr in SplitFlowItems(Copy(S, 2, Length(S) - 2)) do
    if ItemStr <> '' then
    begin
      var SeparatorPos := Pos(':', ItemStr);
      if SeparatorPos > 0 then
      begin
        var KeyStr := UnQuotedString(Trim(Copy(ItemStr, 1, SeparatorPos - 1)));
        var ValStr := Trim(Copy(ItemStr, SeparatorPos + 1, Length(ItemStr)));
        Result.AddPair(KeyStr, ParseFlowValue(ValStr));
      end;
    end;
end;

Function TYamlParser.ParseFlowSequence(const S: String): TJSONArray;
begin
  Result := TJSONArray.Create;
  if Length(S) <= 2 then Exit; // empty []

  for var ItemStr in SplitFlowItems(Copy(S, 2, Length(S) - 2)) do
    if ItemStr <> '' then
      Result.AddElement(ParseFlowValue(ItemStr));
end;

Function TYamlParser.CountIndent(const S: String): Integer;
begin
  Result := 0;
  for var i := 1 to Length(S) do
  begin
    if S[i] = ' ' then
      Inc(Result)
    else
      Break;
  end;
end;

Procedure TYamlParser.ResetContext;
begin
  FContextStack.Clear;
  var Ctx: TContext;
  Ctx.Node := FRootNode;
  Ctx.Indent := -1;
  FContextStack.Add(Ctx);
  FLastPair := nil;
  FBlockType := #0;
  FCurrentBlock := '';
  FBlockIndent := -1;
  FChompingStyle := ' ';
  FExplicitIndent := 0;
end;

Procedure TYamlParser.HandleDocumentSeparator;
begin
  FinalizeBlockScalar;
  if FDocStarted then
    Inc(FCurrentDocIndex);
  FDocStarted := True;

  if FCurrentDocIndex > FTargetDocument then
    FStopParsing := True
  else if FCurrentDocIndex = FTargetDocument then
    ResetContext;
end;

Procedure TYamlParser.ApplyFoldedStyle;
begin
  // Folded style '>': join lines with spaces, blank lines become newlines
  var Folded := '';
  var Lines := TStringList.Create;
  try
    Lines.Text := FCurrentBlock;
    for var I := 0 to Lines.Count - 1 do
    begin
      var Line := Trim(Lines[I]);
      if Line = '' then
      begin
        if Folded <> '' then Folded := Trim(Folded) + sLineBreak + sLineBreak;
      end
      else
        Folded := Folded + Line + ' ';
    end;
    FCurrentBlock := Trim(Folded);
  finally
    Lines.Free;
  end;
end;

Procedure TYamlParser.ApplyChomping;
begin
  // YAML 1.2 chomping:
  //   Strip ('-'): remove all trailing newlines.
  //   Keep  ('+'): preserve trailing blank lines + one final newline.
  //   Clip  (' '): strip trailing newlines, then add exactly one back.
  case FChompingStyle of
    '-': FCurrentBlock := TrimRight(FCurrentBlock);
    '+': FCurrentBlock := FCurrentBlock + sLineBreak;
  else    FCurrentBlock := TrimRight(FCurrentBlock) + sLineBreak;
  end;
end;

Procedure TYamlParser.FinalizeBlockScalar;
begin
  if FBlockType = #0 then Exit;

  if FBlockType = '>' then
    ApplyFoldedStyle
  else
  begin
    // Literal style '|': remove the final trailing newline before chomping
    if FCurrentBlock.EndsWith(sLineBreak) then
      FCurrentBlock := Copy(FCurrentBlock, 1, Length(FCurrentBlock) - Length(sLineBreak));
  end;

  ApplyChomping;

  if (FLastPair <> nil) and (FLastPair.JsonValue is TJSONNull) then
    FLastPair.JsonValue := TJSONString.Create(FCurrentBlock);

  FBlockType := #0;
  FCurrentBlock := '';
  FBlockIndent := -1;
  FChompingStyle := ' ';
  FExplicitIndent := 0;
end;

Procedure TYamlParser.HandleStreamEnd;
begin
  FinalizeBlockScalar;
  if FCurrentDocIndex = FTargetDocument then
    FStopParsing := True;
end;

Procedure TYamlParser.AdjustContext(LineIndent: Integer; IsListItem: Boolean);
begin
  if FContextStack.Count = 0 then Exit;

  // Check if indentation increases (Child Object)
  if LineIndent > FContextStack.Last.Indent then
  begin
    if (FContextStack.Count = 1) and (FContextStack.Last.Indent = -1) then
    begin
      // Root level indentation definition
      var Ctx := FContextStack.Last;
      Ctx.Indent := LineIndent;
      FContextStack[0] := Ctx;
    end
    else if FLastPair <> nil then
    begin
      // Create new child object attached to LastPair
      var NewNode: TJSONValue;
      if IsListItem then
        NewNode := TJSONArray.Create
      else
        NewNode := TJsonObject.Create;

      FLastPair.JsonValue := NewNode;

      var Ctx: TContext;
      Ctx.Node := NewNode;
      Ctx.Indent := LineIndent;
      FContextStack.Add(Ctx);
    end;
  end
  else
  begin
    // Check if indentation decreases (End of Child Object)
    while (FContextStack.Count > 1) and (LineIndent < FContextStack.Last.Indent) do
    begin
      FContextStack.Delete(FContextStack.Count - 1);
    end;
  end;
end;

Function TYamlParser.FindKeySeparator(const YamlLine: String): Integer;
begin
  Result := 0;
  var InQuote := False;
  var QuoteChar := #0;
  for var i := 1 to Length(YamlLine) do
  begin
    var C := YamlLine[i];
    if InQuote then
    begin
      if (C = QuoteChar) and ((i = 1) or (YamlLine[i-1] <> '\')) then
        InQuote := False;
    end
    else
    begin
      if (C = '"') or (C = '''') then
      begin
        InQuote := True;
        QuoteChar := C;
      end
      else if C = ':' then
      begin
        if (i < Length(YamlLine)) and (YamlLine[i+1] = ' ') then
          Exit(i);
        if i = Length(YamlLine) then
          Exit(i);
      end;
    end;
  end;
end;

Procedure TYamlParser.InitBlockScalar(const Value: String; Pair: TJSONPair);
begin
  FBlockType    := Value[1];
  FCurrentBlock := '';
  FBlockIndent  := -1;
  FChompingStyle  := ' ';
  FExplicitIndent := 0;
  for var mi := 2 to Length(Value) do
  begin
    if Value[mi] = '-' then FChompingStyle := '-'
    else if Value[mi] = '+' then FChompingStyle := '+'
    else if (Value[mi] >= '1') and (Value[mi] <= '9') then
      FExplicitIndent := Ord(Value[mi]) - Ord('0');
  end;
  Pair.JsonValue := TJSONNull.Create;
end;

Procedure TYamlParser.ParseKeyPair(const YamlLine: String);
begin
  var SeparatorPos := FindKeySeparator(YamlLine);
  if SeparatorPos > 0 then
  begin
    var Key := UnQuotedString(Trim(Copy(YamlLine, 1, SeparatorPos - 1)));
    var Value := '';
    if SeparatorPos < Length(YamlLine) then
      Value := Trim(Copy(YamlLine, SeparatorPos + 1, Length(YamlLine)));
    var Pair := TJSONPair.Create(Key, ParseFlowValue(Value));
    if FContextStack.Last.Node is TJsonObject then
      TJsonObject(FContextStack.Last.Node).AddPair(Pair);
    FLastPair := Pair;
    if (Length(Value) >= 1) and ((Value[1] = '|') or (Value[1] = '>')) then
      InitBlockScalar(Value, Pair);
  end
  else
  begin
    var Scalar := ParseScalar(YamlLine);
    FRootNode.Free;
    FRootNode := Scalar;
    var Ctx := FContextStack[0];
    Ctx.Node := FRootNode;
    FContextStack[0] := Ctx;
    FStopParsing := True;
  end;
end;

Procedure TYamlParser.ParseListItem(const YamlLine: String; LineIndent: Integer);
begin
  // Remove dash and space "- "
  var Content: String;
  if Length(YamlLine) > 2 then
    Content := Trim(Copy(YamlLine, 3, Length(YamlLine)))
  else
    Content := '';

  if FContextStack.Last.Node is TJSONArray then
  begin
    // Check if the content is a Key-Value pair (Object Item)
    // e.g. "- Key: Value" or "- Key:"
    var SeparatorPos := Pos(': ', Content);
    if (SeparatorPos = 0) and (Content.EndsWith(':')) then
       SeparatorPos := Length(Content);

    if SeparatorPos > 0 then
    begin
       // Create object for the item
       var NewObj := TJsonObject.Create;
       TJSONArray(FContextStack.Last.Node).AddElement(NewObj);

       var Key := UnQuotedString(Trim(Copy(Content, 1, SeparatorPos - 1)));
       var Value: String;
       if SeparatorPos < Length(Content) then
         Value := Trim(Copy(Content, SeparatorPos + 1, Length(Content)))
       else
         Value := '';

       var Pair := TJSONPair.Create(Key, ParseFlowValue(Value));
       NewObj.AddPair(Pair);
       FLastPair := Pair;

       // Push object context to handle children/siblings
       var Ctx: TContext;
       Ctx.Node := NewObj;
       // Indent of the content is LineIndent + 2 (assuming "- " prefix standard indent step)
       Ctx.Indent := LineIndent + 2;
       FContextStack.Add(Ctx);
    end
    else
    begin
       // Simple scalar item
       TJSONArray(FContextStack.Last.Node).AddElement(ParseFlowValue(Content));
       // We don't push context for scalars
     end;
  end;
end;

Function TYamlParser.HandleBlockScalarLine(const RawLine, YamlLine: String; LineIndent: Integer): Boolean;
begin
  if YamlLine = '' then
  begin
    FCurrentBlock := FCurrentBlock + sLineBreak;
    Exit(True);
  end;

  if FBlockIndent = -1 then
  begin
    if LineIndent <= FContextStack.Last.Indent then
    begin
      FinalizeBlockScalar;
      Exit(False);
    end
    else
    begin
      if FExplicitIndent > 0 then
        FBlockIndent := FContextStack.Last.Indent + FExplicitIndent
      else
        FBlockIndent := LineIndent;
    end;
  end;

  if (LineIndent < FBlockIndent) and (Trim(RawLine) <> '') then
  begin
    FinalizeBlockScalar;
    Exit(False);
  end;

  var Content := '';
  if Length(RawLine) >= FBlockIndent then
    Content := Copy(RawLine, FBlockIndent + 1, Length(RawLine));
  FCurrentBlock := FCurrentBlock + Content + sLineBreak;
  Result := True;
end;

Procedure TYamlParser.ParseLine(const RawLine: String);
begin
  var LineIndent := CountIndent(RawLine);
  var YamlLine := Trim(StripComment(RawLine));

  if (FBlockType <> #0) and HandleBlockScalarLine(RawLine, YamlLine, LineIndent) then Exit;

  if (YamlLine <> '') and (not YamlLine.StartsWith('#')) then
  begin
    if YamlLine.StartsWith('---') then begin HandleDocumentSeparator; Exit; end;
    if YamlLine.StartsWith('...') then begin HandleStreamEnd; Exit; end;

    FDocStarted := True;

    if FCurrentDocIndex = FTargetDocument then
    begin
      var IsListItem := YamlLine.StartsWith('- ') or (YamlLine = '-');
      AdjustContext(LineIndent, IsListItem);
      if IsListItem then
        ParseListItem(YamlLine, LineIndent)
      else
        ParseKeyPair(YamlLine);
      if FBlockType <> #0 then FBlockIndent := -1;
    end
    else if FCurrentDocIndex > FTargetDocument then
      FStopParsing := True;
  end;
end;

Function TYamlParser.StringsToValue(const Yaml: array of String; Document: Integer = 0): TJSONValue;
begin
  FCurrentDocIndex := 0;
  FDocStarted := False;
  FTargetDocument := Document;
  FStopParsing := False;

  // Auto-detect root type from the first content line of the target document:
  // skip blank lines, full-line comments, and document markers (--- / ...).
  // The first line that starts with '- ' or is bare '-' indicates a sequence root.
  var RootIsArray := False;
  var DocsSeen := 0;
  for var Line := Low(Yaml) to High(Yaml) do
  begin
    var Trimmed := Trim(Yaml[Line]);
    if Trimmed = '' then Continue;
    if Trimmed.StartsWith('#') then Continue;
    if Trimmed.StartsWith('---') then
    begin
      Inc(DocsSeen);
      Continue;
    end;
    if Trimmed.StartsWith('...') then Continue;
    // First content line of the target document
    if DocsSeen = Document then
    begin
      RootIsArray := Trimmed.StartsWith('- ') or (Trimmed = '-');
      Break;
    end;
  end;

  if RootIsArray then
    FRootNode := TJSONArray.Create
  else
    FRootNode := TJsonObject.Create;

  ResetContext;

  for var Line := Low(Yaml) to High(Yaml) do
  begin
    ParseLine(Yaml[Line]);
    if FStopParsing then Break;
  end;

  FinalizeBlockScalar; // Ensure any open block is closed at the end
  Result := FRootNode; // FRootNode may have been replaced (e.g. bare scalar root)
end;

Function TYamlParser.StringsToObject(const Yaml: array of String; Document: Integer = 0): TJsonObject;
begin
  var Value := StringsToValue(Yaml, Document);
  if Value is TJsonObject then
    Result := TJsonObject(Value)
  else
  begin
    Value.Free;
    raise EYamlParseException.Create(
      'YAML parse error: document root is not a mapping');
  end;
end;

Destructor TYamlParser.Destroy;
begin
  FContextStack.Free;
  inherited Destroy;
end;

end.
