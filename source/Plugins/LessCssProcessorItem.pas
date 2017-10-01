unit LessCssProcessorItem;

interface

Uses
  Winapi.Windows, System.SysUtils, System.Classes, NovusFileUtils,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, JvSimpleXml;

type
  tLessCssProcessorItem = class(TProcessorItem)
  private
  protected
    function GetProcessorName: String; override;
  public
    function PreProcessor(aFilename: String; aTemplate: tNovusTemplate)
      : TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;
      aTemplateFile: string; var aOutputFile: string): TPluginReturn; override;

    function Convert(aFilename: string; var aOutputFile: string)
      : TPluginReturn; override;
  end;

implementation

function tLessCssProcessorItem.GetProcessorName: String;
begin
  Result := 'LESSCSS';
end;

function tLessCssProcessorItem.PreProcessor(aFilename: String;
  aTemplate: tNovusTemplate): TPluginReturn;
begin
  Result := PRIgnore;
end;

function tLessCssProcessorItem.PostProcessor(aProjectItem: tObject;
  aTemplate: tNovusTemplate; aTemplateFile: string; var aOutputFile: string)
  : TPluginReturn;
begin
  aOutputFile := ExtractFilePath(aTemplateFile) +  '_' + ExtractFileName(aTemplateFile);

  Result := PRPassed;
end;

function tLessCssProcessorItem.Convert(aFilename: string;
  var aOutputFile: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
