unit Plugin_SysTagsClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime,
    APIBase ;


type
  tPlugin_SysTagsBase = class(TTagsPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject); override;
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

    function CreatePlugin(aOutput: tOutput; aProject: Tproject): TPlugin; safecall;

  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_SysTags: TPlugin_SysTags = nil;

constructor tPlugin_SysTagsBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject);
begin
  Inherited Create(aOutput,aPluginName, aProject);
end;


destructor  tPlugin_SysTagsBase.Destroy;
begin
  Inherited;
end;

// Plugin_SysTags
function tPlugin_SysTags.GetPluginName: string;
begin
  Result := 'SysTags';
end;

procedure tPlugin_SysTags.Initialize;
begin
end;

function tPlugin_SysTags.CreatePlugin(aOutput: tOutput; aProject: TProject): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SysTags := tPlugin_SysTagsBase.Create(aOutput, GetPluginName, foProject);

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

   end;
end;

function tPlugin_SysTagsBase.IsTagExists(aTagName: String): Integer;
begin
  Result := -1;
  if atagName = 'ZCVERSION' then
    Result := 0;
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


