unit Plugins;

interface

uses  NovusPlugin, Config, Output,Classes, SysUtils, PluginsMapFactory, Plugin;

type
   TPlugins = class
   private
   protected
     foOutput: TOutput;
     FExternalPlugins: TNovusPlugins;
     fPluginsList: TList;
   public
     constructor Create(aOutput: tOutput);
     destructor Destroy; override;

     procedure LoadPlugins;
     procedure UnloadPlugins;
   end;

implementation

Uses Runtime;

constructor TPlugins.create;
begin
  foOutput:= aOutput;

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
  // Internal Plugin Class

  I := 0;
  while (i < PluginsMapFactoryClasses.Count) do
    begin
      FPlugin := TPluginsMapFactory.FindPlugin(PluginsMapFactoryClasses.Items[i].ClassName,
         foOutput );

      fPluginsList.Add(FPlugin);

      Inc(i);
    end;

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

                  fPluginsList.Add(FExternalPlugin.CreatePlugin(foOutput));
                  foOutput.Log('Loaded: ' + FExternalPlugin.PluginName);
                end;
            end
          else foOutput.Log('Missing: ' + loConfigPlugins.PluginFilenamePathname);
        end;

    end;
end;

end.
