unit Processor;

interface

Uses Output, Project, ProjectItem, classes, variables, NovusTemplate,
     CodeGenerator, CodeGeneratorDetails, Template;

type
  TProcessor = class(tobject)
  protected
    foPostProcessor: tPostProcessor;
    foCodeGenerator: tCodegenerator;
    foOutput: TOutput;
    foTemplate: tTemplate;
    foProjectItem: tProjectItem;
    foProject: tProject;
   // foVariables: tVariables;
    fsInputFileName: String;
    fsOutputFilename: String;
    fsRenderBodyTag: String;
  private
  public
    constructor Create(AOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aPostProcessor: tPostProcessor); virtual;
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

  foProjectItem := aProjectItem;

  foProject := aProject;

  //foVariables := aVariables;

  foPostProcessor:= aPostProcessor;

  foOutput := AOutput;

  FoTemplate := TTemplate.CreateTemplate;

  fsRenderBodyTag := '';

  foCodeGenerator:=  tCodegenerator.Create(FoTemplate, FoOutput, FoProject, foProjectItem, foPostProcessor);
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
