unit Plugin;

interface

uses classes, Output, NovusPlugin, Project, config, NovusTemplate, uPSRuntime,
  uPSCompiler, NovusList, SysUtils, JvSimpleXml, CodeGeneratorItem,
  NovusShell, System.IoUtils;

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

    function BeforeCodeGen: boolean; virtual;
    function AfterCodeGen: boolean; virtual;
    function IsCommandLine: boolean; virtual;

    property oProject: tProject read foProject write foProject;

    property oOutput: tOutput read foOutput write foOutput;

    property oConfigPlugin: TConfigPlugin read foConfigPlugin
      write foConfigPlugin;

    property PluginName: String read fsPluginName write fsPluginName;
  end;

  TScriptEnginePlugin = class(TPlugin)
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
    function GetTag(aTagName: String; aCodeGeneratorItem: tCodeGeneratorItem; aTokenIndex: Integer): String; virtual;
    function IsTagExists(aTagName: String): Integer; virtual;
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
    fsDefaultOutputFilename: String;
    foConfigPlugin: tConfigPlugin;
    foOutput: TOutput;
  protected
    function GetProcessorName: String; virtual;
    function Getsourceextension: string;
    function Getoutputextension: string;
    function GetConvertFilename: String;
    function GetConvertFilenameParameters: String;
  public
    constructor Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput);

    function PreProcessor(aFilename: String; aTemplate: tNovusTemplate)
      : TPluginReturn; virtual;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn; virtual;
    function Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string): TPluginReturn; virtual;
    function ParseConvertParameters(aParameters, aInputFilename, aOutputFilename: string): string;
    function RunCaptureCommand(const aCommandLine: string; var aOutput: String): Integer;
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
    fProcessorItems: tNovusList;
    procedure AddProcessorItem(aProcessorItem: TProcessorItem);
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: tProject; aConfigPlugin: TConfigPlugin); override;
    destructor Destroy;

    function GetProcesorItem(aFileExt: string): TProcessorItem;
  end;

  IExternalPlugin = interface(INovusPlugin)
    ['{155A396A-9457-4C48-A787-0C9582361B45}']

    function CreatePlugin(aOutput: tOutput; aProject: tProject;
      aConfigPlugin: TConfigPlugin): TPlugin safecall;
  end;

  TPluginClass = class of TPlugin;

implementation

constructor TPlugin.Create;
begin
  foConfigPlugin := aConfigPlugin;
  foProject := aProject;
  foOutput := aOutput;
  fsPluginName := aPluginName;
end;

function TPlugin.BeforeCodeGen: boolean;
begin
  Result := True;
end;

function TPlugin.AfterCodeGen: boolean;
begin
  Result := True;
end;

function TPlugin.IsCommandLine: boolean;
begin
  Result := True;
end;

function TScriptEnginePlugin.CustomOnUses(var aCompiler
  : TPSPascalCompiler): boolean;
begin
  Result := False;
end;

procedure TScriptEnginePlugin.Initialize(var aImp: TPSRuntimeClassImporter);
begin
  fImp := aImp;
end;

procedure TScriptEnginePlugin.RegisterFunction(var aExec: TPSExec);
begin

end;

procedure TScriptEnginePlugin.SetVariantToClass(var aExec: TPSExec);
begin

end;

procedure TScriptEnginePlugin.RegisterImport;
begin

end;

function TTagPlugin.GetTagName: String;
begin
  Result := '';
end;

function TTagsPlugin.GetTag(aTagName: String; aCodeGeneratorItem: TCodeGeneratorItem; aTokenIndex: Integer): String;
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

procedure TProcessorPlugin.AddProcessorItem(aProcessorItem: TProcessorItem);
begin
  fProcessorItems.Add(aProcessorItem)
end;

constructor TProcessorItem.Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput);
begin
  foConfigPlugin := aConfigPlugin;
  foOutput := aOutput;
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

function TProcessorItem.PreProcessor(aFilename: String; aTemplate: tNovusTemplate): TPluginReturn;
begin
  Result := PRIgnore;
end;

function TProcessorItem.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn;
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

function TProcessorItem.RunCaptureCommand(const aCommandLine: string;
  var aOutput: String): Integer;
Var
  loShell: TNovusShell;
begin
  Try
    Try
      loShell := TNovusShell.Create;

      Result := loShell.RunCaptureCommand(aCommandLine, aOutput);

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



end.
