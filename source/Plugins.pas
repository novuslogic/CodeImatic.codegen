unit Plugins;

interface

uses NovusPlugin, Config, Output, Classes, SysUtils, PluginsMapFactory, Plugin,
  Project, ProjectItem, NovusCommandLine,
  NovusTemplate, PascalScript, uPSRuntime, uPSCompiler, NovusFileUtils,
  CodeGeneratorItem, Loader, CodeGenerator, Template, TokenProcessor;

type
  TPlugins = class(TObject)
  private
  protected
    foScriptEngine: tPascalScriptEngine;
    foProject: tProject;
    foOutput: TOutput;
    FExternalPlugins: TNovusPlugins;
    fPluginsList: TList;
    fImp: TPSRuntimeClassImporter;
  public
    constructor Create(aOutput: TOutput; aProject: tProject;
      aScriptEngine: tPascalScriptEngine);
    destructor Destroy; override;

    procedure LoadPlugins;
    procedure UnloadPlugins;

    procedure RegisterImports;
    function LoadDBSchemaFiles: boolean;
    procedure RegisterFunctions(aExec: TPSExec);
    function FindPlugin(aPluginName: String): TPlugin;

    function IsPluginNameExists(aPluginName: string): Boolean;
    function CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;

    procedure SetVariantToClasses(aExec: TPSExec);

    function IsTagExists(aPluginName: String; aTagName: string): Boolean;
    function GetTag(aPluginName: String; aTagName: string;
      aTokens: tTokenProcessor; aProjectItem: tProjectItem): String;

    function PostProcessor(aProcessorItem: tProcessorItem;
      aProjectItem: tProjectItem;
      var aTemplate: tTemplate;
      aTemplateFile: String; var aOutputFilename: string;
      aProcessorPlugin: tProcessorPlugin): TPluginReturn;

    function Convert(aProcessorItem: tProcessorItem; aProjectItem: tProjectItem;
      var aTemplate: tTemplate;
      aTemplateFile: String;
      var aOutputFilename: string; aProcessorPlugin: tProcessorPlugin)
      : TPluginReturn;

    function PreProcessor(aProjectItem: TObject; aFilename: string;
      var aTemplate: TTemplate;
      aProcessorPlugin: tProcessorPlugin;
      aNodeLoader: tNodeLoader;
      aCodeGenerator: tCodeGenerator)
      : tProcessorItem;

    function IsCommandLine(aResultCommands: INovusCommandLineResultCommands): Boolean;

    function BeforeCodeGen: Boolean;
    function AfterCodeGen: Boolean;

    property PluginsList: TList read fPluginsList write fPluginsList;
  end;

implementation

Uses Runtime;

constructor TPlugins.Create;
begin
  foOutput := aOutput;

  foProject := aProject;

  foScriptEngine := aScriptEngine;

  fImp := foScriptEngine.oImp;

  FExternalPlugins := TNovusPlugins.Create;

  fPluginsList := TList.Create;
end;

destructor TPlugins.Destroy;
begin
  Inherited;

//  UnloadPlugins;

  FExternalPlugins.Free;

  fPluginsList.Free;
end;

procedure TPlugins.UnloadPlugins;
Var
  I: Integer;
  loPlugin: tPlugin;
  fPluginInfo: PPluginInfo;
begin
  foOutput.Log('Unload Plugins');

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);

    loPlugin.Free;
    loPlugin := nil;
  end;

  fPluginsList.Clear;

  //FExternalPlugins.UnloadAllPlugins;

   for I := FExternalPlugins.PluginCount - 1 downto 0 do
    begin
      fPluginInfo := FExternalPlugins.GetPluginList(i);
      foOutput.Log('Unload: ' +fPluginInfo^.PluginName);

      FExternalPlugins.UnloadPlugin(I);
    end;
end;

procedure TPlugins.RegisterImports;
var
  loPlugin: TPlugin;
  I: Integer;
  FExternalPlugin: IExternalPlugin;
begin
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);

    loPlugin := TPlugin(fPluginsList.Items[I]);
    if loPlugin is TPascalScriptPlugin then
    begin
      TPascalScriptPlugin(loPlugin).Initialize(fImp);
      TPascalScriptPlugin(loPlugin).RegisterImport;
    end;
  end;
end;


