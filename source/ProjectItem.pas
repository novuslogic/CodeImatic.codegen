unit ProjectItem;

interface

Uses NovusBO, JvSimpleXml, Project, SysUtils, NovusSimpleXML,
  ProjectConfigParser,
  DBSchema, Properties, NovusTemplate, CodeGenerator, Output, Template,
  NovusFileUtils,
  NovusList, System.RegularExpressions, NovusUtilities, plugin, Loader;

type
  TProjectItemType = (pitItem, pitFolder);

  TProjectItem = class;

  tFileType = class(tobject)
  private
    foProcessorPlugin: tProcessorPlugin;
    fbIsFolder: Boolean;
    fbIsTemplateFile: Boolean;
    fsFullPathname: String;
    fsfilename: String;
    fsProcessor: String;
    foNodeLoader: tNodeLoader;
  protected
  public
    constructor Create;
    destructor Destroy;

    property IsFolder: Boolean read fbIsFolder write fbIsFolder;

    property IsTemplateFile: Boolean read fbIsTemplateFile
      write fbIsTemplateFile;

    property Filename: String read fsfilename write fsfilename;

    property FullPathname: String read fsFullPathname write fsFullPathname;

    property Processor: String read fsProcessor write fsProcessor;

    property oNodeLoader: tNodeLoader read foNodeLoader write foNodeLoader;
  end;

  tFiltered = class(tFileType)
  private
  protected
  public
  end;

  tTemplateFile = class(tFileType)
  private
  protected
  public
  end;

  tSourceFile = class(tFileType)
  private
  protected
    fbIsFiltered: Boolean;
    fsDestFullPathname: String;

  public
    property DestFullPathname: string read fsDestFullPathname
      write fsDestFullPathname;

    property IsFiltered: Boolean read fbIsFiltered write fbIsFiltered;

  end;

  tFilters = class(tnovusList)
  private
  protected
  public
    function AddFile(aFullPathname: string; aFilename: String): tFiltered;
  end;

  tTemplates = class(tnovusList)
  private
  protected
  public
    function AddFile(aFullPathname: string; aFilename: String;
      aProcessor: String; aNodeLoader: tNodeLoader): tTemplateFile;
  end;

  tSourceFiles = class(tnovusList)
  private
  protected
    foProjectItem: TProjectItem;
    foProject: tProject;
    foTemplates: tTemplates;
    foFilters: tFilters;
    fsFolder: String;
    foNodeLoader: tNodeLoader;
  public
    constructor Create(aProject: tProject; aProjectItem: TProjectItem;
      aOutput: Toutput); overload;
    destructor Destroy; override;

    function AddFile(aFullPathname: string; aFilename: String;
      aIsFolder: Boolean): tSourceFile;
    function IsTemplateFile(aFullPathname: string): tTemplateFile;
    function IsFiltered(aFullPathname: string): Boolean;
    function WildcardToRegex(aPattern: string): String;

    property oFilters: tFilters read foFilters write foFilters;

    property oTemplates: tTemplates read foTemplates write foTemplates;

    property Folder: String read fsFolder write fsFolder;

    property oNodeLoader: tNodeLoader read foNodeLoader write foNodeLoader;
  end;

  TProjectItem = class(tobject)
  protected
  private
    fProjectItemType: TProjectItemType;
    foSourceFiles: tSourceFiles;
    foProject: tProject;
    foOutput: Toutput;
    foDBSchema: TDBSchema;
    foProperties: tProperties;
    foConnections: tConnections;
    fsItemName: String;
    fsItemFolder: String;
    fsOutputFile: String;
    fsTemplateFile: String;
    fsPropertiesFile: String;
    fboverrideoutput: Boolean;
    fbdeleteoutput: Boolean;
    fsprocessorPlugin: string;
    fNodeLoader: tNodeLoader;
    fNodeProjectItem: TJvSimpleXmlElem;
    function GetName: String;
  Public
    constructor Create(aProject: tProject; aOutput: Toutput;
      aNodeProjectItem: TJvSimpleXmlElem);

    destructor Destroy; override;

    function Execute: Boolean;

    function GetProperty(aToken: String; aProject: tProject): String;

    property Name: String read GetName;

    property PropertiesFile: String read fsPropertiesFile
      write fsPropertiesFile;

    property TemplateFile: String read fsTemplateFile write fsTemplateFile;

    property OutputFile: String read fsOutputFile write fsOutputFile;

    property overrideoutput: Boolean read fboverrideoutput
      write fboverrideoutput;

    property deleteoutput: Boolean read fbdeleteoutput write fbdeleteoutput;

    property ItemName: String read fsItemName write fsItemName;

    property ItemFolder: String read fsItemFolder write fsItemFolder;

    property ProcessorPlugin: String read fsprocessorPlugin
      write fsprocessorPlugin;

    property oConnections: tConnections read foConnections write foConnections;

    Property oProperties: tProperties read foProperties write foProperties;

    property oDBSchema: TDBSchema read foDBSchema write foDBSchema;


    property oSourceFiles: tSourceFiles read foSourceFiles write foSourceFiles;

    property ProjectItemType: TProjectItemType read fProjectItemType
      write fProjectItemType;

  end;

