unit CodeDocsProcessorItem;

interface

Uses Winapi.Windows, System.SysUtils, System.Classes, NovusFileUtils,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, JvSimpleXml, XMLDocumentationClasses,
  Loader;

type
  tCodeDocsProcessorItem = class(TProcessorItem)
  private
    foLoader: tLoader;
    foXMLDocumentation: TXMLDocumentation;
    fssourcefile: string;
  protected
    function GetProcessorName: String; override;
    function Getoutputextension: string; override;
    function GetSourcefile: String;
  public
    constructor Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput; aProject: TProject);
      override;
    destructor Destroy; Override;

    function PreProcessor(aProjectItem: tObject; var aFilename: String;
      aTemplate: tNovusTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;
      aTemplateFile: String; var aOutputFilename: string)
      : TPluginReturn; override;

    function Convert(aProjectItem: tObject; aInputFilename: string;
      var aOutputFilename: string): TPluginReturn; override;
  end;

implementation

constructor tCodeDocsProcessorItem.Create(aConfigPlugin: tConfigPlugin;
  aOutput: TOutput; aProject: TProject);
begin
  inherited;

  foLoader := tLoader.Create;

  foXMLDocumentation := TXMLDocumentation.Create(aOutput);

end;

destructor tCodeDocsProcessorItem.Destroy;
begin
  foXMLDocumentation.Free;

  foLoader.Free;
end;

function tCodeDocsProcessorItem.GetProcessorName: String;
begin
  Result := 'CodeDocsProcessor';
end;

function tCodeDocsProcessorItem.Getoutputextension: string;
begin
  result := GetProjectItem(Foloader,'outputextension');

  if Result = '' then
    begin
      if oConfigPlugin.oConfigProperties.IsPropertyExists('outputextension') then
        Result := oConfigPlugin.oConfigProperties.GetProperty('outputextension');
    end;
end;

function tCodeDocsProcessorItem.GetSourcefile: String;
begin
  result := GetProjectItem(Foloader,'sourcefile');
end;

function tCodeDocsProcessorItem.PreProcessor(aProjectItem: tObject;
  var aFilename: String; aTemplate: tNovusTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn;

begin
  Result := PRIgnore;

  if aNodeLoader.IsExists then  Foloader.Init(aNodeLoader);

  if Getoutputextension = '' then
    begin
      oOutput.LogError('outputextension cannot be blank.');

      Result := PRFailed;

      exit;

    end;

  if Not FileExists(getsourcefile) then
    begin
      oOutput.LogError('sourcefile [' +getsourcefile + '] cannot be found.');

      Result := PRFailed;

      exit;
    end;

  if not foXMLDocumentation.Parser(aTemplate) then
    Result := PRFailed
  else
    Result := PRPassed;

  if Result = PRPassed then
    begin





    end;

end;

function tCodeDocsProcessorItem.PostProcessor(aProjectItem: tObject;
  aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string)
  : TPluginReturn;
Var
  loProjectItem: tProjectItem;
begin
  loProjectItem := (aProjectItem as tProjectItem);

  aOutputFilename := ChangeFileExt(aOutputFilename, '.' + outputextension);

  Result := TPluginReturn.PRPassed;
end;

function tCodeDocsProcessorItem.Convert(aProjectItem: tObject;
  aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