function TPlugins.LoadDBSchemaFiles: boolean;
var
  loPlugin: TPlugin;
  I: Integer;
  FExternalPlugin: IExternalPlugin;
begin
  Result := true;

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);

    loPlugin := TPlugin(fPluginsList.Items[I]);
    if loPlugin is TDataProcessorPlugin then
    begin
      if Not TDataProcessorPlugin(loPlugin).LoadDBSchemaFile then
        begin
          foOutput.Log('Missing: ' + TDataProcessorPlugin(loPlugin).DBSchemaFile);

          Result := False;

          Break;
        end;
    end;
  end;
end;

procedure TPlugins.SetVariantToClasses(aExec: TPSExec);
var
  loPlugin: TPlugin;
  I: Integer;
  FExternalPlugin: IExternalPlugin;
begin
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);
    if loPlugin is TPascalScriptPlugin then
      TPascalScriptPlugin(loPlugin).SetVariantToClass(aExec);
  end;
end;

procedure TPlugins.RegisterFunctions(aExec: TPSExec);
var
  I: Integer;
  loPlugin: TPlugin;
  FExternalPlugin: IExternalPlugin;
begin
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);
    if loPlugin is TPascalScriptPlugin then
      TPascalScriptPlugin(loPlugin).RegisterFunction(aExec);
  end;

  RegisterClassLibraryRuntime(aExec, fImp);
end;

function TPlugins.CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;
Var
  I: Integer;
  loPlugin: TPlugin;
begin
  Try
    for I := 0 to fPluginsList.Count - 1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[I]);
      if loPlugin is TPascalScriptPlugin then
        TPascalScriptPlugin(loPlugin).CustomOnUses(aCompiler)
    end;

    Result := True;
  Except
    foOutput.WriteExceptLog;

    Result := False;
  End;

end;

procedure TPlugins.LoadPlugins;
Var
  I: Integer;
  FPlugin: TPlugin;
  FExternalPlugin: IExternalPlugin;
  loConfigPlugin: TConfigPlugin;
begin
  // External Plugin
  foOutput.Log('Loading plugins');

  if oConfig.oConfigPluginList.Count > 0 then
  begin
    for I := 0 to oConfig.oConfigPluginList.Count - 1 do
    begin
      loConfigPlugin := TConfigPlugin(oConfig.oConfigPluginList.Items[I]);

      if FileExists(loConfigPlugin.PluginFilenamePathname) then
      begin
        if FExternalPlugins.LoadPlugin(loConfigPlugin.PluginFilenamePathname)
        then
        begin
          FExternalPlugin :=
            IExternalPlugin(FExternalPlugins.Plugins
            [FExternalPlugins.PluginCount - 1]);

          fPluginsList.Add(FExternalPlugin.CreatePlugin(foOutput, foProject,
            loConfigPlugin));
          foOutput.Log('Loaded: ' + FExternalPlugin.PluginName);
        end;
      end
      else
        foOutput.Log('Missing: ' + loConfigPlugin.PluginFilenamePathname);
    end;

  end;
end;

function TPlugins.IsCommandLine(aResultCommands: INovusCommandLineResultCommands): Boolean;
var
  loPlugin: TPlugin;
  I: Integer;

  function FindPluginname(aPluginName: String): INovusCommandLineResultCommand;
   var
      loResultCommand: INovusCommandLineResultCommand;
      loResultOption: INovusCommandLineResultOption;
     begin
       Result := NIL;

       if Assigned(aResultCommands) then
          begin
            loResultCommand := aResultCommands.FirstCommand;
            While( Assigned(loResultCommand)) do
              begin
                loResultOption := loResultCommand.Options.FindOptionByName('pluginname');

                if Assigned(loResultOption) then
                  begin
                    if uppercase(loResultOption.Value) = uppercase(aPluginName) then
                      begin
                        Result := loResultCommand;
                        break;
                      end;
                  end;

                loResultCommand := aResultCommands.NextCommand;
              end;
          end;
    end;

begin
  Result := True;

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);

    Result := loPlugin.IsCommandLine(FindPluginname(loPlugin.PluginName));
    if Not Result then
      break;
  end;
end;

function TPlugins.BeforeCodeGen: Boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := True;

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);

    Result := loPlugin.BeforeCodeGen;
    if Not Result then
      break;
  end;
end;

