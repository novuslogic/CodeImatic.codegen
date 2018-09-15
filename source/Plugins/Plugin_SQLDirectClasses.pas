unit Plugin_SQLDirectClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase,  CodeGeneratorItem, FunctionsParser, ProjectItem,
    Variables, NovusFileUtils;

type
  tPlugin_SQLDirectBase = class(TDBSchemaPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;
  end;

  TPlugin_SQLDirect = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_SQLDirect: tPlugin_SQLDirectBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: Tproject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_SQLDirect: TPlugin_SQLDirect = nil;

constructor tPlugin_SQLdirectBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);


end;


destructor  tPlugin_SQLDirectBase.Destroy;
begin

  Inherited;
end;

// Plugin_SQLDirect
function tPlugin_SQLDirect.GetPluginName: string;
begin
  Result := 'SQLDirect';
end;

procedure tPlugin_SQLDirect.Initialize;
begin
end;

function tPlugin_SQLDirect.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SQLDirect := tPlugin_SQLDirectBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_SQLDirect;
end;


procedure tPlugin_SQLDirect.Finalize;
begin
  //if Assigned(FPlugin_SQLDiect) then FPlugin_SQLDirect.Free;
end;

// tPlugin_SQLDirect
function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_SQLDirect = nil) then _Plugin_SQLDirect := TPlugin_SQLDirect.Create;
  result := _Plugin_SQLDirect;
end;


end.
