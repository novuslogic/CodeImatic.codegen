unit Processor;

interface

Uses Output, Project, ProjectItem, classes, variables, NovusTemplate,
     CodeGenerator, CodeGeneratorItem, Template, Plugin, Plugins, SysUtils;

type
  TProcessor = class(tobject)
  protected
    fsSourceFilename: String;
    fsProcessor: String;
    foProcessorPlugin: tProcessorPlugin;
    foCodeGenerator: tCodegenerator;
    foOutput: TOutput;
    foTemplate: tTemplate;
    foProjectItem: tProjectItem;
    foProject: tProject;
    fsInputFileName: String;
    fsOutputFilename: String;
    fsRenderBodyTag: String;
    foPlugins: tPlugins;
    foPlugin: tPlugin;
    function InsertTagValue(aTagValue: String; aTagName: String): boolean;
  private
  public
    constructor Create(AOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aProcessor: String;
      aInputFileName: String;
      aOutputFilename: string;
      aSourceFilename: String;
      aPlugins: TPlugins); virtual;

    destructor Destroy; override;

    function Execute: boolean;

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
  fsSourceFilename := aSourceFilename;

  foProjectItem := aProjectItem;

  foProject := aProject;
  fsProcessor := aProcessor;

  if Trim(aProcessor) <> '' then
    begin
      if (aPlugins as TPlugins).IsPluginNameExists(aProcessor) then
        begin
          foPlugin := (aPlugins as TPlugins).FindPlugin(aProcessor);

          if (foPlugin Is TProcessorPlugin) then
            begin
               foprocessorPlugin := TProcessorPlugin(foPlugin);
            end;
        end;
    end;


  foOutput := AOutput;

  FoTemplate := TTemplate.CreateTemplate;

  fsRenderBodyTag := '';

  foCodeGenerator := tCodegenerator.Create(foTemplate, foOutput, foProject,
    foProjectItem, foProcessorPlugin, fsInputFileName, aSourceFileName);
end;

destructor TProcessor.Destroy;
begin
  //foCodeGenerator.Free;

  //FoTemplate.Free;

  inherited;
end;

function TProcessor.Execute: boolean;
begin
   result := false;

    Try
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
