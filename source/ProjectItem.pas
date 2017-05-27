unit ProjectItem;

interface

Uses NovusBO, JvSimpleXml, Project, SysUtils, NovusSimpleXML, ProjectConfigParser,
     DBSchema, Properties, NovusTemplate, CodeGenerator, Output, Template, NovusFileUtils,
     NovusList;

type
  TProjectItem = class;

  tFileType = class
  private
    fbIsFolder: Boolean;
    fbIsTemplateFile: Boolean;
    fsFullPathname: String;
  protected
  public
    property IsFolder: Boolean read fbIsFolder write fbIsFolder;

    property IsTemplateFile: Boolean read fbIsTemplateFile
      write fbIsTemplateFile;

    property FullPathname: String
       read fsFullPathname
       write fsFullPathName;
  end;

  tFilterFile = class(tFileType)
  private
  protected
  public
  end;

  tTemplateFile= class(tFileType)
  private
  protected
    fspostprocessor: string;
  public
    property postprocessor: string
      read fspostprocessor
      write fspostprocessor;
  end;

  tSourceFile = class(tFileType)
  private
  protected

    fsSourceFullPathname: String;
    fsDestFullPathname: String;
  public
    property SourceFullPathname: String
      read fsSourceFullPathname
      write fsSourceFullPathname;

    property DestFullPathname: string
      read fsDestFullPathname
      write fsDestFullPathname;
   end;

  tFilters = class(tnovusList)
  private
  protected
  public
    function AddFile(aFullPathname: string): tFilterFile;
  end;

  tTemplates = class(tnovusList)
  private
  protected
  public
    function AddFile(aFullPathname: string; aPostProcessor: String): tTemplateFile;
  end;

  tSourceFiles = class(tnovusList)
  private
  protected
    foTemplates: tTemplates;
    foFilters: tFilters;
    fsFolder: String;
  public
    constructor Create(aProjectItem: TProjectItem;aOutput: Toutput); overload;
    destructor Destroy; override;

    function AddFile(aSourceFullPathname: string): tSourceFile;

    property oFilters: tFilters
      read foFilters
      write foFilters;

    property oTemplates: tTemplates
      read foTemplates
      write foTemplates;

    property Folder: String
      read fsFolder
      write fsFolder;
  end;

  TProjectItem = class(TObject)
  protected
  private
    foSourceFiles: tSourceFiles;
    foProject: TProject;
    foOutput: TOutput;
    foDBSchema: TDBSchema;
    foProperties: tProperties;
    foConnections: tConnections;
    foCodeGenerator: tCodeGenerator;
    foTemplate: TTemplate;
    fsItemName: String;
    fsItemFolder: String;
    fsOutputFile: String;
    fsTemplateFile: String;
    fsPropertiesFile: String;
    fboverrideoutput: Boolean;
    fsPostprocessor: string;
    fJvSimpleXmlElem: TJvSimpleXmlElem;
    function GetName: String;
  Public
    constructor Create(aProject: TProject;aOutput: Toutput);
    destructor Destroy; override;

    function Execute: Boolean;

    function GetProperty(aToken: String; aProject: TProject): String;

    property Name: String
       read GetName;

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

    property ItemFolder: String
      read fsItemFolder
      write fsItemFolder;

    property PostProcessor: String
      read fsPostProcessor
      write fsPostProcessor;

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

    property oSourceFiles: tSourceFiles
      read foSourceFiles
      write foSourceFiles;


  end;


implementation

Uses Config, ProjectFolder;


constructor TProjectItem.Create(aProject: TProject;aOutput: Toutput);
begin
  foProject := aProject;

  foOutput := aOutput;

  foProperties := tProperties.Create;

  foDBSchema := TDBSchema.Create;

  foTemplate := TTemplate.CreateTemplate;

  foSourceFiles:= tSourceFiles.Create(Self, foOutput);
end;

destructor TProjectItem.Destroy;
begin
  foSourceFiles.Free;

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
Var
  loProjectFolder: tProjectFolder;
