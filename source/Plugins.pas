unit Plugins;

interface

uses  NovusPlugin, Config, Output,Classes, SysUtils, PluginsMapFactory, Plugin, Project, ProjectItem,
      NovusTemplate, ScriptEngine, uPSRuntime, uPSCompiler, NovusFileUtils, CodeGeneratorItem;

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

     function IsTagExists(aPluginName: String; aTagName: string): Boolean;
     function GetTag(aPluginName: String;aTagName: string; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;

     function PostProcessor(aProcessorItem: tProcessorItem;
       aProjectItem: tProjectItem;
       aTemplate: tNovusTemplate;
       aTemplateFile: String;
       var aOutputFilename: string;
       aProcessorPlugin: tProcessorPlugin): TPluginReturn;

     function Convert(aProcessorItem: tProcessorItem;
       aProjectItem: tProjectItem;
       aTemplate: tNovusTemplate;
       aTemplateFile: String;
       var aOutputFilename: string;
       aProcessorPlugin: tProcessorPlugin): TPluginReturn;

     function PreProcessor(aFilename: string;
       aTemplate: tNovusTemplate):tProcessorItem;

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
  loConfigPlugin: TConfigPlugin;
begin
  //External Plugin
  foOutput.Log('Loading plugins');

  if oConfig.oConfigPluginList.Count > 0 then
    begin
      for I := 0 to oConfig.oConfigPluginList.Count - 1do
        begin
          loConfigPlugin := tConfigPlugin(oConfig.oConfigPluginList.Items[i]);

          if FileExists(loConfigPlugin.PluginFilenamePathname) then
            begin
              if FExternalPlugins.LoadPlugin(loConfigPlugin.PluginFilenamePathname) then
                begin
                  FExternalPlugin := IExternalPlugin(FExternalPlugins.Plugins[FExternalPlugins.PluginCount-1]);

                  fPluginsList.Add(FExternalPlugin.CreatePlugin(foOutput, foProject, loConfigPlugin));
                  foOutput.Log('Loaded: ' + FExternalPlugin.PluginName);
                end;
            end
          else foOutput.Log('Missing: ' + loConfigPlugin.PluginFilenamePathname);
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

function TPlugins.PostProcessor(aProcessorItem: tProcessorItem;
                                aProjectItem: tProjectItem;
                                aTemplate: tNovusTemplate;
                                aTemplateFile: String;
                                var aOutputFilename: string;
                                aProcessorPlugin: tProcessorPlugin): TPluginReturn;
begin
  Result := PRIgnore ;

  if Not Assigned(aProcessorItem) then Exit;

  Result := aProcessorItem.PostProcessor(aProjectItem, aTemplate, aTemplateFile, aOutputFilename);
  if Result = PRFailed then Fooutput.Failed := true;
end;

function TPlugins.Convert(aProcessorItem: tProcessorItem;
                                aProjectItem: tProjectItem;
                                aTemplate: tNovusTemplate;
                                aTemplateFile: String;
                                var aOutputFilename: string;
                                aProcessorPlugin: tProcessorPlugin): TPluginReturn;
begin
  Result := PRIgnore ;

  if Not Assigned(aProcessorItem) then Exit;

  Result := aProcessorItem.Convert(aProjectItem, aTemplateFile, aOutputFilename);
  if Result = PRFailed then Fooutput.Failed := true;
end;

function TPlugins.PreProcessor(aFilename: string; aTemplate: tNovusTemplate): tProcessorItem;
var
  loPlugin: TPlugin;
  I: Integer;
  lProcessorItem: tProcessorItem;
  lPluginReturn: TPluginReturn;
begin
  Result := NIL;

  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TProcessorPlugin then
        begin
           lProcessorItem := TProcessorPlugin(loPlugin).GetProcesorItem(TNovusFileUtils.ExtractFileExtA(aFilename));
           if Assigned(lProcessorItem) then
             begin
               Result := lProcessorItem;

               lPluginReturn := lProcessorItem.PreProcessor(aFilename, aTemplate);
               if lPluginReturn = PRFailed then Fooutput.Failed := true;

               Exit;
             end;
        end;
    end;
end;


function TPlugins.GetTag(aPluginName: String;aTagName: string; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
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
                  result := ttagsplugin(loplugin).gettag(atagname, aCodeGeneratorItem, aTokenIndex);

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
