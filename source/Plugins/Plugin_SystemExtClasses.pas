unit Plugin_SystemExtClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase , uPSRuntime, uPSCompiler;


type
  tPlugin_SystemExtBase = class(TPascalScriptPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;

    function CustomOnUses(aCompiler: TPSPascalCompiler): Boolean; override;
    procedure RegisterFunctions(aExec: TPSExec); override;
    procedure SetVariantToClasses(aExec: TPSExec); override;
    procedure RegisterImports; override;

  end;

  TPlugin_SystemExt = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_SystemExt: tPlugin_SystemExtBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: Tproject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;

  end;

function GetPluginObject: INovusPlugin; stdcall;
function CommandWriteln(Caller: TPSExec; p: TIFExternalProcRec; Global, Stack: TPSStack): Boolean;

implementation

var
  _Plugin_SystemExt: TPlugin_SystemExt = nil;

constructor tPlugin_SystemExtBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugins);
end;


destructor  tPlugin_SystemExtBase.Destroy;
begin
  Inherited;
end;

// Plugin_SystemExt
function tPlugin_SystemExt.GetPluginName: string;
begin
  Result := 'SystemExt';
end;

procedure tPlugin_SystemExt.Initialize;
begin
end;

function tPlugin_SystemExt.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SystemExt := tPlugin_SystemExtBase.Create(aOutput, GetPluginName, foProject, aConfigPlugins);

  Result := FPlugin_SystemExt;
end;


procedure tPlugin_SystemExt.Finalize;
begin
  //if Assigned(FPlugin_SystemExt) then FPlugin_SystemExt.Free;
end;

// tPlugin_SystemExtBase

function tPlugin_SystemExtBase.CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;
begin
  result := true;

  TPSPascalCompiler(aCompiler).AddFunction('procedure Writeln(s: string);');
end;

procedure tPlugin_SystemExtBase.RegisterFunctions(aExec: TPSExec);
begin
  aExec.RegisterFunctionName('WRITELN', CommandWriteln, nil, nil);
end;

procedure tPlugin_SystemExtBase.SetVariantToClasses(aExec: TPSExec);
begin
  //
end;

procedure tPlugin_SystemExtBase.RegisterImports;
begin
  //
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_SystemExt = nil) then _Plugin_SystemExt := TPlugin_SystemExt.Create;
  result := _Plugin_SystemExt;
end;

function CommandWriteln(Caller: TPSExec; p: TIFExternalProcRec; Global, Stack: TPSStack): Boolean;
var
  PStart: Cardinal;
begin
  if Global = nil then begin result := false; exit; end;
  PStart := Stack.Count - 1;

 // oRuntime.oAPI_Output.Log(Stack.GetString(PStart));

  Result := True;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_SystemExt := nil;
  end;

finalization
  FreeAndNIL(_Plugin_SystemExt);

end.


