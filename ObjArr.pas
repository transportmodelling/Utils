unit ObjArr;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, Classes;

Type
  TCaseType = (ctAsIs,ctLowercase,ctUppercase);

  TJsonObjectArrayParser = Class
  // Reads the successive JSON object literals from a JSON object array literal
  private
    FEndOfArray,OwnsStream: Boolean;
    Stream: TStream;
    Reader: TStreamReader;
  public
    Constructor Create(const Stream: TStream); overload;
    Constructor Create(const FileName: TFileName); overload;
    Constructor Create(const Json: String); overload;
    Function Next(NameCase: TCaseType = ctAsIs): String;
    Destructor Destroy; override;
  public
    Property EndOfArray: Boolean read FEndOfArray;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TJsonObjectArrayParser.Create(const Stream: TStream);
begin
  inherited Create;
  Reader := TStreamReader.Create(Stream,TEncoding.Ansi);
  // Read array start
  while (not Reader.EndOfStream) and (Char(Reader.Peek) in [#10,#13,#32]) do Reader.Read;
  if Reader.EndOfStream or (Char(Reader.Read) <> '[') then raise Exception.Create('Invalid Json-array');
  // Read until first object
  while (not Reader.EndOfStream) and (Char(Reader.Peek) in [#10,#13,#32]) do Reader.Read;
  if not Reader.EndOfStream then
  begin
    if (Char(Reader.Peek) = ']') then
    begin
      Reader.Read;
      FEndOfArray := true;
    end;
  end else
    raise Exception.Create('Invalid Json-array');
end;

Constructor TJsonObjectArrayParser.Create(const FileName: TFileName);
begin
  OwnsStream := true;
  Stream := TBufferedFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  Create(Stream);
end;

Constructor TJsonObjectArrayParser.Create(const Json: String);
begin
  OwnsStream := true;
  Stream := TStringStream.Create(Json);
  Create(Stream);
end;

Function TJsonObjectArrayParser.Next(NameCase: TCaseType = ctAsIs): String;
// Returns the next JSON object literal
begin
  if not FEndOfArray then
  begin
    // Read object string
    while (not Reader.EndOfStream) and (Char(Reader.Peek) in [#10,#13,#32]) do Reader.Read;
    if (not Reader.EndOfStream) and (Char(Reader.Peek) = '{') then
    begin
      var BracesCount := 0;
      var BracketsCount := 0;
      if not Reader.EndOfStream then
      repeat
        var Ch := Char(Reader.Read);
        if not (Ch in [#10,#13,#32]) then
        begin
          if Ch = '{' then Inc(BracesCount) else if Ch = '}' then Dec(BracesCount);
          if Ch = '[' then Inc(BracketsCount) else if Ch = ']' then Dec(BracketsCount);
          if (BracesCount=1) and (BracketsCount=0) then
            case NameCase of
              ctAsIs: Result := Result + Ch;
              ctLowercase: Result := Result + Lowercase(Ch);
              ctUppercase: Result := Result + Uppercase(Ch);
            end
          else
            Result := Result + Ch
        end;
      until Reader.EndOfStream or (BracesCount = 0);
      if (BracesCount > 0) or (BracketsCount > 0) then raise Exception.Create('Invalid Json-array');
    end else
      raise Exception.Create('Invalid Json-array');
    // Read until next object;
    while (not Reader.EndOfStream) and (Char(Reader.Peek) in [#10,#13,#32]) do Reader.Read;
    if not Reader.EndOfStream then
    begin
      var Ch := Char(Reader.Read);
      if Ch = ']' then FEndOfArray := true else
      if Ch <> ',' then raise Exception.Create('Invalid Json-array');
    end else
      raise Exception.Create('Invalid Json-array');
  end else
    raise Exception.Create('Reading past end of Json-array');
end;

Destructor TJsonObjectArrayParser.Destroy;
begin
  Reader.Free;
  if OwnsStream then Stream.Free;
  inherited Destroy;
end;

end.
