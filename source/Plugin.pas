unit Plugin;

interface

uses classes, Output, NovusPlugin, Project, config;

type
   TPlugin = class(TPersistent)
   private
   protected
     foConfigPlugins: TConfigPlugins;
     foProject: tProject;
     foOutput: tOutput;
     fsPluginName: String;
   public
     constructor Create(aOutput: tOutput; aPluginName: String; aProject: tProject; aConfigPlugins: TConfigPlugins); virtual;

     property oProject: Tproject
       read foProject
       write foProject;

     property oOutput: tOutput
       read foOutput
       write foOutput;

     property oConfigPlugins: TConfigPlugins
       read foConfigPlugins
       write foConfigPlugins;

     property PluginName: String
       read fsPluginName
       write fsPluginName;
   end;

   TTagsPlugin = class(TPlugin)
   private
   protected
   public
     function GetTag(aTagName: String): String; virtual;
     function IsTagExists(aTagName: String): Integer; virtual;
   end;


   TConvertPlugin = class(TPlugin)
   private
   protected
   public
   end;

   TCommandLinePlugin = class(TPlugin)
   private
   protected
   public
     function BeforeCodeGen: boolean; virtual;
     function AfterCodeGen: boolean; virtual;
     function IsCommandLine(aCommandLine: String): boolean; virtual;
   end;


   IExternalPlugin = interface(INovusPlugin)
     ['{155A396A-9457-4C48-A787-0C9582361B45}']

     function  CreatePlugin(aOutput: tOutput; aProject: tProject; aConfigPlugins: TConfigPlugins):TPlugin safecall;
   end;


   TPluginClass = class of TPlugin;

implementation

constructor TPlugin.create;
begin
  foConfigPlugins:= aConfigPlugins;
  foProject := aProject;
  foOutput:= aOutput;
  fsPluginName := aPluginName;
end;


function TTagsPlugin.GetTag(aTagName: String): String;
begin
  Result := '';
end;

function TTagsPlugin.IsTagExists(aTagName: String): Integer;
begin
  Result := -1;
end;

function TCommandLinePlugin.BeforeCodeGen: boolean;
begin
  Result := False;
end;

function TCommandLinePlugin.AfterCodeGen: boolean;
begin
  Result := False;
end;

function TCommandLinePlugin.IsCommandLine(aCommandLine: String): boolean;
begin
  Result := False;
end;

end.
