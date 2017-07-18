{$I Zcodegen.inc}
unit Runtime;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, DBSchema, NovusFileUtils,
  Properties, NovusStringUtils, Snippits, Plugins,
  CodeGenerator, Output, NovusVersionUtils, Project, ProjectItem,
  ProjectConfig;

type
  tRuntime = class
  protected
  private
    fsworkingdirectory: string;
    foPlugins: TPlugins;
    foProject: tProject;
  public
    function RunEnvironment: Integer;

    function GetVersion(aIndex: Integer): string;

    property oProject: tProject read foProject write foProject;

    property oPlugins: TPlugins read foPlugins write foPlugins;

  end;

Var
  oRuntime: tRuntime;

implementation

uses ProjectconfigParser;

function tRuntime.RunEnvironment: Integer;
Var
  liIndex, i, x: Integer;
  FTemplateTag: TTemplateTag;
  bOK: Boolean;
  lsPropertieVariable: String;
  FOutput: TOutput;
  loProjectItem: tProjectItem;
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

  FOutput := TOutput.Create('');

  foProject.LoadProjectFile(oConfig.ProjectFileName,
    oConfig.ProjectConfigFileName, FOutput);

  if foProject.oProjectConfig.IsLoaded then
    FOutput.InitLog(tProjectconfigParser.ParseProjectconfig(foProject.BasePath,
      foProject) + oConfig.OutputlogFilename, foProject.OutputConsole,
      oConfig.ConsoleOutputOnly)
  else
    FOutput.InitLog(foProject.BasePath + oConfig.OutputlogFilename,
      foProject.OutputConsole, oConfig.ConsoleOutputOnly);

  if Not oConfig.ConsoleOutputOnly then
  begin
    FOutput.OpenLog(true);

    if not FOutput.IsFileOpen then
    begin
      foProject.Free;

      writeln(FOutput.Filename + ' log file cannot be created.');

      Exit;
    end;
  end;

  FOutput.Log
    ('Zcodegen - © Copyright Novuslogic Software 2011 - 2017 All Rights Reserved');
  FOutput.Log('Version: ' + GetVersion(0));

  FOutput.Log('Project: ' + foProject.ProjectFileName);

  FOutput.Log('Project Config: ' + foProject.oProjectConfig.
    ProjectConfigFileName);

  if Trim(foProject.oProjectConfig.DBSchemaPath) <> '' then
  begin
    if Not FileExists(foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml')
    then
    begin
      FOutput.Log('DBSchema.xml path missing: ' +
        foProject.oProjectConfig.DBSchemaPath);

      Exit;
    end;

    oConfig.dbschemafilename := foProject.oProjectConfig.DBSchemaPath +
      'DBSchema.xml';

    FOutput.Log('DBSchema filename: ' + oConfig.dbschemafilename);
  end;

  if Trim(foProject.oProjectConfig.LanguagesPath) <> '' then
  begin
    if Not DirectoryExists(foProject.oProjectConfig.LanguagesPath) then
    begin
      FOutput.Log('Languages path missing: ' +
        foProject.oProjectConfig.LanguagesPath);

      Exit;
    end;

    oConfig.LanguagesPath := foProject.oProjectConfig.LanguagesPath;

    FOutput.Log('Languages path: ' + oConfig.LanguagesPath);
  end;

  foPlugins := TPlugins.Create(FOutput, foProject);

  foPlugins.LoadPlugins;

  foPlugins.BeforeCodeGen;

  for i := 0 to foProject.oProjectItemList.Count - 1 do
  begin
    loProjectItem := tProjectItem(foProject.oProjectItemList.items[i]);

    if loProjectItem.ItemName <> '' then
    begin
      FOutput.Log('Project Item: ' + loProjectItem.Name);

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.templateFile := tProjectconfigParser.ParseProjectconfig
            (loProjectItem.templateFile, foProject);

        if TNovusFileUtils.IsValidFolder(loProjectItem.templateFile) then
          loProjectItem.templateFile := TNovusFileUtils.TrailingBackSlash
            (loProjectItem.templateFile) + loProjectItem.ItemName;
      Except
        FOutput.Log('TemplateFile Projectconfig error.');

        Break;
      End;

      if Not FileExists(loProjectItem.templateFile) then
      begin
        FOutput.Log('template ' + loProjectItem.templateFile +
          ' cannot be found.');

        FOutput.Failed := true;

        Continue;
      end;
    end
    else
    begin
      loProjectItem.ItemFolder := tProjectconfigParser.ParseProjectconfig
            (loProjectItem.ItemFolder, foProject);

      if not TNovusFileUtils.IsValidFolder(loProjectItem.ItemFolder) then
      begin
        FOutput.Log('ItemFolder ' + loProjectItem.ItemFolder +
          ' cannot be found.');

        FOutput.Failed := true;

        Continue;
      end;

      loProjectItem.oSourceFiles.Folder := tProjectconfigParser.ParseProjectconfig
            (loProjectItem.oSourceFiles.Folder, foProject);

      if not TNovusFileUtils.IsValidFolder(loProjectItem.oSourceFiles.Folder) then
      begin
        FOutput.Log('Sourcefiles.Folder ' + loProjectItem.oSourceFiles.Folder +
          ' cannot be found.');

        FOutput.Failed := true;

        Continue;
      end;
    end;

    Try
      if foProject.oProjectConfig.IsLoaded then
        loProjectItem.OutputFile := tProjectconfigParser.ParseProjectconfig
          (loProjectItem.OutputFile, foProject);

      if TNovusFileUtils.IsValidFolder(loProjectItem.OutputFile) then
      begin
        // if ExtractFilename(loProjectItem.OutputFile) = '' then
        loProjectItem.OutputFile := TNovusFileUtils.TrailingBackSlash
          (loProjectItem.OutputFile) + loProjectItem.ItemName;
      end;
    Except
      FOutput.Log('Output Projectconfig error.');

      Break;
    End;

    if Not DirectoryExists(TNovusStringUtils.JustPathname
      (loProjectItem.OutputFile)) then
    begin
      if not foProject.Createoutputdir then
      begin
        FOutput.Log('output ' + TNovusStringUtils.JustPathname
          (loProjectItem.OutputFile) + ' directory cannot be found.');

        Continue;
      end
      else
      begin
        if Not CreateDir(TNovusStringUtils.JustPathname
          (loProjectItem.OutputFile)) then
        begin
          FOutput.Log('output ' + TNovusStringUtils.JustPathname
            (loProjectItem.OutputFile) + ' directory cannot be created.');

          Continue;
        end;

      end;
    end;

    if (not loProjectItem.overrideoutput) and
      FileExists(loProjectItem.OutputFile) then
    begin
      FOutput.Log('output ' + TNovusStringUtils.JustFilename
        (loProjectItem.OutputFile) + ' exists - Override Output option off.');

      Continue;
    end;

    Try
      if foProject.oProjectConfig.IsLoaded then
        loProjectItem.propertiesFile := tProjectconfigParser.ParseProjectconfig
          (loProjectItem.propertiesFile, foProject);
    Except
      FOutput.Log('PropertiesFile Projectconfig error.');

      Break;
    End;

    if loProjectItem.propertiesFile <> '' then
    begin
      if Not FileExists(loProjectItem.propertiesFile) then
      begin
        FOutput.Log('properties ' + loProjectItem.propertiesFile +
          ' cannot be found.');

        Continue;
      end;
    end;

    If (TNovusFileUtils.IsFileInUse(loProjectItem.OutputFile) = false) or
      (TNovusFileUtils.IsFileReadonly(loProjectItem.OutputFile) = false) then
    begin
      loProjectItem.Execute;
    end
    else
      FOutput.Log('Output: ' + loProjectItem.OutputFile +
        ' is read only or file in use.');
  end;

  if Not FOutput.Failed then
    foPlugins.AfterCodeGen;

  foPlugins.UnLoadPlugins;

  foPlugins.Free;

  if Not FOutput.Failed then
    Result := 0;

  if Not oConfig.ConsoleOutputOnly then
    FOutput.CloseLog;

  FOutput.Free;

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
