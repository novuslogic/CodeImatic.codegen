{$I Zcodegen.inc}
unit Runtime;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, DBSchema, NovusFileUtils,
  Properties, NovusStringUtils, Snippits, Plugins, ScriptEngine,
  CodeGenerator, Output, NovusVersionUtils, Project, ProjectItem,
  ProjectConfig;

type
  tRuntime = class
  protected
  private
    foOutput: tOutput;
    fsworkingdirectory: string;
    foPlugins: TPlugins;
    foProject: tProject;
    foScriptEngine: tScriptEngine;
  public
    function RunEnvironment: Integer;

    function GetVersion(aIndex: Integer): string;

    function RunProjectItems: boolean;

    property oProject: tProject read foProject write foProject;

    property oPlugins: TPlugins read foPlugins write foPlugins;

    property oScriptEngine: tScriptEngine
      read foScriptEngine
      write foScriptEngine;

    property oOutput: tOutput
      read foOutput;
  end;

Var
  oRuntime: tRuntime;

implementation

uses ProjectconfigParser, RuntimeProjectItems;

function tRuntime.RunProjectItems: boolean;
Var
  loRuntimeProjectItems: tRuntimeProjectItems;
  I: Integer;
begin
  Try
    loRuntimeProjectItems:= tRuntimeProjectItems.Create(foOutput, foProject);

    Result := loRuntimeProjectItems.RunProjectItems
  Finally
    loRuntimeProjectItems.Free;
  End;
end;

function tRuntime.RunEnvironment: Integer;
Var
  liIndex, i, x: Integer;
  FTemplateTag: TTemplateTag;
  bOK: Boolean;
  lsPropertieVariable: String;

begin
  Result := -1;

  if Trim(oConfig.workingdirectory) = '' then
  begin
    fsworkingdirectory := TNovusFileUtils.TrailingBackSlash
      (ExtractFilePath(oConfig.ProjectConfigFileName));
    if Trim(fsworkingdirectory) = '' then
      fsworkingdirectory := TNovusFileUtils.TrailingBackSlash
        (TNovusFileUtils.AbsoluteFilePath(oConfig.ProjectConfigFileName));
  end
  else
    fsworkingdirectory := TNovusFileUtils.TrailingBackSlash
      (oConfig.workingdirectory);

  if not DirectoryExists(fsworkingdirectory) then
    Exit;

  foProject := tProject.Create;
  foProject.oProjectConfig.ProjectConfigFileName :=
    oConfig.ProjectConfigFileName;

  if Trim(TNovusStringUtils.JustFilename(oConfig.ProjectConfigFileName))
    = Trim(oConfig.ProjectConfigFileName) then
    foProject.oProjectConfig.ProjectConfigFileName := fsworkingdirectory +
      oConfig.ProjectConfigFileName;

  if not foProject.oProjectConfig.LoadProjectConfigFile
    (foProject.oProjectConfig.ProjectConfigFileName) then
  begin
    if Not FileExists(foProject.oProjectConfig.ProjectConfigFileName) then
    begin
      writeln('Projectconfig missing: ' +
        foProject.oProjectConfig.ProjectConfigFileName);

      foProject.Free;

      Exit;
    end;

    writeln('Loading errror Projectconfig: ' +
      foProject.oProjectConfig.ProjectConfigFileName);

    foProject.Free;

    Exit;
  end;

  FoOutput := TOutput.Create('');

  foProject.LoadProjectFile(oConfig.ProjectFileName,
    oConfig.ProjectConfigFileName, FoOutput);

  if foProject.oProjectConfig.IsLoaded then
    FoOutput.InitLog(tProjectconfigParser.ParseProjectconfig(foProject.BasePath,
      foProject, FoOutput) + oConfig.OutputlogFilename, foProject.OutputConsole,
      oConfig.ConsoleOutputOnly)
  else
    FoOutput.InitLog(foProject.BasePath + oConfig.OutputlogFilename,
      foProject.OutputConsole, oConfig.ConsoleOutputOnly);

  if Not oConfig.ConsoleOutputOnly then
  begin
    FoOutput.OpenLog(true);

    if not FoOutput.IsFileOpen then
    begin
      foProject.Free;

      writeln(FoOutput.Filename + ' log file cannot be created.');

      Exit;
    end;
  end;

  FoOutput.Log
    ('Zcodegen - © Copyright Novuslogic Software 2011 - 2017 All Rights Reserved');
  FoOutput.Log('Version: ' + GetVersion(0));

  FoOutput.Log('Project: ' + foProject.ProjectFileName);

  FoOutput.Log('Project Config: ' + foProject.oProjectConfig.
    ProjectConfigFileName);

  if Trim(foProject.oProjectConfig.DBSchemaPath) <> '' then
  begin
    if Not FileExists(foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml')
    then
    begin
      FoOutput.Log('DBSchema.xml path missing: ' +
        foProject.oProjectConfig.DBSchemaPath);

      Exit;
    end;

    oConfig.dbschemafilename := foProject.oProjectConfig.DBSchemaPath +
      'DBSchema.xml';

    FoOutput.Log('DBSchema filename: ' + oConfig.dbschemafilename);
  end;

  if Trim(foProject.oProjectConfig.LanguagesPath) <> '' then
  begin
    if Not DirectoryExists(foProject.oProjectConfig.LanguagesPath) then
    begin
      FoOutput.Log('Languages path missing: ' +
        foProject.oProjectConfig.LanguagesPath);

      Exit;
    end;

    oConfig.LanguagesPath := foProject.oProjectConfig.LanguagesPath;

    FoOutput.Log('Languages path: ' + oConfig.LanguagesPath);
  end;



  foScriptEngine := tScriptEngine.Create(FoOutput);

  foPlugins := TPlugins.Create(FoOutput, foProject, foScriptEngine);

  foPlugins.LoadPlugins;

  foPlugins.RegisterImports;

  if not foPlugins.IsCommandLine then Exit;

  if not foPlugins.BeforeCodeGen then Exit;

  RunProjectItems;

  if Not FoOutput.Failed then
    foPlugins.AfterCodeGen;

  foPlugins.UnLoadPlugins;

  foPlugins.Free;

  foScriptEngine.Free;

  if Not FoOutput.Failed then
    Result := 0;

  if Not oConfig.ConsoleOutputOnly then
    FoOutput.CloseLog;

  FoOutput.Free;

  foProject.Free;
end;

function tRuntime.GetVersion(aIndex: Integer): string;
begin
  case aIndex of
    0:
      Result := TNovusVersionUtils.GetFullVersionNumber;
    1:
      Result := Trim(TNovusVersionUtils.GetProductName) + ' ' +
        TNovusVersionUtils.GetFullVersionNumber;
  end;
end;

Initialization

oRuntime := tRuntime.Create;

finalization

oRuntime.Free;

end.
