unit Plugin_JSONTagsClasses;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project,
  Output, SysUtils, System.Generics.Defaults, runtime, Config,
  APIBase, NovusGUID, CodeGeneratorItem, FunctionsParser, ProjectItem,
  Variables, NovusFileUtils, CodeGenerator, TokenParser,
  {NovusJSONUtils, } System.IOUtils, System.JSON, TokenProcessor, NovusStringUtils,
  TagBasePlugin, FileExistsFunctionParser;

type
  tJsonValueType = (jsArray, jsObject, jsPair, jsUnknown);

  TJSONTag = class(tTagBasePlugin)
  private
  protected
  public
    function GetJSONObjectVariable(aToken: string): TVariable;
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
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;


  TJSONTag_JSONString = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONPair = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;


  TJSONTag_JSONGetArray = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONArraySize = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_ToJSON = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_JSONQueryValue = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_IsJSONEmpty = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
  public
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; override;
  end;

  TJSONTag_ToJSONValue = class(TJSONTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor);
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
function GetJsonValueType(JSONValue: TJSONValue): tJsonValueType;

implementation

var
  _Plugin_JSONTags: TPlugin_JSONTags = nil;

function GetJsonValueType(JSONValue: TJSONValue): tJsonValueType;
begin
  Result := jsUnknown;

  if JSONValue.classname = 'TJSONPair' then
    result := jsPair
  else
  if JSONValue is TJSONArray then
   Result := jsArray
  else
  if JSONValue is TJSONObject then
    Result := jsObject;
end;

constructor tPlugin_JSONTagsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

  FJSONTags := tJSONTags.Create(TJSONTag_LoadJSON.Create(aOutput),
    TJSONTag_JSONQuery.Create(aOutput), TJSONTag_ToJSON.Create(aOutput),
    TJSONTag_IsJSONEmpty.Create(aOutput),
    TJSONTag_ToJSONValue.Create(aOutput),
    TJSONTag_JSONGetArray.Create(aOutput),
    TJSONTag_JSONArraySize.Create(aOutput),
    TJSONTag_JSONString.Create(aOutput),
    TJSONTag_JSONQueryValue.Create(aOutput),
    TJSONTag_JSONPair.Create(aOutput));
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

