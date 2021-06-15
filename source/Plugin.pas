unit Plugin;

interface

uses classes, Output, NovusPlugin, Project, config, NovusTemplate, uPSRuntime,
  uPSCompiler, NovusList, SysUtils, JvSimpleXml, CodeGeneratorItem, NovusCommandLine,
  NovusShell, System.IoUtils, Loader, Template, DataProcessor, DB, TokenProcessor;

type
  TPluginReturn = (PRFailed, PRPassed, PRIgnore);

  TPlugin = class(TPersistent)
  private
  protected
    foConfigPlugin: TConfigPlugin;
    foProject: tProject;
    foOutput: tOutput;
    fsPluginName: String;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: tProject; aConfigPlugin: TConfigPlugin); virtual;

    destructor Destroy; override;

    function BeforeCodeGen: boolean; virtual;
    function AfterCodeGen: boolean; virtual;
    function IsCommandLine(aResultCommand: INovusCommandLineResultCommand): boolean; virtual;

    property oProject: tProject read foProject write foProject;

    property oOutput: tOutput read foOutput write foOutput;

    property oConfigPlugin: TConfigPlugin read foConfigPlugin
      write foConfigPlugin;

    property PluginName: String read fsPluginName write fsPluginName;
  end;

  TPascalScriptPlugin = class(TPlugin)
  private
  protected
    fImp: TPSRuntimeClassImporter;
  public
    procedure Initialize(var aImp: TPSRuntimeClassImporter); virtual;

    function CustomOnUses(var aCompiler: TPSPascalCompiler): boolean; virtual;
    procedure RegisterFunction(var aExec: TPSExec); virtual;
    procedure SetVariantToClass(var aExec: TPSExec); virtual;
    procedure RegisterImport; virtual;

    property _Imp: TPSRuntimeClassImporter read fImp write fImp;
  end;

  TTagsPlugin = class(TPlugin)
  private
  protected
  public
    function GetTag(aTagName: String; aTokens: tTokenProcessor; aProjectItem: tObject): String; virtual;
    function IsTagExists(aTagName: String): Integer; virtual;
  end;

  TDataProcessorPlugin = class(TPlugin)
  private
  protected
    foDBSchema: TDBSchema;
    function GetDBSchemaFile: string;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: tProject; aConfigPlugin: TConfigPlugin); override;

    destructor Destroy; override;

    function CreateConnection: TConnection; virtual;
    procedure ApplyConnection(aConnectionItem: TConnectionItem; aConnection: tConnection); virtual;
    function GetTableNames(aConnection: tConnection; aTableNames: tStringList): tStringList; virtual;
    function FieldCount(aConnection: tConnection;aTableName: String): Integer; virtual;
    function FieldByIndex(aConnection: tConnection; aTableName: String; AIndex: Integer): TFieldDesc; virtual;
    function GetFieldDesc(aDataSet: tDataSet; aAuxDriver: string): tFieldDesc; virtual;
    function FieldByName(aConnection: tConnection;aTableName: String; aFieldName: String): TFieldDesc; virtual;

    function LoadDBSchemaFile: Boolean;

    property oDBSchema: TDBSchema read foDBSchema write foDBSchema;

    property DBSchemaFile: String read GetDBSchemaFile;


  end;

  TTagPlugin = class(TPlugin)
  private
  protected
    function GetTagName: string; virtual;
  public
    property TagName: String read GetTagName;
  end;

  TProcessorItem = class
  private
    foProject: tProject;
    fsDefaultOutputFilename: String;
    foConfigPlugin: tConfigPlugin;
    foOutput: TOutput;
  protected
    function GetProcessorName: String; virtual;
    function Getsourceextension: string; virtual;
    function Getoutputextension: string; virtual;
    function GetConvertFilename: String; virtual;
    function GetConvertFilenameParameters: String;
    function GetProjectItem(aLoader: tLoader; aNodeName: String): String;
  public
    constructor Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput; aProject: tProject); virtual;
    destructor Destroy; virtual;

    function PreProcessor(aProjectItem: tObject; var aFilename: String; var aTemplate: tTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject)
      : TPluginReturn; virtual;
    function PostProcessor(aProjectItem: tObject; var aTemplate: tTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn; virtual;
    function Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string): TPluginReturn; virtual;
    function ParseConvertParameters(aParameters, aInputFilename, aOutputFilename: string): string;
    function RunCommandCapture(const aCommandLine: string; var aOutput: String): Integer;
    function Delete(const aFilename: String): Boolean;

    property oConfigPlugin: tConfigPlugin
      read foConfigPlugin;
    property ProcessorName: String read GetProcessorName;
    property Sourceextension: string read Getsourceextension;
    property outputextension: string read Getoutputextension;
    property ConvertFilename: string read GetConvertFilename;
    property ConvertFilenameParameters: String read GetConvertFilenameParameters;


    property oOutput: TOutput
      read foOutput;

    property DefaultOutputFilename: String
      read fsDefaultOutputFilename
      write fsDefaultOutputFilename;
  end;

  TProcessorPlugin = class(TPlugin)
  private
  protected
    fbSingleItem: boolean;
    fProcessorItems: tNovusList;
    function GetSingleItem: boolean; virtual;
    procedure AddProcessorItem(aProcessorItem: TProcessorItem);
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: tProject; aConfigPlugin: TConfigPlugin); override;
    destructor Destroy;

    function GetProcessorName(aProcessorName: String): TProcessorItem;

    function GetProcesorItem(aFileExt: string): TProcessorItem; overload;
    function GetProcesorItem: TProcessorItem; overload;

    property SingleItem: boolean
      read fbSingleItem
      write fbSingleItem default false;

  end;

  IExternalPlugin = interface(INovusPlugin)
    ['{155A396A-9457-4C48-A787-0C9582361B45}']

    function CreatePlugin(aOutput: tOutput; aProject: tProject;
      aConfigPlugin: TConfigPlugin): TPlugin safecall;
  end;

  TPluginClass = class of TPlugin;