function TPlugins.AfterCodeGen: Boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := True;

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);

    Result := loPlugin.AfterCodeGen;

    if NOt Result then
      break;
  end;
end;

function TPlugins.IsPluginNameExists(aPluginName: string): Boolean;
begin
  Result := False;

  if Assigned(FindPlugin(aPluginName)) then
    Result := True;
end;

function TPlugins.IsTagExists(aPluginName: string; aTagName: string): Boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := False;

  if not Assigned(fPluginsList) then
    exit;

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);
    if loPlugin is TTagsPlugin then
    begin
      if Uppercase(TTagsPlugin(loPlugin).PluginName) = Uppercase(aPluginName)
      then
      begin
        if TTagsPlugin(loPlugin).IsTagExists(aTagName) <> -1 then
        begin
          Result := True;
          break;
        end;
      end;
    end;
  end;
end;

function TPlugins.PostProcessor(aProcessorItem: tProcessorItem;
  aProjectItem: tProjectItem;
  var aTemplate: tTemplate; aTemplateFile: String;
  var aOutputFilename: string; aProcessorPlugin: tProcessorPlugin)
  : TPluginReturn;
begin
  Result := PRIgnore;

   if Not Assigned(aProcessorItem) then
      exit;

  Result := aProcessorItem.PostProcessor(aProjectItem, aTemplate, aTemplateFile,
    aOutputFilename);
  if Result = PRFailed then
    foOutput.Failed := True;
end;

function TPlugins.Convert(aProcessorItem: tProcessorItem;
  aProjectItem: tProjectItem;
  var aTemplate: tTemplate; aTemplateFile: String;
  var aOutputFilename: string; aProcessorPlugin: tProcessorPlugin)
  : TPluginReturn;
begin
  Result := PRIgnore;

  if Not Assigned(aProcessorItem) then
    exit;

  Result := aProcessorItem.Convert(aProjectItem, aTemplateFile,
    aOutputFilename);
  if Result = PRFailed then
    foOutput.Failed := True;
end;

function TPlugins.PreProcessor(aProjectItem: TObject; aFilename: string;
  var aTemplate: TTemplate;
  aProcessorPlugin: tProcessorPlugin;
  aNodeLoader: tNodeLoader;
  aCodeGenerator: tCodeGenerator)
  : tProcessorItem;
var
  loPlugin: TPlugin;
  I: Integer;
  lProcessorItem: tProcessorItem;
  lPluginReturn: TPluginReturn;

begin
  Result := NIL;

  if Assigned(aProcessorPlugin) then
  begin
    if not aProcessorPlugin.SingleItem then
      lProcessorItem := aProcessorPlugin.GetProcesorItem
        (TNovusFileUtils.ExtractFileExtA(aFilename))
    else
      lProcessorItem := aProcessorPlugin.GetProcesorItem;

    if Assigned(lProcessorItem) then
    begin
      Result := lProcessorItem;

      lPluginReturn := lProcessorItem.PreProcessor(aProjectItem, aFilename, aTemplate, aNodeLoader, aCodeGenerator);
      if lPluginReturn = PRFailed then
        foOutput.Failed := True;
    end;
  end;
end;

function TPlugins.GetTag(aPluginName: String; aTagName: string;
  aTokens: tTokenProcessor; aProjectItem: tProjectItem): String;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := '';
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);
    if Uppercase(TTagsPlugin(loPlugin).PluginName) = Uppercase(aPluginName) then
    begin
      if loPlugin is TTagPlugin then
      begin
        if Uppercase(TTagPlugin(loPlugin).TagName) = Uppercase(aTagName) then
          Result := Uppercase(TTagPlugin(loPlugin).TagName);
      end
      else if loPlugin is TTagsPlugin then
      begin
        if TTagsPlugin(loPlugin).IsTagExists(aTagName) <> -1 then
        begin
          Result := TTagsPlugin(loPlugin).GetTag(aTagName, aTokens,
                aProjectItem);

          break;
        end;
      end;
    end;
  end;
end;

function TPlugins.FindPlugin(aPluginName: String): TPlugin;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := NIL;

  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := TPlugin(fPluginsList.Items[I]);
    if Uppercase(Trim(loPlugin.PluginName)) = Uppercase(Trim(aPluginName)) then
    begin
      Result := loPlugin;

      break;
    end;
  end;
end;

end.
