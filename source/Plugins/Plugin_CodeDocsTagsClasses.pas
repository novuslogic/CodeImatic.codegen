unit Plugin_CodeDocsTagsClasses;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project,
  Output, SysUtils, System.Generics.Defaults, runtime, Config,
  APIBase, NovusGUID, CodeGeneratorItem, FunctionsParser, ProjectItem,
  Variables, NovusFileUtils, CodeGenerator, NovusStringUtils, TokenProcessor,
  TagBasePlugin;

type
  TCodeDocsTag = class(TTagBasePlugin)
  private
  protected
  public
  end;


  TCodeDocsTag_WrapText = class(TCodeDocsTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;



  tCodeDocsTags = array of TCodeDocsTag;

  tPlugin_CodeDocsTagsBase = class(TTagsPlugin)
  private
  protected
    FCodeDocsTags: tCodeDocsTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aTokens: tTokenProcessor; aProjectItem: tObject): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_CodeDocsTags = class(TSingletonImplementation, INovusPlugin,
    IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_CodeDocsTags: tPlugin_CodeDocsTagsBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: TProject;
      aConfigPlugin: tConfigPlugin): TPlugin; safecall;
  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_CodeDocsTags: TPlugin_CodeDocsTags = nil;

constructor tPlugin_CodeDocsTagsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

  FCodeDocsTags := tCodeDocsTags.Create(TCodeDocsTag_WrapText.Create(aOutput));
end;

destructor tPlugin_CodeDocsTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FCodeDocsTags) - 1 do
  begin
    FCodeDocsTags[I].Free;
    FCodeDocsTags[I] := NIL;
  end;

  FCodeDocsTags := NIL;
  Inherited;
end;

// Plugin_CodeDocsTags
function TPlugin_CodeDocsTags.GetPluginName: string;
begin
  Result := 'CodeDocs';
end;

procedure TPlugin_CodeDocsTags.Initialize;
begin
end;

function TPlugin_CodeDocsTags.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugin: tConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_CodeDocsTags := tPlugin_CodeDocsTagsBase.Create(aOutput, GetPluginName,
    foProject, aConfigPlugin);

  Result := FPlugin_CodeDocsTags;
end;

procedure TPlugin_CodeDocsTags.Finalize;
begin
  // if Assigned(FPlugin_CodeDocsTags) then FPlugin_CodeDocsTags.Free;
end;

// tPlugin_CodeDocsTagsBase
function tPlugin_CodeDocsTagsBase.GetTag(aTagName: String;
  aTokens: tTokenProcessor;  aProjectItem: TObject): String;
Var
  liIndex: Integer;
begin
  Result := '';
  liIndex := IsTagExists(aTagName);

  if liIndex = -1 then
  begin
    oOutput.LogError('Cannot find CodeDocs.' + aTagName);

    Exit;
  end;

  Result := FCodeDocsTags[liIndex].Execute((aProjectItem as tProjectItem), aTagName, aTokens);
end;

function tPlugin_CodeDocsTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then
    Exit;

  for I := 0 to Length(FCodeDocsTags) - 1 do
  begin
    if Uppercase(Trim(aTagName)) = Uppercase(Trim(FCodeDocsTags[I].TagName)) then
    begin
      Result := I;

      Break;
    end;
  end;
end;

function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_CodeDocsTags = nil) then
    _Plugin_CodeDocsTags := TPlugin_CodeDocsTags.Create;
  Result := _Plugin_CodeDocsTags;
end;

// WrapText
function TCodeDocsTag_WrapText.GetTagName: String;
begin
  Result := 'WRAPTEXT';
end;

function TCodeDocsTag_WrapText.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  LFunctionParser := NIL;

  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionParser.Create(aProjectItem, aTokens, oOutput,
        aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      if Assigned(LFunctionParser) then
        LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TCodeDocsTag_WrapText.OnExecute(var aToken: String);
begin
  aToken := WrapText(aToken, 100);
end;

exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_CodeDocsTags := nil;
end;

finalization

FreeAndNIL(_Plugin_CodeDocsTags);

end.
