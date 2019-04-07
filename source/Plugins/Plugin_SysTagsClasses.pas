unit Plugin_SysTagsClasses;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project,
  Output, SysUtils, System.Generics.Defaults, runtime, Config,
  APIBase, NovusGUIDEx, CodeGeneratorItem, FunctionsParser, ProjectItem,
  Variables, NovusFileUtils, CodeGenerator, NovusStringUtils, TokenProcessor,
  TagBasePlugin;

type
  TSysTag = class(TTagBasePlugin)
  private
  protected
  public
  end;

  TSysTag_Uplower = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_IsVarEmpty = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_Version = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_Lower = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_Upper = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_FilePathToURL = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_Pred = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_Inc = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_Dec = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_newguid = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_BlankLine = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  TSysTag_NewguidNoBrackets = class(TSysTag)
  private
  protected
    function GetTagName: String; override;
  public
    function Execute(aProjectItem: tProjectItem;aTagName: String; aTokens: tTokenProcessor): String; override;
  end;

  tSysTags = array of TSysTag;

  tPlugin_SysTagsBase = class(TTagsPlugin)
  private
  protected
    FSysTags: tSysTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aTokens: tTokenProcessor; aProjectItem: tObject): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_SysTags = class(TSingletonImplementation, INovusPlugin,
    IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_SysTags: tPlugin_SysTagsBase;
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
  _Plugin_SysTags: TPlugin_SysTags = nil;

constructor tPlugin_SysTagsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

  FSysTags := tSysTags.Create(TSysTag_Version.Create(aOutput),
    TSysTag_newguid.Create(aOutput), TSysTag_NewguidNoBrackets.Create(aOutput),
    TSysTag_FilePathToURL.Create(aOutput), TSysTag_Lower.Create(aOutput),
    TSysTag_Upper.Create(aOutput), TSysTag_Uplower.Create(aOutput),
    TSysTag_Pred.Create(aOutput),
    TSysTag_IsVarEmpty.Create(aOutput),
    TSysTag_Inc.Create(aOutput),
    TSysTag_Dec.Create(aOutput));
end;

destructor tPlugin_SysTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FSysTags) - 1 do
  begin
    FSysTags[I].Free;
    FSysTags[I] := NIL;
  end;

  FSysTags := NIL;
  Inherited;
end;

// Plugin_SysTags
function TPlugin_SysTags.GetPluginName: string;
begin
  Result := 'Sys';
end;

procedure TPlugin_SysTags.Initialize;
begin
end;

function TPlugin_SysTags.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugin: tConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SysTags := tPlugin_SysTagsBase.Create(aOutput, GetPluginName,
    foProject, aConfigPlugin);

  Result := FPlugin_SysTags;
end;

procedure TPlugin_SysTags.Finalize;
begin
  // if Assigned(FPlugin_SysTags) then FPlugin_SysTags.Free;
end;

// tPlugin_SysTagsBase
function tPlugin_SysTagsBase.GetTag(aTagName: String;
  aTokens: tTokenProcessor;  aProjectItem: TObject): String;
Var
  liIndex: Integer;
begin
  Result := '';
  liIndex := IsTagExists(aTagName);

  if liIndex = -1 then
  begin
    oOutput.LogError('Cannot find sys.' + aTagName);

    Exit;
  end;

  Result := FSysTags[liIndex].Execute((aProjectItem as tProjectItem), aTagName, aTokens);
end;

function tPlugin_SysTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then
    Exit;

  for I := 0 to Length(FSysTags) - 1 do
  begin
    if Uppercase(Trim(aTagName)) = Uppercase(Trim(FSysTags[I].TagName)) then
    begin
      Result := I;

      Break;
    end;
  end;
end;

function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_SysTags = nil) then
    _Plugin_SysTags := TPlugin_SysTags.Create;
  Result := _Plugin_SysTags;
end;

function TSysTag_Upper.GetTagName: String;
begin
  Result := 'UPPER';
end;

