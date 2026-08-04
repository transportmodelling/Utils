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
  SysUtils, Classes, JSON, Generics.Collections;

Type
  EYamlParseException = Class(Exception);

  TYamlParser = Class
  private
    Type
      TContext = record
        Node: TJSONValue;
        Indent: Integer;
      end;
    Var
      FCurrentDocIndex: Integer;
      FDocStarted: Boolean;
      FContextStack: TList<TContext>;
      FLastPair: TJSONPair;
      FTargetDocument: Integer;
      FRootNode: TJSONValue;
      FStopParsing: Boolean;
      // Multiline block handling
      FCurrentBlock: String;
      FBlockIndent: Integer;
      FBlockType: Char;     // '|' or '>'
      FChompingStyle: Char; // ' '=clip (default), '-'=strip, '+'=keep
      FExplicitIndent: Integer; // 0 = auto-detect
    Class Function QuotedCharacter(const Line: String; Position: Integer;
                                   var InQuote: Boolean; var QuoteChar: Char): Boolean; static;
    Class Function ScalarTag(var Value: String): String; static;
    Function StripComment(const Line: String): String;
    Function UnQuotedString(const S: String): String;
    Function CountIndent(const S: String): Integer;
    Function SplitFlowItems(const Inner: String): TArray<String>;
    Function ParseFlowSequence(const S: String): TJSONArray;
    Function ParseFlowMap(const S: String): TJSONObject;
    Function ParseScalar(const S: String): TJSONValue;
    Function ParseFlowValue(const S: String): TJSONValue;
    Function FindKeySeparator(const YamlLine: String): Integer;
    Function RootIsSequence(const Yaml: array of String): Boolean;
    Function SetBlockIndent(LineIndent: Integer): Boolean;
    Function HandleBlockScalarLine(const RawLine,YamlLine: String; LineIndent: Integer): Boolean;
    Procedure ResetContext;
    Procedure HandleDocumentSeparator;
    Procedure HandleStreamEnd;
    Procedure ApplyFoldedStyle;
    Procedure ApplyChomping;
    Procedure FinalizeBlockScalar;
    Procedure PushChildContext(LineIndent: Integer; IsListItem: Boolean);
    Procedure AdjustContext(LineIndent: Integer; IsListItem: Boolean);
    Procedure InitBlockScalar(const Value: String; Pair: TJSONPair);
    Procedure ParseKeyPair(const YamlLine: String);
    Procedure AddObjectListItem(const Content: String; SeparatorPos,LineIndent: Integer);
    Procedure ParseListItem(const YamlLine: String; LineIndent: Integer);
    Procedure ParseContentLine(const YamlLine: String; LineIndent: Integer);
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

Class Function TYamlParser.QuotedCharacter(const Line: String; Position: Integer;
                                           var InQuote: Boolean; var QuoteChar: Char): Boolean;
