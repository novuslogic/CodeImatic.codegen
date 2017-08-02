unit Processor;

interface

Uses Output, Project, ProjectItem, classes, variables, NovusTemplate,
     CodeGenerator, CodeGeneratorItem, Template, Plugin;

type
  TProcessor = class(tobject)
  protected
    foProcessorPlugin: tProcessorPlugin;
    foCodeGenerator: tCodegenerator;
    foOutput: TOutput;
    foTemplate: tTemplate;
    foProjectItem: tProjectItem;
    foProject: tProject;
    fsInputFileName: String;
    fsOutputFilename: String;
    fsRenderBodyTag: String;
  private
  public
    constructor Create(AOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aProcessorPlugin: tProcessorPlugin;
      aInputFileName: String;
      aOutputFilename: string;
      aSourceFilename: String); virtual;

    destructor Destroy; override;

    function Execute: boolean;

    function InsertTagValue(aTagValue: String; aTagName: String): boolean;

    property OutputFilename: String
      read fsOutputFilename
      write fsOutputFilename;

    property InputFilename: String
       read fsInputFilename
       write fsInputFilename;

    property oTemplate: tTemplate
      read foTemplate
      write foTemplate;

    property oCodeGenerator: tCodeGenerator
      read foCodeGenerator
      write foCodeGenerator;

  end;

implementation

constructor TProcessor.Create;
begin
  inherited Create;

  fsOutputFilename := aOutputFilename;
  fsInputFilename := aInputFilename;

  foProjectItem := aProjectItem;

  foProject := aProject;

  foProcessorPlugin := aProcessorPlugin;

  foOutput := AOutput;

  FoTemplate := TTemplate.CreateTemplate;

  fsRenderBodyTag := '';

  foCodeGenerator := tCodegenerator.Create(foTemplate, foOutput, foProject,
    foProjectItem, foProcessorPlugin, fsInputFileName, aSourceFileName);
end;

destructor TProcessor.Destroy;
begin
  foCodeGenerator.Free;

  FoTemplate.Free;

  inherited;
end;

function TProcessor.Execute: boolean;
begin
  Try
    result := false;

    foTemplate.TemplateDoc.LoadFromFile(InputFilename);

    foTemplate.ParseTemplate;

    Result := foCodeGenerator.Execute(OutputFilename);
  Except
    foOutput.InternalError;

    Result := False;
  End;

end;

function TProcessor.InsertTagValue(aTagValue: String; aTagName: String): boolean;
begin
  Result := foCodeGenerator.InsertTagValue(aTagValue, aTagName);
end;

end.