function TSysTag_Upper.Execute(aProjectItem: tProjectItem;aTagName: String;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  Try
    Try
      LFunctionParser := tFunctionParser.Create(aProjectItem, aTokens, oOutput);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_Upper.OnExecute(var aToken: String);
begin
  aToken := Uppercase(aToken);
end;

//TSysTag_Uplower
function TSysTag_Uplower.GetTagName: String;
begin
  Result := 'UPLOWER';
end;

function TSysTag_Uplower.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionParser.Create(aProjectItem, aTokens, oOutput,
        aTagName);


      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_Uplower.OnExecute(var aToken: String);
begin
  aToken := TNovusStringUtils.UpLowerA(aToken, true);
end;


//TSysTag_IsVarEmpty
function TSysTag_IsVarEmpty.GetTagName: String;
begin
  Result := 'IsVarEmpty';
end;

function TSysTag_IsVarEmpty.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionParser.Create(aProjectItem, aTokens, oOutput,
        aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_IsVarEmpty.OnExecute(var aToken: String);
var
  FVariable: tVariable;
  FLinkedVariable: tVariable;
begin
  FVariable := oVariables.GetVariableByName(aToken);
  if not Assigned(FVariable) then
    begin
      oOutput.LogError('Syntax Error: "' + aToken + '" not variable not found.');

      aToken := 'false';

      Exit;
    end;

  if FVariable.Islinked then
    begin
      FLinkedVariable := oVariables.GetVariableByName(FVariable.Value);
      aToken := 'false';

      if not Assigned(FLinkedVariable) then
        begin
          oOutput.LogError('Syntax Error: "' + FLinkedVariable.Value + '" linked variable not found.');

          Exit;
        end;

      if FLinkedVariable.IsVarEmpty then
         aToken := 'true';

      Exit;
   end;

  aToken := 'false';
  if FVariable.IsVarEmpty then
    begin
      aToken := 'true';
    end;

end;

function TSysTag_Version.GetTagName: String;
begin
  Result := 'VERSION';
end;

function TSysTag_Version.Execute(aProjectItem: tProjectItem; aTagName: string;aTokens: tTokenProcessor): String;
begin
  Self.oVariables := tProjectItem(aProjectItem).oVariables;

  Result := oRuntime.GetVersion(1);
end;

function TSysTag_Lower.GetTagName: String;
begin
  Result := 'LOWER';
end;

function TSysTag_Lower.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionParser.Create(aProjectItem, aTokens, oOutput,
        aTagName);

    //  LFunctionParser.TokenIndex := aTokenIndex;

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_Lower.OnExecute(var aToken: String);
begin
  aToken := Lowercase(aToken);
end;

function TSysTag_FilePathToURL.GetTagName: String;
begin
  Result := 'FILEPATHTOURL';
end;

function TSysTag_FilePathToURL.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  Try
    Try
      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser := tFunctionParser.Create(aProjectItem,aTokens, oOutput,
        aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_FilePathToURL.OnExecute(var aToken: String);
begin
  aToken := TNovusFileUtils.FilePathToURL(aToken);
end;

function TSysTag_newguid.GetTagName: String;
begin
  Result := 'NEWGUID';
end;

function TSysTag_newguid.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
begin
  Self.oVariables := tProjectItem(aProjectItem).oVariables;
  Result := TGuidExUtils.NewGuidString;
end;

function TSysTag_BlankLine.GetTagName: String;
begin
  Result := 'BLANKLINE';
end;

function TSysTag_BlankLine.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
begin
  Result := cBlankLine;
end;

function TSysTag_NewguidNoBrackets.GetTagName: String;
begin
  Result := 'NEWGUIDNOBRACKETS';
end;

function TSysTag_NewguidNoBrackets.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
begin
  Result := TGuidExUtils.NewGuidNoBracketsString;;
end;



function TSysTag_Pred.GetTagName: String;
begin
  Result := 'PRED';
end;

function TSysTag_Pred.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionParser;
begin
  Try
    Try
      LFunctionParser := tFunctionParser.Create(aProjectItem,aTokens, oOutput,
        aTagName);

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_Pred.OnExecute(var aToken: String);
begin
  aToken := IntToStr(Pred(StrToint(aToken)));
end;


function TSysTag_Inc.GetTagName: String;
begin
  Result := 'Inc';
end;

function TSysTag_Inc.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionBParser;
begin
  Try
    Try
      LFunctionParser := tFunctionBParser.Create(aProjectItem,aTokens, oOutput,
        aTagName);

      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_Inc.OnExecute(var aToken: String);
var
  FVariable: tVariable;
  FLinkedVariable: tVariable;
  LiNewValiue: Integer;
begin
  FVariable := oVariables.GetVariableByName(aToken);
  if not Assigned(FVariable) then
    begin
      oOutput.LogError('Syntax Error: "' + aToken + '" not variable not found.');

      aToken := 'false';

      Exit;
    end;

  if Not FVariable.IsNumeric then
    begin
      oOutput.LogError('Syntax Error: "' + aToken + '" is not numeric.');

      aToken := 'false';

      Exit;
    end;

  FVariable.Value := FVariable.Value + 1;
  aToken := cDeleteLine;
end;

function TSysTag_Dec.GetTagName: String;
begin
  Result := 'Dec';
end;

function TSysTag_Dec.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: tTokenProcessor): String;
var
  LFunctionParser: tFunctionBParser;
begin
  Try
    Try
      LFunctionParser := tFunctionBParser.Create(aProjectItem,aTokens, oOutput,
        aTagName);

      Self.oVariables := tProjectItem(aProjectItem).oVariables;

      LFunctionParser.OnExecute := OnExecute;

      Result := LFunctionParser.Execute;
    Finally
      LFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

procedure TSysTag_Dec.OnExecute(var aToken: String);
var
  FVariable: tVariable;
  FLinkedVariable: tVariable;
  LiNewValiue: Integer;
begin
  FVariable := oVariables.GetVariableByName(aToken);
  if not Assigned(FVariable) then
    begin
      oOutput.LogError('Syntax error: "' + aToken + '" not variable not found.');

      aToken := 'false';

      Exit;
    end;

  if Not FVariable.IsNumeric then
    begin
      oOutput.LogError('Syntax error: "' + aToken + '" is not numeric.');

      aToken := 'false';

      Exit;
    end;

  FVariable.Value := FVariable.Value - 1;
  aToken := cDeleteLine;
end;


exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_SysTags := nil;
end;

finalization

FreeAndNIL(_Plugin_SysTags);

end.
