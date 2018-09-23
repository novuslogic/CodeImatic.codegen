unit Plugin_SQLDirClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase, NovusGUIDEx, CodeGeneratorItem, FunctionsParser, ProjectItem,
    Variables, NovusFileUtils;


type
  tPlugin_SQLDirBase = class(TDBSchemaPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function SetupDatabase: Boolean; override;
  end;

  TPlugin_SQLDir = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_SQLDir: tPlugin_SQLDirBase;
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
  _Plugin_SQLDir: TPlugin_SQLDir = nil;

constructor tPlugin_SQLDirBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);
end;


destructor  tPlugin_SQLDirBase.Destroy;
Var
  I: Integer;
begin
  
  Inherited;
end;

// Plugin_SQLDir
function tPlugin_SQLDir.GetPluginName: string;
begin
  Result := 'SQLDIR';
end;

procedure tPlugin_SQLDir.Initialize;
begin
end;

function tPlugin_SQLDir.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SQLDir := tPlugin_SQLDirBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_SQLDir;
end;


procedure tPlugin_SQLDir.Finalize;
begin
  //if Assigned(FPlugin_SQLDir) then FPlugin_SQLDir.Free;
end;

// tPlugin_SQLDirBase


function tPlugin_SQLDirBase.SetupDatabase: Boolean;
begin
  Result := False;


  foOutput.Log('yes');
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_SQLDir = nil) then _Plugin_SQLDir := TPlugin_SQLDir.Create;
  result := _Plugin_SQLDir;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_SQLDir := nil;
  end;

finalization
  FreeAndNIL(_Plugin_SQLDir);

end.