implementation

uses ProjectParser, CodeGenerator;

constructor TPlugin.Create;
begin
  foConfigPlugin := aConfigPlugin;
  foProject := aProject;
  foOutput := aOutput;
  fsPluginName := aPluginName;
end;

destructor TPlugin.Destroy;
begin
  inherited Destroy;

end;

function TPlugin.BeforeCodeGen: boolean;
begin
  Result := True;
end;

function TPlugin.AfterCodeGen: boolean;
begin
  Result := True;
end;

function TPlugin.IsCommandLine(aResultCommand: INovusCommandLineResultCommand): boolean;
begin
  Result := True;
end;

function TPascalScriptPlugin.CustomOnUses(var aCompiler
  : TPSPascalCompiler): boolean;
begin
  Result := False;
end;

procedure TPascalScriptPlugin.Initialize(var aImp: TPSRuntimeClassImporter);
begin
  fImp := aImp;
end;

procedure TPascalScriptPlugin.RegisterFunction(var aExec: TPSExec);
begin

end;

procedure TPascalScriptPlugin.SetVariantToClass(var aExec: TPSExec);
begin

end;

procedure TPascalScriptPlugin.RegisterImport;
begin

end;

function TTagPlugin.GetTagName: String;
begin
  Result := '';
end;

function TTagsPlugin.GetTag(aTagName: String; aTokens: tTokenProcessor; aProjectItem: tObject): String;
begin
  Result := '';
end;

function TTagsPlugin.IsTagExists(aTagName: String): Integer;
begin
  Result := -1;
end;

constructor TProcessorPlugin.Create(aOutput: tOutput; aPluginName: String;
  aProject: tProject; aConfigPlugin: TConfigPlugin);
begin
  inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

  fProcessorItems := tNovusList.Create(TProcessorItem);
end;

destructor TProcessorPlugin.Destroy;
begin
  fProcessorItems.Free;
end;


function TProcessorPlugin.GetProcessorName(aProcessorName: String): TProcessorItem;
Var
  I: Integer;
  loProcessorItem: TProcessorItem;
begin
  Result := NIL;

  for I  := 0 to fProcessorItems.Count - 1  do
    begin
      loProcessorItem:= TProcessorItem(fProcessorItems.Items[i]);

      if ((uppercase(loProcessorItem.ProcessorName) = Uppercase(aProcessorName))) then
        begin
          Result := loProcessorItem;
          Break;
        end;
    end;
