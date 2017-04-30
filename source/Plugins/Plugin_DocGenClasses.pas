unit Plugin_DocGenClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase, NovusGUIDEx;


type
  tPlugin_DocGenBase = class(TTagsPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;
  end;

  TPlugin_DocGen = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_DocGen: tPlugin_DocGenBase;
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
  _Plugin_DocGen: TPlugin_DocGen = nil;

constructor tPlugin_DocGenBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugins);
end;


destructor  tPlugin_DocGenBase.Destroy;
begin
  Inherited;
end;

// Plugin_DocGen
function tPlugin_DocGen.GetPluginName: string;
begin
  Result := 'DocGen';
end;

procedure tPlugin_DocGen.Initialize;
begin
end;

function tPlugin_DocGen.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_DocGen := tPlugin_DocGenBase.Create(aOutput, GetPluginName, foProject, aConfigPlugins);

  Result := FPlugin_DocGen;
end;


procedure tPlugin_DocGen.Finalize;
begin
  //if Assigned(FPlugin_DocGen) then FPlugin_DocGen.Free;
end;

// tPlugin_DocGenBase
function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_DocGen = nil) then _Plugin_DocGen := TPlugin_DocGen.Create;
  result := _Plugin_DocGen;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_DocGen := nil;
  end;

finalization
  FreeAndNIL(_Plugin_DocGen);

end.


