unit Plugin_SysTagsClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase, NovusGUIDEx;


type
  tPlugin_SysTagsBase = class(TTagsPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_SysTags = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_SysTags: tPlugin_SysTagsBase;
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
  _Plugin_SysTags: TPlugin_SysTags = nil;

constructor tPlugin_SysTagsBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);
end;


destructor  tPlugin_SysTagsBase.Destroy;
begin
  Inherited;
end;

// Plugin_SysTags
function tPlugin_SysTags.GetPluginName: string;
begin
  Result := 'Sys';
end;

procedure tPlugin_SysTags.Initialize;
begin
end;

function tPlugin_SysTags.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SysTags := tPlugin_SysTagsBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_SysTags;
end;


procedure tPlugin_SysTags.Finalize;
begin
  //if Assigned(FPlugin_SysTags) then FPlugin_SysTags.Free;
end;

// tPlugin_SysTagsBase
function tPlugin_SysTagsBase.GetTag(aTagName: String): String;
begin
   case IsTagExists(aTagName) of
   0: result := oRuntime.GetVersion(1);
   1: result := TGuidExUtils.NewGuidString;
   2: result := TGuidExUtils.NewGuidNoBracketsString;
   end;
end;

function tPlugin_SysTagsBase.IsTagExists(aTagName: String): Integer;
begin
  Result := -1;
  if uppercase(atagName) = 'VERSION' then
    Result := 0
  else
  if uppercase(aTagName) = 'NEWGUID' then
    result := 1;
  if uppercase(aTagName) = 'NEWGUIDNOBRACKETS' then
    result := 2;
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_SysTags = nil) then _Plugin_SysTags := TPlugin_SysTags.Create;
  result := _Plugin_SysTags;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_SysTags := nil;
  end;

finalization
  FreeAndNIL(_Plugin_SysTags);

end.


