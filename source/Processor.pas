unit Processor;

interface

Uses Output, Project, ProjectItem, classes, variables, NovusTemplate,
     CodeGenerator, CodeGeneratorItem, Template, Plugin, Plugins, SysUtils, Loader;

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
    foNodeLoader: tNodeLoader;
    function InsertTagValue(aTagValue: String; aTagName: String): boolean;
    procedure Init;
  private
  public
    constructor Create(aOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aProcessor: String;
      aInputFileName: String;
      aOutputFilename: string;
      aSourceFilename: String;
      aPlugins: TPlugins;
      aNodeLoader: tNodeLoader); overload;

      constructor Create(aOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aProcessor: String;
      aInputFileName: String;
      aOutputFilename: string;
      aSourceFilename: String;
      aPlugins: TPlugins); overload;

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

constructor TProcessor.Create(aOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aProcessor: String;
      aInputFileName: String;
      aOutputFilename: string;
      aSourceFilename: String;
      aPlugins: TPlugins;
      aNodeLoader: tNodeLoader);
begin
  inherited Create;

  fsOutputFilename := aOutputFilename;
  fsInputFilename := aInputFilename;
  fsSourceFilename := aSourceFilename;

  foProjectItem := aProjectItem;

  foProject := aProject;
  fsProcessor := aProcessor;
  foNodeLoader := aNodeLoader;
  foOutput := AOutput;
  foPlugins := aPlugins;


  Init;


end;

constructor TProcessor.Create(aOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem;
      aProcessor: String;
      aInputFileName: String;
      aOutputFilename: string;
      aSourceFilename: String;
      aPlugins: TPlugins);
begin
  inherited Create;

  fsOutputFilename := aOutputFilename;
  fsInputFilename := aInputFilename;
  fsSourceFilename := aSourceFilename;

  foProjectItem := aProjectItem;

  foProject := aProject;
  fsProcessor := aProcessor;
  foOutput := AOutput;
  foPlugins := aPlugins;

  Init;
end;

destructor TProcessor.Destroy;
begin
  foCodeGenerator.Free;

  FoTemplate.Free;

  inherited;
end;

procedure TProcessor.Init;
begin
  if Trim(fsProcessor) <> '' then
    begin
      if (foPlugins as TPlugins).IsPluginNameExists(fsProcessor) then
        begin
          foPlugin := (foPlugins as TPlugins).FindPlugin(fsProcessor);

          if (foPlugin Is TProcessorPlugin) then
            begin
               foprocessorPlugin := TProcessorPlugin(foPlugin);
            end;
        end;
    end;


  FoTemplate := TTemplate.CreateTemplate;

  fsRenderBodyTag := '';

  foCodeGenerator := tCodegenerator.Create(foTemplate, foOutput, foProject,
    foProjectItem, foProcessorPlugin, fsInputFileName, fsSourceFileName);
end;

function TProcessor.Execute: boolean;
begin
   result := false;

    Try
      foTemplate.TemplateDoc.LoadFromFile(InputFilename);

      foTemplate.ParseTemplate;

      foCodeGenerator.oNodeLoader := foNodeLoader;

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
