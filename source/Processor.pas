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
    function FindProcessorPlugin(aProcessor: string): TProcessorPlugin;
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

    function Execute(aDolayout: boolean = false): boolean;

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


function TProcessor.FindProcessorPlugin(aProcessor: string): TProcessorPlugin;
Var
  I: Integer;
  loProcessorItem: TProcessorItem;
begin
  Result := nil;

  if not Assigned(foPlugins) then Exit;
  foPlugin := NIL;

  // PluginName
  if (foPlugins as TPlugins).IsPluginNameExists(fsProcessor) then
    begin
      foPlugin := (foPlugins as TPlugins).FindPlugin(fsProcessor);

      if (foPlugin Is TProcessorPlugin) then
        begin
          Result := TProcessorPlugin(foPlugin);
        end;
    end;

  // ProcessorName
  If not Assigned(Result) then
    begin
      for I := 0 to (foPlugins as TPlugins).PluginsList.Count - 1 do
      begin
        foPlugin := (foPlugins as TPlugins).PluginsList.Items[I];
        if (foPlugin Is TProcessorPlugin) then
          begin
            loProcessorItem := TProcessorPlugin(foPlugin).GetProcessorName(fsProcessor);
            if Assigned(loProcessorItem) then
            begin
              Result := TProcessorPlugin(foPlugin);
              break;
            end;
          end;
      end;
    end;
end;


procedure TProcessor.Init;
begin
  if Trim(fsProcessor) <> '' then
    begin
      foprocessorPlugin := FindProcessorPlugin(fsProcessor);
      (*
      if (foPlugins as TPlugins).IsPluginNameExists(fsProcessor) then
        begin
          foPlugin := (foPlugins as TPlugins).FindPlugin(fsProcessor);

          if (foPlugin Is TProcessorPlugin) then
            begin
               foprocessorPlugin := TProcessorPlugin(foPlugin);
            end;
        end;
        *)
    end;


  FoTemplate := TTemplate.CreateTemplate;

  fsRenderBodyTag := '';

  foCodeGenerator := tCodegenerator.Create(foTemplate, foOutput, foProject,
    foProjectItem, foProcessorPlugin, fsInputFileName, fsSourceFileName);
end;

function TProcessor.Execute(aDolayout: boolean = false): boolean;
begin
   result := false;

    Try
      foOutput.LogFormat('Parse Input Filename [%s] ...', [InputFilename]);

      foTemplate.TemplateDoc.LoadFromFile(InputFilename);

      foTemplate.ParseTemplate;

      foCodeGenerator.oNodeLoader := foNodeLoader;

      foOutput.LogFormat('Processor Output Filename [%s] ...', [InputFilename]);

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