implementation

Uses Config, ProjectItemFolder, Plugins, Processor;

constructor TProjectItem.Create(aProject: tProject; aOutput: Toutput;
  aNodeProjectItem: TJvSimpleXmlElem);
begin
  foProject := aProject;

  foOutput := aOutput;


  foProperties := tProperties.Create;

  foDBSchema := TDBSchema.Create;

  // foTemplate := TTemplate.CreateTemplate;

  fNodeProjectItem := aNodeProjectItem;

  foSourceFiles := tSourceFiles.Create(foProject, Self, foOutput);
end;

destructor TProjectItem.Destroy;
begin
  foSourceFiles.Free;

  FreeandNil(foConnections);

  // FreeandNil(foTemplate);
  FreeandNil(foProperties);
  FreeandNil(foDBSchema);

  // FreeandNil(foCodeGenerator);

  inherited;
end;

function TProjectItem.GetProperty(aToken: string; aProject: tProject): String;
var
  Index: integer;
begin
  result := '';

  if aToken <> '' then
  begin
    if Trim(Uppercase(aToken)) = 'NAME' then
      result := ItemName
    else
    begin
      Index := 0;
      if assigned(TNovusSimpleXML.FindNode(fNodeProjectItem, Trim(aToken),
        Index)) then
      begin
        Index := 0;
        result := TNovusSimpleXML.FindNode(fNodeProjectItem,
          Trim(Uppercase(aToken)), Index).Value;
      end;
    end;

    result := tProjectConfigParser.ParseProjectConfig(result, aProject,
      foOutput);
  end;
end;

function TProjectItem.Execute: Boolean;
Var
  loProjectItemFolder: tProjectItemFolder;
  loProcessor: TProcessor;
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

    case Self.ProjectItemType of
      pitItem:
        begin
          foOutput.Log('Source : ' + fsTemplateFile);

          foOutput.Log('Output: ' + fsOutputFile);

          foOutput.Log('Build started ' + foOutput.FormatedNow);

          Try
            loProcessor := TProcessor.Create(foOutput, foProject, Self,
              fsprocessorPlugin, TemplateFile, fsOutputFile, TemplateFile,
              (foProject.oPlugins as tPlugins));

            result := loProcessor.Execute;

          Finally
            loProcessor.Free;
          End;

          (*
            foTemplate.TemplateDoc.LoadFromFile(TemplateFile);

            foTemplate.ParseTemplate;

            foCodeGenerator := tCodeGenerator.Create(foTemplate, foOutput,
            foProject, Self, NIL, fsTemplateFile, fsTemplateFile);

            foCodeGenerator.Execute(fsOutputFile);
          *)

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
      pitFolder:
        begin
          Try
            foOutput.Log('Build started ' + foOutput.FormatedNow);

            loProjectItemFolder := tProjectItemFolder.Create(foOutput,
              foProject, Self);

            loProjectItemFolder.Execute;

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
            loProjectItemFolder.Free;
          End;

        end;

    end;

  Except
    foOutput.InternalError;
  End;
end;

function TProjectItem.GetName: String;
begin
  result := '';
  case Self.ProjectItemType of
    pitItem:
      result := ItemName;
    pitFolder:
      result := ItemFolder;
  end;
end;

// tSourceFiles
constructor tSourceFiles.Create(aProject: tProject; aProjectItem: TProjectItem;
  aOutput: Toutput);
begin
  Initclass(tSourceFile);

  foProject := aProject;
  foProjectItem := aProjectItem;

  foFilters := tFilters.Create(tFiltered);

  foTemplates := tTemplates.Create(tTemplateFile);
end;

destructor tSourceFiles.Destroy;
begin
  foFilters.Free;
  foTemplates.Free;

  inherited;
