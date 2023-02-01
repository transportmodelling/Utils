unit ShortGUID;

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
  SysUtils, NetEncoding;

Type
  TShortGUID = Class
  // A wrapper for dealing with base64 encoded GUIDs
  // Based on: https://github.com/csharpvitamins/CSharpVitamins.ShortGuid
  private
    Class Var
      Base64: TBase64Encoding;
  public
    Class Constructor Create;
    Class Function GUIDToStr(const GUID: TGUID): String;
    Class Function GUIDToUrl(const GUID: TGUID): String;
    Class Function StrToGUID(const GUID: String): TGUID;
    Class Function UrlToGUID(url: String): TGUID;
    Class Destructor Destroy;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Constructor TShortGUID.Create;
begin
  Base64 := TBase64Encoding.Create(0);
end;

Class Function TShortGUID.GUIDToStr(const GUID: TGUID): String;
begin
  Result := Copy(Base64.EncodeBytesToString(GUID.ToByteArray),1,22);
end;

Class Function TShortGUID.GUIDToUrl(const GUID: TGUID): String;
begin
  // Convert GUID to string
  Result := GUIDToStr(GUID);
  // Replace / with _
  var SlashPos := Pos('/',Result);
  while SlashPos > 0 do
  begin
    Result[SlashPos] := '_';
    SlashPos := Pos('/',Result);
  end;
  // Replace + with -
  var PlusPos := Pos('+',Result);
  while PlusPos > 0 do
  begin
    Result[PlusPos] := '-';
    PlusPos := Pos('+',Result);
  end;
end;

Class Function TShortGUID.StrToGUID(const GUID: String): TGUID;
begin
  case Length(GUID) of
    // Short GUID...
    22: Result := TGUID.Create(Base64.DecodeStringToBytes(GUID+'=='));
    // Regular GUID...
    38: result := TGUID.Create(GUID);
    else raise Exception.Create('Invalid GUID');
  end;
end;

Class Function TShortGUID.UrlToGUID(url: String): TGUID;
begin
  if Length(url) = 22 then
  begin
    // Replace _ with /
    var UnderscorePos := Pos('_',url);
    while UnderscorePos > 0 do
    begin
      url[UnderscorePos] := '/';
      UnderscorePos := Pos('_',url);
    end;
    // Replace - with +
    var MinusPos := Pos('-',url);
    while MinusPos > 0 do
    begin
      url[MinusPos] := '+';
      MinusPos := Pos('-',url);
    end;
    // Convert url to GUID
    Result := StrToGUID(url);
  end else
    raise Exception.Create('Invalid url');
end;

Class Destructor TShortGUID.Destroy;
begin
  Base64.Free;
end;

end.
