unit Plugins;

interface

uses  NovusPlugin, Config, Output,Classes, SysUtils, PluginsMapFactory, Plugin, Project,
      NovusTemplate;

type
   TPlugins = class
   private
   protected
     foProject: tProject;
     foOutput: TOutput;
     FExternalPlugins: TNovusPlugins;
     fPluginsList: TList;
   public
     constructor Create(aOutput: tOutput; aProject: Tproject);
     destructor Destroy; override;

     procedure LoadPlugins;
     procedure UnloadPlugins;

     function FindPlugin(aPluginName: String): TPlugin;

     function IsCommandLine(aCommandLinePlugin: TCommandLinePlugin): boolean;

     function IsTagExists(aTagName: string): Boolean;
     function GetTag(aTagName: string): String;

     function PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate; var aOutputFile: string): boolean; overload;
     function PostProcessor(aFilename: string; var aTemplateDoc: tStringlist): boolean; overload;

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

function TPlugins.IsCommandLine(aCommandLinePlugin: TCommandLinePlugin): boolean;
var
  I: integer;
begin
  Result := false;

  for I := 0 to ParamCount do
    begin
      if aCommandLinePlugin.IsCommandLine(ParamStr(i)) then
        begin
          Result := true;
          Break;
        end;
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
      if loPlugin is TCommandLinePlugin then
        begin
          if IsCommandLine(TCommandLinePlugin(loPlugin)) then
            Result :=  TCommandLinePlugin(loPlugin).BeforeCodeGen;

          if NOt Result then break;
      end;
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
      if loPlugin is TCommandLinePlugin then
        begin
          if IsCommandLine(TCommandLinePlugin(loPlugin)) then
            Result :=  TCommandLinePlugin(loPlugin).AfterCodeGen;

          if NOt Result then break;
        end;
    end;
end;


function TPlugins.IsTagExists(aTagName: string): Boolean;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := False;
  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TTagsPlugin then
        begin
          if TTagsPlugin(loPlugin).IsTagExists(aTagName) <> -1 then
            begin
              Result := True;
              Break;
            end;
        end;
    end;
end;

function TPlugins.PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
var
  loPlugin: TPlugin;
  I: Integer;
  fssourceextension: string;
begin
  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TPostProcessorPlugin then
        begin
          if aProjectItem.PostProcessor<> '' then
            begin
              if uppercase(TPostProcessorPlugin(loPlugin).PluginName) = Uppercase(aProjectItem.PostProcessor) then
                begin
                  if TPostProcessorPlugin(loPlugin).PostProcessor(aProjectItem, aTemplate, aOutputFile) = false then
                    Fooutput.Failed := true;

                  break;
                end;
            end
          else
          if (CompareText('.'+TPostProcessorPlugin(loPlugin).sourceextension,  ExtractFileExt(aProjectItem.TemplateFile)) =0) then
            begin
              if TPostProcessorPlugin(loPlugin).PostProcessor(aProjectItem, aTemplate, aOutputFile) = false then
                Fooutput.Failed := true;

              break;
            end;
        end;
    end;
end;

function TPlugins.PostProcessor(aFilename: string; var aTemplateDoc: tStringlist): boolean;
var
  loPlugin: TPlugin;
  I: Integer;
  fssourceextension: string;
begin
  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TPostProcessorPlugin then
        begin
          if (CompareText('.'+TPostProcessorPlugin(loPlugin).sourceextension,  ExtractFileExt(aFilename)) =0) then
            begin
             if TPostProcessorPlugin(loPlugin).PostProcessor(aFilename, aTemplateDoc) = false then
               Fooutput.Failed := true;
            end;
        end;
    end;
end;


function TPlugins.GetTag(aTagName: string): String;
var
  loPlugin: TPlugin;
  I: Integer;
begin
  Result := '';
  for I := 0 to fPluginsList.Count -1 do
    begin
      loPlugin := TPlugin(fPluginsList.Items[i]);
      if loPlugin is TTagsPlugin then
        begin
          if TTagsPlugin(loPlugin).IsTagExists(aTagName) <> -1 then
            begin
              Result := TTagsPlugin(loPlugin).GetTag(aTagName);

              Break;
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
      if loPlugin.PluginName =  aPluginName then
        begin
          Result :=  loPlugin;

          break;
        end;
    end;
end;

end.
