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
    function Getoutputextension: string; override;
  public
    function PreProcessor(aProjectItem: tObject;aFilename: String; aTemplate: tNovusTemplate)
      : TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn; override;

    function Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string):TPluginReturn; override;
  end;

implementation



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
end;

function tCodeDocsProcessorItem.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string): TPluginReturn;
Var
  loProjectItem: tProjectItem;
begin
  loProjectItem := (aProjectItem as tProjectItem);

  aOutputFilename := ChangeFileExt(aOutputFilename, '.' + outputextension);

 // oOutput.Log('New output:' + aOutputFilename);

  Result := TPluginReturn.PRPassed;
end;

function tCodeDocsProcessorItem.Convert(aProjectItem: tObject;aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
