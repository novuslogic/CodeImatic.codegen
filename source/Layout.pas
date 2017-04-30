unit Layout;

interface

Uses Output, Project, ProjectItem, classes, variables, NovusTemplate,
     CodeGenerator, CodeGeneratorDetails, Template;

type
  TLayout = class(tobject)
  protected
    foCodeGenerator: tCodegenerator;
    foOutput: TOutput;
    foTemplate: tTemplate;
    foProjectItem: tProjectItem;
    foProject: tProject;
    foVariables: tVariables;
    fsInputFileName: String;
    fsOutputFilename: String;
    fsRenderBodyTag: String;
  private
  public
    constructor Create(AOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem; aVariables: tVariables); virtual;
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

constructor TLayout.Create;
begin
  inherited Create;

  foProjectItem := aProjectItem;

  foProject := aProject;

  foVariables := aVariables;

  foOutput := AOutput;

  FoTemplate := TTemplate.CreateTemplate;

  fsRenderBodyTag := '';

  foCodeGenerator:=  tCodegenerator.Create(FoTemplate, FoOutput, FoProject, foProjectItem);
end;

destructor TLayout.Destroy;
begin
  foCodeGenerator.Free;

  FoTemplate.Free;

  inherited;
end;




function TLayout.Execute: boolean;
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

function TLayout.InsertTagValue(aTagValue: String; aTagName: String): boolean;
begin
  Result := foCodeGenerator.InsertTagValue(aTagValue, aTagName);
end;

end.