end;


function TProcessorPlugin.GetProcesorItem(aFileExt: string): TProcessorItem;
Var
  I: Integer;
  loProcessorItem: TProcessorItem;
begin
  Result := NIL;

  for I  := 0 to fProcessorItems.Count - 1  do
    begin
      loProcessorItem:= TProcessorItem(fProcessorItems.Items[i]);

      if ((uppercase(loProcessorItem.Sourceextension) = Uppercase(aFileExt))) then
        begin
          Result := loProcessorItem;
          Break;
        end;
    end;
end;

function TProcessorPlugin.GetSingleItem: boolean;
begin
  result := false;
end;

function TProcessorPlugin.GetProcesorItem: TProcessorItem;
begin
  Result := NIL;
  if (fProcessorItems.Count > 0) then
    Result := TProcessorItem(fProcessorItems.Items[0]);
end;

procedure TProcessorPlugin.AddProcessorItem(aProcessorItem: TProcessorItem);
begin
  fProcessorItems.Add(aProcessorItem)
end;

constructor TProcessorItem.Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput; aProject: tProject);
begin
  foConfigPlugin := aConfigPlugin;
  foOutput := aOutput;
  foProject := aProject;
end;

destructor TProcessorItem.Destroy;
begin
  //
end;

function TProcessorItem.Getsourceextension: string;
var
  loProperties: TJvSimpleXmlElem;
begin
  Result := '';

  loProperties := oConfigPlugin.oConfigProperties.IsPropertyExistsEx(GetProcessorName);
  if Assigned(loProperties) then
    begin
      if oConfigPlugin.oConfigProperties.IsPropertyExists('sourceextension', loProperties) then
        Result := oConfigPlugin.oConfigProperties.GetProperty('sourceextension', loProperties);
    end;
end;


function TProcessorItem.Getoutputextension: string;
var
  loProperties: TJvSimpleXmlElem;
begin
  Result := '';

  loProperties := oConfigPlugin.oConfigProperties.IsPropertyExistsEx(GetProcessorName);
  if Assigned(loProperties) then
    begin
      if oConfigPlugin.oConfigProperties.IsPropertyExists('outputextension', loProperties) then
        Result := oConfigPlugin.oConfigProperties.GetProperty('outputextension', loProperties);
    end;
end;


function TProcessorItem.GetConvertFilename: String;
var
  loProperties, loconvert: TJvSimpleXmlElem;
begin
  loProperties := oConfigPlugin.oConfigProperties.IsPropertyExistsEx(GetProcessorName);
  if Assigned(loProperties) then
    begin
     loconvert :=  oConfigPlugin.oConfigProperties.IsPropertyExistsEx('convert', loProperties);
     if assigned(loconvert) then
       if oConfigPlugin.oConfigProperties.IsPropertyExists('filename', loconvert) then
          Result := oConfigPlugin.oConfigProperties.GetProperty('filename', loconvert);
    end;
end;


function TProcessorItem.GetConvertFilenameParameters: string;
var
  loProperties, loconvert: TJvSimpleXmlElem;
begin
  loProperties := oConfigPlugin.oConfigProperties.IsPropertyExistsEx(GetProcessorName);
  if Assigned(loProperties) then
    begin
     loconvert :=  oConfigPlugin.oConfigProperties.IsPropertyExistsEx('convert', loProperties);
     if assigned(loconvert) then
       if oConfigPlugin.oConfigProperties.IsPropertyExists('parameters', loconvert) then
          Result := oConfigPlugin.oConfigProperties.GetProperty('parameters', loconvert);
    end;
end;

function TProcessorItem.GetProcessorName: string;
begin
  Result := '';
end;

function TProcessorItem.GetProjectItem(aLoader: tLoader; aNodeName: String): String;
Var
  fotmpNodeLoader: tNodeLoader;
begin
  result := '';

  fotmpNodeLoader := aLoader.GetNode(aLoader.RootNodeLoader,aNodeName, 0);

  if fotmpNodeLoader.IsExists then
    begin
       Result := tProjectParser.ParseProject(fotmpNodeLoader.Node.Value, foProject, foOutput);
     end;
