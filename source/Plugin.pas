unit Plugin;

interface

uses classes, Output, NovusPlugin, Project, config, NovusTemplate, uPSRuntime, uPSCompiler;

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

   TPascalScriptPlugin = class(TPlugin)
   private
   protected
   public
     function CustomOnUses(aCompiler: TPSPascalCompiler): Boolean; virtual;
     procedure RegisterFunctions(aExec: TPSExec); virtual;
     procedure SetVariantToClasses(aExec: TPSExec); virtual;
     procedure RegisterImports; virtual;
   end;


   TPostProcessorPlugin = class(TPlugin)
   private
   protected
     function Getsourceextension: string; virtual;
     function Getoutputextension: string; virtual;
   public
     function PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate; var aOutputFile: string): boolean; overload; virtual;
     function PostProcessor(aFilename: String; var aTemplateDoc: tstringlist): boolean;  overload; virtual;

     property Sourceextension: string
       read Getsourceextension;

      property outputextension: string
       read Getoutputextension;
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

function TPostProcessorPlugin.PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
begin
  Result := false;
end;

function TPostProcessorPlugin.PostProcessor(aFilename: String; var aTemplateDoc: tstringlist): boolean;
begin
  Result := false;
end;

function TPostProcessorPlugin.Getsourceextension: string;
begin
  Result := '';
end;

function TPostProcessorPlugin.Getoutputextension: string;
begin
  Result := '';
end;

function TPascalScriptPlugin.CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;
begin
  result := false;
end;

procedure TPascalScriptPlugin.RegisterFunctions(aExec: TPSExec);
begin
  //
end;

procedure TPascalScriptPlugin.SetVariantToClasses(aExec: TPSExec);
begin
  //
end;

procedure TPascalScriptPlugin.RegisterImports;
begin
  //
end;


end.
