unit Plugin_CodebehineTagClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase , uPSRuntime, uPSCompiler;


type
  tPlugin_CodebehineTagBase = class(TTagPlugin)
  private
  protected
    function GetTagName: string; override;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;

    function CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;
    procedure RegisterFunctions(aExec: TPSExec);
    procedure SetVariantToClasses(aExec: TPSExec);
    procedure RegisterImports;



  end;

  TPlugin_CodebehineTag = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_CodebehineTag: tPlugin_CodebehineTagBase;
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
  _Plugin_CodebehineTag: TPlugin_CodebehineTag = nil;

constructor tPlugin_CodebehineTagBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugins);
end;


destructor  tPlugin_CodebehineTagBase.Destroy;
begin
  Inherited;
end;

// Plugin_CodebehineTag
function tPlugin_CodebehineTag.GetPluginName: string;
begin
  Result := 'CodebehineTag';
end;

procedure tPlugin_CodebehineTag.Initialize;
begin
end;

function tPlugin_CodebehineTag.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_CodebehineTag := tPlugin_CodebehineTagBase.Create(aOutput, GetPluginName, foProject, aConfigPlugins);

  Result := FPlugin_CodebehineTag;
end;


procedure tPlugin_CodebehineTag.Finalize;
begin
  //if Assigned(FPlugin_CodebehineTag) then FPlugin_CodebehineTag.Free;
end;

// tPlugin_CodebehineTagBase

function tPlugin_CodebehineTagBase.CustomOnUses(aCompiler: TPSPascalCompiler): Boolean;
begin
  result := true;

  TPSPascalCompiler(aCompiler).AddFunction('procedure Writeln(s: string);');
end;

procedure tPlugin_CodebehineTagBase.RegisterFunctions(aExec: TPSExec);
begin
  aExec.RegisterFunctionName('WRITELN', CommandWriteln, nil, nil);
end;

procedure tPlugin_CodebehineTagBase.SetVariantToClasses(aExec: TPSExec);
begin
  //
end;

procedure tPlugin_CodebehineTagBase.RegisterImports;
begin
  //
end;

function tPlugin_CodebehineTagBase.GetTagName: string;
begin
  result := 'CODEBEHINE';
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_CodebehineTag = nil) then _Plugin_CodebehineTag := TPlugin_CodebehineTag.Create;
  result := _Plugin_CodebehineTag;
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
    _Plugin_CodebehineTag := nil;
  end;

finalization
  FreeAndNIL(_Plugin_CodebehineTag);

end.


