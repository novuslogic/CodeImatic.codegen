unit Plugin_SassClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,  NovusStringUtils,
    APIBase, ProjectItem, TagType ;


type
  tPlugin_SassBase = class( TProcessorPlugin)
  private
  protected
    function Getoutputextension: string; override;
    function Getsourceextension: string; override;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;

    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;var aOutputFile: string): boolean; overload; override;
    function PreProcessor(aFilename: String; var aTemplateDoc: tStringlist): boolean; override;


  end;

  TPlugin_Sass = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_Sass: tPlugin_SassBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: Tproject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;


  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_Sass: TPlugin_Sass = nil;

constructor tPlugin_SassBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugins);
end;


destructor  tPlugin_SassBase.Destroy;
begin
  Inherited;
end;

// Plugin_Sass
function tPlugin_Sass.GetPluginName: string;
begin
  Result := 'Sass';
end;

procedure tPlugin_Sass.Initialize;
begin
end;

function tPlugin_Sass.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_Sass := tPlugin_SassBase.Create(aOutput, GetPluginName, foProject, aConfigPlugins);

  Result := FPlugin_Sass;
end;


procedure tPlugin_Sass.Finalize;
begin
  //if Assigned(FPlugin_Sass) then FPlugin_Sass.Free;
end;

// tPlugin_SassBase

function tPlugin_SassBase.Getoutputextension: String;
begin
  Result := 'css';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('outputextension') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('outputextension');
end;

function tPlugin_SassBase.Getsourceextension: String;
begin
  Result := 'scss';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('sourceextension') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('sourceextension');
end;

function tPlugin_SassBase.PreProcessor(aFilename: string; var aTemplateDoc: tStringlist): boolean;
Var
  //fSassprocessor: TSassDaringFireball;
  fsProcessed: string;
begin
  Result := False;    result := false;

  foOutput.Log('Processor:' + pluginname);

  (*
  Try
    Try
      fSassprocessor:= TSassDaringFireball.Create;

      fsProcessed := fSassprocessor.process(aTemplateDoc.Text);

      aTemplateDoc.Text := fsProcessed;

      result := true;
    Except
      result := false;

      foOutput.InternalError;
    End;
  Finally
    fSassprocessor.Free;
  End;
  *)
end;

function tPlugin_SassBase.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
begin
  result := false;

  foOutput.Log('Postprocessor:' + pluginname);

  Try
    aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

    foOutput.Log('New output:' + aOutputFile);

    result := true;
  Except
    result := false;
    foOutput.InternalError;
  End;
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_Sass = nil) then _Plugin_Sass := TPlugin_Sass.Create;
  result := _Plugin_Sass;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_Sass := nil;
  end;

finalization
  FreeAndNIL(_Plugin_Sass);

end.


