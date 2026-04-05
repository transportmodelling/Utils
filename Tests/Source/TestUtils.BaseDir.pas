unit TestUtils.BaseDir;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, IOUtils, DUnitX.TestFramework, BaseDir;

Type
  [TestFixture]
  TBaseDirectoryTests = class
  public
    // Create normalises the path (trailing delimiter, expanded)
    [Test] Procedure TestCreateNormalisesPath;
    // Implicit assignment from String sets BaseDirectory correctly
    [Test] Procedure TestImplicitFromString;
    // Implicit cast to String returns BaseDirectory
    [Test] Procedure TestImplicitToString;
    // SetCurrentDir sets BaseDirectory to the current working directory
    [Test] Procedure TestSetCurrentDir;
    // SetExeDir sets BaseDirectory to the directory of the executable
    [Test] Procedure TestSetExeDir;
    // Default-initialised record has BaseDirectory = current dir
    [Test] Procedure TestInitialize;
    // Property write normalises the path
    [Test] Procedure TestPropertyWrite;
    // Contains: a relative path always returns True
    [Test] Procedure TestContains_RelativePath;
    // Contains: an absolute path under the base returns True
    [Test] Procedure TestContains_MatchingAbsPath;
    // Contains: an absolute path outside the base returns False
    [Test] Procedure TestContains_NonMatchingAbsPath;
    // Contains(out): relative path returns True, RelativePath = original
    [Test] Procedure TestContainsOut_RelativePath;
    // Contains(out): matching absolute path returns True, RelativePath = tail
    [Test] Procedure TestContainsOut_Match;
    // Contains(out): non-matching absolute path returns False, RelativePath = ''
    [Test] Procedure TestContainsOut_NoMatch;
    // AbsolutePath: relative input is expanded under the base
    [Test] Procedure TestAbsolutePath_FromRelative;
    // AbsolutePath: absolute input is returned unchanged
    [Test] Procedure TestAbsolutePath_FromAbsolute;
    // RelativePath: returns the relative portion of an absolute sub-path
    [Test] Procedure TestRelativePath;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TBaseDirectoryTests.TestCreateNormalisesPath;
begin
  var BD := TBaseDirectory.Create('C:\Foo\Bar');
  var S: String := BD;
  Assert.IsTrue(S.EndsWith(PathDelim),   'Must end with path delimiter');
  Assert.IsTrue(S.StartsWith('C:\'),     'Must keep drive root');
end;

Procedure TBaseDirectoryTests.TestImplicitFromString;
begin
  var BD: TBaseDirectory := 'C:\Temp';
  var S: String := BD;
  Assert.AreEqual(IncludeTrailingPathDelimiter(ExpandFileName('C:\Temp')), S);
end;

Procedure TBaseDirectoryTests.TestImplicitToString;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var S: String := BD;
  Assert.AreEqual(IncludeTrailingPathDelimiter(ExpandFileName('C:\Foo')), S);
end;

Procedure TBaseDirectoryTests.TestSetCurrentDir;
begin
  var BD: TBaseDirectory;
  BD.SetCurrentDir;
  var Expected := IncludeTrailingPathDelimiter(ExpandFileName(GetCurrentDir));
  Assert.AreEqual(Expected, BD.BaseDirectory);
end;

Procedure TBaseDirectoryTests.TestSetExeDir;
begin
  var BD: TBaseDirectory;
  BD.SetExeDir;
  var Expected := IncludeTrailingPathDelimiter(ExpandFileName(ExtractFileDir(ParamStr(0))));
  Assert.AreEqual(Expected, BD.BaseDirectory);
end;

Procedure TBaseDirectoryTests.TestInitialize;
begin
  // Initialize operator fires on declaration, setting to current dir
  var BD: TBaseDirectory;
  var Expected := IncludeTrailingPathDelimiter(ExpandFileName(GetCurrentDir));
  Assert.AreEqual(Expected, BD.BaseDirectory);
end;

Procedure TBaseDirectoryTests.TestPropertyWrite;
begin
  var BD: TBaseDirectory;
  BD.BaseDirectory := 'C:\Foo\Bar';
  Assert.AreEqual(IncludeTrailingPathDelimiter(ExpandFileName('C:\Foo\Bar')), BD.BaseDirectory);
end;

Procedure TBaseDirectoryTests.TestContains_RelativePath;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  Assert.IsTrue(BD.Contains('sub\file.txt'), 'Relative path must always be contained');
end;

Procedure TBaseDirectoryTests.TestContains_MatchingAbsPath;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var AbsPath := BD.BaseDirectory + 'sub\file.txt';
  Assert.IsTrue(BD.Contains(AbsPath), 'Absolute path under base must be contained');
end;

Procedure TBaseDirectoryTests.TestContains_NonMatchingAbsPath;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  Assert.IsFalse(BD.Contains('C:\Other\file.txt'), 'Path outside base must not be contained');
end;

Procedure TBaseDirectoryTests.TestContainsOut_RelativePath;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var RelPath: String;
  var Result := BD.Contains('sub\file.txt', RelPath);
  Assert.IsTrue(Result);
  Assert.AreEqual('sub\file.txt', RelPath);
end;

Procedure TBaseDirectoryTests.TestContainsOut_Match;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var AbsPath := BD.BaseDirectory + 'sub\file.txt';
  var RelPath: String;
  var Result := BD.Contains(AbsPath, RelPath);
  Assert.IsTrue(Result);
  Assert.AreEqual('sub\file.txt', RelPath);
end;

Procedure TBaseDirectoryTests.TestContainsOut_NoMatch;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var RelPath: String;
  var Result := BD.Contains('C:\Other\file.txt', RelPath);
  Assert.IsFalse(Result);
  Assert.AreEqual('', RelPath);
end;

Procedure TBaseDirectoryTests.TestAbsolutePath_FromRelative;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var Abs := BD.AbsolutePath('sub\file.txt');
  Assert.AreEqual(ExpandFileName('C:\Foo\sub\file.txt'), Abs);
end;

Procedure TBaseDirectoryTests.TestAbsolutePath_FromAbsolute;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var Abs := BD.AbsolutePath('C:\Other\file.txt');
  Assert.AreEqual('C:\Other\file.txt', Abs);
end;

Procedure TBaseDirectoryTests.TestRelativePath;
begin
  var BD := TBaseDirectory.Create('C:\Foo');
  var Rel := BD.RelativePath('C:\Foo\sub\file.txt');
  Assert.AreEqual('sub\file.txt', Rel);
end;

initialization
  TDUnitX.RegisterTestFixture(TBaseDirectoryTests);

end.
