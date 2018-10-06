unit Plugin_DBTagsClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase, NovusGUIDEx, CodeGeneratorItem, FunctionsParser, ProjectItem,
    Variables, NovusFileUtils, CodeGenerator;


type
  TDBTag = class
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

  TDBTag_FieldCount = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String; override;
  end;


  tDBTags = array of TDBTag;

  tPlugin_DBTagsBase = class(TTagsPlugin)
  private
  protected
    FDBTags: tDBTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_DBTags = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_DBTags: tPlugin_DBTagsBase;
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
  _Plugin_DBTags: TPlugin_DBTags = nil;

constructor tPlugin_DBTagsBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);

  FDBTags:= tDBTags.Create(TDBTag_FieldCount.Create(aOutput)) ;
end;


destructor  tPlugin_DBTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FDBTags) -1 do
   begin
     FDBTags[i].Free;
     FDBTags[i] := NIL;
   end;

  FDBTags := NIL;
  Inherited;
end;

// Plugin_DBTags
function tPlugin_DBTags.GetPluginName: string;
begin
  Result := 'DB';
end;

procedure tPlugin_DBTags.Initialize;
begin
end;

function tPlugin_DBTags.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_DBTags := tPlugin_DBTagsBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_DBTags;
end;


procedure tPlugin_DBTags.Finalize;
begin
  //if Assigned(FPlugin_DBTags) then FPlugin_DBTags.Free;
end;

// tPlugin_DBTagsBase
function tPlugin_DBTagsBase.GetTag(aTagName: String; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
Var
  liIndex: Integer;
begin
  Result := '';
  liIndex := IsTagExists(aTagName);
  if liIndex = -1 then
   begin
     oOutput.LogError('Cannot find sys.' + aTagname);

     Exit;
   end;
  
  Result := FDBTags[liIndex].Execute(aCodeGeneratorItem, aTokenIndex);
end;

function tPlugin_DBTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then Exit;
   
  for I := 0 to Length(FDBTags) -1 do
   begin
     if Uppercase(Trim(aTagName)) = Uppercase(Trim(FDBTags[i].TagName)) then
       begin
         Result := i;

         Break;
       end;
   end;
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_DBTags = nil) then _Plugin_DBTags := TPlugin_DBTags.Create;
  result := _Plugin_DBTags;
end;


constructor TDBTag.Create(aOutput: tOutput);
begin
  foOutput:= aOutput;
end;

function TDBTag.GetTagName: String;
begin
  Result := '';
end;

function TDBTag.Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
begin
  Result := '';
end;




function TDBTag_FieldCount.GetTagName: String;
begin
  Result := 'FIELDCOUNT';
end;

function TDBTag_FieldCount.Execute(aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
var
  LFunctionsParser: tFunctionsParser;
begin
  Try
    Try
      LFunctionsParser:= tFunctionsParser.Create(aCodeGeneratorItem, foOutput);

      LFunctionsParser.TokenIndex := aTokenIndex;

      LFunctionsParser.OnExecuteFunction := OnExecute;

      Result := LFunctionsParser.Execute;
    Finally
      LFunctionsParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TDBTag_FieldCount.OnExecute(var aToken: String);
begin
  aToken :='';
end;


exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_DBTags := nil;
  end;

finalization
  FreeAndNIL(_Plugin_DBTags);

end.


