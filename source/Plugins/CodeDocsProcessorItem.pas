unit CodeDocsProcessorItem;

interface

Uses Winapi.Windows, System.SysUtils, System.Classes,NovusFileUtils,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, JvSimpleXml;

type
  tCodeDocsProcessorItem = class(TProcessorItem)
  private
  protected
    function GetProcessorName: String; override;
  public
    function PreProcessor(aFilename: String; aTemplate: tNovusTemplate)
      : TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn; override;

    function Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string):TPluginReturn; override;
  end;

implementation

function tCodeDocsProcessorItem.GetProcessorName: String;
begin
  Result := 'CODEDOCS';
end;

function tCodeDocsProcessorItem.PreProcessor(aFilename: String; aTemplate: tNovusTemplate): TPluginReturn;
begin
  Result := PRIgnore;
end;

function tCodeDocsProcessorItem.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

function tCodeDocsProcessorItem.Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
