unit Plugins;

interface

uses  NovusPlugin, Config, Output,Classes, SysUtils, PluginsMapFactory, Plugin, Project, ProjectItem,
      NovusTemplate, ScriptEngine, uPSRuntime, uPSCompiler;

type
   TPlugins = class
   private
   protected
     foScriptEngine: tScriptEngine;
     foProject: tProject;
     foOutput: TOutput;
     FExternalPlugins: TNovusPlugins;
     fPluginsList: TList;
     fImp: TPSRuntimeClassImporter;
   public
     constructor Create(aOutput: tOutput; aProject: Tproject; aScriptEngine: tScriptEngine);
     destructor Destroy; override;

     procedure LoadPlugins;
     procedure UnloadPlugins;

     procedure RegisterImports;
     procedure RegisterFunctions(aExec: TPSExec);
     function FindPlugin(aPluginName: String): TPlugin;

     function IsPluginNameExists(aPluginName: string): Boolean;
     function CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;

     procedure SetVariantToClasses(aExec: TPSExec);

     //function IsCommandLine(aCommandLinePlugin: TCommandLinePlugin): boolean;

     function IsTagExists(aPluginName: String; aTagName: string): Boolean;
     function GetTag(aPluginName: String;aTagName: string): String;

     function PostProcessor(aProjectItem: tProjectItem;
       aTemplate: tNovusTemplate; var aOutputFile: string;
       aProcessorPlugin: tProcessorPlugin): Boolean;

     function PreProcessor(aFilename: string;
       var aTemplateDoc: tStringlist): Boolean;

     function IsCommandLine: boolean;

     function BeforeCodeGen: boolean;
     function AfterCodeGen: boolean;

     property PluginsList: TList
       read fPluginsList
       write fPluginsList;
   end;

implementation

Uses Runtime;

constructor TPlugins.create;
begin
  foOutput:= aOutput;

  foProject := aProject;

  foScriptEngine := aScriptEngine;

  fImp := foScriptEngine.oImp;


  FExternalPlugins := TNovusPlugins.Create;

  fPluginsList := TList.Create;
end;

destructor TPlugins.destroy;
begin
  Inherited;

  UnloadPlugins;

  FExternalPlugins.Free;

  fPluginsList.Free;
end;

procedure TPlugins.UnloadPlugins;
Var
  I: Integer;
  loPlugin: tPlugin;
begin

  for I := 0 to fPluginsList.Count -1 do
   begin
     loPlugin := TPlugin(fPluginsList.Items[i]);
     loPlugin.Free;
     loPlugin := nil;
   end;

  fPluginsList.Clear;

  FExternalPlugins.UnloadAllPlugins;
end;


procedure TPlugins.RegisterImports;
var
  loPlugin: tPlugin;
  I: Integer;
  FExternalPlugin: IExternalPlugin;
begin
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := tPlugin(fPluginsList.Items[I]);

    loPlugin := TPlugin(fPluginsList.Items[i]);
    if loPlugin is TScriptEnginePlugin then
      begin
        TScriptEnginePlugin(loPlugin).Initialize(fImp);
        TScriptEnginePlugin(loPlugin).RegisterImport;
      end;
  end;
end;

procedure TPlugins.SetVariantToClasses(aExec: TPSExec);
var
  loPlugin: tPlugin;
  I: Integer;
  FExternalPlugin: IExternalPlugin;
begin
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := tPlugin(fPluginsList.Items[I]);
    if loPlugin is TScriptEnginePlugin then
      TScriptEnginePlugin(loPlugin).SetVariantToClass(aExec);
  end;
end;

procedure TPlugins.RegisterFunctions(aExec: TPSExec);
var
  I: Integer;
  loPlugin: tPlugin;
  FExternalPlugin: IExternalPlugin;
begin
  for I := 0 to fPluginsList.Count - 1 do
  begin
    loPlugin := tPlugin(fPluginsList.Items[I]);
    if loPlugin is TScriptEnginePlugin then
      TScriptEnginePlugin(loPlugin).RegisterFunction(aExec);
  end;

  RegisterClassLibraryRuntime(aExec, fImp);
end;

function TPlugins.CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;
Var
  I: Integer;
  loPlugin: tPlugin;
begin
  Try
    for I := 0 to fPluginsList.Count - 1 do
    begin
      loPlugin := tPlugin(fPluginsList.Items[I]);
      if loPlugin is TScriptEnginePlugin then
        TScriptEnginePlugin(loPlugin).CustomOnUses(aCompiler)
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
  FPlugin: tPlugin;
  FExternalPlugin: IExternalPlugin;
  loConfigPlugins: TConfigPlugins;
