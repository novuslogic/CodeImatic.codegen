unit CodeDocsProcessorItem;

interface

Uses Winapi.Windows, System.SysUtils, System.Classes,NovusFileUtils,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, JvSimpleXml, XMLDocumentationClasses;

type
  tCodeDocsProcessorItem = class(TProcessorItem)
  private
    foXMLDocumentation: TXMLDocumentation;
  protected
    function GetProcessorName: String; override;
    function Getoutputextension: string; override;
  public
    constructor Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput); override;
    destructor Destroy; Override;

    function PreProcessor(aProjectItem: tObject;aFilename: String; aTemplate: tNovusTemplate)
      : TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn; override;

    function Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string):TPluginReturn; override;
  end;

implementation


constructor tCodeDocsProcessorItem.Create(aConfigPlugin: tConfigPlugin; aOutput: TOutput);
begin
  inherited;

  foXMLDocumentation := tXMLDocumentation.Create(aOutput);

end;

destructor tCodeDocsProcessorItem.Destroy;
begin
  foXMLDocumentation.Free;
end;

function tCodeDocsProcessorItem.GetProcessorName: String;
begin
  Result := 'CodeDocsProcessor';
end;

function tCodeDocsProcessorItem.Getoutputextension: string;
begin





  if oConfigPlugin.oConfigProperties.IsPropertyExists('outputextension') then
    Result := oConfigPlugin.oConfigProperties.GetProperty('outputextension');



end;

function tCodeDocsProcessorItem.PreProcessor(aProjectItem: tObject;aFilename: String; aTemplate: tNovusTemplate): TPluginReturn;
begin
  Result := PRIgnore;

  if not   foXMLDocumentation.Parser(aTemplate) then
    Result := PRFailed
  else
    Result := PRPassed;


end;

function tCodeDocsProcessorItem.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn;
Var
  loProjectItem: tProjectItem;
begin
  loProjectItem := (aProjectItem as tProjectItem);

  aOutputFilename := ChangeFileExt(aOutputFilename, '.' + outputextension);

  Result := TPluginReturn.PRPassed;
end;

function tCodeDocsProcessorItem.Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
