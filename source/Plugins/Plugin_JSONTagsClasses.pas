unit Plugin_JSONTagsClasses;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project,
  Output, SysUtils, System.Generics.Defaults, runtime, Config,
  APIBase, NovusGUIDEx, CodeGeneratorItem, FunctionsParser, ProjectItem,
  Variables, NovusFileUtils, CodeGenerator, JSONFunctionParser, TokenParser,
  NovusJSONUtils, System.IOUtils, System.JSON, TokenProcessor, NovusStringUtils;

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

    function GetJSONObjectVariable(aToken: string): TVariable;

    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; virtual;

    property TagName: String read GetTagName;

    property oOutput: tOutput read foOutput;

    property oVariables: TVariables read foVariables write foVariables;
  end;

  TJSONTag_LoadJSON = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser;
      aJSONFilename: String);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONQuery = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONPairValue = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONGetArray = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONArraySize = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_ToJSON = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_ToJSONValue = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  tJSONTags = array of TJSONTag;

  tPlugin_JSONTagsBase = class(TTagsPlugin)
  private
  protected
    FJSONTags: tJSONTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aTokens: tTokenProcessor;
      aProjectItem: TObject): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_JSONTags = class(TSingletonImplementation, INovusPlugin,
    IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_JSONTags: tPlugin_JSONTagsBase;
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
  _Plugin_JSONTags: TPlugin_JSONTags = nil;

constructor tPlugin_JSONTagsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

  FJSONTags := tJSONTags.Create(TJSONTag_LoadJSON.Create(aOutput),
    TJSONTag_JSONQuery.Create(aOutput), TJSONTag_ToJSON.Create(aOutput),
    TJSONTag_ToJSONValue.Create(aOutput),
    TJSONTag_JSONGetArray.Create(aOutput),
    TJSONTag_JSONArraySize.Create(aOutput),
    TJSONTag_JSONPairValue.Create(aOutput));
end;

destructor tPlugin_JSONTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FJSONTags) - 1 do
  begin
    FJSONTags[I].Free;
    FJSONTags[I] := NIL;
  end;

  FJSONTags := NIL;
  Inherited;
end;

// Plugin_JSONTags
function TPlugin_JSONTags.GetPluginName: string;
begin
  Result := 'JSON';
end;

procedure TPlugin_JSONTags.Initialize;
begin
end;

function TPlugin_JSONTags.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugin: tConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_JSONTags := tPlugin_JSONTagsBase.Create(aOutput, GetPluginName,
    foProject, aConfigPlugin);

  Result := FPlugin_JSONTags;
end;

procedure TPlugin_JSONTags.Finalize;
begin
  // if Assigned(FPlugin_JSONTags) then FPlugin_JSONTags.Free;
end;

// tPlugin_JSONTagsBase
function tPlugin_JSONTagsBase.GetTag(aTagName: String; aTokens: tTokenProcessor;
  aProjectItem: TObject): String;
Var
  liIndex: Integer;
begin
  Result := '';

  liIndex := IsTagExists(aTagName);
  if liIndex = -1 then
  begin
    oOutput.LogError('Cannot find JOSN.' + aTagName);

    Exit;
  end;

  Result := FJSONTags[liIndex].Execute((aProjectItem as tProjectItem),
    aTagName, aTokens);
end;

function tPlugin_JSONTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then
    Exit;

  for I := 0 to Length(FJSONTags) - 1 do
  begin
    if Uppercase(Trim(aTagName)) = Uppercase(Trim(FJSONTags[I].TagName)) then
    begin
      Result := I;

      Break;
    end;
  end;
end;

function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_JSONTags = nil) then
    _Plugin_JSONTags := TPlugin_JSONTags.Create;
  Result := _Plugin_JSONTags;
end;

constructor TJSONTag.Create(aOutput: tOutput);
begin
  foOutput := aOutput;
end;

function TJSONTag.GetTagName: String;
begin
  Result := '';
end;

function TJSONTag.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
begin
  Result := '';
end;

function TJSONTag.GetJSONObjectVariable(aToken: string): TVariable;
Var
  FVariable: TVariable;
begin
  Result := NIL;

  FVariable := Self.oVariables.GetVariableByName(aToken);
  if Not Assigned(FVariable) then
  begin
    Self.foOutput.LogError(TJSONTag.ClassName +
      ' Object Variable cannot be found.');
    Exit;
  end
  else if Not FVariable.IsObject then
  begin
    Self.foOutput.LogError('[' + aToken + '] not an Object Variable.');
    Exit;
  end
  else if FVariable.Value <> TJSONTag.ClassName then
  begin
    Self.foOutput.LogError('[' + aToken + '] not ' + TJSONTag.ClassName +
      ' Object Variable.');
    Exit;
  end;

  Result := FVariable;
end;

function TJSONTag_LoadJSON.GetTagName: String;
begin
  Result := 'LOADJSON';
end;

function TJSONTag_LoadJSON.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LJSONFunctionParser: tJSONFunctionParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LJSONFunctionParser := tJSONFunctionParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LJSONFunctionParser.OnExecute := OnExecute;

      Result := LJSONFunctionParser.Execute;
    Finally
      LJSONFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_LoadJSON.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aJSONFilename: String);
Var
  FJSONValue: TJSONValue;
begin
  aToken := '';

  Try
    FJSONValue := TJSONObject.ParseJSONValue
      (TEncoding.ASCII.GetBytes(TFile.ReadAllText(aJSONFilename)), 0);
  Except
    oOutput.LogError('JSONFilename cannot read [' + aJSONFilename + ']');
  End;

  aToken := Self.oVariables.AddVariableObject(FJSONValue, TJSONTag.ClassName);
end;