// Tracks the quote state while scanning a line; returns whether the character
// at the position opens, closes or lies within a quoted section
begin
  var Character := Line[Position];
  if InQuote then
  begin
    if (Character = QuoteChar) and ((Position = 1) or (Line[Position-1] <> '\')) then InQuote := false;
    Result := true;
  end else
  if (Character = '"') or (Character = '''') then
  begin
    InQuote := true;
    QuoteChar := Character;
    Result := true;
  end else
    Result := false;
end;

Class Function TYamlParser.ScalarTag(var Value: String): String;
// Strips a type tag (!!str, !!int, !!float, !!bool, !!null) from the value
// and returns it in lower case; returns an empty string when there is no tag
begin
  Result := '';
  if Value.StartsWith('!!') then
  begin
    var SpacePos := Pos(' ',Value);
    if SpacePos > 0 then
    begin
      Result := LowerCase(Copy(Value,3,SpacePos-3));
      Value := Trim(Copy(Value,SpacePos+1,Length(Value)));
    end else
    begin
      // Tag without a value (e.g. bare "!!null")
      Result := LowerCase(Copy(Value,3,Length(Value)));
      Value := '';
    end;
  end;
end;

Function TYamlParser.StripComment(const Line: String): String;
Var
  InQuote: Boolean;
  QuoteChar: Char;
begin
  Result := Line;
  InQuote := false;
  QuoteChar := #0;
  for var Position := 1 to Length(Line) do
  if not QuotedCharacter(Line,Position,InQuote,QuoteChar) then
  if Line[Position] = '#' then Exit(Trim(Copy(Line,1,Position-1)));
end;

Function TYamlParser.UnQuotedString(const S: String): String;
begin
  Result := S;
  if (Length(Result) >= 2) and
     (((Result.StartsWith('"')) and (Result.EndsWith('"'))) or
      ((Result.StartsWith('''')) and (Result.EndsWith('''')))) then
  Result := Copy(Result,2,Length(Result)-2);
end;

Function TYamlParser.CountIndent(const S: String): Integer;
begin
  Result := 0;
  for var Position := 1 to Length(S) do
  if S[Position] = ' ' then Inc(Result) else Break;
end;

Function TYamlParser.SplitFlowItems(const Inner: String): TArray<String>;
Var
  InQuote: Boolean;
  QuoteChar: Char;
begin
  Result := [];
  var StartPos := 1;
  var Depth := 0;
  InQuote := false;
  QuoteChar := #0;
  for var Position := 1 to Length(Inner) do
  if not QuotedCharacter(Inner,Position,InQuote,QuoteChar) then
  begin
    var Character := Inner[Position];
    if (Character = '{') or (Character = '[') then Inc(Depth) else
    if (Character = '}') or (Character = ']') then Dec(Depth) else
    if (Character = ',') and (Depth = 0) then
    begin
      Result := Result + [Trim(Copy(Inner,StartPos,Position-StartPos))];
      StartPos := Position + 1;
    end;
  end;
  if StartPos <= Length(Inner) then
  Result := Result + [Trim(Copy(Inner,StartPos,Length(Inner)-StartPos+1))];
end;

Function TYamlParser.ParseFlowSequence(const S: String): TJSONArray;
begin
  Result := TJSONArray.Create;
  if Length(S) <= 2 then Exit; // empty []
  for var ItemStr in SplitFlowItems(Copy(S,2,Length(S)-2)) do
  if ItemStr <> '' then Result.AddElement(ParseFlowValue(ItemStr));
end;

Function TYamlParser.ParseFlowMap(const S: String): TJSONObject;
begin
  Result := TJsonObject.Create;
  if Length(S) <= 2 then Exit; // empty {}
  for var ItemStr in SplitFlowItems(Copy(S,2,Length(S)-2)) do
  if ItemStr <> '' then
  begin
    var SeparatorPos := Pos(':',ItemStr);
    if SeparatorPos > 0 then
    begin
      var KeyStr := UnQuotedString(Trim(Copy(ItemStr,1,SeparatorPos-1)));
      var ValStr := Trim(Copy(ItemStr,SeparatorPos+1,Length(ItemStr)));
      Result.AddPair(KeyStr,ParseFlowValue(ValStr));
    end;
  end;
end;

Function TYamlParser.ParseScalar(const S: String): TJSONValue;
begin
  // A quoted value is a string without type inference
  var Unquoted := UnQuotedString(S);
  if (S.StartsWith('"') and S.EndsWith('"')) or
     (S.StartsWith('''') and S.EndsWith('''')) then Exit(TJSONString.Create(Unquoted));
  // Forced types from a type tag
  var ParseTarget := Unquoted;
  var ForcedTag := ScalarTag(ParseTarget);
  if ForcedTag = 'str' then Exit(TJSONString.Create(ParseTarget));
  if ForcedTag = 'null' then Exit(TJSONNull.Create);
  if ForcedTag = 'bool' then
  if SameText(ParseTarget,'true') then Exit(TJSONTrue.Create) else Exit(TJSONFalse.Create);
  // Inferred types; !!int and !!float fall through to the numeric parsing
  if SameText(ParseTarget,'true') then Exit(TJSONTrue.Create);
  if SameText(ParseTarget,'false') then Exit(TJSONFalse.Create);
  if SameText(ParseTarget,'null') or (ParseTarget = '~') or (ParseTarget = '') then Exit(TJSONNull.Create);
  var IntValue: Int64;
  if TryStrToInt64(ParseTarget,IntValue) then Exit(TJSONNumber.Create(IntValue));
  var FloatValue: Double;
  if TryStrToFloat(ParseTarget,FloatValue,TFormatSettings.Invariant) then Exit(TJSONNumber.Create(FloatValue));
  Result := TJSONString.Create(ParseTarget);
end;

Function TYamlParser.ParseFlowValue(const S: String): TJSONValue;
begin
  if S = '' then Exit(TJSONNull.Create);
  if S.StartsWith('{') then
  begin
    // Try standard JSON first
    Result := TJSONObject.ParseJSONValue(S);
    if Result = nil then Result := ParseFlowMap(S);
  end else
  if S.StartsWith('[') then
  begin
    // Try standard JSON first
    Result := TJSONObject.ParseJSONValue(S);
    if Result = nil then Result := ParseFlowSequence(S);
  end else
    Result := ParseScalar(S);
end;

Function TYamlParser.FindKeySeparator(const YamlLine: String): Integer;
Var
  InQuote: Boolean;
  QuoteChar: Char;
begin
  Result := 0;
  InQuote := false;
  QuoteChar := #0;
  for var Position := 1 to Length(YamlLine) do
  if not QuotedCharacter(YamlLine,Position,InQuote,QuoteChar) then
  if YamlLine[Position] = ':' then
  begin
    if (Position < Length(YamlLine)) and (YamlLine[Position+1] = ' ') then Exit(Position);
    if Position = Length(YamlLine) then Exit(Position);
  end;
end;

Function TYamlParser.RootIsSequence(const Yaml: array of String): Boolean;
// Detects the root type from the first content line of the target document:
// blank lines, full-line comments and document markers (--- / ...) are
// skipped. A first content line that starts with '- ' or is a bare '-'
// indicates a sequence root.
begin
  Result := false;
  var DocsSeen := 0;
  for var Line := low(Yaml) to high(Yaml) do
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
    if DocsSeen = FTargetDocument then
    Exit(Trimmed.StartsWith('- ') or (Trimmed = '-'));
  end;
end;

Function TYamlParser.SetBlockIndent(LineIndent: Integer): Boolean;
// Establishes the block indentation from the first block line; returns false
// when the line closes the block instead
begin
  if LineIndent <= FContextStack.Last.Indent then Result := false else
  begin
    Result := true;
    if FExplicitIndent > 0 then
      FBlockIndent := FContextStack.Last.Indent + FExplicitIndent
    else
      FBlockIndent := LineIndent;
  end;
end;

Function TYamlParser.HandleBlockScalarLine(const RawLine,YamlLine: String; LineIndent: Integer): Boolean;
begin
  if YamlLine = '' then
  begin
    FCurrentBlock := FCurrentBlock + sLineBreak;
    Result := true;
  end else
  if ((FBlockIndent = -1) and (not SetBlockIndent(LineIndent)))
  or ((FBlockIndent >= 0) and (LineIndent < FBlockIndent) and (Trim(RawLine) <> '')) then
  begin
    FinalizeBlockScalar;
    Result := false;
  end else
  begin
    var Content := '';
    if Length(RawLine) >= FBlockIndent then Content := Copy(RawLine,FBlockIndent+1,Length(RawLine));
    FCurrentBlock := FCurrentBlock + Content + sLineBreak;
    Result := true;
  end;
end;

Procedure TYamlParser.ResetContext;
Var
  Ctx: TContext;
begin
  FContextStack.Clear;
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
  if FDocStarted then Inc(FCurrentDocIndex);
  FDocStarted := true;
  if FCurrentDocIndex > FTargetDocument then
    FStopParsing := true
  else
    if FCurrentDocIndex = FTargetDocument then ResetContext;
end;

Procedure TYamlParser.HandleStreamEnd;
begin
  FinalizeBlockScalar;
  if FCurrentDocIndex = FTargetDocument then FStopParsing := true;
end;

Procedure TYamlParser.ApplyFoldedStyle;
// Folded style '>': join lines with spaces, blank lines become newlines
Var
  Lines: TStringList;
begin
  var Folded := '';
  Lines := TStringList.Create;
  try
    Lines.Text := FCurrentBlock;
    for var Line := 0 to Lines.Count-1 do
    begin
      var Trimmed := Trim(Lines[Line]);
      if Trimmed = '' then
      begin
        if Folded <> '' then Folded := Trim(Folded) + sLineBreak + sLineBreak;
      end else
        Folded := Folded + Trimmed + ' ';
    end;
    FCurrentBlock := Trim(Folded);
  finally
    Lines.Free;
  end;
end;

Procedure TYamlParser.ApplyChomping;
// YAML 1.2 chomping:
//   Strip ('-'): remove all trailing newlines.
//   Keep  ('+'): preserve trailing blank lines + one final newline.
//   Clip  (' '): strip trailing newlines, then add exactly one back.
begin
  case FChompingStyle of
    '-': FCurrentBlock := TrimRight(FCurrentBlock);
    '+': FCurrentBlock := FCurrentBlock + sLineBreak;
  else   FCurrentBlock := TrimRight(FCurrentBlock) + sLineBreak;
  end;
end;

Procedure TYamlParser.FinalizeBlockScalar;
begin
  if FBlockType = #0 then Exit;
  if FBlockType = '>' then
    ApplyFoldedStyle
  else
    // Literal style '|': remove the final trailing newline before chomping
    if FCurrentBlock.EndsWith(sLineBreak) then
    FCurrentBlock := Copy(FCurrentBlock,1,Length(FCurrentBlock)-Length(sLineBreak));
  ApplyChomping;
  if (FLastPair <> nil) and (FLastPair.JsonValue is TJSONNull) then
  FLastPair.JsonValue := TJSONString.Create(FCurrentBlock);
  FBlockType := #0;
  FCurrentBlock := '';
  FBlockIndent := -1;
  FChompingStyle := ' ';
  FExplicitIndent := 0;
end;

Procedure TYamlParser.PushChildContext(LineIndent: Integer; IsListItem: Boolean);
Var
  Ctx: TContext;
begin
  if (FContextStack.Count = 1) and (FContextStack.Last.Indent = -1) then
  begin
    // Root level indentation definition
    Ctx := FContextStack.Last;
    Ctx.Indent := LineIndent;
    FContextStack[0] := Ctx;
  end else
  if FLastPair <> nil then
  begin
    // Create a new child node attached to the last pair
    var NewNode: TJSONValue;
    if IsListItem then NewNode := TJSONArray.Create else NewNode := TJsonObject.Create;
    FLastPair.JsonValue := NewNode;
    Ctx.Node := NewNode;
    Ctx.Indent := LineIndent;
    FContextStack.Add(Ctx);
  end;
end;

Procedure TYamlParser.AdjustContext(LineIndent: Integer; IsListItem: Boolean);
begin
  if FContextStack.Count = 0 then Exit;
  if LineIndent > FContextStack.Last.Indent then
    PushChildContext(LineIndent,IsListItem)
  else
    // Decreased indentation ends the child nodes
    while (FContextStack.Count > 1) and (LineIndent < FContextStack.Last.Indent) do
    FContextStack.Delete(FContextStack.Count-1);
end;

Procedure TYamlParser.InitBlockScalar(const Value: String; Pair: TJSONPair);
begin
  FBlockType := Value[1];
  FCurrentBlock := '';
  FBlockIndent := -1;
  FChompingStyle := ' ';
  FExplicitIndent := 0;
  for var Position := 2 to Length(Value) do
  begin
    if Value[Position] = '-' then FChompingStyle := '-' else
    if Value[Position] = '+' then FChompingStyle := '+' else
    if (Value[Position] >= '1') and (Value[Position] <= '9') then
    FExplicitIndent := Ord(Value[Position]) - Ord('0');
  end;
  Pair.JsonValue := TJSONNull.Create;
end;

Procedure TYamlParser.ParseKeyPair(const YamlLine: String);
begin
  var SeparatorPos := FindKeySeparator(YamlLine);
  if SeparatorPos > 0 then
  begin
    var Key := UnQuotedString(Trim(Copy(YamlLine,1,SeparatorPos-1)));
    var Value := '';
    if SeparatorPos < Length(YamlLine) then
    Value := Trim(Copy(YamlLine,SeparatorPos+1,Length(YamlLine)));
    var Pair := TJSONPair.Create(Key,ParseFlowValue(Value));
    if FContextStack.Last.Node is TJsonObject then
    TJsonObject(FContextStack.Last.Node).AddPair(Pair);
    FLastPair := Pair;
    if (Length(Value) >= 1) and ((Value[1] = '|') or (Value[1] = '>')) then
    InitBlockScalar(Value,Pair);
  end else
  begin
    // A line without a key separator makes the document a bare scalar
    var Scalar := ParseScalar(YamlLine);
    FRootNode.Free;
    FRootNode := Scalar;
    var Ctx := FContextStack[0];
    Ctx.Node := FRootNode;
    FContextStack[0] := Ctx;
    FStopParsing := true;
  end;
end;

Procedure TYamlParser.AddObjectListItem(const Content: String; SeparatorPos,LineIndent: Integer);
// Adds a "- Key: Value" list item as an object and pushes its context to
// handle children and siblings
Var
  Ctx: TContext;
begin
  var NewObj := TJsonObject.Create;
  TJSONArray(FContextStack.Last.Node).AddElement(NewObj);
  var Key := UnQuotedString(Trim(Copy(Content,1,SeparatorPos-1)));
  var Value := '';
  if SeparatorPos < Length(Content) then
  Value := Trim(Copy(Content,SeparatorPos+1,Length(Content)));
  var Pair := TJSONPair.Create(Key,ParseFlowValue(Value));
  NewObj.AddPair(Pair);
  FLastPair := Pair;
  Ctx.Node := NewObj;
  // Indent of the content assumes the standard "- " indent step
  Ctx.Indent := LineIndent + 2;
  FContextStack.Add(Ctx);
end;

Procedure TYamlParser.ParseListItem(const YamlLine: String; LineIndent: Integer);
begin
  // Remove dash and space "- "
  var Content := '';
  if Length(YamlLine) > 2 then Content := Trim(Copy(YamlLine,3,Length(YamlLine)));
  if FContextStack.Last.Node is TJSONArray then
  begin
    // A key separator makes the item an object; a scalar item otherwise
    var SeparatorPos := Pos(': ',Content);
    if (SeparatorPos = 0) and (Content.EndsWith(':')) then SeparatorPos := Length(Content);
    if SeparatorPos > 0 then
      AddObjectListItem(Content,SeparatorPos,LineIndent)
    else
      TJSONArray(FContextStack.Last.Node).AddElement(ParseFlowValue(Content));
  end;
end;

Procedure TYamlParser.ParseContentLine(const YamlLine: String; LineIndent: Integer);
begin
  var IsListItem := YamlLine.StartsWith('- ') or (YamlLine = '-');
  AdjustContext(LineIndent,IsListItem);
  if IsListItem then
    ParseListItem(YamlLine,LineIndent)
  else
    ParseKeyPair(YamlLine);
  if FBlockType <> #0 then FBlockIndent := -1;
end;

Procedure TYamlParser.ParseLine(const RawLine: String);
begin
  var LineIndent := CountIndent(RawLine);
  var YamlLine := Trim(StripComment(RawLine));
  if (FBlockType <> #0) and HandleBlockScalarLine(RawLine,YamlLine,LineIndent) then Exit;
  if (YamlLine <> '') and (not YamlLine.StartsWith('#')) then
  begin
    if YamlLine.StartsWith('---') then HandleDocumentSeparator else
    if YamlLine.StartsWith('...') then HandleStreamEnd else
    begin
      FDocStarted := true;
      if FCurrentDocIndex = FTargetDocument then
        ParseContentLine(YamlLine,LineIndent)
      else
        if FCurrentDocIndex > FTargetDocument then FStopParsing := true;
    end;
  end;
end;

Function TYamlParser.StringsToValue(const Yaml: array of String; Document: Integer = 0): TJSONValue;
begin
  FCurrentDocIndex := 0;
  FDocStarted := false;
  FTargetDocument := Document;
  FStopParsing := false;
  if RootIsSequence(Yaml) then
    FRootNode := TJSONArray.Create
  else
    FRootNode := TJsonObject.Create;
  ResetContext;
  for var Line := low(Yaml) to high(Yaml) do
  begin
    ParseLine(Yaml[Line]);
    if FStopParsing then Break;
  end;
  FinalizeBlockScalar; // Ensure any open block is closed at the end
  Result := FRootNode; // FRootNode may have been replaced (e.g. bare scalar root)
end;

Function TYamlParser.StringsToObject(const Yaml: array of String; Document: Integer = 0): TJsonObject;
begin
  var Value := StringsToValue(Yaml,Document);
  if Value is TJsonObject then
    Result := TJsonObject(Value)
  else
  begin
    Value.Free;
    raise EYamlParseException.Create('YAML parse error: document root is not a mapping');
  end;
end;

Destructor TYamlParser.Destroy;
begin
  FContextStack.Free;
  inherited Destroy;
end;

end.
