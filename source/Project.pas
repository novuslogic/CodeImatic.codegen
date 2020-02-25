unit Project;

interface

Uses NovusXMLBO, Classes, SysUtils, NovusStringUtils, NovusBO, NovusList,NovusFileUtils,
     JvSimpleXml, NovusSimpleXML, XMLlist, {ProjectConfig, } Output,
     ProjectConfigLoader;


Type
  TProject = class(TXMLlist)
  protected
  private
    foProjectConfigLoader: TProjectConfigLoader;
    foPlugins: tObject;
    foOutput: TOutput;
    fbcreateoutputdir: Boolean;
  //  foProjectConfig: TProjectConfig;
    foProjectItemList: TNovusList;
    fsBasePath: String;
    fsTemplatePath: String;
    fsProjectFilename: String;
    fbOutputConsole: Boolean;
    function GetoPlugins: TObject;
    procedure SetoPlugins(Value: tObject);
  public
    constructor Create(aOutput: tOutput); reintroduce;
    destructor Destroy; override;

    function GetBasePath: String;
    function GetOutputConsole: Boolean;
    function GetCreateoutputdir: Boolean;

    function GetWorkingdirectory: String;

    function LoadProjectFile(aProjectFilename: String;aOutput: TOutput; aWorkingdirectory: string): boolean;

    property oProjectItemList: TNovusList
      read foProjectItemList
      write foProjectItemList;

    property ProjectFileName: String
      read fsProjectFileName
      write fsProjectFileName;

    property BasePath: string
      read fsBasePath
      write fsBasePath;

    property  OutputConsole: Boolean
      read  fbOutputConsole
      write fbOutputConsole;

   property Createoutputdir: Boolean
      read fbcreateoutputdir
      write fbcreateoutputdir;

   // property oProjectConfig: TProjectConfig
   //   read foProjectConfig
    //  write foProjectConfig;

    property oPlugins: tObject
       read GetoPlugins
       write SetoPlugins;

    property oProjectConfigLoader: TProjectConfigLoader
      read foProjectConfigLoader
      write foProjectConfigLoader;
  end;

implementation

uses Runtime, ProjectParser, ProjectItem, ProjectItemLoader, Plugins;


constructor TProject.Create(aOutput: tOutput);
begin
  inherited Create;

  foProjectConfigLoader := TProjectConfigLoader.Create(Self, aOutput);

  foProjectItemList:= TNovusList.Create(TProjectItem);
end;

destructor TProject.Destroy;
begin
  foProjectConfigLoader.Free;

  foProjectItemList.Free;

  inherited;
end;


function TProject.GetWorkingdirectory: String;
var
  lsWorkingdirectory: String;
begin
  Result := '';

  lsWorkingdirectory := Trim(foProjectConfigLoader.workingdirectory);

  if lsWorkingdirectory <> '' then
    lsWorkingdirectory :=  IncludeTrailingPathDelimiter(foProjectConfigLoader.workingdirectory);

  if (Not DirectoryExists(lsWorkingdirectory))  or (Trim(lsWorkingdirectory) = '') then
    lsWorkingdirectory := IncludeTrailingPathDelimiter(TNovusFileUtils.AbsoluteFilePath(ProjectFileName));

  result := lsWorkingdirectory;
end;


function TProject.GetBasePath: String;
var
  lsOutputpath: string;
begin
  lsOutputpath := TNovusFileUtils.TrailingBackSlash(GetFieldAsString(oXMLDocument.Root, 'outputpath'));

  if Trim(lsOutputpath) = '' then
    lsOutputpath := TNovusFileUtils.TrailingBackSlash(GetFieldAsString(oXMLDocument.Root, 'messageslogpath'));

  if Trim(lsOutputPath) = '' then
    lsOutputPath := GetWorkingdirectory;

  if lsOutputpath <> '' then
    Result := TNovusFileUtils.TrailingBackSlash(lsOutputpath);
end;

function TProject.GetoPlugins: TObject;
begin
  Result := FoPlugins;
end;

procedure TProject.SetoPlugins(Value: tObject);
begin
  foPlugins := Value;
  oProjectConfigLoader.oPlugins := Value;
end;

function TProject.GetOutputConsole: Boolean;
begin
  Result := GetFieldAsBoolean(oXMLDocument.Root, 'outputconsole');
end;

function TProject.LoadProjectFile(aProjectFilename: String; aOutput: TOutput; aWorkingdirectory: string): boolean;
Var
  fNodeProjectItem: TJvSimpleXmlElem;
  Index: Integer;
  loProjectItem: TProjectItem;
  Tmp: string;
begin
  Result := False;

  foOutput := aOutput;

  XMLFileName := aProjectFilename;
  ProjectFileName := aProjectFilename;

  Result := Retrieve;
  if not Result then exit;

  // Project Config
  foProjectConfigLoader.LoadProjectConfig(aWorkingdirectory);

  fsBasePath := GetBasePath;

  fbOutputConsole := GetoutputConsole;
  fbCreateoutputdir := GetCreateoutputdir;

  //Project Items
  Index := 0;
  fNodeProjectItem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'projectitem', Index);
  While(fNodeProjectItem <> NIL) do
  begin
      loProjectItem:= TProjectItem.Create(self, foOutput, fNodeProjectItem);

      if TProjectItemLoader.LoadProjectItem(Self, loProjectItem, fNodeProjectItem, foOutput, (foPlugins as TPlugins) ) then
        oProjectItemList.Add(loProjectItem);
      tmp := fNodeProjectItem.SaveToString;

      fNodeProjectItem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'projectitem', Index);
    end;

end;

function TProject.GetCreateoutputdir: Boolean;
begin
  Result := GetFieldAsBoolean(oXMLDocument.Root, 'Createoutputdir');
end;







end.