// TJSONTag_JSONQuery

function TJSONTag_JSONQuery.GetTagName: String;
begin
  Result := 'JSONQUERY';
end;

function TJSONTag_JSONQuery.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionAParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionAParser := tFunctionAParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LFunctionAParser.OnExecute := OnExecute;

      Result := LFunctionAParser.Execute;
    Finally
      LFunctionAParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_JSONQuery.OnExecute(var aToken: String;
  aTokenParser: tTokenParser);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  FJSONValueRoot := TJSONValue(FVariable.oObject);

  lsElement := aTokenParser.ParseNextToken;
  if Trim(lsElement) = '' then
  begin
    foOutput.LogError('Element cannot be blank.');

    Exit;
  end;

  FJSONValue := FJSONValueRoot.GetValue<TJSONValue>(lsElement);
  if not Assigned(FJSONValue) then
  begin
    foOutput.LogError('Element [' + lsElement + '] cannot be found.');

    Exit;
  end;

  aToken := Self.oVariables.AddVariableObject(FJSONValue, TJSONTag.ClassName);
end;

// TJSONTag_ToJSON
function TJSONTag_ToJSON.GetTagName: String;
begin
  Result := 'TOJSON';
end;

function TJSONTag_ToJSON.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionAParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionAParser := tFunctionAParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LFunctionAParser.OnExecute := OnExecute;

      Result := LFunctionAParser.Execute;
    Finally
      LFunctionAParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_ToJSON.OnExecute(var aToken: String;
  aTokenParser: tTokenParser);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

   aToken := TJSONValue(FVariable.oObject).ToJSON;
end;

// TJSONTag_ToJSONValue
function TJSONTag_ToJSONValue.GetTagName: String;
begin
  Result := 'TOJSONValue';
end;

function TJSONTag_ToJSONValue.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionAParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionAParser := tFunctionAParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LFunctionAParser.OnExecute := OnExecute;

      Result := LFunctionAParser.Execute;
    Finally
      LFunctionAParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_ToJSONValue.OnExecute(var aToken: String;
  aTokenParser: tTokenParser);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  FJSONValueRoot := TJSONValue(FVariable.oObject);

  aToken := FJSONValueRoot.Value;
end;

// TJSONTag_JSONGetArray
function TJSONTag_JSONGetArray.GetTagName: String;
begin
  Result := 'JSONGETARRAY';
end;

function TJSONTag_JSONGetArray.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionAParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionAParser := tFunctionAParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LFunctionAParser.OnExecute := OnExecute;

      Result := LFunctionAParser.Execute;
    Finally
      LFunctionAParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_JSONGetArray.OnExecute(var aToken: String;
  aTokenParser: tTokenParser);
Var
  FJSONArray: TJSONArray;
  FVariable: TVariable;
  lsElement: string;
  liIndex: Integer;
  FJSONValue: TJSONValue;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  FJSONArray := TJSONArray(FVariable.oObject);

  lsElement := aTokenParser.ParseNextToken;
  if Trim(lsElement) = '' then
  begin
    foOutput.LogError('Incorrect syntax: Element Index cannot be blank.');

    Exit;
  end;

  if not TNovusStringUtils.IsNumberStr(lsElement) then
    begin
      foOutput.Log('Incorrect syntax: Element Index is not a numeric.');

      Exit;
    end;

  liIndex := TNovusStringUtils.Str2Int(lsElement);
  if liIndex < 0 then
    begin
      foOutput.Log('Incorrect syntax: Element Index less than zero.');

      Exit;
    end;

  if liIndex > (FJSONArray.Size - 1) then
    begin
      foOutput.Log('Incorrect syntax: Element Index greater than JSON Array size.');

      Exit;
    end;

  FJSONValue :=  TJSONValue(FJSONArray.Get(liIndex));
  aToken := Self.oVariables.AddVariableObject(FJSONValue, TJSONTag.ClassName);
end;

// TJSONTag_JSONPairValue
function TJSONTag_JSONPairValue.GetTagName: String;
begin
  Result := 'JSONPairValue';
end;

function TJSONTag_JSONPairValue.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionAParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionAParser := tFunctionAParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LFunctionAParser.OnExecute := OnExecute;

      Result := LFunctionAParser.Execute;
    Finally
      LFunctionAParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_JSONPairValue.OnExecute(var aToken: String;
  aTokenParser: tTokenParser);
Var
  FJSONArray: TJSONArray;
  FVariable: TVariable;
  lsElement: string;
  liIndex: Integer;
  FJSONValue: TJSONValue;
  FJSONPair: TJSONPair;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  FJSONPair:= TJSONPair(FVariable.oObject);

  aToken := FJSONPair.JsonString.Value;
end;


// TJSONTag_JSONArraySize
function TJSONTag_JSONArraySize.GetTagName: String;
begin
  Result := 'JSONArraySize';
end;

function TJSONTag_JSONArraySize.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionAParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionAParser := tFunctionAParser.Create(aProjectItem, aTokens,
        foOutput, aTagName);

      LFunctionAParser.OnExecute := OnExecute;

      Result := LFunctionAParser.Execute;
    Finally
      LFunctionAParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TJSONTag_JSONArraySize.OnExecute(var aToken: String;
  aTokenParser: tTokenParser);
Var
  FJSONArray: TJSONArray;
  FVariable: TVariable;
  lsElement: string;
  liIndex: Integer;
  FJSONValue: TJSONValue;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  FJSONArray := TJSONArray(FVariable.oObject);

  aToken := IntToStr(FJSONArray.Size-1);
end;



exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_JSONTags := nil;
end;

finalization

FreeAndNIL(_Plugin_JSONTags);

end.
