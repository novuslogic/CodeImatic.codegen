unit ProjectItem;

interface

Uses NovusBO, JvSimpleXml, Project, SysUtils, NovusSimpleXML, ProjectConfigParser,
     DBSchema, Properties, NovusTemplate, CodeGenerator, Output, Template;

type
  TProjectItem = class(TObject)
  protected
  private
    foProject: TProject;
    foOutput: TOutput;
    foDBSchema: TDBSchema;
    foProperties: tProperties;
    foConnections: tConnections;
    foCodeGenerator: tCodeGenerator;
    foTemplate: TTemplate;
    fsItemName: String;
    fsOutputFile: String;
    fsTemplateFile: String;
    fsPropertiesFile: String;
    fboverrideoutput: Boolean;
    fsPostprocessor: string;
    fJvSimpleXmlElem: TJvSimpleXmlElem;
  Public
    constructor Create(aProject: TProject;aOutput: Toutput);
    destructor Destroy; override;

    function Execute: Boolean;

    function GetProperty(aToken: String; aProject: TProject): String;

    property PropertiesFile: String
       read fsPropertiesFile
       write fsPropertiesFile;

    property TemplateFile: String
      read fsTemplateFile
      write fsTemplateFile;

    property OutputFile: String
       read fsOutputFile
       write fsOutputFile;

    property overrideoutput: Boolean
      read fboverrideoutput
      write fboverrideoutput;

    property ItemName: String
      read fsItemName
      write fsItemName;

    property PostProcessor: String
      read fsPostProcessor
      write fsPostProcessor;

    property XmlElem: TJvSimpleXmlElem
      read fJvSimpleXmlElem
      write fJvSimpleXmlElem;

    property oConnections: tConnections
         read foConnections
         write foConnections;

    Property oProperties: tProperties
        read foProperties
        write foProperties;

    property oDBSchema: TDBSchema
        read  foDBSchema
        write  foDBSchema;

    property oCodeGenerator: tCodeGenerator
      read foCodeGenerator
      write foCodeGenerator;
  end;


implementation

Uses Config;


constructor TProjectItem.Create(aProject: TProject;aOutput: Toutput);
begin
  foProject := aProject;

  foOutput := aOutput;

  foProperties := tProperties.Create;

  foDBSchema := TDBSchema.Create;

  foTemplate := TTemplate.CreateTemplate;
end;

destructor TProjectItem.Destroy;
begin
  FreeandNil(foConnections);

  FreeandNil(foTemplate);
  FreeandNil(foProperties);
  FreeandNil(foDBSchema);

  FreeandNil(foCodeGenerator);

  inherited;
end;

function TProjectItem.GetProperty(aToken: string; aProject: TProject): String;
var
  Index: integer;
begin
  result := '';

  if aToken <> '' then
    begin
      if Trim(Uppercase(aToken))= 'NAME' then
        result := ItemName
      else
         begin
           Index := 0;
           if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, Trim(AToken), Index)) then
             begin
               Index := 0;
               Result := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, Trim(Uppercase(aToken)), Index).Value;
             end;

         end;

      Result := tProjectConfigParser.ParseProjectConfig(Result, aProject);
    end;
end;

function TProjectItem.Execute: Boolean;
begin
  Try
    Result := false;

    if PropertiesFile <> '' then
      begin
        foProperties.oProject := foProject;
        foProperties.oOutput :=Fooutput;
        foProperties.XMLFileName := PropertiesFile;
        foProperties.Retrieve;
      end;

    if fileexists(oconfig.dbschemafilename) then
      begin
        fodbschema.xmlfilename := oconfig.dbschemafilename;
        fodbschema.retrieve;
      end;

    foConnections := tConnections.Create(Fooutput, foProject.oProjectConfig, Self);


    FoOutput.Log('Template/Source : ' + fsTemplateFile);

    FoOutput.Log('Output: ' + fsOutPutFile);

    FoOutput.Log('Build started ' + Fooutput.FormatedNow);

    foTemplate.TemplateDoc.LoadFromFile(TemplateFile);

    foTemplate.ParseTemplate;

    foCodeGenerator := tCodeGenerator.Create(foTemplate, Fooutput, foProject, Self);

    foCodeGenerator.Execute(fsOutPutFile);

    if Not Fooutput.Failed then
      begin
        if Not Fooutput.Errors then
          FoOutput.Log('Build succeeded ' + Fooutput.FormatedNow)
        else
          FoOutput.Log('Build with errors ' + Fooutput.FormatedNow);
      end
    else
      FoOutput.LogError('Build failed ' + Fooutput.FormatedNow);

    Result := (Not Fooutput.Failed);
  Except
    FoOutput.InternalError;
  End;
end;


end.
