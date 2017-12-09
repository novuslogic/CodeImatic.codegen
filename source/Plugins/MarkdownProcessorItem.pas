unit MarkdownProcessorItem;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, SysUtils, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, MarkdownDaringFireball, MarkdownProcessor, ProjectItem, TagType,
  Loader;

type
  tMarkdownProcessorItem = class(TProcessorItem)
  private
  protected
    function GetProcessorName: String; override;
  public
    function PreProcessor(aProjectItem: tObject; var aFilename: String;
      aTemplate: tNovusTemplate;aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;
      aTemplateFile: String; var aOutputFilename: string)
      : TPluginReturn; override;

    function Convert(aProjectItem: tObject; aInputFilename: string;
      var aOutputFilename: string): TPluginReturn; override;
  end;

implementation

function tMarkdownProcessorItem.GetProcessorName: String;
begin
  Result := 'Markdown';
end;

function tMarkdownProcessorItem.PreProcessor(aProjectItem: tObject;
  var aFilename: String; aTemplate: tNovusTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn;
Var
  fMarkdownprocessor: TMarkdownDaringFireball;
begin
  Try
    Try
      fMarkdownprocessor := TMarkdownDaringFireball.Create;

      aTemplate.TemplateDoc.Text := fMarkdownprocessor.process
        (aTemplate.TemplateDoc.Text);

      Result := TPluginReturn.PRPassed;
    Except
      Result := TPluginReturn.PRFailed;

      oOutput.InternalError;
    End;
  Finally
    fMarkdownprocessor.Free;
  End;
end;

function tMarkdownProcessorItem.PostProcessor(aProjectItem: tObject;
  aTemplate: tNovusTemplate; aTemplateFile: String; var aOutputFilename: string)
  : TPluginReturn;
begin
  aOutputFilename := ChangeFileExt(aOutputFilename, '.' + outputextension);

  oOutput.Log('New output:' + aOutputFilename);

  Result := TPluginReturn.PRPassed;
end;

function tMarkdownProcessorItem.Convert(aProjectItem: tObject;
  aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
