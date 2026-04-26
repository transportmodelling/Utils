unit KeyVal;

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
  SysUtils, StrUtils, Generics.Collections, BaseDir;

Type
  TKeyValuePair = TPair<String,String>;
  TKeyValuePairs = TArray<TKeyValuePair>;

  TKeyValuePairsHelper = record helper for TKeyValuePairs
  private
    Class Var
      // Base directory used by the Path-method
      BaseDirectory: TBaseDirectory;
  public
    Class Procedure SetBaseDir(const BaseDir: String);
  public
    // Manage content
    Constructor Create(const KeyValuePairs: array of TKeyValuePair); overload;
    Constructor Create(const KeyValuePairs: TDictionary<String,String>); overload;
    Constructor Create(const KeyValuePairs: String; const KeyValueSeparator,PairSeparator: Char); overload;
    Procedure Clear;
    Procedure Append(const Key,Value: String); overload;
    Procedure Append(const KeyValuePair: TKeyValuePair); overload;
    Procedure Append(const KeyValuePairs: array of TKeyValuePair); overload;
    Procedure Append(const KeyValuePairs: TDictionary<String,String>); overload;
    Procedure Delete(Index: Integer); overload;
    Procedure Delete(const Key: String); overload;
    // Query content
    Function Count: Integer;
    Function Contains(const Key: String; OccurrenceIndex: Integer = 0): Boolean; overload;
    Function Contains(const Key: String; var Value: String; OccurrenceIndex: Integer = 0): Boolean; overload;
    Function Str(const Key: String; OccurrenceIndex: Integer = 0): String;
    Function Int(const Key: String; OccurrenceIndex: Integer = 0): Integer;
    Function Int64(const Key: String; OccurrenceIndex: Integer = 0): Int64;
    Function Float(const Key: String; OccurrenceIndex: Integer = 0): Float64;
    Function Path(const Key: String; OccurrenceIndex: Integer = 0): String;
    Function AsString(const KeyValueSeparator: Char = ':'; PairSeparator: Char = ';'): String;
    Procedure AddToDictionary(const Dictionary: TDictionary<String,String>);
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Procedure TKeyValuePairsHelper.SetBaseDir(const BaseDir: String);
begin
  BaseDirectory := BaseDir;
end;

Constructor TKeyValuePairsHelper.Create(const KeyValuePairs: array of TKeyValuePair);
begin
  Clear;
  Append(KeyValuePairs);
end;

Constructor TKeyValuePairsHelper.Create(const KeyValuePairs: TDictionary<String,String>);
begin
  Clear;
  Append(KeyValuePairs);
end;

Constructor TKeyValuePairsHelper.Create(const KeyValuePairs: String; const KeyValueSeparator,PairSeparator: Char);
begin
  Clear;
  for var Token in SplitString(KeyValuePairs,PairSeparator) do
  begin
    var Sep := Pos(KeyValueSeparator, Token);
    if Sep > 0 then Append(Copy(Token,1,Sep-1),Copy(Token,Sep+1,MaxInt));
  end;
end;

Procedure TKeyValuePairsHelper.Clear;
begin
  Finalize(Self);
end;

Procedure TKeyValuePairsHelper.Append(const Key,Value: String);
begin
  Append(TKeyValuePair.Create(Key,Value));
end;

Procedure TKeyValuePairsHelper.Append(const KeyValuePair: TKeyValuePair);
begin
  Self := Self + [KeyValuePair];
end;

Procedure TKeyValuePairsHelper.Append(const KeyValuePairs: array of TKeyValuePair);
begin
  var Index := Count;
  SetLength(Self,Count+Length(KeyValuePairs));
  for var KeyValuePair := low(KeyValuePairs) to high(KeyValuePairs) do
  begin
    Self[Index] := KeyValuePairs[KeyValuePair];
    Inc(Index);
  end;
end;

Procedure TKeyValuePairsHelper.Append(const KeyValuePairs: TDictionary<String,String>);
begin
  for var Pair in KeyValuePairs do Append(Pair.Key,Pair.Value);
end;

