unit Plugin_XMLTagsClasses;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project,
  Output, SysUtils, System.Generics.Defaults, runtime, Config,
  APIBase, NovusGUIDEx, CodeGeneratorItem, FunctionsParser, ProjectItem,
  Variables, NovusFileUtils, CodeGenerator, FileExistsFunctionParser, TokenParser,
  NovusJSONUtils, System.IOUtils, System.JSON, TokenProcessor, NovusStringUtils,
  TagBasePlugin, XMLList;

type
  tJsonValueType = (jsArray, jsObject, jsPair, jsUnknown);

  TXMLTag = class(tTagBasePlugin)
  private
  protected
  public
    function GetXMLListObjectVariable(aToken: string): TVariable;
  end;

  TXMLTag_XMLList = class(TXMLTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TXMLTag_XMLListCount = class(TXMLTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TXMLTag_LoadXMLList = class(TXMLTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String;
       aTokenParser: tTokenParser; aFilename: String);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;


  tXMLTags = array of TXMLTag;

  tPlugin_XMLTagsBase = class(TTagsPlugin)
  private
  protected
    FXMLTags: tXMLTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aTokens: tTokenProcessor;
      aProjectItem: TObject): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_XMLTags = class(TSingletonImplementation, INovusPlugin,
    IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_XMLTags: tPlugin_XMLTagsBase;
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
  _Plugin_XMLTags: TPlugin_XMLTags = nil;


constructor tPlugin_XMLTagsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);


  FXMLTags := tXMLTags.Create(TXMLTag_XMLList.Create(aOutput),
    TXMLTag_XMLListCount.Create(aOutput), TXMLTag_LoadXMLList.Create(aOutput));
end;

destructor tPlugin_XMLTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FXMLTags) - 1 do
  begin
    FXMLTags[I].Free;
    FXMLTags[I] := NIL;
  end;

  FXMLTags := NIL;
  Inherited;
end;


function TXMLTag.GetXMLListObjectVariable(aToken: string): TVariable;
Var
  FVariable: TVariable;
begin
  Result := NIL;

  if AToken= ''  then
    begin
      Self.oOutput.LogError(
      'Blank Variable name.');

      Exit;
    end;

  FVariable := Self.oVariables.GetVariableByName(aToken);

  if Not Assigned(FVariable) then
  begin
    Self.oOutput.LogError(aToken +
      ' Object Variable cannot be found.');
    Exit;
  end
  else if Not FVariable.IsObject then
  begin
    Self.oOutput.LogError('[' + aToken + '] not an Object Variable.');
    Exit;
  end
  else if FVariable.Value <> tXMLlist.ClassName then
  begin
    Self.oOutput.LogError('[' + aToken + '] not ' + tXMLlist.ClassName +
      ' Object Variable.');
    Exit;
  end;

  Result := FVariable;
end;

// Plugin_XMLTags
function TPlugin_XMLTags.GetPluginName: string;
begin
  Result := 'XML';
end;

procedure TPlugin_XMLTags.Initialize;
begin
end;

function TPlugin_XMLTags.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugin: tConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_XMLTags := tPlugin_XMLTagsBase.Create(aOutput, GetPluginName,
    foProject, aConfigPlugin);

  Result := FPlugin_XMLTags;
end;

procedure TPlugin_XMLTags.Finalize;
begin
  // if Assigned(FPlugin_XMLTags) then FPlugin_XMLTags.Free;
end;

// tPlugin_XMLTagsBase
function tPlugin_XMLTagsBase.GetTag(aTagName: String; aTokens: tTokenProcessor;
  aProjectItem: TObject): String;
Var
  liIndex: Integer;
begin
  Result := '';

  liIndex := IsTagExists(aTagName);
  if liIndex = -1 then
  begin
    oOutput.LogError('Cannot find XML.' + aTagName);

    Exit;
  end;

  Result := FXMLTags[liIndex].Execute((aProjectItem as tProjectItem),
    aTagName, aTokens);
end;

function tPlugin_XMLTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then
    Exit;

  for I := 0 to Length(FXMLTags) - 1 do
  begin
    if Uppercase(Trim(aTagName)) = Uppercase(Trim(FXMLTags[I].TagName)) then
    begin
      Result := I;

      Break;
    end;
  end;
end;


//TXMLTag_XMLlist
function TXMLTag_XMLlist.GetTagName: String;
begin
  Result := 'XMLLIST';
end;

function TXMLTag_XMLlist.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionParser: TFunctionAParser;
begin
  (*
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := TFunctionAParser.Create(aProjectItem, aTokens,
        oOutput, aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
  *)
end;

procedure TXMLTag_XMLlist.OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValue: TJSONValue;
begin
  aToken := '';
  (*
  Try
    FJSONValue := TJSONObject.ParseJSONValue
      (TEncoding.ASCII.GetBytes(TFile.ReadAllText(aJSONFilename)), 0);
  Except
    oOutput.LogError('JSONFilename cannot read [' + aJSONFilename + ']');
  End;

  aToken := Self.oVariables.AddVariableObject(FJSONValue, TJSONTag.ClassName);
  *)
end;


//TXMLTag_XMLListCount
function TXMLTag_XMLListCount.GetTagName: String;
begin
  Result := 'XMLListCount';
end;

function TXMLTag_XMLListCount.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionParser: TFunctionAParser;
begin

  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := TFunctionAParser.Create(aProjectItem, aTokens,
        oOutput, aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;

end;

procedure TXMLTag_XMLListCount.OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetXMLListObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  if Assigned(FVariable.oObject) then
    begin
      aToken := IntToStr(TXMLList(FVariable.oObject).GetCount);
    end
  else
    aToken := '';



  (*
  Try
    FJSONValue := TJSONObject.ParseJSONValue
      (TEncoding.ASCII.GetBytes(TFile.ReadAllText(aJSONFilename)), 0);
  Except
    oOutput.LogError('JSONFilename cannot read [' + aJSONFilename + ']');
  End;

  aToken := Self.oVariables.AddVariableObject(FJSONValue, TJSONTag.ClassName);
  *)
end;

//TXMLTag_LoadXMLList
function TXMLTag_LoadXMLList.GetTagName: String;
begin
  Result := 'LoadXMLList';
end;

function TXMLTag_LoadXMLList.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionParser: TFileExistsFunctionParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := TFileExistsFunctionParser.Create(aProjectItem, aTokens,
        oOutput, aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TXMLTag_LoadXMLList.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aFilename: String);
Var
  foXMLlist : tXMLlist;
begin
  aToken := '';
  Try
    foXMLlist := tXMLlist.Create;
    foXMLlist.XMLFileName := aFilename;
    foXMLlist.Retrieve;
  Except
    oOutput.LogError('XMLList Filename cannot read [' + aFilename + ']');

    FreeandNil(foXMLlist);
  End;

  aToken := Self.oVariables.AddVariableObject(foXMLlist, tXMLlist.ClassName, true);
end;




function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_XMLTags = nil) then
    _Plugin_XMLTags := TPlugin_XMLTags.Create;
  Result := _Plugin_XMLTags;
end;

exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_XMLTags := nil;
end;

finalization

FreeAndNIL(_Plugin_XMLTags);

end.