end;

function tSourceFiles.AddFile(aFullPathname: string; aFilename: String;
  aIsFolder: Boolean): tSourceFile;
var
  loSourceFile: tSourceFile;
  fsSourcefullpathname: string;
  foTemplateFile: tTemplateFile;
begin
  try
    loSourceFile := tSourceFile.Create;
    loSourceFile.FullPathname := Trim(aFullPathname);
    loSourceFile.IsFolder := aIsFolder;
    loSourceFile.Filename := aFilename;

    loSourceFile.IsTemplateFile := false;
    if loSourceFile.IsFolder = false then
    begin
      foTemplateFile := IsTemplateFile(aFullPathname);
      loSourceFile.IsTemplateFile := false;
      if assigned(foTemplateFile) then
      begin
        loSourceFile.IsTemplateFile := true;
        loSourceFile.Processor := foTemplateFile.Processor;
        loSourceFile.oNodeLoader := foTemplateFile.oNodeLoader;
      end;
    end;

    loSourceFile.IsFiltered := IsFiltered(aFullPathname);

    // Local to dev directory only
    if compareText(aFullPathname, Self.Folder) > 0 then
    begin
      loSourceFile.DestFullPathname := StringReplace(aFullPathname, Self.Folder,
        foProjectItem.OutputFile, [rfReplaceAll, rfIgnoreCase]);
    end
    else
    begin
      //

    end;

    // foProjectItem.ItemFolder;

    Add(loSourceFile);
  finally
    result := loSourceFile;
  end;
end;

function tSourceFiles.IsFiltered(aFullPathname: string): Boolean;
var
  foFilterd: tFiltered;
  I: integer;
  fsFullPathname, fsWildcard: string;
begin
  result := false;

  for I := 0 to oFilters.Count - 1 do
  begin
    foFilterd := tFiltered(oFilters.Items[I]);

    fsWildcard := WildcardToRegex(foFilterd.FullPathname);

    result := TRegEx.IsMatch(aFullPathname, fsWildcard,
      [TRegExOption.roIgnoreCase]);
    if result then
      break;
  end;
end;

function tSourceFiles.IsTemplateFile(aFullPathname: string): tTemplateFile;
var
  foTemplateFile: tTemplateFile;
  I: integer;
  fsFullPathname, fsWildcard: string;
begin
  result := NIL;

  for I := 0 to oTemplates.Count - 1 do
  begin
    foTemplateFile := tTemplateFile(oTemplates.Items[I]);

    fsWildcard := WildcardToRegex(foTemplateFile.Filename);

    if TRegEx.IsMatch(aFullPathname, fsWildcard, [TRegExOption.roIgnoreCase])
    then
    begin
      result := foTemplateFile;

      break;
    end;
  end;
end;

function tSourceFiles.WildcardToRegex(aPattern: string): String;
begin
  result := TRegEx.Escape(aPattern, true);
end;

// tFileType
constructor tFileType.Create;
begin
  foProcessorPlugin := NIL;

  // foProcessorPlugin := tProcessorPlugin.Create(NIL, '', NIL, NIL);
end;

destructor tFileType.Destroy;
begin
  foProcessorPlugin := NIL;

  // foProcessorPlugin.Free;
end;

// tFilters
function tFilters.AddFile(aFullPathname: string; aFilename: String): tFiltered;
var
  loFiltered: tFiltered;
begin
  loFiltered := tFiltered.Create;
  loFiltered.FullPathname := Trim(aFullPathname);
  loFiltered.IsFolder := TNovusFileUtils.IsValidFolder(loFiltered.FullPathname);
  loFiltered.IsTemplateFile := false;
  loFiltered.Filename := aFilename;

  Add(loFiltered);
end;

// TemplateFile

function tTemplates.AddFile(aFullPathname: string; aFilename: String;
  aProcessor: String; aNodeLoader: tNodeLoader): tTemplateFile;
var
  loTemplateFile: tTemplateFile;
  loPlugin: TPlugin;
begin
  loTemplateFile := tTemplateFile.Create;
  loTemplateFile.FullPathname := Trim(aFullPathname);
  loTemplateFile.IsFolder := false;
  loTemplateFile.IsTemplateFile := true;
  loTemplateFile.Processor := aProcessor;
  loTemplateFile.Filename := aFilename;
  loTemplateFile.oNodeLoader := aNodeLoader;

  Add(loTemplateFile);

  result := loTemplateFile;
end;

end.
