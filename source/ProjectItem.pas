unit ProjectItem;

interface

Uses NovusBO, JvSimpleXml, Project, SysUtils, NovusSimpleXML, ProjectConfigParser,
     DBSchema, Properties, NovusTemplate, CodeGenerator, Output, Template, NovusFileUtils,
     NovusList, System.RegularExpressions, NovusUtilities, plugin;

type
  TProjectItem = class;

  tFileType = class(tobject)
  private
    foProcessorPlugin: tProcessorPlugin;
    fbIsFolder: Boolean;
    fbIsTemplateFile: Boolean;
    fsFullPathname: String;
    fsfilename: String;
  protected
  public
    constructor Create;
    destructor Destroy;

    property IsFolder: Boolean read fbIsFolder write fbIsFolder;

    property IsTemplateFile: Boolean read fbIsTemplateFile
      write fbIsTemplateFile;

    property Filename: String
      read fsFilename
      write fsFilename;

    property FullPathname: String
       read fsFullPathname
       write fsFullPathName;

    property oprocessorPlugin: tProcessorPlugin
      read foprocessorPlugin
      write foprocessorPlugin;
  end;

  tFiltered = class(tFileType)
  private
  protected
  public
  end;

  tTemplateFile= class(tFileType)
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
    property DestFullPathname: string
      read fsDestFullPathname
      write fsDestFullPathname;

    property IsFiltered: boolean
      read fbIsFiltered
      write fbIsfiltered;
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
    function AddFile(aFullPathname: string; aFilename: String; aProcessor: String): tTemplateFile;
  end;

  tSourceFiles = class(tnovusList)
  private
  protected
    foProjectItem: tProjectItem;
    foProject: tProject;
    foTemplates: tTemplates;
    foFilters: tFilters;
    fsFolder: String;
  public
    constructor Create(aProject:tProject;aProjectItem: TProjectItem;aOutput: Toutput); overload;
    destructor Destroy; override;

    function AddFile(aFullPathname: string; aFilename: String): tSourceFile;
    function IsTemplateFile(aFullPathname: string): tTemplateFile;
    function IsFiltered(aFullPathname: string): boolean;
    function WildcardToRegex(aPattern: string): String;

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
    fbdeleteoutput: boolean;
    fsprocessor: string;
    fNodeProjectItem: TJvSimpleXmlElem;
    function GetName: String;
  Public
    constructor Create(aProject: TProject;aOutput: Toutput; aNodeProjectItem: TJvSimpleXmlElem);
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

    property deleteoutput: boolean
      read fbdeleteoutput
      write fbdeleteoutput;

    property ItemName: String
      read fsItemName
      write fsItemName;

    property ItemFolder: String
      read fsItemFolder
      write fsItemFolder;

    property Processor: String
      read fsProcessor
      write fsProcessor;

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

Uses Config, ProjectItemFolder;


constructor TProjectItem.Create(aProject: TProject;aOutput: Toutput; aNodeProjectItem: TJvSimpleXmlElem);
begin
  foProject := aProject;

  foOutput := aOutput;

  foProperties := tProperties.Create;

  foDBSchema := TDBSchema.Create;

  foTemplate := TTemplate.CreateTemplate;

  fNodeProjectItem := aNodeProjectItem;

  foSourceFiles:= tSourceFiles.Create(foProject, Self, foOutput);
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
           if assigned(TNovusSimpleXML.FindNode(fNodeProjectItem, Trim(AToken), Index)) then
             begin
               Index := 0;
               Result := TNovusSimpleXML.FindNode(fNodeProjectItem, Trim(Uppercase(aToken)), Index).Value;
             end;
         end;

      Result := tProjectConfigParser.ParseProjectConfig(Result, aProject, foOutput);
    end;
end;

function TProjectItem.Execute: Boolean;
Var
  loProjectItemFolder: tProjectItemFolder;
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

          loProjectItemFolder:= tProjectItemFolder.Create(foOutput, foProject,self);

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
      end
    else
    if ItemName <> '' then
    begin
      foOutput.Log('Source : ' + fsTemplateFile);

      foOutput.Log('Output: ' + fsOutputFile);

      foOutput.Log('Build started ' + foOutput.FormatedNow);

      foTemplate.TemplateDoc.LoadFromFile(TemplateFile);

      foTemplate.ParseTemplate;

      foCodeGenerator := tCodeGenerator.Create(foTemplate, foOutput,
        foProject, Self, NIL, fsTemplateFile, fsTemplateFile);

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
constructor tSourceFiles.Create(aProject:tProject;aProjectItem: TProjectItem;aOutput: Toutput);
begin
  Initclass(tSourceFile);

  foProject := aProject;
  foProjectItem := aProjectItem;

  foFilters:= tFilters.Create(tFiltered);

  foTemplates := tTemplates.Create(tTemplateFile);