end;

function TProcessorItem.PreProcessor(aProjectItem: tObject; var aFilename: String; var aTemplate: tTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn;
begin
  Result := PRIgnore;
end;

function TProcessorItem.PostProcessor(aProjectItem: tObject; var aTemplate: tTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

function TProcessorItem.Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;



function TProcessorItem.ParseConvertParameters(aParameters, aInputFilename, aOutputFilename: string): string;
Var
  loTemplate: tNovusTemplate;
  I: Integer;
  FTemplateTag: TTemplateTag;
begin
  result := aParameters;

  if aParameters = '' then
    Exit;

  Try
    loTemplate := tNovusTemplate.Create;

    loTemplate.StartToken := '[';
    loTemplate.EndToken := ']';
    loTemplate.SecondToken :='%';

    loTemplate.TemplateDoc.Text := Trim(aParameters);

    loTemplate.ParseTemplate;

    For I := 0 to loTemplate.TemplateTags.Count - 1 do
    begin
      FTemplateTag := TTemplateTag(loTemplate.TemplateTags.items[I]);

      if CompareText(FTemplateTag.TagName, 'InputFilename' ) = 0 then
        FTemplateTag.TagValue := aInputFilename
      else
      if CompareText(FTemplateTag.TagName, 'OutputFilename' ) = 0 then
        FTemplateTag.TagValue := aOutputFilename
    end;

    loTemplate.InsertAllTagValues;

    result := Trim(loTemplate.OutputDoc.Text);

  Finally
    loTemplate.Free;
  End;
end;

function TProcessorItem.RunCommandCapture(const aCommandLine: string;
  var aOutput: String): Integer;
Var
  loShell: TNovusShell;
begin
  Try
    Try
      loShell := TNovusShell.Create;

      Result := loShell.RunCommandCapture(aCommandLine, aOutput);

    Except
      foOutput.InternalError;
    End;
  Finally
    loShell.Free;
  End;
end;

function TProcessorItem.Delete(const aFilename: String): Boolean;
begin
  Try
    Try
      TFile.Delete(aFilename);

      Result := True;
    Except
      Result := False;

      oOutput.InternalError;
    End;
  Finally

  End;
end;


// TDataProcessorPlugin
constructor TDataProcessorPlugin.Create;
begin
  inherited create(aOutput,aPluginName,aProject,aConfigPlugin);

  foDBSchema:= TDBSchema.Create;
end;

destructor TDataProcessorPlugin.Destroy;
begin
  inherited Destroy;


  foDBSchema.Free;
end;



function TDataProcessorPlugin.CreateConnection: TConnection;
begin
  Result := NIL;
end;

procedure TDataProcessorPlugin.ApplyConnection(aConnectionItem: TConnectionItem; aConnection: tConnection);
begin
  //
end;


function TDataProcessorPlugin.GetTableNames(aConnection: tConnection; aTableNames: tStringList): tStringList;
begin
  Result := NIL;
end;

function TDataProcessorPlugin.FieldCount(aConnection: tConnection;aTableName: String): Integer;
begin
  Result := -1;
end;


function TDataProcessorPlugin.FieldByIndex(aConnection: tConnection; aTableName: String; AIndex: Integer): TFieldDesc;
begin
  result := NIL;
end;

function TDataProcessorPlugin.GetFieldDesc(aDataSet: tDataSet; aAuxDriver: string): tFieldDesc;
begin
  Result := NIL;
end;

function  TDataProcessorPlugin.FieldByName(aConnection: tConnection;aTableName: String; aFieldName: String): TFieldDesc;
begin
  Result := NIL;
end;

function TDataProcessorPlugin.LoadDBSchemaFile: Boolean;
begin
  Result := True;
  if Trim(DBSchemaFile) = '' then  Exit;
  
  result := false;
  foDBSchema.XMLFileName := oConfig.rootpath + 'plugins\' + DBSchemaFile;
  result := foDBSchema.Retrieve;
end;

function TDataProcessorPlugin.GetDBSchemaFile: string;
begin
  if foConfigPlugin.oConfigProperties.IsPropertyExists('DBSchemaFile') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('DBSchemaFile');
end;


end.