Procedure TKeyValuePairsHelper.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < Count) then
  begin
    for var I := Index to Count-2 do Self[I] := Self[I+1];
    SetLength(Self,Count-1);
  end else
    raise Exception.CreateFmt('Index (%d) out of range',[Index]);
end;

Procedure TKeyValuePairsHelper.Delete(const Key: String);
// Removes the first pair whose key matches (case-insensitive).
// Raises an exception if the key is not found.
begin
  for var I := 0 to Count-1 do
  if SameText(Self[I].Key, Key) then
  begin
    Delete(I);
    Exit;
  end;
  raise Exception.Create('Key (' + Key + ') does not exist');
end;

Function TKeyValuePairsHelper.Count: Integer;
begin
  Result := Length(Self);
end;

Function TKeyValuePairsHelper.Contains(const Key: String; OccurrenceIndex: Integer = 0): Boolean;
Var
  Value: String;
begin
  Result := Contains(Key,Value,OccurrenceIndex);
end;

Function TKeyValuePairsHelper.Contains(const Key: String; var Value: String; OccurrenceIndex: Integer = 0): Boolean;
begin
  var MatchCount := 0;
  for var KeyValuePair := 0 to Count-1 do
  if SameText(Self[KeyValuePair].Key,Key) then
  begin
    if MatchCount = OccurrenceIndex then
    begin
      Value := Self[KeyValuePair].Value;
      Exit(true);
    end;
    Inc(MatchCount);
  end;
  Result := false;
end;

Function TKeyValuePairsHelper.Str(const Key: String; OccurrenceIndex: Integer = 0): String;
begin
  var MatchCount := 0;
  for var I := 0 to Count-1 do
  if SameText(Self[I].Key,Key) then
  begin
    if MatchCount = OccurrenceIndex then Exit(Self[I].Value);
    Inc(MatchCount);
  end;
  if MatchCount = 0 then
    raise Exception.Create('Key (' + Key + ') does not exist')
  else
    raise Exception.CreateFmt('Key (%s) occurrence %d does not exist',[Key,OccurrenceIndex]);
end;

Function TKeyValuePairsHelper.Int(const Key: String; OccurrenceIndex: Integer = 0): Integer;
begin
  var S := Str(Key,OccurrenceIndex);
  if not TryStrToInt(S,Result) then raise Exception.CreateFmt('Key (%s) value "%s" is not a valid integer',[Key,S]);
end;

Function TKeyValuePairsHelper.Int64(const Key: String; OccurrenceIndex: Integer = 0): Int64;
begin
  var S := Str(Key,OccurrenceIndex);
  if not TryStrToInt64(S,Result) then raise Exception.CreateFmt('Key (%s) value "%s" is not a valid int64',[Key,S]);
end;

Function TKeyValuePairsHelper.Float(const Key: String; OccurrenceIndex: Integer = 0): Float64;
begin
  var S := Str(Key,OccurrenceIndex);
  if not TryStrToFloat(S,Result) then raise Exception.CreateFmt('Key (%s) value "%s" is not a valid float',[Key,S]);
end;

Function TKeyValuePairsHelper.Path(const Key: String; OccurrenceIndex: Integer = 0): String;
begin
  Result := BaseDirectory.AbsolutePath(Str(Key,OccurrenceIndex));
end;

Function TKeyValuePairsHelper.AsString(const KeyValueSeparator: Char = ':'; PairSeparator: Char = ';'): String;
// Returns all pairs serialized as a single string.
// Each pair is formatted as Key + KeyValueSeparator + ' ' + Value.
// Pairs are joined with PairSeparator + ' '; no trailing separator is appended.
begin
  Result := '';
  for var Pair in Self do
  begin
    if Result <> '' then Result := Result + PairSeparator + ' ';
    Result := Result + Pair.Key + KeyValueSeparator + ' ' + Pair.Value;
  end;
end;

Procedure TKeyValuePairsHelper.AddToDictionary(const Dictionary: TDictionary<String,String>);
// Raises EListError if a key already exists in the dictionary (TDictionary default).
begin
  for var Pair in Self do Dictionary.Add(Pair.Key, Pair.Value);
end;

initialization
  TKeyValuePairs.BaseDirectory.SetExeDir;
end.
