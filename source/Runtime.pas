{$I CodeImatic.codegen.inc}
unit Runtime;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, NovusFileUtils,
  Properties, NovusStringUtils, Snippits, Plugins, PascalScript, dialogs,
  NovusCommandLine,
  CodeGenerator, Output, NovusVersionUtils, Project, ProjectItem, CommandLine;

type
  tRuntime = class
  protected
  private
    foOutput: tOutput;
    fsworkingdirectory: string;
    foPlugins: TPlugins;
    foProject: tProject;
    foScriptEngine: TPascalScriptEngine;
  public
    function Execute(aCommandLineResult: INovusCommandLineResult): Integer;

    function GetVersion(aIndex: Integer): string;
    function GetVersionCopyright: string;

    function RunProjectItems: boolean;

    property oProject: tProject read foProject write foProject;

    property oPlugins: TPlugins read foPlugins write foPlugins;

    property oScriptEngine: TPascalScriptEngine read foScriptEngine
      write foScriptEngine;

    property oOutput: tOutput read foOutput;
  end;

Var
  oRuntime: tRuntime;

implementation

uses ProjectParser, RuntimeProjectItems;

function tRuntime.RunProjectItems: boolean;
Var
  loRuntimeProjectItems: tRuntimeProjectItems;
  I: Integer;
begin
  Try
    loRuntimeProjectItems := tRuntimeProjectItems.Create(foOutput, foProject,
      foPlugins);

    Result := loRuntimeProjectItems.RunProjectItems
  Finally
    loRuntimeProjectItems.Free;
  End;
end;

function tRuntime.Execute(aCommandLineResult: INovusCommandLineResult): Integer;
Var
  liIndex, I, x: Integer;
  FTemplateTag: TTemplateTag;
  bOK: boolean;
  lsPropertieVariable: String;
  fNovusCommandLineResultCommands: INovusCommandLineResultCommands;
  fNovusCommandLineResultCommand: INovusCommandLineResultCommand;
  fNovusCommandLineResultOption: INovusCommandLineResultOption;
