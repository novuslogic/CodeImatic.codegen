unit MarkdownProcessorItem;

interface

uses Classes, Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, SysUtils, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, MarkdownDaringFireball, MarkdownProcessor, ProjectItem, TagType;

type
  tMarkdownProcessorItem = class(TProcessorItem)
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

function tMarkdownProcessorItem.GetProcessorName: String;
begin
  Result := 'Markdown';
end;

function tMarkdownProcessorItem.PreProcessor(aFilename: String;
  aTemplate: tNovusTemplate): TPluginReturn;
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
  aTemplate: tNovusTemplate; aTemplateFile: string; var aOutputFile: string)
  : TPluginReturn;
begin
  aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

  oOutput.Log('New output:' + aOutputFile);

  Result := TPluginReturn.PRPassed;
end;

function tMarkdownProcessorItem.Convert(aFilename: string;
  var aOutputFile: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

(*
  function tPlugin_MarkdownBase.PreProcessor(aFilename: string; var aTemplateDoc: tStringlist): boolean;
  Var
  fMarkdownprocessor: TMarkdownDaringFireball;
  fsProcessed: string;
  begin
  Result := False;

  foOutput.Log('Processor:' + pluginname);

  Try
  Try
  fMarkdownprocessor:= TMarkdownDaringFireball.Create;

  fsProcessed := fMarkdownprocessor.process(aTemplateDoc.Text);

  aTemplateDoc.Text := fsProcessed;

  result := true;
  Except
  result := false;

  foOutput.InternalError;
  End;
  Finally
  fMarkdownprocessor.Free;
  End;
  end;

  function tPlugin_MarkdownBase.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
  begin
  result := false;

  foOutput.Log('Postprocessor:' + pluginname);

  Try
  // aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

  foOutput.Log('New output:' + aOutputFile);

  result := true;
  Except
  result := false;
  foOutput.InternalError;
  End;
  end;
*)

end.