end;

destructor tSourceFiles.Destroy;
begin
  foFilters.Free;
  foTemplates.Free;

  inherited;
end;

function tSourceFiles.AddFile(aFullPathname: string; aFilename: String): tSourceFile;
var
  loSourceFile: tSourceFile;
  fsSourcefullpathname: string;
  foTemplateFile: tTemplateFile;
begin
  try
    loSourceFile:= tSourceFile.Create;
    loSourceFile.FullPathname := Trim(aFullPathname);
    loSourceFile.IsFolder := TNovusFileUtils.IsValidFolder(aFullPathname);
    loSourceFile.Filename := aFilename;

    loSourceFile.IsTemplateFile := false;
    if loSourceFile.IsFolder = false then
      begin
        foTemplateFile := IsTemplateFile(aFullPathname);

        loSourceFile.IsTemplateFile := (foTemplateFile <> NIL);

        if loSourceFile.IsTemplateFile then
           TNovusUtilities.CopyObject(foTemplateFile.oprocessorPlugin, loSourceFile.oprocessorPlugin);
      end;

    loSourceFile.IsFiltered := IsFiltered(aFullPathname);

    // Local to dev directory only
    if compareText(aFullPathname, self.Folder ) > 0 then
      begin
        loSourceFile.DestFullPathname := StringReplace(aFullPathname, self.Folder ,
              foProjectItem.OutputFile, [rfReplaceAll, rfIgnoreCase]);
      end
    else
      begin
//


      end;

//    foProjectItem.ItemFolder;

    Add(loSourceFile);
  finally
    Result := loSourceFile;
  end;
end;


function tSourceFiles.IsFiltered(aFullPathname: string): boolean;
var
  foFilterd: tFiltered;
  I: integer;
  fsfullpathname,
  fsWildcard: string;
begin
  Result := False;

  for I := 0 to oFilters.Count - 1 do
    begin
      foFilterd:= tFiltered(oFilters.Items[i]);

      fsWildcard := WildcardToRegex(foFilterd.FullPathname);

      result := TRegEx.IsMatch(aFullPathname, fsWildcard, [TRegExOption.roIgnoreCase]);
      if Result then break;
    end;
end;

function tSourceFiles.IsTemplateFile(aFullPathname: string): tTemplateFile;
var
  foTemplateFile: tTemplateFile;
  I: integer;
  fsfullpathname,
  fsWildcard: string;
begin
  Result := NIL;

  for I := 0 to oTemplates.Count - 1 do
    begin
      foTemplateFile:= tTemplateFile(oTemplates.Items[i]);

      fsWildcard := WildcardToRegex(foTemplateFile.Filename);

      if TRegEx.IsMatch(aFullPathname, fsWildcard, [TRegExOption.roIgnoreCase]) then
        begin
          Result := foTemplateFile;

          Break;
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
  foprocessorplugin := tprocessorplugin.create(NIL, '', NIL, NIL);
end;

destructor tFileType.Destroy;
begin
  foprocessorplugin.Free;
end;


// tFilters
function tFilters.AddFile(aFullPathname: string; aFilename: String): tFiltered;
var
  loFiltered: tFiltered;
begin
  loFiltered:= tFiltered.Create;
  loFiltered.FullPathname := Trim(aFullPathname);
  loFiltered.IsFolder := TNovusFileUtils.IsValidFolder(loFiltered.FullPathname);
  loFiltered.IsTemplateFile := false;
  loFiltered.Filename := aFilename;

  Add(loFiltered);
end;

// TemplateFile

function tTemplates.AddFile(aFullPathname: string; aFilename: String; aProcessor: String): tTemplateFile;
var
  loTemplateFile: tTemplateFile;
begin
  loTemplateFile:= tTemplateFile.Create;
  loTemplateFile.FullPathname := Trim(aFullPathname);
  loTemplateFile.IsFolder := false;
  loTemplateFile.IsTemplateFile := true;
  loTemplateFile.oprocessorplugin.PluginName := aProcessor;
  loTemplateFile.Filename := aFilename;

  Add(loTemplateFile);

  Result := loTemplateFile;
end;



end.
