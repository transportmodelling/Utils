unit BaseDir;

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
  SysUtils,IOUtils;

Type
  TBaseDirectory = record
  private
    FBaseDirectory: String;
    Procedure SetBaseDirectory(BaseDirectory: String);
  public
    Class Operator Initialize(out BaseDirectory: TBaseDirectory);
    Class Operator Implicit(BaseDirectory: TBaseDirectory): String;
    Class Operator Implicit(BaseDirectory: String): TBaseDirectory;
  public
    Constructor Create(const BaseDirectory: String);
    Function Contains(const Path: String): Boolean; overload;
    Function Contains(const Path: String; out RelativePath: String): Boolean; overload;
    Function RelativePath(const AbsolutePath: string): String;
    Function AbsolutePath(const RelativePath: String): String;
  public
    Property BaseDirectory: string read FBaseDirectory write SetBaseDirectory;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Class Operator TBaseDirectory.Initialize(out BaseDirectory: TBaseDirectory);
begin
  BaseDirectory.BaseDirectory := GetCurrentDir;
end;

Class Operator TBaseDirectory.Implicit(BaseDirectory: TBaseDirectory): String;
begin
  Result := BaseDirectory.BaseDirectory;
end;

Class Operator TBaseDirectory.Implicit(BaseDirectory: String): TBaseDirectory;
begin
  Result.BaseDirectory := BaseDirectory;
end;

Constructor TBaseDirectory.Create(const BaseDirectory: String);
begin
  SetBaseDirectory(BaseDirectory);
end;

Procedure TBaseDirectory.SetBaseDirectory(BaseDirectory: String);
begin
  FBaseDirectory := IncludeTrailingPathDelimiter(ExpandFileName(BaseDirectory));
end;

Function TBaseDirectory.Contains(const Path: String): Boolean;
begin
  if TPath.IsRelativePath(Path) then
    Result := true
  else
    begin
      var Directory := Copy(Path,1,Length(FBaseDirectory));
      Result := SameText(FBaseDirectory,Directory);
    end;
end;

Function TBaseDirectory.Contains(const Path: String; out RelativePath: String): Boolean;
begin
  if TPath.IsRelativePath(Path) then
  begin
    Result := true;
    RelativePath := Path;
  end else
  begin
    var Directory := Copy(Path,1,Length(FBaseDirectory));
    Result := SameText(FBaseDirectory,Directory);
    if Result then
      RelativePath := Copy(Path,Length(FBaseDirectory)+1,MaxInt)
    else
      RelativePath := '';
  end;
end;

Function TBaseDirectory.RelativePath(const AbsolutePath: string): String;
begin
  Result := ExtractRelativePath(FBaseDirectory,AbsolutePath);
end;

Function TBaseDirectory.AbsolutePath(const RelativePath: String): String;
begin
  if TPath.IsRelativePath(RelativePath) then
    Result := ExpandFileName(FBaseDirectory+RelativePath)
  else
    Result := RelativePath;
end;

end.