function TJSONTag.GetJSONObjectVariable(aToken: string): TVariable;
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
  else if FVariable.Value <> TJSONTag.ClassName then
  begin
    Self.oOutput.LogError('[' + aToken + '] not ' + TJSONTag.ClassName +
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

  aToken := Self.oVariables.AddVariableObject(TJSONTag.ClassName, FJSONValue,  true);
end;


// TJSONTag_JSONQuery
function TJSONTag_JSONQuery.GetTagName: String;
begin
  Result := 'JSONQUERY';
end;

function TJSONTag_JSONQuery.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_JSONQuery.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
  fJsonValueType: tJsonValueType;
begin

  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
     Exit;

  FJSONValue := NIL;

  if Not FVariable.IsVarEmpty then
    begin
      FJSONValueRoot := TJSONValue(FVariable.oObject);

      lsElement := aTokenParser.ParseNextToken;

      if Trim(lsElement) = '' then
      begin
        oOutput.LogError('Syntax Error: Element cannot be blank.');

        Exit;
      end;

      fJsonValueType := GetJsonValueType(FJSONValueRoot);

      case fJsonValueType of
        jsPair:
          begin
            Try
              FJSONValueRoot := TJSONPair(FVariable.oObject).JsonValue;
              FJSONValueRoot.TryGetValue<TJSONValue>(lsElement, FJSONValue);

            Except
              On EJSONException do
              begin
                FJSONValue := NIL;
              end;
            End;

          end;
        jsArray: begin
            oOutput.LogError('JSON Array Not Supported.');

        end;
        jsObject:
          begin
            Try
              FJSONValueRoot.TryGetValue<TJSONValue>(lsElement, FJSONValue);



            Except
              On EJSONException do
              begin
                FJSONValue := NIL;
              end;
            End;

          end;

      end;

    end;


  aToken := Self.oVariables.AddVariableObject(TJSONTag.ClassName, FJSONValue, false);
end;

// TJSONTag_ToJSON
function TJSONTag_ToJSON.GetTagName: String;
begin
  Result := 'TOJSON';
end;

function TJSONTag_ToJSON.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_ToJSON.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  if Assigned(FVariable.oObject) then
    begin

      aToken := TJSONValue(FVariable.oObject).ToJSON
    end
  else
    aToken := '';
end;



// TJSONTag_IsJSONEmpty
function TJSONTag_IsJSONEmpty.GetTagName: String;
begin
  Result := 'IsJSONEmpty';
end;

function TJSONTag_IsJSONEmpty.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_IsJSONEmpty.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  if Assigned(FVariable.oObject) then
   begin
     aToken := 'true';
     if Trim(TJSONValue(FVariable.oObject).ToJSON) = '' then  aToken := 'false';
   end
  else
    aToken := 'false';
end;


// TJSONTag_ToJSONValue
function TJSONTag_ToJSONValue.GetTagName: String;
begin
  Result := 'TOJSONValue';
end;

function TJSONTag_ToJSONValue.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_ToJSONValue.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  if Not Assigned(FVariable.oObject) then Exit;

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
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_JSONGetArray.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
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
    oOutput.LogError('Syntax Error: Element Index cannot be blank.');

    Exit;
  end;

  if not TNovusStringUtils.IsNumeric(lsElement) then
    begin
      oOutput.LogError('Syntax Error: Element Index is not a numeric.');

      Exit;
    end;

  liIndex := TNovusStringUtils.Str2Int(lsElement);
  if liIndex < 0 then
    begin
      oOutput.LogError('Syntax Error: Element Index less than zero.');

      Exit;
    end;

  if liIndex > (FJSONArray.Size - 1) then
    begin
      oOutput.LogError('Syntax Error: Element Index greater than JSON Array size.');

      Exit;
    end;

  FJSONValue := NIL;
  Try
    FJSONValue :=  TJSONArray(FJSONArray.Get(liIndex));

  Except
    oOutput.InternalError;
  End;


  aToken := Self.oVariables.AddVariableObject(TJSONTag.ClassName, FJSONValue, false);
end;

// TJSONTag_JSONString
function TJSONTag_JSONString.GetTagName: String;
begin
  Result := 'JSONString';
end;

function TJSONTag_JSONString.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_JSONString.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
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

  Try
    FJSONPair:= TJSONPair(FVariable.oObject);

    if Assigned(FJSONPair) then
      aToken := FJSONPair.JsonString.Value;
  Except
    aToken := '';
  End;
end;

// TJSONTag_JSONPair
function TJSONTag_JSONPair.GetTagName: String;
begin
  Result := 'JSONPair';
end;

function TJSONTag_JSONPair.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_JSONPair.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONArray: TJSONArray;
  FVariable: TVariable;
  lsElement: string;
  liIndex: Integer;
  FJSONValue: TJSONValue;
  FJSONPair: TJSONPair;
  FJOSNObject: tJSONObject;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  Try
    FJSONPair:= TJSONPair(FVariable.oObject);

    aToken := Self.oVariables.AddVariableObject(TJSONTag.ClassName, FJSONPair, false);
  Except
    aToken := '';
  End;
end;



// TJSONTag_JSONArraySize
function TJSONTag_JSONArraySize.GetTagName: String;
begin
  Result := 'JSONArraySize';
end;

function TJSONTag_JSONArraySize.Execute(aProjectItem: tProjectItem;
  aTagName: String; aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_JSONArraySize.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONArray: TJSONArray;
  FVariable: TVariable;
  lsElement: string;
  liIndex: Integer;
  FJSONValue: TJSONValue;
begin
  FVariable := GetJSONObjectVariable(aToken);

  if not Assigned(FVariable) then Exit;

  FJSONArray := TJSONArray(FVariable.oObject);

  aToken := IntToStr(FJSONArray.Size-1);
end;



// JSONQueryValue
function TJSONTag_JSONQueryValue.GetTagName: String;
begin
  Result := 'JSONQueryValue';
end;

function TJSONTag_JSONQueryValue.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionAParser;
begin
  Try
    Try
      Self.oVariables := aProjectItem.oVariables;

      LFunctionParser := tFunctionAParser.Create(aProjectItem, aTokens,
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

procedure TJSONTag_JSONQueryValue.OnExecute(var aToken: String;
  aTokenParser: tTokenParser; aTokens: tTokenProcessor);
Var
  FJSONValueRoot: TJSONValue;
  FJSONValue: TJSONValue;
  FVariable: TVariable;
  lsElement: string;
  fJsonValueType: tJsonValueType;
begin
  FVariable := GetJSONObjectVariable(aToken);
  if not Assigned(FVariable) then
    Exit;

  if Assigned(FVariable.oObject) then
    begin
      if not FVariable.IsVarEmpty then
        begin

          lsElement := aTokenParser.ParseNextToken;

          if (Trim(lsElement) = '') or (Trim(lsElement) = ')') then
          begin
            oOutput.LogError('Element cannot be blank or ")".');

            aToken := '';

            Exit;
          end;

        FJSONValueRoot := TJSONValue(FVariable.oObject);

        fJsonValueType := GetJsonValueType(FJSONValueRoot);

        case fJsonValueType of
          jsPair:
            begin
              Try
                FJSONValueRoot := TJSONPair(FVariable.oObject).JsonValue;
                FJSONValueRoot.TryGetValue<TJSONValue>(lsElement, FJSONValue);

              Except
                On EJSONException do
                begin
                  FJSONValue := NIL;
                end;
              End;

            end;
          jsArray: begin
              oOutput.LogError('Not Supported.');

          end;
          jsObject:
            begin
              Try
                FJSONValueRoot.TryGetValue<TJSONValue>(lsElement, FJSONValue);



              Except
                On EJSONException do
                begin
                  FJSONValue := NIL;
                end;
              End;

            end;

           end;

          aToken := '';
          if Assigned(FJSONValue) then
            aToken := FJSONValue.Value;
        end
          else
             aToken := '';
    end
  else
    aToken := '';

end;




exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_JSONTags := nil;
end;

finalization

FreeAndNIL(_Plugin_JSONTags);

end.
