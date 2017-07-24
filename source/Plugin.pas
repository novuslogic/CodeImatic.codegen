unit Plugin;

interface

uses classes, Output, NovusPlugin, Project, (*ProjectItem,*) config, NovusTemplate, uPSRuntime, uPSCompiler;

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

  TScriptEnginePlugin = class(TPlugin)
  private
  protected
    fImp: TPSRuntimeClassImporter;
  public
    procedure initialize(var aImp: TPSRuntimeClassImporter); virtual;

    function CustomOnUses(var aCompiler: TPSPascalCompiler): Boolean; virtual;
    procedure RegisterFunction(var aExec: TPSExec); virtual;
    procedure SetVariantToClass(var aExec: TPSExec); virtual;
    procedure RegisterImport; virtual;

    property _Imp: TPSRuntimeClassImporter read fImp write fImp;
  end;

   TTagsPlugin = class(TPlugin)
   private
   protected
   public
     function GetTag(aTagName: String): String; virtual;
     function IsTagExists(aTagName: String): Integer; virtual;
   end;

   TTagPlugin = class(TPlugin)
   private
   protected
     function GetTagName: string; virtual;
   public
     property TagName: String
       read GetTagName;
   end;

   TProcessorPlugin = class(TPlugin)
   private
   protected
     function Getsourceextension: string; virtual;
     function Getoutputextension: string; virtual;
   public
     function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; var aOutputFile: string): boolean; virtual;
     function PreProcessor(aFilename: String; var aTemplateDoc: tstringlist): boolean; virtual;

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

function TScriptEnginePlugin.CustomOnUses(var aCompiler: TPSPascalCompiler): Boolean;
begin
  Result := False;
end;

procedure TScriptEnginePlugin.initialize(var aImp: TPSRuntimeClassImporter);
begin
  fImp := aImp;
end;


procedure TScriptEnginePlugin.RegisterFunction(var aExec: TPSExec);
begin

end;

procedure TScriptEnginePlugin.SetVariantToClass(var aExec: TPSExec);
begin

end;

procedure TScriptEnginePlugin.RegisterImport;
begin

end;


function TTagPlugin.GetTagName: String;
begin
  result := '';
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

function TProcessorPlugin.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
begin
  Result := false;
end;

function TProcessorPlugin.PreProcessor(aFilename: String; var aTemplateDoc: tstringlist): boolean;
begin
  Result := false;
end;

function TProcessorPlugin.Getsourceextension: string;
begin
  Result := '';
end;

function TProcessorPlugin.Getoutputextension: string;
begin
  Result := '';
end;




end.
