unit MarkdownProcessorItem;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, SysUtils, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, MarkdownDaringFireball, MarkdownProcessor, ProjectItem, TagType,
  Loader, template, CodeGenerator, TagTypeParser;

type
  tMarkdownProcessorItem = class(TProcessorItem)
  private
  protected
    foCodeGenerator: tCodeGenerator;
    foProjectItem: tProjectItem;
    function GetProcessorName: String; override;
    procedure DoBlockEvent(const aBlock: tBlock);
  public
    function PreProcessor(aProjectItem: tObject; var aFilename: String;
      var aTemplate: tTemplate;aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; var aTemplate: tTemplate;
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


procedure tMarkdownProcessorItem.DoBlockEvent(const aBlock: tBlock);
var
  fTagType: TTagType;
  loTemplate: ttemplate;
begin
  aBlock.type_ := btNONE;

  fTagType := TTagTypeParser.ParseTagType(foProjectItem, foCodeGenerator,
      aBlock.lines.value,  oOutput, true);




end;

function tMarkdownProcessorItem.PreProcessor(aProjectItem: tObject;
  var aFilename: String; var aTemplate: tTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn;
Var
  fMarkdownprocessor: TMarkdownDaringFireball;

begin
  Try
    Try
      fMarkdownprocessor := TMarkdownDaringFireball.Create;

      FoCodeGenerator := (aCodeGenerator as tCodeGenerator);
      foProjectItem := (aProjectItem as tProjectItem);

      fMarkdownprocessor.OnBlock := DoBlockEvent;

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

  Result := TPluginReturn.PRIgnore;
end;

function tMarkdownProcessorItem.PostProcessor(aProjectItem: tObject;
  var aTemplate: tTemplate; aTemplateFile: String; var aOutputFilename: string)
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