begin
  Result := 0;

  oConfig.workingdirectory := '';

  fNovusCommandLineResultOption := aCommandLineResult.FindFirstCommandwithOption
    (clOutputlog);
  if Assigned(fNovusCommandLineResultOption) then
    oConfig.OutputlogFilename := fNovusCommandLineResultOption.Value;

  fNovusCommandLineResultOption := aCommandLineResult.FindFirstCommandwithOption
    (clworkingdirectory);
  if Assigned(fNovusCommandLineResultOption) then
    oConfig.workingdirectory := fNovusCommandLineResultOption.Value;

  if Trim(oConfig.workingdirectory) = '' then
  begin
    fsworkingdirectory := TNovusFileUtils.TrailingBackSlash
      (ExtractFilePath(oConfig.ProjectFileName));
    if Trim(fsworkingdirectory) = '' then
      fsworkingdirectory := TNovusFileUtils.TrailingBackSlash
        (TNovusFileUtils.AbsoluteFilePath(oConfig.ProjectFileName));
  end
  else
    fsworkingdirectory := TNovusFileUtils.TrailingBackSlash
      (oConfig.workingdirectory);

  if Trim(fsworkingdirectory) = '' then
    fsworkingdirectory := GetCurrentDir;

  if not DirectoryExists(fsworkingdirectory) then
  begin
    aCommandLineResult.ExitCode := -2;

    Result := aCommandLineResult.ExitCode;

    aCommandLineResult.AddError('Workingdirectory cannot be found.');

    Exit;
  end;

  foOutput := tOutput.Create('');

  oConfig.Consoleoutputonly := false;
  fNovusCommandLineResultCommand := aCommandLineResult.FindFirstCommand
    (clConsoleoutputonly);
  if Assigned(fNovusCommandLineResultCommand) then
    oConfig.Consoleoutputonly := fNovusCommandLineResultCommand.IsCommandOnly;
  foOutput.Consoleoutputonly := oConfig.Consoleoutputonly;

  // var
  fNovusCommandLineResultCommands :=
    aCommandLineResult.Commands.GetCommands(clvar);
  if Assigned(fNovusCommandLineResultCommands) then
  begin
    fNovusCommandLineResultCommand :=
      fNovusCommandLineResultCommands.FirstCommand;
    While (Assigned(fNovusCommandLineResultCommand)) do
    begin
      if not oConfig.oVariablesCmdLine.AddVariableCmdLine
        (fNovusCommandLineResultCommand.Options.FirstOption.Value) then
      begin
        foProject.Free;

        aCommandLineResult.ExitCode := -4;

        Result := aCommandLineResult.ExitCode;

        aCommandLineResult.AddError('Variable Command Line error [' +
          oConfig.oVariablesCmdLine.Error + ']');

        Exit;

      end;

      fNovusCommandLineResultCommand :=
        fNovusCommandLineResultCommands.NextCommand;
    end;
  end;

  foProject := tProject.Create(foOutput);

  oConfig.ProjectFileName := '';
  fNovusCommandLineResultOption := aCommandLineResult.FindFirstCommandwithOption
    (clproject);
  if Assigned(fNovusCommandLineResultOption) then
    oConfig.ProjectFileName := fNovusCommandLineResultOption.Value;

  If not foProject.LoadProjectFile(oConfig.ProjectFileName, foOutput,
    fsworkingdirectory) then
  begin
    aCommandLineResult.AddError('Project [filename] cannot not be found [' +
      oConfig.ProjectFileName + ']');

    aCommandLineResult.ExitCode := -5;

    if Assigned(foProject) then
      foProject.Free;

    Exit;

  end;

  if foProject.oProjectConfigLoader.Load then
    foOutput.InitLog(tProjectParser.ParseProject(foProject.BasePath, foProject,
      foOutput) + oConfig.OutputlogFilename, foProject.OutputConsole,
      oConfig.Consoleoutputonly)
  else
    foOutput.InitLog(foProject.BasePath + oConfig.OutputlogFilename,
      foProject.OutputConsole, oConfig.Consoleoutputonly);

  if Not oConfig.Consoleoutputonly then
  begin
    if not foOutput.OpenLog then
    begin
      foProject.Free;

      aCommandLineResult.ExitCode := -3;

      Result := aCommandLineResult.ExitCode;

      aCommandLineResult.AddError(foOutput.Filename +
        ' log file cannot be created.');

      Exit;
    end;
  end;

  foOutput.Log('Logging started');

  foOutput.Log(GetVersionCopyright);
  foOutput.Log('Version: ' + GetVersion(0));

  foOutput.Log('Project: ' + foProject.ProjectFileName);

  // FoOutput.Log('Project Config: ' + foProject.oProjectConfig.
  // ProjectConfigFileName);

  (*
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
  *)

  (*
    if Trim(foProject.oProjectConfigLoader.LanguagesPath) <> '' then
    begin
    if Not DirectoryExists(foProject.oProjectConfigLoader.LanguagesPath) then
    begin
    FoOutput.Log('Languages path missing: ' +
    foProject.oProjectConfigLoader.LanguagesPath);

    Exit;
    end;

    oConfig.LanguagesPath := foProject.oProjectConfigLoader.LanguagesPath;

    FoOutput.Log('Languages path: ' + oConfig.LanguagesPath);
    end;
  *)

  foScriptEngine := TPascalScriptEngine.Create(foOutput);

  foPlugins := TPlugins.Create(foOutput, foProject, foScriptEngine);

  foPlugins.LoadPlugins;

  foPlugins.RegisterImports;
  if not foPlugins.LoadDBSchemaFiles then
    Exit;

  fNovusCommandLineResultCommands := aCommandLineResult.Commands.GetCommands
    (clplugin);

  if not foPlugins.IsCommandLine(fNovusCommandLineResultCommands) then
    Exit;

  if not foPlugins.BeforeCodeGen then
    Exit;

  foProject.oPlugins := foPlugins;

  // foProject.oProjectConfigLoader.LoadConnections;

  RunProjectItems;

  if Not foOutput.Failed then
    foPlugins.AfterCodeGen;

  foPlugins.UnLoadPlugins;

  foPlugins.Free;

  foScriptEngine.Free;

  if Not foOutput.Failed then
    Result := 0;

  if Not oConfig.Consoleoutputonly then
  begin
    foOutput.CloseLog;

    foOutput.Log('Logging finished');
  end;

  foOutput.Free;

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

function tRuntime.GetVersionCopyright: string;
begin
  Result := 'CodeImatic.codegen - © Copyright Novuslogic Software 2020 All Rights Reserved';
end;

Initialization

oRuntime := tRuntime.Create;

finalization

oRuntime.Free;

end.
