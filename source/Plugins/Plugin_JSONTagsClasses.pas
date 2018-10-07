unit Plugin_JSONTagsClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase, NovusGUIDEx, CodeGeneratorItem, FunctionsParser, ProjectItem,
    Variables, NovusFileUtils, CodeGenerator;


type
  TJSONTag = class
  private
     foOutput: tOutput;
     foProjectItem: tProjectItem;
     foVariables: TVariables;
  protected
     function GetTagName: String; virtual;
  public
     constructor Create(aOutput: tOutput);

     function Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String; virtual;

     property TagName: String
       read GetTagName;

     property oOutput: tOutput
       read foOutput;
  end;

  TJSONTag_FieldCount = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String; override;
  end;


  tJSONTags = array of TJSONTag;

  tPlugin_JSONTagsBase = class(TTagsPlugin)
  private
  protected
    FJSONTags: tJSONTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_JSONTags = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_JSONTags: tPlugin_JSONTagsBase;
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
  _Plugin_JSONTags: TPlugin_JSONTags = nil;

constructor tPlugin_JSONTagsBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);

  FJSONTags:= tJSONTags.Create(TJSONTag_FieldCount.Create(aOutput)) ;
end;


destructor  tPlugin_JSONTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FJSONTags) -1 do
   begin
     FJSONTags[i].Free;
     FJSONTags[i] := NIL;
   end;

  FJSONTags := NIL;
  Inherited;
end;

// Plugin_JSONTags
function tPlugin_JSONTags.GetPluginName: string;
begin
  Result := 'JSON';
end;

procedure tPlugin_JSONTags.Initialize;
begin
end;

function tPlugin_JSONTags.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_JSONTags := tPlugin_JSONTagsBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_JSONTags;
end;


procedure tPlugin_JSONTags.Finalize;
begin
  //if Assigned(FPlugin_JSONTags) then FPlugin_JSONTags.Free;
end;

// tPlugin_JSONTagsBase
function tPlugin_JSONTagsBase.GetTag(aTagName: String; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
Var
  liIndex: Integer;
begin
  Result := '';
  liIndex := IsTagExists(aTagName);
  if liIndex = -1 then
   begin
     oOutput.LogError('Cannot find JOSN.' + aTagname);

     Exit;
   end;
  
  Result := FJSONTags[liIndex].Execute(aCodeGeneratorItem, aTokenIndex);
end;

function tPlugin_JSONTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then Exit;
   
  for I := 0 to Length(FJSONTags) -1 do
   begin
     if Uppercase(Trim(aTagName)) = Uppercase(Trim(FJSONTags[i].TagName)) then
       begin
         Result := i;

         Break;
       end;
   end;
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_JSONTags = nil) then _Plugin_JSONTags := TPlugin_JSONTags.Create;
  result := _Plugin_JSONTags;
end;


constructor TJSONTag.Create(aOutput: tOutput);
begin
  foOutput:= aOutput;
end;

function TJSONTag.GetTagName: String;
begin
  Result := '';
end;

function TJSONTag.Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
begin
  Result := '';
end;




function TJSONTag_FieldCount.GetTagName: String;
begin
  Result := 'FIELDCOUNT';
end;

function TJSONTag_FieldCount.Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
var
  LFunctionsParser: tFunctionsParser;
begin
  Try
    Try
      LFunctionsParser:= tFunctionsParser.Create(aCodeGeneratorItem, foOutput);

      LFunctionsParser.TokenIndex := aTokenIndex;

      LFunctionsParser.OnExecute := OnExecute;

      Result := LFunctionsParser.Execute;
    Finally
      LFunctionsParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_FieldCount.OnExecute(var aToken: String);
begin
  aToken :='';
end;


exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_JSONTags := nil;
  end;

finalization
  FreeAndNIL(_Plugin_JSONTags);

end.