begin
  Try
    result := false;

    if PropertiesFile <> '' then
    begin
      foProperties.oProject := foProject;
      foProperties.oOutput := foOutput;
      foProperties.XMLFileName := PropertiesFile;
      foProperties.Retrieve;
    end;

    if fileexists(oconfig.dbschemafilename) then
    begin
      foDBSchema.XMLFileName := oconfig.dbschemafilename;
      foDBSchema.Retrieve;
    end;

    foConnections := tConnections.Create(foOutput,
      foProject.oProjectConfig, Self);

    if ItemFolder <> '' then
      begin
        Try
          foOutput.Log('Build started ' + foOutput.FormatedNow);

          loProjectFolder:= tProjectFolder.Create(foOutput, foProject,self);

          loProjectFolder.Execute;

          if Not foOutput.Failed then
            begin
              if Not foOutput.Errors then
                foOutput.Log('Build succeeded ' + foOutput.FormatedNow)
              else
                foOutput.Log('Build with errors ' + foOutput.FormatedNow);
            end
            else
              foOutput.LogError('Build failed ' + foOutput.FormatedNow);

           result := (Not foOutput.Failed);
        Finally
          loProjectFolder.Free;
        End;
      end
    else
    if ItemName <> '' then
    begin
      foOutput.Log('Template/Source : ' + fsTemplateFile);

      foOutput.Log('Output: ' + fsOutputFile);

      foOutput.Log('Build started ' + foOutput.FormatedNow);

      foTemplate.TemplateDoc.LoadFromFile(TemplateFile);

      foTemplate.ParseTemplate;

      foCodeGenerator := tCodeGenerator.Create(foTemplate, foOutput,
        foProject, Self);

      foCodeGenerator.Execute(fsOutputFile);

      if Not foOutput.Failed then
      begin
        if Not foOutput.Errors then
          foOutput.Log('Build succeeded ' + foOutput.FormatedNow)
        else
          foOutput.Log('Build with errors ' + foOutput.FormatedNow);
      end
      else
        foOutput.LogError('Build failed ' + foOutput.FormatedNow);

      result := (Not foOutput.Failed);

    end;
  Except
    foOutput.InternalError;
  End;
end;

function TProjectItem.GetName: String;
begin
  if ItemName <> '' then
    Result := ItemName
  else
    Result := ItemFolder;
end;


// tSourceFiles
constructor tSourceFiles.Create(aProjectItem: TProjectItem;aOutput: Toutput);
begin
  Initclass(tSourceFile);

  foFilters:= tFilters.Create(tFilterFile);

  foTemplates := tTemplates.Create(tTemplateFile);
end;

destructor tSourceFiles.Destroy;
begin
  foFilters.Free;
  foTemplates.Free;

  inherited;
end;




function tSourceFiles.AddFile(aSourceFullPathname: string): tSourceFile;
var
  loSourceFile: tSourceFile;
begin
  loSourceFile:= tSourceFile.Create;
  loSourceFile.SourceFullPathname := Trim(aSourceFullPathname);
  loSourceFile.IsFolder := TNovusFileUtils.IsValidFolder(loSourceFile.SourceFullPathname);
  loSourceFile.IsTemplateFile := false;


  Add(loSourceFile);

end;


// tFilters
function tFilters.AddFile(aFullPathname: string): tFilterFile;
var
  loFilterFile: tFilterFile;
begin
  loFilterFile:= tFilterFile.Create;
  loFilterFile.FullPathname := Trim(aFullPathname);
  loFilterFile.IsFolder := false; //TNovusFileUtils.IsValidFolder(loFilterFile.FullPathname);
  loFilterFile.IsTemplateFile := false;

  Add(loFilterFile);
end;

// Templateiles
function tTemplates.AddFile(aFullPathname: string; aPostProcessor: String): tTemplateFile;
var
  loTemplateFile: tTemplateFile;
begin
  loTemplateFile:= tTemplateFile.Create;
  loTemplateFile.FullPathname := Trim(aFullPathname);
  loTemplateFile.IsFolder := false; //TNovusFileUtils.IsValidFolder(loFilterFile.FullPathname);
  loTemplateFile.IsTemplateFile := true;
  loTemplateFile.postprocessor := aPostProcessor;

  Add(loTemplateFile);

  Result := loTemplateFile;
end;



end.