begin
  //External Plugin
  foOutput.Log('Loading plugins');

  if oConfig.oConfigPluginsList.Count > 0 then
    begin
      for I := 0 to oConfig.oConfigPluginsList.Count - 1do
        begin
          loConfigPlugins := tConfigPlugins(oConfig.oConfigPluginsList.Items[i]);

          if FileExists(loConfigPlugins.PluginFilenamePathname) then
            begin
              if FExternalPlugins.LoadPlugin(loConfigPlugins.PluginFilenamePathname) then
                begin
                  FExternalPlugin := IExternalPlugin(FExternalPlugins.Plugins[FExternalPlugins.PluginCount-1]);

                  fPluginsList.Add(FExternalPlugin.CreatePlugin(foOutput, foProject, loConfigPlugins));
                  foOutput.Log('Loaded: ' + FExternalPlugin.PluginName);
                end;
            end
          else foOutput.Log('Missing: ' + loConfigPlugins.PluginFilenamePathname);
        end;

    end;
end;

function TPlugins.IsCommandLine: boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := True;

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);

      Result :=  loPlugin.IsCommandLine;
      if Not Result then break;
    end;
end;


function TPlugins.BeforeCodeGen: boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := True;

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);

      Result :=  loPlugin.BeforeCodeGen;
      if Not Result then break;
    end;
end;

function TPlugins.AfterCodeGen: boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := true;

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);

      Result := loPlugin.AfterCodeGen;

      if NOt Result then break;
    end;
end;


function TPlugins.IsPluginNameExists(aPluginName: string): Boolean;
begin
  Result := False;

  if Assigned(FindPlugin(aPluginName)) then Result := true;
end;

function TPlugins.IsTagExists(aPluginName: string;aTagName: string): Boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := False;

  if not assigned(fPluginsList) then exit;

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TTagsPlugin then
        begin
          if Uppercase(TTagsPlugin(loPlugin).PluginName) = Uppercase(aPluginName) then
            begin
              if TTagsPlugin(loPlugin).IsTagExists(aTagName) <> -1 then
                begin
                  Result := True;
                  Break;
                end;
            end;
        end;
    end;
end;

function TPlugins.PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate; var aOutputFile: string; aProcessorPlugin: tProcessorPlugin): boolean;
var
  loPlugin: TPlugin;
  I: Integer;
  fssourceextension: string;
begin
  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TProcessorPlugin then
        begin
          if Assigned(aProcessorPlugin) then
            begin
              if uppercase(TProcessorPlugin(loPlugin).PluginName) = Uppercase(aProcessorPlugin.PluginName) then
                begin
                  if TProcessorPlugin(loPlugin).PostProcessor(aProjectItem, aTemplate, aOutputFile) = false then
                    Fooutput.Failed := true;

                  break;
                end;
            end
          else
          if aProjectItem.Processor<> '' then
            begin
              if uppercase(TProcessorPlugin(loPlugin).PluginName) = Uppercase(aProjectItem.Processor) then
                begin
                  if TProcessorPlugin(loPlugin).PostProcessor(aProjectItem, aTemplate, aOutputFile) = false then
                    Fooutput.Failed := true;

                  break;
                end;
            end
          else
          if (CompareText('.'+TProcessorPlugin(loPlugin).sourceextension,  ExtractFileExt(aProjectItem.TemplateFile)) =0) then
            begin
              if TProcessorPlugin(loPlugin).PostProcessor(aProjectItem, aTemplate, aOutputFile) = false then
                Fooutput.Failed := true;

              break;
            end;
        end;
    end;
end;

function TPlugins.PreProcessor(aFilename: string; var aTemplateDoc: tStringlist): boolean;
var
  loPlugin: TPlugin;
  I: Integer;
  fssourceextension: string;
begin
  Result := False;

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TProcessorPlugin then
        begin
          if (CompareText('.'+TProcessorPlugin(loPlugin).sourceextension,  ExtractFileExt(aFilename)) =0) then
            begin
              Result := TProcessorPlugin(loPlugin).PreProcessor(aFilename, aTemplateDoc);
              if result = false then Fooutput.Failed := true;
            end;
        end;
    end;
end;


function TPlugins.GetTag(aPluginName: String;aTagName: string): String;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := '';
  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if Uppercase(TTagsPlugin(loPlugin).PluginName) = Uppercase(aPluginName) then
        begin
          if loPlugin is TTagPlugin then
            begin
              if Uppercase(ttagplugin(loplugin).TagName) = Uppercase(aTagName) then
                result := Uppercase(ttagplugin(loplugin).TagName);
            end
          else
          if loPlugin is TTagsPlugin then
            begin
              if ttagsplugin(loplugin).istagexists(atagname) <> -1 then
                begin
                  result := ttagsplugin(loplugin).gettag(atagname);

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

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if Uppercase(Trim(loPlugin.PluginName)) =  Uppercase(Trim(aPluginName)) then
        begin
          Result :=  loPlugin;

          break;
        end;
    end;
end;

end.
